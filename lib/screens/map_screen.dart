import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import '../models/models.dart';
import '../models/location_quality_settings.dart';
import '../services/location_service.dart';
import '../services/aggregation_service.dart';
import '../services/map_lod_service.dart';
import '../services/lora_companion_service.dart';
import '../services/database_service.dart';
import '../services/upload_service.dart';
import '../services/settings_service.dart';
import '../utils/geohash_utils.dart';
import '../utils/heading_utils.dart';
import '../utils/color_blind_palette.dart';
import '../services/widget_service.dart';
import 'package:geohash_plus/geohash_plus.dart' as geohash;
import 'package:usb_serial/usb_serial.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:screenshot/screenshot.dart';
import 'package:saver_gallery/saver_gallery.dart';
import 'package:flutter_map_cache/flutter_map_cache.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:dio_cache_interceptor_file_store/dio_cache_interceptor_file_store.dart';
import 'package:flutter_map_heatmap/flutter_map_heatmap.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:typed_data';
import 'debug_log_screen.dart';
import 'debug_diagnostics_screen.dart';
import 'session_history_screen.dart';
import 'signal_trend_screen.dart';
import '../main.dart';
import '../constants/app_version.dart';
import '../services/ducting_service.dart';
import '../services/carpeater_service.dart';
import '../services/sound_service.dart';
import '../services/tile_download_service.dart';
import 'analytics_screen.dart';
import 'achievements_screen.dart';
import 'device_comparison_screen.dart';
import 'ducting_forecast_screen.dart';
import 'repeater_health_screen.dart';
import '../services/achievement_service.dart';
import '../services/radio_position_estimator.dart';
import '../services/screen_wake_service.dart';
import '../services/android_tracking_settings_service.dart';
import 'settings/settings_screen.dart';

part 'settings/settings_dialogs.dart';
part 'settings/settings_page.dart';
part 'settings/sections/about_section.dart';
part 'settings/sections/app_device_section.dart';
part 'settings/sections/backup_section.dart';
part 'settings/sections/carpeater_section.dart';
part 'settings/sections/data_management_section.dart';
part 'settings/sections/diagnostics_section.dart';
part 'settings/sections/discovery_section.dart';
part 'settings/sections/feedback_section.dart';
part 'settings/sections/location_section.dart';
part 'settings/sections/location_quality_section.dart';
part 'settings/sections/map_display_section.dart';
part 'settings/sections/online_map_section.dart';
part 'settings/sections/statistics_section.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  // App version is imported from constants/app_version.dart

  final LocationService _locationService = LocationService();
  final MapController _mapController = MapController();
  final UploadService _uploadService = UploadService();
  final SettingsService _settingsService = SettingsService();
  final ScreenshotController _screenshotController = ScreenshotController();
  final AndroidTrackingSettingsService _androidTrackingSettings =
      AndroidTrackingSettingsService();

  bool _isTracking = false;
  bool _isConnecting = false;
  int _sampleCount = 0;
  List<Sample> _samples = [];
  AggregationResult? _aggregationResult;
  double _mapLodZoom = 13;
  final LayerHitNotifier<Coverage> _coverageHitNotifier = ValueNotifier(null);
  final LayerHitNotifier<SampleCluster> _sampleHitNotifier = ValueNotifier(
    null,
  );
  AggregationResult? _cachedLodAggregation;
  int? _cachedCoverageLodPrecision;
  List<Coverage> _cachedLodCoverages = const [];
  List<Edge> _cachedLodEdges = const [];
  List<Sample>? _cachedSampleLodSource;
  int? _cachedSampleLodPrecision;
  String? _cachedSampleLodFilter;
  List<SampleCluster> _cachedSampleClusters = const [];

  String _colorMode = 'quality';
  bool _showSamples = false;
  bool _showGpsSamples = true; // Show GPS-only samples (null pingSuccess)
  bool _showSuccessfulOnly = false; // Show only samples with successful pings
  bool _showCoverage = true; // Show coverage boxes
  bool _showEdges = true;
  bool _showRepeaters = true;
  bool _autoPingEnabled = false;
  String? _ignoredRepeaterPrefix;
  String?
  _includeOnlyRepeaters; // Comma-separated list of repeater prefixes to show
  bool _filterEdgesByWhitelist = false; // Whether to apply whitelist to edges
  double _pingIntervalMeters = 805.0; // Default 0.5 miles
  int _coveragePrecision = 7; // Default precision 7 (~150m squares)

  // Repeaters
  List<Repeater> _repeaters = [];

  LatLng? _currentPosition;
  Timer? _updateTimer;
  StreamSubscription<LatLng>? _positionSubscription;
  StreamSubscription<LocationPositionSource>? _positionSourceSubscription;
  StreamSubscription<double>? _courseSubscription;
  StreamSubscription<CompassEvent>? _compassSubscription;
  StreamSubscription<void>? _sampleSavedSubscription;
  StreamSubscription<String>? _pingEventSubscription;
  StreamSubscription<double>? _distanceSubscription;
  StreamSubscription<double>? _speedSubscription;
  StreamSubscription<String>? _newRepeaterSubscription;
  StreamSubscription<String>? _deadZoneSubscription;
  StreamSubscription<PingResult>? _radioPositionSubscription;

  // Ping visual indicator
  bool _showPingPulse = false;

  // Coarse radio-derived position. This is kept visually separate from GPS.
  PingResult? _latestPingResult;
  RadioPositionEstimate? _radioPositionEstimate;
  Timer? _radioPositionExpiryTimer;

  // Distance tracking
  double _totalDistance = 0.0;
  double _currentSpeed = 0.0;
  String _distanceUnit = 'km';

  // Color blind mode
  String _colorBlindMode = 'normal';

  // Discovery timeout (5-30 seconds)
  int _discoveryTimeoutSeconds = 10;
  bool _thoroughResponseCollection = false;

  // Fuel unit ('imperial' for MPG/gal, 'metric' for L/100km/L)
  String _fuelUnit = 'metric';

  // Screenshot mode - hide UI elements
  bool _hideUIForScreenshot = false;

  // LoRa connection status
  bool _loraConnected = false;
  ConnectionType _connectionType = ConnectionType.none;
  int? _batteryPercent;
  StreamSubscription<int?>? _batterySubscription;

  // Auto-follow GPS location
  bool _followLocation = false;

  // Map rotation lock
  bool _lockRotationNorth = false;

  // Keep the display awake whenever the app is visible
  bool _keepScreenOn = false;

  // Current location marker and heading
  CurrentLocationMarkerStyle _currentLocationMarkerStyle =
      CurrentLocationMarkerStyle.circle;
  double _currentHeading = 0;
  double? _pendingHeading;
  double _pendingHeadingFactor = 0.3;
  Timer? _headingUpdateTimer;
  bool _hasCompassHeading = false;
  bool _followHeading = false;

  // Route trail
  bool _showRouteTrail = false;

  // Session filter
  WSession? _activeSessionFilter;

  // Offline tile cache
  CacheStore? _tileCacheStore;

  // Map theme is independent from the Material interface theme.
  MapThemeMode _mapThemeMode = MapThemeMode.system;

  // Heatmap
  bool _showHeatmap = false;
  final StreamController<void> _heatmapRebuildStream =
      StreamController.broadcast();

  // Aggregation cache - skip recomputation when nothing changed
  int _lastAggregatedSampleCount = -1;
  int _lastAggregatedRepeaterCount = -1;

  // Source filter for multi-device wardrive
  String? _activeSourceFilter;

  // Auto-follow throttle
  DateTime _lastAutoFollowMove = DateTime.now();
  static const _autoFollowInterval = Duration(seconds: 2);

  // Coverage prediction rings
  bool _showPredictionRings = false;
  bool _showRadioPosition = true;
  bool _beaconDbWifiPositioning = false;
  LocationQualitySettings _locationQualitySettings =
      const LocationQualitySettings();
  LocationPositionSource _positionSource = LocationPositionSource.fused;

  // Atmospheric ducting
  bool _showDucting = false;
  String _currentDuctingRisk = DuctingRisk.unknown;

  // Sound & vibration feedback
  bool _soundEnabled = false;
  bool _vibrationEnabled = false;

  // Ping mode
  String _pingMode = 'time';
  int _pingTimeInterval = 30;

  // Planned repeater markers
  List<Map<String, dynamic>> _plannedMarkers = [];

  // Delete mode
  bool _deleteMode = false;

  // Privacy zones
  List<Map<String, dynamic>> _privacyZones = [];

  // Battery saver mode
  bool _batterySaverActive = false;
  StreamSubscription<bool>? _batterySaverSubscription;

  // Quick settings overlay
  bool _showQuickSettings = false;

  // Alert toggles
  bool _deadZoneAlertsEnabled = true;
  bool _newRepeaterAlertsEnabled = true;

  // Community coverage (downloaded from web map)
  Map<String, dynamic>? _communityCoverage;
  bool _showCommunityCoverage = false;

  // Carpeater mode
  bool _carpeaterEnabled = false;
  String? _carpeaterRepeaterId;
  String? _carpeaterPassword;
  int _carpeaterInterval = 30;
  CarpeaterState _carpeaterState = CarpeaterState.disabled;
  StreamSubscription<CarpeaterState>? _carpeaterStateSubscription;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    // Initialize tile cache store
    final cacheDir = await getApplicationDocumentsDirectory();
    _tileCacheStore = FileCacheStore('${cacheDir.path}/tile_cache');

    // Initialize home screen widget
    await WidgetService.initialize();

    // Load saved settings
    await _loadSettings();

    // Load planned markers and privacy zones
    await _loadMarkers();
    await _loadPrivacyZones();

    // Subscribe to battery updates
    final loraService = _locationService.loraCompanion;
    _batterySubscription = loraService.batteryStream.listen((percent) {
      setState(() {
        _batteryPercent = percent;
      });
    });

    _radioPositionSubscription = loraService.pingResults.listen((result) {
      if (!mounted) return;
      _radioPositionExpiryTimer?.cancel();
      setState(() {
        _latestPingResult = result.status == PingStatus.success ? result : null;
        _radioPositionEstimate = _calculateRadioPositionEstimate(_repeaters);
      });
      if (result.status == PingStatus.success) {
        _radioPositionExpiryTimer = Timer(const Duration(minutes: 2), () {
          if (!mounted) return;
          setState(() {
            _latestPingResult = null;
            _radioPositionEstimate = null;
          });
        });
      }
    });

    // Subscribe to Carpeater state changes
    _carpeaterStateSubscription = _locationService.carpeaterService.stateStream
        .listen((state) {
          if (mounted) {
            setState(() {
              _carpeaterState = state;
            });
          }
        });

    // Subscribe to position updates
    _positionSubscription = _locationService.currentPositionStream.listen((
      position,
    ) {
      if (!mounted) return;
      final shouldCenterMap = _currentPosition == null;
      setState(() {
        _currentPosition = position;
      });

      if (shouldCenterMap) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _mapController.move(position, 13.0);
        });
      }

      // Auto-follow if enabled (throttled to reduce map redraws)
      if (_followLocation) {
        final now = DateTime.now();
        if (now.difference(_lastAutoFollowMove) >= _autoFollowInterval) {
          _lastAutoFollowMove = now;
          _mapController.move(position, _mapController.camera.zoom);
        }
      }
    });

    _positionSourceSubscription = _locationService.positionSourceStream.listen((
      source,
    ) {
      if (mounted) {
        setState(() {
          _positionSource = source;
        });
      }
    });

    _courseSubscription = _locationService.courseStream.listen((heading) {
      if (!_hasCompassHeading) {
        _scheduleHeadingUpdate(heading, factor: 1);
      }
    });

    _syncCompassSubscription();

    // Subscribe to sample saved events - reload map when new samples are saved
    _sampleSavedSubscription = _locationService.sampleSavedStream.listen((_) {
      _loadSamples();
    });

    // Subscribe to ping events for visual feedback
    _pingEventSubscription = _locationService.pingEventStream.listen((event) {
      if (event == 'pinging' && mounted) {
        setState(() {
          _showPingPulse = true;
        });
        // Hide pulse after 2 seconds
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              _showPingPulse = false;
            });
          }
        });
      }
    });

    // Subscribe to new repeater discovery alerts
    _newRepeaterSubscription = _locationService.loraCompanion.newRepeaterStream
        .listen((repeaterId) {
          if (mounted) {
            SoundService().playPingSuccessGood();
            _showSnackBar('🆕 New repeater discovered: $repeaterId');
          }
        });

    // Subscribe to dead zone alerts
    _deadZoneSubscription = _locationService.deadZoneStream.listen((cellHash) {
      if (mounted) {
        _showSnackBar('⚠️ Entering known dead zone ($cellHash)');
      }
    });

    // Subscribe to battery saver mode changes
    _batterySaverSubscription = _locationService.batterySaverStream.listen((
      active,
    ) {
      if (mounted) {
        setState(() {
          _batterySaverActive = active;
        });
        _showSnackBar(
          active
              ? '🔋 Battery saver ON — ping interval doubled'
              : '🔋 Battery saver OFF — normal ping interval restored',
        );
      }
    });

    // Subscribe to achievement unlocks
    AchievementService().unlockStream.listen((achievement) {
      if (mounted) {
        _showSnackBar(
          '🏆 Achievement unlocked: ${achievement.icon} ${achievement.title}',
        );
      }
    });

    // Check achievements on startup
    AchievementService().checkAndUnlock();

    // Load known repeater IDs from DB so only truly new ones trigger alerts
    final knownIds = await DatabaseService().getDistinctRepeaterIds();
    await _locationService.loraCompanion.loadKnownRepeaterIds(knownIds);

    // Load alert toggle settings
    final newRepeaterAlerts = await _settingsService
        .getNewRepeaterAlertsEnabled();
    _locationService.loraCompanion.setNewRepeaterAlertsEnabled(
      newRepeaterAlerts,
    );

    // Subscribe to distance updates (no setState — updated in _loadSamples cycle)
    _distanceSubscription = _locationService.totalDistanceStream.listen((
      distance,
    ) {
      if (mounted) {
        _totalDistance = _distanceUnit == 'miles'
            ? _locationService.totalDistanceMiles
            : _locationService.totalDistanceKm;
      }
    });

    // Subscribe to speed updates (no setState — updated in _loadSamples cycle)
    _speedSubscription = _locationService.speedStream.listen((speed) {
      if (mounted) {
        _currentSpeed = _distanceUnit == 'miles'
            ? _locationService.currentSpeedMph
            : _locationService.currentSpeedKmh;
      }
    });

    await _loadSamples();
    await _locationService.startPositionSearch();

    // Load cached community coverage for offline viewing
    final cached = await _uploadService.loadCachedCoverage();
    if (cached != null && cached['coverage'] != null) {
      setState(() {
        _communityCoverage = cached['coverage'] as Map<String, dynamic>;
      });
    }

    // Update periodically
    _updateTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _loadSamples();
    });
  }

  Future<void> _loadSettings() async {
    final showSamples = await _settingsService.getShowSamples();
    final showGpsSamples = await _settingsService.getShowGpsSamples();
    final showCoverage = await _settingsService.getShowCoverage();
    final showEdges = await _settingsService.getShowEdges();
    final showRepeaters = await _settingsService.getShowRepeaters();
    final colorMode = await _settingsService.getColorMode();
    final pingInterval = await _settingsService.getPingInterval();
    final coveragePrecision = await _settingsService.getCoveragePrecision();
    final ignoredPrefix = await _settingsService.getIgnoredRepeaterPrefix();
    final includeOnly = await _settingsService.getIncludeOnlyRepeaters();
    final filterEdges = await _settingsService.getFilterEdgesByWhitelist();
    final distanceUnit = await _settingsService.getDistanceUnit();
    final colorBlindMode = await _settingsService.getColorBlindMode();
    final discoveryTimeout = await _settingsService.getDiscoveryTimeout();
    final thoroughResponseCollection = await _settingsService
        .getThoroughResponseCollection();
    final fuelUnit = await _settingsService.getFuelUnit();
    final showRouteTrail = await _settingsService.getShowRouteTrail();
    final showHeatmap = await _settingsService.getShowHeatmap();
    final showPredictionRings = await _settingsService.getShowPredictionRings();
    final showRadioPosition = await _settingsService.getShowRadioPosition();
    final beaconDbWifiPositioning = await _settingsService
        .getBeaconDbWifiPositioning();
    final locationQualitySettings = await _settingsService
        .getLocationQualitySettings();
    final showDucting = await _settingsService.getShowDucting();
    final mapThemeMode = await _settingsService.getMapThemeMode();

    setState(() {
      _showSamples = showSamples;
      _showGpsSamples = showGpsSamples;
      _showCoverage = showCoverage;
      _showEdges = showEdges;
      _showRepeaters = showRepeaters;
      _colorMode = colorMode;
      _pingIntervalMeters = pingInterval;
      _coveragePrecision = coveragePrecision;
      _ignoredRepeaterPrefix = ignoredPrefix;
      _includeOnlyRepeaters = includeOnly;
      _filterEdgesByWhitelist = filterEdges;
      _distanceUnit = distanceUnit;
      _colorBlindMode = colorBlindMode;
      _discoveryTimeoutSeconds = discoveryTimeout;
      _thoroughResponseCollection = thoroughResponseCollection;
      _fuelUnit = fuelUnit;
      _showRouteTrail = showRouteTrail;
      _showHeatmap = showHeatmap;
      _showPredictionRings = showPredictionRings;
      _showRadioPosition = showRadioPosition;
      _beaconDbWifiPositioning = beaconDbWifiPositioning;
      _locationQualitySettings = locationQualitySettings;
      _showDucting = showDucting;
      _mapThemeMode = mapThemeMode;
    });

    // Load ping mode settings
    final pingMode = await _settingsService.getPingMode();
    final pingTimeInterval = await _settingsService.getPingTimeInterval();
    setState(() {
      _pingMode = pingMode;
      _pingTimeInterval = pingTimeInterval;
    });
    _locationService.setPingMode(pingMode);
    _locationService.setPingTimeInterval(pingTimeInterval);

    // Load sound & vibration settings
    final soundEnabled = await _settingsService.getSoundEnabled();
    final vibrationEnabled = await _settingsService.getVibrationEnabled();
    setState(() {
      _soundEnabled = soundEnabled;
      _vibrationEnabled = vibrationEnabled;
    });
    SoundService().setEnabled(soundEnabled);
    SoundService().setVibrationEnabled(vibrationEnabled);

    // Load lock rotation and successful-only filter
    final lockRotation = await _settingsService.getLockRotationNorth();
    final keepScreenOn = await _settingsService.getKeepScreenOn();
    final currentLocationMarkerStyle = await _settingsService
        .getCurrentLocationMarkerStyle();
    final showSuccessfulOnly = await _settingsService.getShowSuccessfulOnly();
    setState(() {
      _lockRotationNorth = lockRotation;
      _keepScreenOn = keepScreenOn;
      _currentLocationMarkerStyle = currentLocationMarkerStyle;
      _showSuccessfulOnly = showSuccessfulOnly;
    });
    await ScreenWakeService.instance.setAlwaysOn(keepScreenOn);

    // Load alert toggles
    final deadZoneAlerts = await _settingsService.getDeadZoneAlertsEnabled();
    final newRepeaterAlerts = await _settingsService
        .getNewRepeaterAlertsEnabled();
    setState(() {
      _deadZoneAlertsEnabled = deadZoneAlerts;
      _newRepeaterAlertsEnabled = newRepeaterAlerts;
    });

    // Load Carpeater settings
    final carpeaterEnabled = await _settingsService.getCarpeaterEnabled();
    final carpeaterRepeaterId = await _settingsService.getCarpeaterRepeaterId();
    final carpeaterPassword = await _settingsService.getCarpeaterPassword();
    final carpeaterInterval = await _settingsService.getCarpeaterInterval();
    setState(() {
      _carpeaterEnabled = carpeaterEnabled;
      _carpeaterRepeaterId = carpeaterRepeaterId;
      _carpeaterPassword = carpeaterPassword;
      _carpeaterInterval = carpeaterInterval;
    });
    _locationService.setCarpeaterMode(carpeaterEnabled);

    // Apply to services
    _locationService.setPingInterval(pingInterval);
    _locationService.setWifiPositioningEnabled(beaconDbWifiPositioning);
    _locationService.setLocationQualitySettings(locationQualitySettings);
    _locationService.loraCompanion.setIgnoredRepeaterPrefix(ignoredPrefix);
  }

  void _syncCompassSubscription() {
    _compassSubscription?.cancel();
    _compassSubscription = null;
    _hasCompassHeading = false;

    if (_currentLocationMarkerStyle != CurrentLocationMarkerStyle.arrow) {
      return;
    }

    _compassSubscription = FlutterCompass.events?.listen(
      (event) {
        final heading = event.heading;
        if (heading == null || !heading.isFinite) return;
        _hasCompassHeading = true;
        _scheduleHeadingUpdate(heading);
      },
      onError: (_) {
        _hasCompassHeading = false;
      },
    );
  }

  void _scheduleHeadingUpdate(double heading, {double factor = 0.3}) {
    _pendingHeading = HeadingUtils.normalize(heading);
    _pendingHeadingFactor = factor;
    if (_headingUpdateTimer?.isActive ?? false) return;

    _applyPendingHeading();
    _headingUpdateTimer = Timer(const Duration(milliseconds: 80), () {
      _headingUpdateTimer = null;
      _applyPendingHeading();
    });
  }

  void _applyPendingHeading() {
    final heading = _pendingHeading;
    _pendingHeading = null;
    if (heading == null || !mounted) return;

    final smoothed = HeadingUtils.interpolate(
      _currentHeading,
      heading,
      factor: _pendingHeadingFactor,
    );
    if (HeadingUtils.shortestDelta(_currentHeading, smoothed).abs() < 0.25) {
      return;
    }
    setState(() {
      _currentHeading = smoothed;
    });
    if (_followHeading) {
      _rotateMapToHeading();
    }
  }

  Future<void> _loadSamples() async {
    final count = await _locationService.getSampleCount();
    final loraService = _locationService.loraCompanion;
    final discoveredRepeaters = loraService.discoveredRepeaters;
    final isConnected = loraService.isDeviceConnected;
    final connType = loraService.connectionType;

    // Skip expensive aggregation if sample count and repeater count haven't changed
    final needsReaggregation =
        count != _lastAggregatedSampleCount ||
        discoveredRepeaters.length != _lastAggregatedRepeaterCount;

    if (needsReaggregation) {
      var samples = await _locationService.getAllSamples();

      // Apply session time filter if active
      if (_activeSessionFilter != null) {
        final start = _activeSessionFilter!.startTime;
        final end = _activeSessionFilter!.endTime ?? DateTime.now();
        samples = samples
            .where(
              (s) =>
                  s.timestamp.isAfter(
                    start.subtract(const Duration(seconds: 1)),
                  ) &&
                  s.timestamp.isBefore(end.add(const Duration(seconds: 1))),
            )
            .toList();
      }

      // Apply source filter if active
      if (_activeSourceFilter != null) {
        samples = samples
            .where((s) => s.source == _activeSourceFilter)
            .toList();
      }

      // Aggregate data with user's chosen coverage precision and repeaters
      final result = AggregationService.buildIndexes(
        samples,
        discoveredRepeaters,
        coveragePrecision: _coveragePrecision,
      );

      // Combine repeaters from both LoRa service (live) and aggregation result (historical)
      final Map<String, Repeater> repeaterMap = {};
      for (final repeater in result.repeaters) {
        repeaterMap[repeater.id] = repeater;
      }
      for (final repeater in discoveredRepeaters) {
        repeaterMap[repeater.id] = repeater;
      }

      _lastAggregatedSampleCount = count;
      _lastAggregatedRepeaterCount = discoveredRepeaters.length;

      setState(() {
        _samples = samples;
        _sampleCount = count;
        _aggregationResult = result;
        _loraConnected = isConnected;
        _connectionType = connType;
        _autoPingEnabled = _locationService.isAutoPingEnabled;
        _repeaters = repeaterMap.values.toList();
        _radioPositionEstimate = _calculateRadioPositionEstimate(
          repeaterMap.values,
        );
      });
    } else {
      // Just update connection status and auto-ping state if changed
      final newAutoPing = _locationService.isAutoPingEnabled;
      if (_loraConnected != isConnected ||
          _connectionType != connType ||
          _autoPingEnabled != newAutoPing ||
          _sampleCount != count) {
        setState(() {
          _sampleCount = count;
          _loraConnected = isConnected;
          _connectionType = connType;
          _autoPingEnabled = newAutoPing;
        });
      }
    }

    // Update ducting badge if enabled
    if (_showDucting) {
      final risk = await _locationService.ductingService.getLatestRisk();
      if (mounted && risk != _currentDuctingRisk) {
        setState(() {
          _currentDuctingRisk = risk;
        });
      }
    }

    // Update home screen widget
    final connLabel = isConnected
        ? (connType == ConnectionType.usb ? 'USB' : 'BT')
        : '---';
    final pingSamples = _samples.where((s) => s.pingSuccess != null).toList();
    final successCount = pingSamples.where((s) => s.pingSuccess == true).length;
    final rate = pingSamples.isNotEmpty
        ? '${(successCount / pingSamples.length * 100).toStringAsFixed(0)}%'
        : '--';
    final dist = _isTracking
        ? '${_totalDistance.toStringAsFixed(1)} ${_distanceUnit == "miles" ? "mi" : "km"}'
        : '--';
    WidgetService.update(
      sampleCount: count,
      isTracking: _isTracking,
      connectionLabel: connLabel,
      successRate: rate,
      distance: dist,
    );
  }

  Future<void> _toggleTracking() async {
    if (_isTracking) {
      // Persist session distance before stopping
      final sessionMeters = _locationService.totalDistanceMeters;
      if (sessionMeters > 0) {
        await _settingsService.addToTotalDistanceDriven(sessionMeters);
      }
      // Stop tracking and auto-ping
      await _locationService.stopTracking();
      _locationService.disableAutoPing();
      setState(() {
        _isTracking = false;
        _autoPingEnabled = false;
      });
      // Check for newly unlocked achievements
      AchievementService().checkAndUnlock();
    } else {
      if (!await _prepareAndroidTracking()) return;

      // Start tracking
      final started = await _locationService.startTracking();
      if (started) {
        // Auto-enable ping or Carpeater if LoRa is connected
        if (_loraConnected && _carpeaterEnabled) {
          _locationService.setCarpeaterMode(true);
          final carpeaterStarted = await _locationService.startCarpeater();
          setState(() {
            _isTracking = true;
            _autoPingEnabled = false;
          });
          _showSnackBar(
            carpeaterStarted
                ? 'Carpeater mode started'
                : 'Carpeater failed — check settings',
          );
        } else if (_loraConnected) {
          _locationService.enableAutoPing();
          setState(() {
            _isTracking = true;
            _autoPingEnabled = true;
          });
          _showSnackBar('Location tracking and auto-ping started');
        } else {
          setState(() {
            _isTracking = true;
          });
          _showSnackBar('Location tracking started');
        }
      } else {
        _showSnackBar(
          _locationService.lastStartError ??
              'Failed to start location tracking. Check Android settings.',
        );
      }
    }
  }

  Future<bool> _prepareAndroidTracking() async {
    if (!Platform.isAndroid) return true;

    final foregroundStatus = await Permission.locationWhenInUse.request();
    if (!foregroundStatus.isGranted) return true;

    final accuracy = await Geolocator.getLocationAccuracy();
    if (accuracy != LocationAccuracyStatus.precise) {
      await _showSettingsDialog(
        title: 'Precise location required',
        message:
            'Wardriving needs precise location. In Android app permissions, '
            'enable “Use precise location”, then tap Start again.',
        actionLabel: 'Open app settings',
        onOpen: openAppSettings,
      );
      return false;
    }

    var backgroundStatus = await Permission.locationAlways.status;
    if (!backgroundStatus.isGranted) {
      final shouldRequest = await _showRequestDialog(
        title: 'Allow location all the time',
        message:
            'MeshCore Wardrive records while the screen is off or another app '
            'is open. Android needs location access set to “Allow all the time”.',
      );
      if (!shouldRequest) return false;

      backgroundStatus = await Permission.locationAlways.request();
      if (!backgroundStatus.isGranted) {
        await _showSettingsDialog(
          title: 'Background location required',
          message:
              'Select Permissions → Location → Allow all the time, then return '
              'and tap Start again.',
          actionLabel: 'Open app settings',
          onOpen: openAppSettings,
        );
        return false;
      }
    }

    final batteryStatus = await Permission.ignoreBatteryOptimizations.status;
    if (!batteryStatus.isGranted) {
      final shouldRequest = await _showRequestDialog(
        title: 'Unrestricted battery use',
        message:
            'Allow MeshCore Wardrive to ignore battery optimizations so Android '
            'does not pause GPS, radio communication, or Wi-Fi scans during a drive.',
      );
      if (shouldRequest) {
        await Permission.ignoreBatteryOptimizations.request();
      }
    }

    if (_beaconDbWifiPositioning) {
      if (!await _requestWifiScanThrottlingDisabled()) return false;
    }

    return true;
  }

  Future<bool> _requestWifiScanThrottlingDisabled() async {
    if (!Platform.isAndroid) return true;

    final throttlingEnabled = await _androidTrackingSettings
        .isWifiScanThrottlingEnabled();
    if (throttlingEnabled == false || !mounted) return true;

    final openedSettings = await _showSettingsDialog(
      title: 'Disable Wi-Fi scan throttling',
      message:
          'Android does not let apps change this setting automatically. In '
          'Developer options, turn off “Wi-Fi scan throttling” for timely '
          'beaconDB position updates.',
      actionLabel: 'Developer options',
      onOpen: _androidTrackingSettings.openWifiScanThrottlingSettings,
    );
    return !openedSettings;
  }

  Future<bool> _showRequestDialog({
    required String title,
    required String message,
  }) async {
    if (!mounted) return false;
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Not now'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Continue'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<bool> _showSettingsDialog({
    required String title,
    required String message,
    required String actionLabel,
    required Future<bool> Function() onOpen,
  }) async {
    if (!mounted) return false;
    final shouldOpen = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Not now'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(actionLabel),
          ),
        ],
      ),
    );
    if (shouldOpen != true) return false;
    return onOpen();
  }

  Future<void> _clearData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Map History?'),
        content: Text(
          'This will permanently delete all $_sampleCount samples and coverage data from the map.\n\nThis action cannot be undone.',
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _locationService.clearAllSamples();
      await _loadSamples();
      _showSnackBar('Deleted $_sampleCount samples');
    }
  }

  Future<void> _exportData() async {
    // Ask user for export format
    final format = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Format'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.code),
              title: const Text('JSON'),
              subtitle: const Text('Full data with all fields'),
              onTap: () => Navigator.pop(context, 'json'),
            ),
            ListTile(
              leading: const Icon(Icons.table_chart),
              title: const Text('CSV'),
              subtitle: const Text('Spreadsheet-compatible'),
              onTap: () => Navigator.pop(context, 'csv'),
            ),
            ListTile(
              leading: const Icon(Icons.route),
              title: const Text('GPX'),
              subtitle: const Text('GPS track for mapping apps'),
              onTap: () => Navigator.pop(context, 'gpx'),
            ),
            ListTile(
              leading: const Icon(Icons.map),
              title: const Text('KML'),
              subtitle: const Text('Google Earth format'),
              onTap: () => Navigator.pop(context, 'kml'),
            ),
          ],
        ),
      ),
    );

    if (format == null) return;

    // Ask save or share
    final choice = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Export as ${format.toUpperCase()}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'save'),
            child: const Text('Save to Folder'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'share'),
            child: const Text('Share'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (choice == null) return;

    try {
      final samples = await _locationService.getAllSamples();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      String content;
      String fileName;
      String extension;

      switch (format) {
        case 'csv':
          content = _buildCsvExport(samples);
          extension = 'csv';
          fileName = 'meshcore_export_$timestamp.csv';
          break;
        case 'gpx':
          content = _buildGpxExport(samples);
          extension = 'gpx';
          fileName = 'meshcore_export_$timestamp.gpx';
          break;
        case 'kml':
          content = _buildKmlExport(samples);
          extension = 'kml';
          fileName = 'meshcore_export_$timestamp.kml';
          break;
        default:
          // Include discovered repeater contacts in the export
          final repeaterJsonList = _repeaters
              .where(
                (r) =>
                    r.position.latitude != 0.0 || r.position.longitude != 0.0,
              )
              .map((r) => r.toJson())
              .toList();
          final data = await DatabaseService().exportAllData(
            repeaters: repeaterJsonList,
          );
          content = jsonEncode(data);
          extension = 'json';
          fileName = 'meshcore_export_$timestamp.json';
      }

      if (choice == 'save') {
        await FilePicker.platform.saveFile(
          dialogTitle: 'Save Export',
          fileName: fileName,
          type: FileType.custom,
          allowedExtensions: [extension],
          bytes: utf8.encode(content),
        );
        _showSnackBar(
          'Exported ${samples.length} samples as ${format.toUpperCase()}',
        );
      } else if (choice == 'share') {
        final directory = await getExternalStorageDirectory();
        final file = File('${directory!.path}/$fileName');
        await file.writeAsString(content);

        await Share.shareXFiles(
          [XFile(file.path)],
          subject: 'MeshCore Wardrive Export',
          text: 'Exported ${samples.length} samples from MeshCore Wardrive',
        );
        _showSnackBar('Export shared');
      }
    } catch (e) {
      _showSnackBar('Export failed: $e');
    }
  }

  String _buildCsvExport(List<Sample> samples) {
    final buffer = StringBuffer();
    buffer.writeln('id,lat,lon,timestamp,geohash,rssi,snr,pingSuccess,path');
    for (final s in samples) {
      buffer.writeln(
        '${s.id},${s.position.latitude},${s.position.longitude},'
        '${s.timestamp.toIso8601String()},${s.geohash},'
        '${s.rssi ?? ''},${s.snr ?? ''},'
        '${s.pingSuccess ?? ''},${s.path ?? ''}',
      );
    }
    return buffer.toString();
  }

  String _buildGpxExport(List<Sample> samples) {
    final sorted = List<Sample>.from(samples)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln('<gpx version="1.1" creator="MeshCore Wardrive"');
    buffer.writeln('  xmlns="http://www.topografix.com/GPX/1/1">');
    buffer.writeln('  <trk>');
    buffer.writeln(
      '    <name>MeshCore Wardrive ${DateFormat('yyyy-MM-dd').format(DateTime.now())}</name>',
    );
    buffer.writeln('    <trkseg>');
    for (final s in sorted) {
      buffer.writeln(
        '      <trkpt lat="${s.position.latitude}" lon="${s.position.longitude}">',
      );
      buffer.writeln(
        '        <time>${s.timestamp.toUtc().toIso8601String()}</time>',
      );
      if (s.rssi != null) {
        buffer.writeln(
          '        <desc>RSSI: ${s.rssi} dBm, SNR: ${s.snr} dB</desc>',
        );
      }
      buffer.writeln('      </trkpt>');
    }
    buffer.writeln('    </trkseg>');
    buffer.writeln('  </trk>');
    buffer.writeln('</gpx>');
    return buffer.toString();
  }

  String _buildKmlExport(List<Sample> samples) {
    final sorted = List<Sample>.from(samples)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final coords = sorted
        .map((s) => '${s.position.longitude},${s.position.latitude},0')
        .join('\n            ');

    // Build placemarks for ping results
    final placemarks = StringBuffer();
    for (final s in sorted.where((s) => s.pingSuccess != null)) {
      final icon = s.pingSuccess == true ? '#successStyle' : '#failStyle';
      placemarks.writeln('    <Placemark>');
      placemarks.writeln('      <styleUrl>$icon</styleUrl>');
      placemarks.writeln(
        '      <description>${s.pingSuccess == true ? 'Success' : 'Failed'}${s.rssi != null ? ' RSSI:${s.rssi}' : ''}</description>',
      );
      placemarks.writeln(
        '      <Point><coordinates>${s.position.longitude},${s.position.latitude},0</coordinates></Point>',
      );
      placemarks.writeln('    </Placemark>');
    }

    return '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
  <Document>
    <name>MeshCore Wardrive ${DateFormat('yyyy-MM-dd').format(DateTime.now())}</name>
    <Style id="successStyle"><IconStyle><color>ff00ff00</color></IconStyle></Style>
    <Style id="failStyle"><IconStyle><color>ff0000ff</color></IconStyle></Style>
    <Placemark>
      <name>Route Trail</name>
      <LineString>
        <coordinates>
            $coords
        </coordinates>
      </LineString>
    </Placemark>
$placemarks  </Document>
</kml>''';
  }

  Future<void> _importData() async {
    try {
      // Pick JSON file(s) — allow multiple for community merge
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        allowMultiple: true,
      );

      if (result == null || result.files.isEmpty) return;

      int totalSamplesImported = 0;
      int totalSessionsImported = 0;
      final Set<String> sources = {};

      for (final pickedFile in result.files) {
        if (pickedFile.path == null) continue;
        final file = File(pickedFile.path!);
        final jsonString = await file.readAsString();
        final dynamic jsonData = jsonDecode(jsonString);

        // Use unified import that handles both old (array) and new (object) formats
        final counts = await DatabaseService().importAllData(jsonData);
        totalSamplesImported += counts['samples'] ?? 0;
        totalSessionsImported += counts['sessions'] ?? 0;

        // Extract sources for display
        if (jsonData is Map<String, dynamic> &&
            jsonData.containsKey('samples')) {
          for (final s in (jsonData['samples'] as List<dynamic>)) {
            final map = s as Map<String, dynamic>;
            if (map['source'] != null) sources.add(map['source'] as String);
          }
        } else if (jsonData is List) {
          for (final s in jsonData) {
            final map = s as Map<String, dynamic>;
            if (map['source'] != null) sources.add(map['source'] as String);
          }
        }
      }

      // Reload map
      _lastAggregatedSampleCount = -1;
      await _loadSamples();

      final sourceLabel = sources.isNotEmpty
          ? ' from ${sources.join(', ')}'
          : '';
      final sessionLabel = totalSessionsImported > 0
          ? ', $totalSessionsImported sessions'
          : '';
      _showSnackBar(
        'Imported $totalSamplesImported samples$sessionLabel$sourceLabel',
      );
    } catch (e) {
      _showSnackBar('Import failed: $e');
    }
  }

  Future<void> _exportSettings() async {
    try {
      final jsonString = await _settingsService.exportSettingsJson();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = 'meshcore_settings_$timestamp.json';

      // Ask save or share
      final choice = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Export Settings'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, 'save'),
              child: const Text('Save to Folder'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, 'share'),
              child: const Text('Share'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      );

      if (choice == null) return;

      if (choice == 'save') {
        await FilePicker.platform.saveFile(
          dialogTitle: 'Save Settings',
          fileName: fileName,
          type: FileType.custom,
          allowedExtensions: ['json'],
          bytes: utf8.encode(jsonString),
        );
        _showSnackBar('Settings exported');
      } else if (choice == 'share') {
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/$fileName');
        await file.writeAsString(jsonString);
        await Share.shareXFiles([
          XFile(file.path),
        ], text: 'MeshCore Wardrive Settings');
      }
    } catch (e) {
      _showSnackBar('Export failed: $e');
    }
  }

  Future<void> _importSettings() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.single.path == null) return;

      final file = File(result.files.single.path!);
      final jsonString = await file.readAsString();

      // Show confirmation dialog
      if (!mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Import Settings'),
          content: const Text(
            'This will overwrite your current app settings '
            '(display options, ping settings, upload servers, carpeater config, etc).\n\n'
            'Your wardrive data will NOT be affected.\n\n'
            'Continue?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Import'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      final applied = await _settingsService.importSettingsJson(jsonString);

      // Reload settings to apply changes
      await _loadSettings();
      _lastAggregatedSampleCount = -1; // Force reaggregation
      await _loadSamples();

      _showSnackBar('Imported $applied settings');
    } on FormatException catch (e) {
      _showSnackBar('Invalid settings file: ${e.message}');
    } catch (e) {
      _showSnackBar('Import failed: $e');
    }
  }

  // ============================================================================
  // PLANNED MARKERS
  // ============================================================================

  Future<void> _loadMarkers() async {
    final markers = await DatabaseService().getAllMarkers();
    setState(() {
      _plannedMarkers = markers;
    });
  }

  void _handleMapLongPress(LatLng point) async {
    final controller = TextEditingController();
    final label = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Planned Repeater'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Label (optional)',
                hintText: 'e.g., Hilltop near Tracyton',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Add Marker'),
          ),
        ],
      ),
    );

    if (label != null) {
      await DatabaseService().addMarker(
        point.latitude,
        point.longitude,
        label.isEmpty ? null : label,
      );
      await _loadMarkers();
      _showSnackBar('Planned repeater marker added');
    }
  }

  void _showMarkerInfo(Map<String, dynamic> marker) {
    final lat = marker['lat'] as double;
    final lon = marker['lon'] as double;
    final label = marker['label'] as String?;
    final id = marker['id'] as int;
    final createdAt = DateTime.fromMillisecondsSinceEpoch(
      marker['created_at'] as int,
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(label ?? 'Planned Repeater'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Lat: ${lat.toStringAsFixed(6)}'),
            Text('Lon: ${lon.toStringAsFixed(6)}'),
            Text(
              'Added: ${DateFormat('MMM d, yyyy').format(createdAt)}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await DatabaseService().deleteMarker(id);
              await _loadMarkers();
              _showSnackBar('Marker deleted');
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildPlannedMarkersLayer() {
    if (_plannedMarkers.isEmpty) return const SizedBox.shrink();

    final markers = _plannedMarkers.map((m) {
      final lat = m['lat'] as double;
      final lon = m['lon'] as double;
      final label = m['label'] as String?;

      return Marker(
        point: LatLng(lat, lon),
        width: 36,
        height: 36,
        child: GestureDetector(
          onTap: () => _showMarkerInfo(m),
          child: const Icon(Icons.add_location, color: Colors.amber, size: 36),
        ),
      );
    }).toList();

    return MarkerLayer(markers: markers);
  }

  // ============================================================================
  // PRIVACY ZONES
  // ============================================================================

  Future<void> _loadPrivacyZones() async {
    final zones = await DatabaseService().getAllPrivacyZones();
    setState(() {
      _privacyZones = zones;
    });
  }

  Future<void> _addPrivacyZone(LatLng center) async {
    final radiusOptions = [
      {'label': '500m (~0.3 mi)', 'meters': 500.0},
      {'label': '1 km (~0.6 mi)', 'meters': 1000.0},
      {'label': '2 km (~1.2 mi)', 'meters': 2000.0},
      {'label': '5 km (~3 mi)', 'meters': 5000.0},
    ];
    double selectedRadius = 1000.0;
    final labelController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add Privacy Zone'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Center: ${center.latitude.toStringAsFixed(5)}, ${center.longitude.toStringAsFixed(5)}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              const Text(
                'Data inside this zone will be excluded from uploads and exports.',
                style: TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: labelController,
                decoration: const InputDecoration(
                  labelText: 'Label (optional)',
                  hintText: 'e.g., Home',
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Radius:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              ...radiusOptions.map(
                (opt) => RadioListTile<double>(
                  title: Text(opt['label'] as String),
                  value: opt['meters'] as double,
                  groupValue: selectedRadius,
                  onChanged: (v) => setDialogState(() => selectedRadius = v!),
                  dense: true,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Add Zone'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      await DatabaseService().addPrivacyZone(
        center.latitude,
        center.longitude,
        selectedRadius,
        labelController.text.isEmpty ? null : labelController.text,
      );
      await _loadPrivacyZones();
      _showSnackBar('Privacy zone added');
    }
  }

  Widget _buildPrivacyZonesLayer() {
    if (_privacyZones.isEmpty) return const SizedBox.shrink();

    final polygons = <Polygon>[];
    for (final zone in _privacyZones) {
      final center = LatLng(zone['lat'] as double, zone['lon'] as double);
      final radius = zone['radius_meters'] as double;
      final points = _circlePoints(center, radius, segments: 48);
      polygons.add(
        Polygon(
          points: points,
          color: Colors.grey.withValues(alpha: 0.15),
          borderColor: Colors.grey.withValues(alpha: 0.5),
          borderStrokeWidth: 2,
          isFilled: true,
        ),
      );
    }

    return PolygonLayer(polygons: polygons);
  }

  // ============================================================================
  // DELETE MODE
  // ============================================================================

  void _deleteSample(Sample sample) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Sample'),
        content: Text(
          'Delete this ${sample.pingSuccess == true
              ? "successful"
              : sample.pingSuccess == false
              ? "failed"
              : "GPS-only"} '
          'sample from ${DateFormat('MMM d HH:mm').format(sample.timestamp)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await DatabaseService().deleteSample(sample.id);
      _lastAggregatedSampleCount = -1;
      await _loadSamples();
      _showSnackBar('Sample deleted');
    }
  }

  void _deleteCoverageCell(Coverage coverage) async {
    final total = (coverage.received + coverage.lost).round();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Coverage Cell'),
        content: Text(
          'Delete all $total samples in this coverage area?\n\n'
          'Cell: ${coverage.id}\n'
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Delete All',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final deleted = await DatabaseService().deleteSamplesByGeohash(
        coverage.id,
      );
      _lastAggregatedSampleCount = -1;
      await _loadSamples();
      _showSnackBar('Deleted $deleted samples from cell');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  void _updateMapState(VoidCallback callback) {
    if (!mounted) return;
    setState(callback);
  }

  int get _coverageLodPrecision => MapLodService.precisionForZoom(
    _mapLodZoom,
    maxPrecision: _coveragePrecision,
  );

  int get _sampleLodPrecision =>
      MapLodService.precisionForZoom(_mapLodZoom, maxPrecision: 8);

  void _updateMapLodZoom(double zoom) {
    final oldCoveragePrecision = _coverageLodPrecision;
    final oldSamplePrecision = _sampleLodPrecision;
    final newCoveragePrecision = MapLodService.precisionForZoom(
      zoom,
      maxPrecision: _coveragePrecision,
    );
    final newSamplePrecision = MapLodService.precisionForZoom(
      zoom,
      maxPrecision: 8,
    );

    if (oldCoveragePrecision == newCoveragePrecision &&
        oldSamplePrecision == newSamplePrecision) {
      return;
    }

    setState(() {
      _mapLodZoom = zoom;
    });
  }

  void _ensureCoverageLod() {
    final aggregation = _aggregationResult;
    final precision = _coverageLodPrecision;
    if (aggregation == null) {
      _cachedLodAggregation = null;
      _cachedLodCoverages = const [];
      _cachedLodEdges = const [];
      return;
    }
    if (identical(_cachedLodAggregation, aggregation) &&
        _cachedCoverageLodPrecision == precision) {
      return;
    }

    final coverages = MapLodService.aggregateCoverages(
      aggregation.coverages,
      precision: precision,
    );
    _cachedLodAggregation = aggregation;
    _cachedCoverageLodPrecision = precision;
    _cachedLodCoverages = coverages;
    _cachedLodEdges = MapLodService.aggregateEdges(
      aggregation.edges,
      coverages,
      precision: precision,
    );
  }

  List<SampleCluster> _sampleClustersForCurrentLod() {
    final filterKey = [
      _showGpsSamples,
      _showSuccessfulOnly,
      _includeOnlyRepeaters ?? '',
    ].join('|');
    final precision = _sampleLodPrecision;
    if (identical(_cachedSampleLodSource, _samples) &&
        _cachedSampleLodPrecision == precision &&
        _cachedSampleLodFilter == filterKey) {
      return _cachedSampleClusters;
    }

    final allowedPrefixes = _includeOnlyRepeaters
        ?.split(',')
        .map((value) => value.trim().toUpperCase())
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
    final filteredSamples = _samples.where((sample) {
      if (!_showGpsSamples && sample.pingSuccess == null) return false;
      if (_showSuccessfulOnly && sample.pingSuccess != true) return false;
      if (allowedPrefixes != null && allowedPrefixes.isNotEmpty) {
        final sampleNodeId = sample.path?.toUpperCase() ?? '';
        if (!allowedPrefixes.any(sampleNodeId.startsWith)) return false;
      }
      return true;
    });

    _cachedSampleLodSource = _samples;
    _cachedSampleLodPrecision = precision;
    _cachedSampleLodFilter = filterKey;
    _cachedSampleClusters = MapLodService.aggregateSamples(
      filteredSamples,
      precision: precision,
    );
    return _cachedSampleClusters;
  }

  Future<void> _checkForUpdates() async {
    try {
      final response = await http
          .get(
            Uri.parse(
              'https://api.github.com/repos/mintylinux/Meshcore-Wardrive-Android/releases/latest',
            ),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final tagName = data['tag_name'].toString();
        // Extract version from tag like "Meshcore-Wardrive-Android-1.0.2"
        final latestVersion = tagName.split('-').last;

        if (latestVersion != appVersion) {
          if (!mounted) return;
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Update Available'),
              content: Text(
                'New version $latestVersion is available!\n\n'
                'Current version: $appVersion\n\n'
                'Would you like to download it?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Later'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _openGitHub();
                  },
                  child: const Text('Download'),
                ),
              ],
            ),
          );
        } else {
          _showSnackBar('You\'re on the latest version!');
        }
      } else {
        _showSnackBar('Could not check for updates');
      }
    } on SocketException {
      _showSnackBar('No internet connection. Try again when you are online.');
    } on TimeoutException {
      _showSnackBar('Update check timed out. Try again later.');
    } catch (_) {
      _showSnackBar('Could not check for updates');
    }
  }

  Future<void> _openGitHub() async {
    final url = Uri.parse(
      'https://github.com/mintylinux/Meshcore-Wardrive-Android/releases',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      _showSnackBar('Could not open GitHub');
    }
  }

  void _toggleFollowLocation() {
    setState(() {
      _followLocation = !_followLocation;
    });

    if (_followLocation) {
      // Center on current location when enabling follow
      if (_currentPosition != null) {
        _mapController.move(_currentPosition!, _mapController.camera.zoom);
      }
      _showSnackBar('Auto-follow enabled');
    } else {
      _showSnackBar('Auto-follow disabled');
    }
  }

  void _handleCompassButton() {
    final canFollowHeading =
        _currentLocationMarkerStyle == CurrentLocationMarkerStyle.arrow &&
        !_lockRotationNorth;

    if (!canFollowHeading) {
      setState(() {
        _followHeading = false;
      });
      _mapController.rotate(0);
      _showSnackBar('Map reset to north');
      return;
    }

    setState(() {
      _followHeading = !_followHeading;
    });

    if (_followHeading) {
      _rotateMapToHeading();
      _showSnackBar('Heading-up enabled');
    } else {
      _mapController.rotate(0);
      _showSnackBar('Heading-up disabled — map reset to north');
    }
  }

  void _rotateMapToHeading() {
    _mapController.rotate(HeadingUtils.mapRotationForHeading(_currentHeading));
  }

  Future<void> _captureScreenshot() async {
    try {
      // Hide UI elements
      setState(() {
        _hideUIForScreenshot = true;
      });

      // Wait for UI to update
      await Future.delayed(const Duration(milliseconds: 300));

      // Capture screenshot
      final Uint8List? imageBytes = await _screenshotController.capture(
        pixelRatio: 2.0, // Higher quality
      );

      // Restore UI
      setState(() {
        _hideUIForScreenshot = false;
      });

      if (imageBytes == null) {
        _showSnackBar('Failed to capture screenshot');
        return;
      }

      // Save to gallery
      final String fileName =
          'meshcore_wardrive_${DateTime.now().millisecondsSinceEpoch}.png';
      final result = await SaverGallery.saveImage(
        imageBytes,
        quality: 100,
        fileName: fileName,
        androidRelativePath: "Pictures/MeshCore",
        skipIfExists: false,
      );

      if (result.isSuccess) {
        _showSnackBar('Screenshot saved to gallery!');

        // Ask if user wants to share
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Screenshot Saved'),
            content: const Text('Would you like to share the screenshot?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  // Save temp file and share
                  final tempDir = await getTemporaryDirectory();
                  final file = File('${tempDir.path}/meshcore_screenshot.png');
                  await file.writeAsBytes(imageBytes);
                  await Share.shareXFiles([
                    XFile(file.path),
                  ], text: 'MeshCore Wardrive Coverage Map');
                },
                child: const Text('Yes'),
              ),
            ],
          ),
        );
      } else {
        _showSnackBar('Failed to save screenshot');
      }
    } catch (e) {
      // Restore UI on error
      setState(() {
        _hideUIForScreenshot = false;
      });
      _showSnackBar('Error capturing screenshot: $e');
    }
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    _batterySubscription?.cancel();
    _positionSubscription?.cancel();
    _positionSourceSubscription?.cancel();
    _courseSubscription?.cancel();
    _compassSubscription?.cancel();
    _headingUpdateTimer?.cancel();
    _sampleSavedSubscription?.cancel();
    _pingEventSubscription?.cancel();
    _distanceSubscription?.cancel();
    _speedSubscription?.cancel();
    _newRepeaterSubscription?.cancel();
    _deadZoneSubscription?.cancel();
    _radioPositionSubscription?.cancel();
    _radioPositionExpiryTimer?.cancel();
    _batterySaverSubscription?.cancel();
    _heatmapRebuildStream.close();
    _coverageHitNotifier.dispose();
    _sampleHitNotifier.dispose();
    _locationService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MeshCore Wardrive'),
        actions: [
          IconButton(
            icon: const Icon(Icons.terminal),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const DebugLogScreen()),
              );
            },
            tooltip: 'Debug Terminal',
          ),
          IconButton(
            icon: const Icon(Icons.camera_alt),
            onPressed: _captureScreenshot,
            tooltip: 'Screenshot',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showSettings,
          ),
        ],
      ),
      body: Screenshot(
        controller: _screenshotController,
        child: Stack(
          children: [
            _buildMap(),
            if (!_hideUIForScreenshot) _buildControlPanel(),
            if (_showQuickSettings)
              Positioned(
                bottom: 80,
                right: 16,
                child: Card(
                  elevation: 8,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Quick Settings',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () =>
                                  setState(() => _showQuickSettings = false),
                              child: const Icon(
                                Icons.close,
                                size: 18,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Ping Dist: ',
                              style: TextStyle(fontSize: 12),
                            ),
                            DropdownButton<double>(
                              value: _pingIntervalMeters,
                              isDense: true,
                              items: const [
                                DropdownMenuItem(
                                  value: 200.0,
                                  child: Text(
                                    '200m',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 400.0,
                                  child: Text(
                                    '400m',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 805.0,
                                  child: Text(
                                    '0.5mi',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 1609.0,
                                  child: Text(
                                    '1mi',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),
                              ],
                              onChanged: (v) async {
                                setState(() => _pingIntervalMeters = v!);
                                _locationService.setPingInterval(v!);
                                await _settingsService.setPingInterval(v);
                              },
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Timeout: ',
                              style: TextStyle(fontSize: 12),
                            ),
                            DropdownButton<int>(
                              value: _discoveryTimeoutSeconds,
                              isDense: true,
                              items: const [
                                DropdownMenuItem(
                                  value: 10,
                                  child: Text(
                                    '10s',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 15,
                                  child: Text(
                                    '15s',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 20,
                                  child: Text(
                                    '20s',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 30,
                                  child: Text(
                                    '30s',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),
                              ],
                              onChanged: (v) async {
                                setState(() => _discoveryTimeoutSeconds = v!);
                                await _settingsService.setDiscoveryTimeout(v!);
                              },
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Mode: ',
                              style: TextStyle(fontSize: 12),
                            ),
                            DropdownButton<String>(
                              value: _pingMode,
                              isDense: true,
                              items: const [
                                DropdownMenuItem(
                                  value: 'distance',
                                  child: Text(
                                    'Distance',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 'time',
                                  child: Text(
                                    'Time',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 'both',
                                  child: Text(
                                    'Both',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),
                              ],
                              onChanged: (v) async {
                                setState(() => _pingMode = v!);
                                await _settingsService.setPingMode(v!);
                                _locationService.setPingMode(v);
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            if (_deleteMode)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  color: Colors.red.withValues(alpha: 0.9),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Row(
                      children: [
                        const Icon(Icons.delete, color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'DELETE MODE: Tap a coverage square or sample to delete',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => setState(() => _deleteMode = false),
                          child: const Text(
                            'EXIT',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: _hideUIForScreenshot
          ? null
          : Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FloatingActionButton(
                  heroTag: 'compass',
                  mini: true,
                  onPressed: _handleCompassButton,
                  tooltip:
                      _currentLocationMarkerStyle ==
                              CurrentLocationMarkerStyle.arrow &&
                          !_lockRotationNorth
                      ? _followHeading
                            ? 'Stop heading-up and reset north'
                            : 'Rotate map with heading'
                      : 'Reset to North',
                  backgroundColor: _followHeading ? Colors.blue : null,
                  child: const Icon(Icons.navigation),
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  heroTag: 'location',
                  mini: true,
                  onPressed: _toggleFollowLocation,
                  backgroundColor: _followLocation ? Colors.blue : null,
                  child: Icon(
                    _followLocation ? Icons.gps_fixed : Icons.gps_not_fixed,
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onDoubleTap: () =>
                      setState(() => _showQuickSettings = !_showQuickSettings),
                  child: FloatingActionButton(
                    heroTag: 'tracking',
                    onPressed: _toggleTracking,
                    backgroundColor: _isTracking ? Colors.red : Colors.green,
                    child: Icon(_isTracking ? Icons.stop : Icons.play_arrow),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildMap() {
    final isDarkMode = _usesDarkMapTiles(context);

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _currentPosition ?? GeohashUtils.centerPos,
        initialZoom: 13.0,
        minZoom: 3.0,
        maxZoom: 18.0,
        interactionOptions: InteractionOptions(
          flags: _lockRotationNorth
              ? InteractiveFlag.all &
                    ~InteractiveFlag
                        .rotate // Disable rotation
              : InteractiveFlag.all, // Allow all interactions
        ),
        onTap: (tapPosition, point) => _handleMapTap(point),
        onLongPress: (tapPosition, point) => _handleMapLongPress(point),
        onMapEvent: (event) {
          _updateMapLodZoom(event.camera.zoom);

          if (event is MapEventRotate &&
              event.source != MapEventSource.mapController &&
              _followHeading) {
            setState(() {
              _followHeading = false;
            });
          }

          // Disable follow mode if user manually pans/drags the map
          if (event is MapEventMoveStart &&
              event.source == MapEventSource.mapController) {
            // Ignore programmatic moves (from auto-follow)
            return;
          }
          if (event is MapEventMoveStart && _followLocation) {
            setState(() {
              _followLocation = false;
            });
          }
        },
      ),
      children: [
        TileLayer(
          urlTemplate: isDarkMode
              ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png'
              : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          subdomains: isDarkMode ? const ['a', 'b', 'c', 'd'] : const [],
          userAgentPackageName: 'com.meshcore.wardrive',
          tileProvider: _tileCacheStore != null
              ? CachedTileProvider(store: _tileCacheStore!)
              : null,
        ),
        if (_showRouteTrail) _buildRouteTrailLayer(),
        if (_showHeatmap) _buildHeatmapLayer(),
        if (_showPredictionRings) _buildPredictionRingsLayer(),
        _buildPrivacyZonesLayer(),
        if (_showCommunityCoverage && _communityCoverage != null)
          _buildCommunityCoverageLayer(),
        if (_showCoverage) ..._buildCoverageLayers(),
        if (_showSamples) _buildSampleLayer(),
        if (_showEdges) _buildEdgeLayer(),
        if (_showRepeaters) _buildRepeaterLayer(),
        if (_showRadioPosition) ..._buildRadioPositionLayers(),
        _buildPlannedMarkersLayer(),
        if (_currentPosition != null && !_hideUIForScreenshot)
          _buildCurrentLocationLayer(),
      ],
    );
  }

  Widget _buildRouteTrailLayer() {
    if (_samples.isEmpty) return const SizedBox.shrink();

    // Sort samples by timestamp (oldest first)
    final sorted = List<Sample>.from(_samples)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final polylines = <Polyline>[];
    const maxGapMinutes = 5; // Break trail if gap > 5 minutes

    var segmentPoints = <LatLng>[];
    Color segmentColor = Colors.blue;

    for (int i = 0; i < sorted.length; i++) {
      final sample = sorted[i];

      // Determine color for this point
      Color pointColor;
      if (sample.pingSuccess == true) {
        pointColor = ColorBlindPalette.getSuccessColor(_colorBlindMode);
      } else if (sample.pingSuccess == false) {
        pointColor = ColorBlindPalette.getFailureColor(_colorBlindMode);
      } else {
        pointColor = Colors.blue;
      }

      if (i > 0) {
        final gap = sample.timestamp
            .difference(sorted[i - 1].timestamp)
            .inMinutes;

        if (gap > maxGapMinutes) {
          // Save current segment and start new one
          if (segmentPoints.length >= 2) {
            polylines.add(
              Polyline(
                points: List.from(segmentPoints),
                color: segmentColor.withValues(alpha: 0.7),
                strokeWidth: 3.0,
              ),
            );
          }
          segmentPoints = [sample.position];
          segmentColor = pointColor;
          continue;
        }

        // If color changes, end current segment and start new one
        if (pointColor != segmentColor && segmentPoints.length >= 2) {
          polylines.add(
            Polyline(
              points: List.from(segmentPoints),
              color: segmentColor.withValues(alpha: 0.7),
              strokeWidth: 3.0,
            ),
          );
          // Start new segment from last point of previous segment for continuity
          segmentPoints = [segmentPoints.last, sample.position];
          segmentColor = pointColor;
          continue;
        }
      } else {
        segmentColor = pointColor;
      }

      segmentPoints.add(sample.position);
    }

    // Add final segment
    if (segmentPoints.length >= 2) {
      polylines.add(
        Polyline(
          points: segmentPoints,
          color: segmentColor.withValues(alpha: 0.7),
          strokeWidth: 3.0,
        ),
      );
    }

    return PolylineLayer(polylines: polylines);
  }

  Widget _buildHeatmapLayer() {
    if (_samples.isEmpty) return const SizedBox.shrink();

    // Convert samples to weighted points
    // Higher weight = hotter on the heatmap
    final data = _samples.map((sample) {
      double weight;
      if (sample.pingSuccess == true) {
        weight = 1.0; // Successful ping = hot
      } else if (sample.pingSuccess == false) {
        weight = 0.5; // Failed ping = warm
      } else {
        weight = 0.2; // GPS-only = cool
      }
      return WeightedLatLng(sample.position, weight);
    }).toList();

    return HeatMapLayer(
      heatMapDataSource: InMemoryHeatMapDataSource(data: data),
      heatMapOptions: HeatMapOptions(
        gradient: {
          0.25: Colors.green,
          0.50: Colors.yellow,
          0.75: Colors.orange,
          1.0: Colors.red,
        },
        minOpacity: 0.1,
      ),
      reset: _heatmapRebuildStream.stream,
    );
  }

  List<Widget> _buildCoverageLayers() {
    if (_aggregationResult == null) return [];
    _ensureCoverageLod();

    final coveragePolygons = <Polygon<Coverage>>[];

    for (final coverage in _cachedLodCoverages) {
      final gh = geohash.GeoHash.decode(coverage.id);
      final color = Color(
        AggregationService.getCoverageColor(
          coverage,
          _colorMode,
          colorBlindMode: _colorBlindMode,
        ),
      );
      final opacity = AggregationService.getCoverageOpacity(coverage);

      // Get corners from geohash bounds
      final sw = gh.bounds.southWest;
      final ne = gh.bounds.northEast;

      coveragePolygons.add(
        Polygon<Coverage>(
          points: [
            LatLng(sw.latitude, sw.longitude),
            LatLng(sw.latitude, ne.longitude),
            LatLng(ne.latitude, ne.longitude),
            LatLng(ne.latitude, sw.longitude),
          ],
          color: color.withValues(alpha: opacity),
          borderColor: color,
          borderStrokeWidth: 1,
          hitValue: coverage,
        ),
      );
    }

    return [
      GestureDetector(
        onTap: () {
          final hits = _coverageHitNotifier.value?.hitValues;
          if (hits == null || hits.isEmpty) return;
          final coverage = hits.first;
          if (_deleteMode && _coverageLodPrecision < _coveragePrecision) {
            _showSnackBar('Zoom in to delete an individual coverage cell');
            return;
          }
          if (_deleteMode) {
            _deleteCoverageCell(coverage);
          } else {
            _showCoverageInfo(coverage);
          }
        },
        child: PolygonLayer<Coverage>(
          polygons: coveragePolygons,
          hitNotifier: _coverageHitNotifier,
        ),
      ),
    ];
  }

  Widget _buildSampleLayer() {
    if (_samples.isEmpty) return const SizedBox.shrink();
    final clusters = _sampleClustersForCurrentLod();
    final circles = clusters
        .map((cluster) {
          final Color color;
          if (cluster.successfulCount >= cluster.failedCount &&
              cluster.successfulCount > 0) {
            color = ColorBlindPalette.getSuccessColor(_colorBlindMode);
          } else if (cluster.failedCount > 0) {
            color = ColorBlindPalette.getFailureColor(_colorBlindMode);
          } else {
            color = ColorBlindPalette.getGpsOnlyColor(_colorBlindMode);
          }
          final radius = math.min(
            9.0,
            3.0 + math.log(cluster.sampleCount + 1) / math.ln2,
          );

          return CircleMarker<SampleCluster>(
            point: cluster.position,
            radius: radius,
            color: color.withValues(alpha: 0.7),
            borderColor: color.withValues(alpha: 0.95),
            borderStrokeWidth: 1,
            hitValue: cluster,
          );
        })
        .toList(growable: false);

    return GestureDetector(
      onTap: () {
        final hits = _sampleHitNotifier.value?.hitValues;
        if (hits == null || hits.isEmpty) return;
        final cluster = hits.first;
        if (_deleteMode && cluster.sampleCount == 1) {
          _deleteSample(cluster.newestSample);
        } else if (_deleteMode) {
          _showSnackBar('Zoomed points are grouped; delete from coverage view');
        } else if (cluster.sampleCount == 1) {
          _showSampleInfo(cluster.newestSample);
        } else {
          _showSampleClusterInfo(cluster);
        }
      },
      child: CircleLayer<SampleCluster>(
        circles: circles,
        hitNotifier: _sampleHitNotifier,
      ),
    );
  }

  Widget _buildEdgeLayer() {
    if (_aggregationResult == null) return const SizedBox.shrink();
    _ensureCoverageLod();

    // Filter edges by whitelist if enabled
    var edges = _cachedLodEdges;

    if (_filterEdgesByWhitelist &&
        _includeOnlyRepeaters != null &&
        _includeOnlyRepeaters!.isNotEmpty) {
      final allowedPrefixes = _includeOnlyRepeaters!
          .split(',')
          .map((s) => s.trim().toUpperCase())
          .toList();
      edges = edges.where((edge) {
        final repeaterId = edge.repeater.id.toUpperCase();
        return allowedPrefixes.any((prefix) => repeaterId.startsWith(prefix));
      }).toList();
    }

    final polylines = edges.map((edge) {
      return Polyline(
        points: [edge.coverage.position, edge.repeater.position],
        color: Colors.purple.withValues(
          alpha: 0.6,
        ), // Increased from 0.3 to 0.6
        strokeWidth: 2, // Increased from 1 to 2
      );
    }).toList();

    return PolylineLayer(polylines: polylines);
  }

  Widget _buildRepeaterLayer() {
    if (_repeaters.isEmpty) return const SizedBox.shrink();

    final markers = _repeaters.map((repeater) {
      return Marker(
        point: repeater.position,
        width: 30,
        height: 30,
        child: GestureDetector(
          onTap: () => _showRepeaterInfo(repeater),
          child: Icon(
            Icons.cell_tower,
            color: ColorBlindPalette.getRepeaterColor(_colorBlindMode),
            size: 30,
          ),
        ),
      );
    }).toList();

    return MarkerLayer(markers: markers);
  }

  RadioPositionEstimate? _calculateRadioPositionEstimate(
    Iterable<Repeater> repeaters,
  ) {
    final result = _latestPingResult;
    if (result == null ||
        DateTime.now().difference(result.timestamp) >
            const Duration(minutes: 2)) {
      return null;
    }

    return RadioPositionEstimator.estimate(
      responses: result.responses,
      repeaters: repeaters,
    );
  }

  List<Widget> _buildRadioPositionLayers() {
    final estimate = _radioPositionEstimate;
    if (estimate == null) return const [];

    const color = Colors.grey;
    final uncertaintyText = estimate.uncertaintyMeters >= 1000
        ? '${(estimate.uncertaintyMeters / 1000).toStringAsFixed(1)} km'
        : '${estimate.uncertaintyMeters.round()} m';

    return [
      PolygonLayer(
        polygons: [
          Polygon(
            points: _circlePoints(
              estimate.position,
              estimate.uncertaintyMeters,
            ),
            color: color.withValues(alpha: 0.12),
            borderColor: color.withValues(alpha: 0.7),
            borderStrokeWidth: 2,
          ),
        ],
      ),
      MarkerLayer(
        markers: [
          Marker(
            point: estimate.position,
            width: 28,
            height: 28,
            child: Semantics(
              label: 'Approximate radio position, uncertainty $uncertaintyText',
              button: true,
              child: GestureDetector(
                onTap: () => _showSnackBar(
                  'Approximate radio position · '
                  '${estimate.repeaterCount} repeaters · ±$uncertaintyText',
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.85),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(
                    Icons.wifi_tethering,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ];
  }

  /// Generate polygon points approximating a circle at a given radius
  List<LatLng> _circlePoints(
    LatLng center,
    double radiusMeters, {
    int segments = 72,
  }) {
    const distance = Distance();
    return List.generate(segments, (i) {
      final bearing = (360.0 / segments) * i;
      return distance.offset(center, radiusMeters, bearing);
    });
  }

  Widget _buildPredictionRingsLayer() {
    if (_repeaters.isEmpty || _samples.isEmpty) return const SizedBox.shrink();

    // Build lookup: repeater ID -> list of distances (meters) from successful samples
    final Map<String, List<double>> repeaterDistances = {};
    final Map<String, Repeater> repeaterById = {};
    const distance = Distance();
    final allowedPrefixes =
        _includeOnlyRepeaters != null && _includeOnlyRepeaters!.isNotEmpty
        ? _includeOnlyRepeaters!
              .split(',')
              .map((s) => s.trim().toUpperCase())
              .toList()
        : null;

    for (final repeater in _repeaters) {
      // Skip repeaters at 0,0 (unknown position)
      if (repeater.position.latitude == 0.0 &&
          repeater.position.longitude == 0.0) {
        continue;
      }
      if (allowedPrefixes != null) {
        final repeaterId = repeater.id.toUpperCase();
        final matches = allowedPrefixes.any(
          (prefix) => repeaterId.startsWith(prefix),
        );
        if (!matches) continue;
      }
      repeaterById[AggregationService.repeaterLookupKey(repeater.id)] =
          repeater;
    }

    // Match samples to repeaters by path (nodeId)
    for (final sample in _samples) {
      if (sample.pingSuccess != true ||
          sample.path == null ||
          sample.path!.isEmpty) {
        continue;
      }
      final repeater =
          repeaterById[AggregationService.repeaterLookupKey(sample.path!)];
      if (repeater == null) continue;

      final dist = distance.as(
        LengthUnit.Meter,
        sample.position,
        repeater.position,
      );
      // Skip impossibly large distances (GPS noise)
      if (dist > 100000) continue; // 100km sanity cap

      repeaterDistances.putIfAbsent(repeater.id, () => []);
      repeaterDistances[repeater.id]!.add(dist);
    }

    final polygons = <Polygon>[];

    for (final entry in repeaterDistances.entries) {
      final repeater = repeaterById[entry.key]!;
      final distances = entry.value..sort();

      // Need at least 3 data points for meaningful prediction
      if (distances.length < 3) continue;

      // Percentile-based rings
      final p25 = distances[(distances.length * 0.25).floor()];
      final p75 = distances[(distances.length * 0.75).floor()];
      final maxDist = distances.last;

      // Skip if rings would be too small to see (<50m)
      if (maxDist < 50) continue;

      // Edge ring (outer, red) — max observed distance
      polygons.add(
        Polygon(
          points: _circlePoints(repeater.position, maxDist),
          color: Colors.red.withValues(alpha: 0.05),
          borderColor: Colors.red.withValues(alpha: 0.35),
          borderStrokeWidth: 1.5,
          isFilled: true,
        ),
      );

      // Moderate ring (middle, yellow)
      if (p75 > 50 && p75 < maxDist * 0.95) {
        polygons.add(
          Polygon(
            points: _circlePoints(repeater.position, p75),
            color: Colors.yellow.withValues(alpha: 0.08),
            borderColor: Colors.yellow.withValues(alpha: 0.5),
            borderStrokeWidth: 1.5,
            isFilled: true,
          ),
        );
      }

      // Strong ring (inner, green)
      if (p25 > 50 && p25 < p75 * 0.95) {
        polygons.add(
          Polygon(
            points: _circlePoints(repeater.position, p25),
            color: Colors.green.withValues(alpha: 0.10),
            borderColor: Colors.green.withValues(alpha: 0.6),
            borderStrokeWidth: 1.5,
            isFilled: true,
          ),
        );
      }
    }

    if (polygons.isEmpty) return const SizedBox.shrink();
    return PolygonLayer(polygons: polygons);
  }

  Widget _buildCurrentLocationLayer() {
    final markers = [
      Marker(
        point: _currentPosition!,
        width: _currentLocationMarkerStyle == CurrentLocationMarkerStyle.arrow
            ? 34
            : 20,
        height: _currentLocationMarkerStyle == CurrentLocationMarkerStyle.arrow
            ? 34
            : 20,
        child: _buildCurrentPositionMarker(),
      ),
    ];

    // Add ping pulse animation when auto-pinging
    if (_showPingPulse) {
      markers.add(
        Marker(
          point: _currentPosition!,
          width: 60,
          height: 60,
          child: TweenAnimationBuilder(
            tween: Tween<double>(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 1500),
            builder: (context, double value, child) {
              return Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.orange.withValues(alpha: 1.0 - value),
                    width: 3,
                  ),
                ),
              );
            },
          ),
        ),
      );
    }

    return MarkerLayer(markers: markers);
  }

  Widget _buildCurrentPositionMarker() {
    final positionColor = _positionSource == LocationPositionSource.wifi
        ? Colors.cyan
        : Colors.blue;
    final positionLabel = _positionSource == LocationPositionSource.wifi
        ? 'Current Wi-Fi location from beaconDB'
        : 'Current fused Android location';
    if (_currentLocationMarkerStyle == CurrentLocationMarkerStyle.circle) {
      return Semantics(
        label: positionLabel,
        child: Container(
          decoration: BoxDecoration(
            color: positionColor,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
        ),
      );
    }

    return Semantics(
      label: '$positionLabel, heading ${_currentHeading.round()} degrees',
      child: Transform.rotate(
        angle: _currentHeading * math.pi / 180,
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Icon(Icons.navigation, size: 34, color: Colors.white),
            Icon(Icons.navigation, size: 27, color: positionColor),
          ],
        ),
      ),
    );
  }

  Widget _buildControlPanel() {
    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              // Connection Status Icon
              Icon(
                _loraConnected
                    ? Icons.bluetooth_connected
                    : Icons.bluetooth_disabled,
                size: 16,
                color: _loraConnected ? Colors.green : Colors.grey,
              ),
              const SizedBox(width: 4),
              Text(
                _loraConnected
                    ? (_connectionType == ConnectionType.usb ? 'USB' : 'BT')
                    : 'No LoRa',
                style: TextStyle(
                  fontSize: 12,
                  color: _loraConnected ? Colors.green : Colors.grey,
                ),
              ),
              if (_loraConnected && _batteryPercent != null)
                const SizedBox(width: 4),
              if (_loraConnected && _batteryPercent != null)
                Icon(
                  _getBatteryIcon(_batteryPercent!),
                  size: 14,
                  color: _getBatteryColor(_batteryPercent!),
                ),
              if (_loraConnected && _batteryPercent != null)
                const SizedBox(width: 2),
              if (_loraConnected && _batteryPercent != null)
                Text(
                  '$_batteryPercent%',
                  style: TextStyle(
                    fontSize: 11,
                    color: _getBatteryColor(_batteryPercent!),
                  ),
                ),
              const SizedBox(width: 12),
              const Text('•', style: TextStyle(color: Colors.grey)),
              const SizedBox(width: 12),
              // Stats
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Samples: $_sampleCount',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_isTracking)
                      Text(
                        '${_totalDistance.toStringAsFixed(2)} ${_distanceUnit == 'miles' ? 'mi' : 'km'} • ${_currentSpeed.toStringAsFixed(1)} ${_distanceUnit == 'miles' ? 'mph' : 'km/h'}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),
                    if (_carpeaterEnabled &&
                        _carpeaterState != CarpeaterState.disabled)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: GestureDetector(
                          onTap: _carpeaterState == CarpeaterState.error
                              ? () async {
                                  _showSnackBar('Retrying Carpeater...');
                                  final ok = await _locationService
                                      .startCarpeater();
                                  _showSnackBar(
                                    ok
                                        ? 'Carpeater reconnected'
                                        : 'Carpeater retry failed',
                                  );
                                }
                              : null,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  (_carpeaterState == CarpeaterState.error
                                          ? Colors.red
                                          : _carpeaterState ==
                                                    CarpeaterState.loggedIn ||
                                                _carpeaterState ==
                                                    CarpeaterState
                                                        .discovering ||
                                                _carpeaterState ==
                                                    CarpeaterState
                                                        .fetchingNeighbours
                                          ? Colors.green
                                          : Colors.orange)
                                      .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _carpeaterState == CarpeaterState.error
                                    ? Colors.red
                                    : _carpeaterState ==
                                              CarpeaterState.loggedIn ||
                                          _carpeaterState ==
                                              CarpeaterState.discovering ||
                                          _carpeaterState ==
                                              CarpeaterState.fetchingNeighbours
                                    ? Colors.green
                                    : Colors.orange,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'CP: ${_carpeaterStateLabel()}',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        _carpeaterState == CarpeaterState.error
                                        ? Colors.red
                                        : _carpeaterState ==
                                                  CarpeaterState.loggedIn ||
                                              _carpeaterState ==
                                                  CarpeaterState.discovering ||
                                              _carpeaterState ==
                                                  CarpeaterState
                                                      .fetchingNeighbours
                                        ? Colors.green
                                        : Colors.orange,
                                  ),
                                ),
                                if (_carpeaterState ==
                                    CarpeaterState.error) ...[
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.refresh,
                                    size: 10,
                                    color: Colors.red,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    if (_showDucting &&
                        _currentDuctingRisk != DuctingRisk.unknown)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: _getDuctingColor(
                              _currentDuctingRisk,
                            ).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _getDuctingColor(_currentDuctingRisk),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            'Ducting: ${DuctingService.riskLabel(_currentDuctingRisk)}',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: _getDuctingColor(_currentDuctingRisk),
                            ),
                          ),
                        ),
                      ),
                    if (_batterySaverActive)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange, width: 1),
                          ),
                          child: const Text(
                            '🔋 Saver',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const Spacer(),
              // Connect button or Manual Ping
              if (!_loraConnected)
                TextButton(
                  onPressed: _isConnecting ? null : _showConnectionDialog,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    minimumSize: Size.zero,
                  ),
                  child: Text(
                    _isConnecting ? 'Connecting...' : 'Connect',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              if (_loraConnected) ...[
                IconButton(
                  icon: const Icon(Icons.link_off, size: 16),
                  onPressed: _disconnectLoRa,
                  tooltip: 'Disconnect',
                  color: Colors.red,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.send, size: 18),
                  onPressed: _manualPing,
                  tooltip: 'Manual Ping',
                  color: Colors.blue,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _toggleAutoPing(bool? value) {
    if (value == true) {
      _locationService.enableAutoPing();
    } else {
      _locationService.disableAutoPing();
    }
    setState(() {
      _autoPingEnabled = value ?? false;
    });
  }

  Future<void> _manualPing() async {
    if (!_loraConnected) {
      _showSnackBar('Connect LoRa device first');
      return;
    }

    if (_currentPosition == null) {
      _showSnackBar('Waiting for GPS location...');
      return;
    }

    if (_locationService.loraCompanion.isPingInProgress) {
      _showSnackBar('A ping is already in progress');
      return;
    }

    _showSnackBar('Sending ping...');
    SoundService().playPingSent();

    // Send ping via LoRa companion
    final result = await _locationService.loraCompanion.ping(
      latitude: _currentPosition!.latitude,
      longitude: _currentPosition!.longitude,
      timeoutSeconds: _discoveryTimeoutSeconds,
      waitForAllResponses: true,
      collectUntilTimeout: _thoroughResponseCollection,
    );

    final responses = result.responses;
    final pingSuccess =
        result.status == PingStatus.success && responses.isNotEmpty;

    if (pingSuccess) {
      for (final response in responses) {
        await SoundService().playForPingResult(
          success: true,
          snr: response.snr,
          rssi: response.rssi,
        );
      }
    } else {
      await SoundService().playForPingResult(success: false);
    }

    // Create and save sample
    final geohash = GeohashUtils.sampleKey(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
    );

    if (pingSuccess) {
      for (var index = 0; index < responses.length; index++) {
        final response = responses[index];
        final sample = Sample(
          id: '${DateTime.now().microsecondsSinceEpoch}_${index}_$geohash',
          position: _currentPosition!,
          timestamp: DateTime.now(),
          path: response.nodeId,
          geohash: geohash,
          rssi: response.rssi,
          snr: response.snr,
          pingSuccess: true,
          responseTimeMs: response.responseTimeMs,
          deviceId: _locationService.loraCompanion.connectedDeviceId,
        );
        await DatabaseService().insertSample(sample);
      }
    } else {
      final sample = Sample(
        id: '${DateTime.now().microsecondsSinceEpoch}_$geohash',
        position: _currentPosition!,
        timestamp: DateTime.now(),
        geohash: geohash,
        pingSuccess: false,
        responseTimeMs: result.responseTimeMs,
        deviceId: _locationService.loraCompanion.connectedDeviceId,
      );
      await DatabaseService().insertSample(sample);
    }

    // Reload samples to update map
    await _loadSamples();

    // Show result
    if (pingSuccess) {
      final summary = responses.length == 1
          ? '✅ Ping heard by ${_shortNodeId(responses.single.nodeId)}'
          : '✅ Discovery complete: found ${responses.length} repeaters';
      _showSnackBar(summary);
    } else if (result.status == PingStatus.timeout) {
      _showSnackBar('❌ No response - dead zone');
    } else {
      _showSnackBar('❌ Ping failed: ${result.error}');
    }
  }

  String _shortNodeId(String nodeId) {
    return (nodeId.length > 8 ? nodeId.substring(0, 8) : nodeId).toUpperCase();
  }

  void _showConnectionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Connect LoRa Device'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Choose connection method:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _connectUsb();
              },
              icon: const Icon(Icons.usb),
              label: const Text('Scan USB Devices'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 40),
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _connectBluetooth();
              },
              icon: const Icon(Icons.bluetooth),
              label: const Text('Scan Bluetooth'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 40),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _connectUsb() async {
    if (_isConnecting) return;
    setState(() => _isConnecting = true);
    try {
      final devices = await _locationService.loraCompanion.scanUsbDevices();

      if (!mounted) return;

      if (devices.isEmpty) {
        _showSnackBar('No USB devices found');
        return;
      }

      final selected = await showDialog<UsbDevice>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Select USB Device'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: devices.map((device) {
              return ListTile(
                title: Text(device.productName ?? 'USB Device'),
                subtitle: Text('VID: ${device.vid}, PID: ${device.pid}'),
                onTap: () => Navigator.pop(context, device),
              );
            }).toList(),
          ),
        ),
      );

      if (selected != null) {
        final connected = await _locationService.loraCompanion.connectUsb(
          selected,
        );
        if (connected) {
          _showSnackBar('Connected via USB');
          await _loadSamples();
        } else {
          _showSnackBar('Failed to connect USB device');
        }
      }
    } catch (e) {
      _showSnackBar('USB error: $e');
    } finally {
      if (mounted) setState(() => _isConnecting = false);
    }
  }

  Future<void> _connectBluetooth() async {
    if (_isConnecting) return;
    setState(() => _isConnecting = true);
    try {
      _showSnackBar('Scanning for Bluetooth devices...');
      final devices = await _locationService.loraCompanion
          .scanBluetoothDevices();

      if (!mounted) return;

      if (devices.isEmpty) {
        _showSnackBar('No LoRa devices found via Bluetooth');
        return;
      }

      final selected = await showDialog<BluetoothDevice>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Select Bluetooth Device'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: devices.map((device) {
              return ListTile(
                title: Text(device.platformName),
                subtitle: Text(device.remoteId.toString()),
                onTap: () => Navigator.pop(context, device),
              );
            }).toList(),
          ),
        ),
      );

      if (selected != null) {
        _showSnackBar('Connecting to ${selected.platformName}...');

        final connected = await _locationService.loraCompanion.connectBluetooth(
          selected,
        );
        if (connected) {
          _showSnackBar('Connected via Bluetooth!');
          await _loadSamples();
        } else {
          _showSnackBar('Failed to connect Bluetooth device');
        }
      }
    } catch (e) {
      _showSnackBar('Bluetooth error: $e');
    } finally {
      if (mounted) setState(() => _isConnecting = false);
    }
  }

  Future<void> _disconnectLoRa() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disconnect LoRa Device'),
        content: const Text('Disconnect from your LoRa companion device?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Disable auto-ping and carpeater
      _locationService.disableAutoPing();
      _locationService.carpeaterService.stop();
      setState(() {
        _autoPingEnabled = false;
        _carpeaterState = CarpeaterState.disabled;
      });

      await _locationService.loraCompanion.disconnectDevice();
      await _loadSamples();
      _showSnackBar('LoRa device disconnected');
    }
  }

  IconData _getBatteryIcon(int percent) {
    if (percent > 90) return Icons.battery_full;
    if (percent > 70) return Icons.battery_5_bar;
    if (percent > 50) return Icons.battery_4_bar;
    if (percent > 30) return Icons.battery_3_bar;
    if (percent > 15) return Icons.battery_2_bar;
    return Icons.battery_1_bar;
  }

  Color _getBatteryColor(int percent) {
    if (percent > 30) return Colors.green;
    if (percent > 15) return Colors.orange;
    return Colors.red;
  }

  String _carpeaterStateLabel() {
    switch (_carpeaterState) {
      case CarpeaterState.disabled:
        return 'Off';
      case CarpeaterState.connecting:
        return 'Connecting';
      case CarpeaterState.loggingIn:
        return 'Login...';
      case CarpeaterState.loggedIn:
        return 'Ready';
      case CarpeaterState.discovering:
        return 'Scanning';
      case CarpeaterState.fetchingNeighbours:
        return 'Fetching';
      case CarpeaterState.error:
        return 'Error';
    }
  }

  Color _getDuctingColor(String risk) {
    switch (risk) {
      case 'none':
        return Colors.green;
      case 'possible':
        return Colors.orange;
      case 'likely':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Future<void> _refreshContacts() async {
    if (!_loraConnected) {
      _showSnackBar('Connect LoRa device first');
      return;
    }

    _showSnackBar('Refreshing contact list...');

    // Request full contact list from device
    await _locationService.loraCompanion.refreshContactList();

    // Give it a moment to process
    await Future.delayed(const Duration(seconds: 2));

    _showSnackBar('Contact list updated');
  }

  Future<void> _scanForRepeaters() async {
    if (!_loraConnected) {
      _showSnackBar('Connect LoRa device first');
      return;
    }

    _showSnackBar('Scanning for repeaters...');

    final repeaters = await _locationService.loraCompanion.scanForRepeaters();

    setState(() {
      _repeaters = repeaters;
    });

    if (repeaters.isEmpty) {
      _showSnackBar('No repeaters found');
    } else {
      _showSnackBar('Found ${repeaters.length} repeater(s)');
      _showRepeatersDialog();
    }
  }

  void _openSessionHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SessionHistoryScreen(
          onSessionSelected: (session) {
            setState(() {
              _activeSessionFilter = session;
            });
            _lastAggregatedSampleCount = -1; // Force reaggregation with filter
            _loadSamples();
            _showSnackBar(
              'Showing session from ${DateFormat('MMM d, h:mm a').format(session.startTime)}',
            );
          },
        ),
      ),
    );
  }

  void _openDebugDiagnostics() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            DebugDiagnosticsScreen(locationService: _locationService),
      ),
    );
  }

  String _getInterfaceThemeModeText() {
    final appState = MyApp.of(context);
    if (appState == null) return 'System Default';

    switch (appState.themeMode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System Default';
    }
  }

  Future<void> _showInterfaceThemeSelector() async {
    final appState = MyApp.of(context);
    if (appState == null) return;

    final selected = await showDialog<ThemeMode>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Interface Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Light'),
              leading: const Icon(Icons.light_mode),
              onTap: () => Navigator.pop(context, ThemeMode.light),
            ),
            ListTile(
              title: const Text('Dark'),
              leading: const Icon(Icons.dark_mode),
              onTap: () => Navigator.pop(context, ThemeMode.dark),
            ),
            ListTile(
              title: const Text('System Default'),
              leading: const Icon(Icons.brightness_auto),
              onTap: () => Navigator.pop(context, ThemeMode.system),
            ),
          ],
        ),
      ),
    );

    if (selected != null) {
      await appState.setThemeMode(selected);
    }
  }

  String _getMapThemeModeText() {
    switch (_mapThemeMode) {
      case MapThemeMode.light:
        return 'Light';
      case MapThemeMode.dark:
        return 'Dark';
      case MapThemeMode.system:
        return 'System Default';
    }
  }

  bool _usesDarkMapTiles(BuildContext context) {
    switch (_mapThemeMode) {
      case MapThemeMode.light:
        return false;
      case MapThemeMode.dark:
        return true;
      case MapThemeMode.system:
        return MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    }
  }

  Future<void> _showMapThemeSelector() async {
    final selected = await showDialog<MapThemeMode>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Map Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Light'),
              leading: const Icon(Icons.light_mode),
              onTap: () => Navigator.pop(context, MapThemeMode.light),
            ),
            ListTile(
              title: const Text('Dark'),
              leading: const Icon(Icons.dark_mode),
              onTap: () => Navigator.pop(context, MapThemeMode.dark),
            ),
            ListTile(
              title: const Text('System Default'),
              leading: const Icon(Icons.brightness_auto),
              onTap: () => Navigator.pop(context, MapThemeMode.system),
            ),
          ],
        ),
      ),
    );

    if (selected != null) {
      setState(() {
        _mapThemeMode = selected;
      });
      await _settingsService.setMapThemeMode(selected);
    }
  }

  String? _getRepeaterName(String? repeaterId) {
    if (repeaterId == null) return null;

    // If it's a 2-char prefix, try to expand it first
    String? fullId = repeaterId;
    if (repeaterId.length == 2) {
      fullId = _locationService.loraCompanion.matchRepeaterPrefix(repeaterId);
      if (fullId == null) {
        // No match found, return the 2-char prefix as-is
        return repeaterId;
      }
    }

    // First check discovered repeaters list
    final repeater = _repeaters.firstWhere(
      (r) => r.id == fullId,
      orElse: () => Repeater(
        id: fullId!,
        position: const LatLng(0, 0),
        timestamp: DateTime.now(),
      ),
    );
    if (repeater.name != null) return repeater.name;

    // Fall back to checking LoRa service's contact cache
    final loraRepeater = _locationService.loraCompanion.getRepeaterLocation(
      fullId,
    );
    return loraRepeater?.name;
  }

  void _showSampleInfo(Sample sample) {
    final timestamp = DateFormat(
      'MMM d, yyyy HH:mm:ss',
    ).format(sample.timestamp);
    final hasSignalData = sample.rssi != null || sample.snr != null;
    final pingStatus = sample.pingSuccess == true
        ? '✅ Success'
        : sample.pingSuccess == false
        ? '❌ Failed'
        : '📍 GPS Only';

    // Get repeater name if available (sample.path holds repeater/node ID)
    final repeaterName = sample.path != null
        ? _getRepeaterName(sample.path)
        : null;
    final idOrName = repeaterName ?? sample.path ?? 'Unknown';
    final repeaterDisplay = (repeaterName != null)
        ? repeaterName
        : (idOrName.length > 8
              ? idOrName.substring(0, 8).toUpperCase()
              : idOrName.toUpperCase());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sample Info'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Status: ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(pingStatus),
              ],
            ),
            const SizedBox(height: 8),
            Text('Time: $timestamp', style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 8),
            Text('Lat: ${sample.position.latitude.toStringAsFixed(6)}'),
            Text('Lon: ${sample.position.longitude.toStringAsFixed(6)}'),
            if (sample.path != null) ...[
              const Divider(height: 16),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text(
                    'Repeater: ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Expanded(
                    child: Text(
                      repeaterDisplay,
                      style: const TextStyle(fontFamily: 'monospace'),
                    ),
                  ),
                ],
              ),
            ],
            if (hasSignalData) const Divider(height: 16),
            if (hasSignalData) const SizedBox(height: 8),
            if (sample.rssi != null)
              Row(
                children: [
                  const Text(
                    'RSSI: ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text('${sample.rssi} dBm'),
                ],
              ),
            if (sample.snr != null)
              Row(
                children: [
                  const Text(
                    'SNR: ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text('${sample.snr} dB'),
                ],
              ),
            if (sample.responseTimeMs != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Text(
                    'Response: ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text('${sample.responseTimeMs} ms'),
                ],
              ),
            ],
            if (sample.ductingRisk != null) ...[
              const Divider(height: 16),
              Row(
                children: [
                  const Text(
                    'Ducting: ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _getDuctingColor(
                        sample.ductingRisk!,
                      ).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      DuctingService.riskLabel(sample.ductingRisk!),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _getDuctingColor(sample.ductingRisk!),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showSampleClusterInfo(SampleCluster cluster) {
    final newestTimestamp = DateFormat(
      'MMM d, yyyy HH:mm:ss',
    ).format(cluster.newestSample.timestamp);
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${cluster.sampleCount} grouped samples'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Successful: ${cluster.successfulCount}'),
            Text('Failed: ${cluster.failedCount}'),
            Text('GPS only: ${cluster.gpsOnlyCount}'),
            const SizedBox(height: 8),
            Text('Newest: $newestTimestamp'),
            const SizedBox(height: 8),
            const Text('Zoom in for a more detailed breakdown.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showRepeaterInfo(Repeater repeater) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          repeater.name ??
              'Repeater ${(repeater.id.length > 8 ? repeater.id.substring(0, 8) : repeater.id).toUpperCase()}',
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ID: ${(repeater.id.length > 8 ? repeater.id.substring(0, 8) : repeater.id).toUpperCase()}',
              style: const TextStyle(fontFamily: 'monospace'),
            ),
            const SizedBox(height: 8),
            Text('Lat: ${repeater.position.latitude.toStringAsFixed(6)}'),
            Text('Lon: ${repeater.position.longitude.toStringAsFixed(6)}'),
            if (repeater.rssi != null) const SizedBox(height: 8),
            if (repeater.rssi != null) Text('RSSI: ${repeater.rssi} dBm'),
            if (repeater.snr != null) Text('SNR: ${repeater.snr} dB'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() {
                _includeOnlyRepeaters = repeater.id;
              });
              await _settingsService.setIncludeOnlyRepeaters(repeater.id);
              _loadSamples();
              _showSnackBar(
                'Filtering by ${(repeater.id.length > 8 ? repeater.id.substring(0, 8) : repeater.id).toUpperCase()}',
              );
            },
            child: const Text('Filter by This'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _mapController.move(repeater.position, 15.0);
            },
            child: const Text('Show on Map'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showCoverageInfo(Coverage coverage) {
    // Calculate total samples and success rate
    final total = coverage.received + coverage.lost;
    final successRate = total > 0
        ? ((coverage.received / total) * 100).toStringAsFixed(0)
        : 'N/A';
    final reliabilityText = total > 0 ? '$successRate%' : 'No ping data';

    // Round weighted values to 1 decimal place for display
    final receivedDisplay = coverage.received.toStringAsFixed(1);
    final lostDisplay = coverage.lost.toStringAsFixed(1);
    final totalDisplay = total.toStringAsFixed(1);

    // Show two-byte repeater prefixes so IDs stay compact but distinguishable.
    final uniquePrefixes =
        coverage.repeaters
            .map((id) => id.substring(0, id.length >= 4 ? 4 : id.length))
            .toSet()
            .toList()
          ..sort();
    final repeaterText = uniquePrefixes.isNotEmpty
        ? uniquePrefixes.join(', ')
        : 'None';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Coverage Square Info'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Samples: ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(totalDisplay),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text(
                  'Success Rate: ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(reliabilityText),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text(
                  'Received: ',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Flexible(child: Text(receivedDisplay)),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Text(
                  'Lost: ',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Flexible(child: Text(lostDisplay)),
              ],
            ),
            if (coverage.received > 0) const SizedBox(height: 8),
            if (coverage.received > 0)
              Row(
                children: [
                  const Text(
                    'Repeaters Heard: ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text('${uniquePrefixes.length}'),
                ],
              ),
            if (coverage.received > 0) const SizedBox(height: 4),
            if (coverage.received > 0)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Repeater IDs: ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Expanded(
                    child: Text(
                      repeaterText,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showRepeatersDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Nearby Repeaters (${_repeaters.length})'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _repeaters.length,
            itemBuilder: (context, index) {
              final repeater = _repeaters[index];
              return ListTile(
                leading: const Icon(Icons.cell_tower, color: Colors.purple),
                title: Text(repeater.name ?? 'Repeater ${repeater.id}'),
                subtitle: Text(
                  '${repeater.position.latitude.toStringAsFixed(4)}, '
                  '${repeater.position.longitude.toStringAsFixed(4)}'
                  '${repeater.snr != null ? " • SNR: ${repeater.snr} dB" : ""}'
                  '${repeater.rssi != null ? " • RSSI: ${repeater.rssi} dBm" : ""}',
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showRepeaterInfo(repeater);
                },
                trailing: IconButton(
                  icon: const Icon(Icons.location_searching),
                  onPressed: () {
                    Navigator.pop(context);
                    _mapController.move(repeater.position, 15.0);
                  },
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _uploadSamples() async {
    final endpoints = await _uploadService.getUploadEndpoints();
    final savedSelectedSites = await _uploadService.getSelectedEndpoints();
    if (!mounted) return;

    final selectedSites = await showDialog<List<String>>(
      context: context,
      builder: (context) => UploadEndpointSelectionDialog(
        endpoints: endpoints,
        initiallySelectedNames: savedSelectedSites,
      ),
    );
    if (!mounted || selectedSites == null || selectedSites.isEmpty) return;

    // Track progress state
    int currentBatch = 0;
    int totalBatches = 0;
    String currentSite = '';

    // Show loading dialog with progress
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  currentSite.isNotEmpty
                      ? 'Uploading to $currentSite...'
                      : 'Uploading samples...',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                if (totalBatches > 1)
                  Text(
                    'Batch $currentBatch of $totalBatches',
                    style: const TextStyle(fontSize: 12),
                  ),
              ],
            ),
          );
        },
      ),
    );

    try {
      // Build repeater names map from discovered repeaters and LoRa service
      final repeaterNames = <String, String>{};

      // Add names from discovered repeaters
      for (final repeater in _repeaters) {
        if (repeater.name != null) {
          repeaterNames[repeater.id] = repeater.name!;
        }
      }

      // Add names from LoRa service contact cache
      final loraService = _locationService.loraCompanion;
      for (final contact in loraService.discoveredRepeaters) {
        if (contact.name != null && !repeaterNames.containsKey(contact.id)) {
          repeaterNames[contact.id] = contact.name!;
        }
      }

      Map<String, UploadResult> results;

      // Always use multi-site upload path if any endpoints are configured
      // This ensures custom endpoints work correctly
      if (selectedSites.isNotEmpty && endpoints.isNotEmpty) {
        results = await _uploadService.uploadToSelectedEndpoints(
          endpointNames: selectedSites,
          repeaterNames: repeaterNames,
          onProgress: (siteName, current, total) {
            if (mounted) {
              currentSite = siteName;
              currentBatch = current;
              totalBatches = total;
            }
          },
        );
      } else {
        // Fallback for backward compatibility (shouldn't happen)
        final result = await _uploadService.uploadAllSamples(
          repeaterNames: repeaterNames,
          onProgress: (current, total) {
            if (mounted) {
              currentBatch = current;
              totalBatches = total;
            }
          },
        );
        results = {'Upload': result};
      }

      if (mounted) {
        Navigator.pop(context); // Close loading dialog

        // Show results
        final allSuccess = results.values.every((r) => r.success);
        final successCount = results.values.where((r) => r.success).length;

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(allSuccess ? 'Upload Complete' : 'Upload Results'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (results.length > 1)
                  Text('Uploaded to $successCount of ${results.length} sites'),
                const SizedBox(height: 8),
                ...results.entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Icon(
                          entry.value.success
                              ? Icons.check_circle
                              : Icons.error,
                          color: entry.value.success
                              ? Colors.green
                              : Colors.red,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                entry.key,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (!entry.value.success)
                                Text(
                                  entry.value.message,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        _showSnackBar('Upload error: $e');
      }
    }
  }

  Future<void> _manageUploadSites() async {
    final endpoints = await _uploadService.getUploadEndpoints();
    final selectedNames = await _uploadService.getSelectedEndpoints();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => SafeArea(
          child: DraggableScrollableSheet(
            initialChildSize: 0.6,
            minChildSize: 0.4,
            maxChildSize: 0.9,
            expand: false,
            builder: (context, scrollController) => Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
              ),
              child: ListView(
                controller: scrollController,
                children: [
                  Row(
                    children: const [
                      Text(
                        'Manage Upload Sites',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Select which sites to upload to:',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  if (endpoints.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(20),
                      child: Text('No upload sites configured'),
                    )
                  else
                    ...endpoints.map((endpoint) {
                      final isSelected = selectedNames.contains(endpoint.name);
                      return CheckboxListTile(
                        title: Text(endpoint.name),
                        subtitle: Text(
                          endpoint.url,
                          style: const TextStyle(fontSize: 11),
                          overflow: TextOverflow.ellipsis,
                        ),
                        value: isSelected,
                        onChanged: (value) {
                          setModalState(() {
                            if (value == true) {
                              if (!selectedNames.contains(endpoint.name)) {
                                selectedNames.add(endpoint.name);
                              }
                            } else {
                              selectedNames.remove(endpoint.name);
                            }
                          });
                        },
                        secondary: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.edit,
                                size: 20,
                                color: Colors.blue,
                              ),
                              onPressed: () async {
                                final edited = await _showEditEndpointDialog(
                                  endpoint,
                                );
                                if (edited != null) {
                                  final index = endpoints.indexOf(endpoint);
                                  if (index != -1) {
                                    // Update selected names if name changed
                                    if (selectedNames.contains(endpoint.name)) {
                                      selectedNames.remove(endpoint.name);
                                      selectedNames.add(edited.name);
                                    }
                                    endpoints[index] = edited;
                                    await _uploadService.setUploadEndpoints(
                                      endpoints,
                                    );
                                    await _uploadService.setSelectedEndpoints(
                                      selectedNames,
                                    );
                                    setModalState(() {});
                                  }
                                }
                              },
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete,
                                size: 20,
                                color: Colors.red,
                              ),
                              onPressed: () async {
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Delete Site'),
                                    content: Text('Delete "${endpoint.name}"?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, false),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, true),
                                        style: TextButton.styleFrom(
                                          foregroundColor: Colors.red,
                                        ),
                                        child: const Text('Delete'),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirmed == true) {
                                  endpoints.remove(endpoint);
                                  selectedNames.remove(endpoint.name);
                                  await _uploadService.setUploadEndpoints(
                                    endpoints,
                                  );
                                  await _uploadService.setSelectedEndpoints(
                                    selectedNames,
                                  );
                                  setModalState(() {});
                                }
                              },
                            ),
                          ],
                        ),
                      );
                    }),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: () async {
                          final result = await _showAddEndpointDialog();
                          if (result != null) {
                            endpoints.add(result);
                            selectedNames.add(result.name);
                            await _uploadService.setUploadEndpoints(endpoints);
                            await _uploadService.setSelectedEndpoints(
                              selectedNames,
                            );
                            setModalState(() {});
                          }
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Add Site'),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () async {
                          await _uploadService.setSelectedEndpoints(
                            selectedNames,
                          );
                          Navigator.pop(context);
                          _showSnackBar('Upload sites updated');
                        },
                        child: const Text('Save'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showOfflineTileDownload() async {
    if (_tileCacheStore == null) {
      _showSnackBar('Tile cache not initialized');
      return;
    }

    final bounds = _mapController.camera.visibleBounds;
    final currentZoom = _mapController.camera.zoom.floor();
    final isDarkMode = _usesDarkMapTiles(context);

    int minZoom = currentZoom;
    int maxZoom = (currentZoom + 3).clamp(0, 18);

    final result = await showDialog<Map<String, int>>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final tileCount = TileDownloadService.estimateTileCount(
              bounds.southWest,
              bounds.northEast,
              minZoom,
              maxZoom,
            );
            final estimatedMB = (tileCount * 15 / 1024).toStringAsFixed(
              1,
            ); // ~15KB per tile

            return AlertDialog(
              title: const Text('Download Offline Tiles'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Download map tiles for the current view area.'),
                  const SizedBox(height: 16),
                  Text('Min Zoom: $minZoom'),
                  Slider(
                    value: minZoom.toDouble(),
                    min: 3,
                    max: 18,
                    divisions: 15,
                    label: '$minZoom',
                    onChanged: (v) {
                      setDialogState(() {
                        minZoom = v.round();
                        if (maxZoom < minZoom) maxZoom = minZoom;
                      });
                    },
                  ),
                  Text('Max Zoom: $maxZoom'),
                  Slider(
                    value: maxZoom.toDouble(),
                    min: 3,
                    max: 18,
                    divisions: 15,
                    label: '$maxZoom',
                    onChanged: (v) {
                      setDialogState(() {
                        maxZoom = v.round();
                        if (minZoom > maxZoom) minZoom = maxZoom;
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$tileCount tiles (~$estimatedMB MB)',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (tileCount > 5000)
                    const Text(
                      'Large download — consider a smaller area or zoom range',
                      style: TextStyle(color: Colors.orange, fontSize: 12),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, {
                    'minZoom': minZoom,
                    'maxZoom': maxZoom,
                  }),
                  child: const Text('Download'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == null || !mounted) return;

    final urlTemplate = isDarkMode
        ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png'
        : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

    final cacheDir =
        '${(await getApplicationDocumentsDirectory()).path}/tile_cache';
    final downloader = TileDownloadService(cacheDir);
    final totalTiles = TileDownloadService.estimateTileCount(
      bounds.southWest,
      bounds.northEast,
      result['minZoom']!,
      result['maxZoom']!,
    );

    // Show progress dialog
    bool downloadCancelled = false;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        int completed = 0;
        return StatefulBuilder(
          builder: (context, setProgressState) {
            // Start download on first build
            if (completed == 0) {
              downloader
                  .downloadTiles(
                    sw: bounds.southWest,
                    ne: bounds.northEast,
                    minZoom: result['minZoom']!,
                    maxZoom: result['maxZoom']!,
                    urlTemplate: urlTemplate,
                    onProgress: (done, total) {
                      if (context.mounted) {
                        setProgressState(() {
                          completed = done;
                        });
                      }
                    },
                  )
                  .then((succeeded) {
                    if (context.mounted) Navigator.pop(context);
                    if (!downloadCancelled) {
                      _showSnackBar('Downloaded $succeeded/$totalTiles tiles');
                    }
                  });
            }

            final progress = totalTiles > 0 ? completed / totalTiles : 0.0;

            return AlertDialog(
              title: const Text('Downloading Tiles'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LinearProgressIndicator(value: progress),
                  const SizedBox(height: 12),
                  Text('$completed / $totalTiles tiles'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    downloadCancelled = true;
                    downloader.cancel();
                    Navigator.pop(context);
                    _showSnackBar(
                      'Download cancelled ($completed tiles cached)',
                    );
                  },
                  child: const Text('Cancel'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _shareCoverageMap() async {
    try {
      // Hide UI elements for clean screenshot
      setState(() {
        _hideUIForScreenshot = true;
      });
      await Future.delayed(const Duration(milliseconds: 300));

      final Uint8List? imageBytes = await _screenshotController.capture(
        pixelRatio: 2.0,
      );

      setState(() {
        _hideUIForScreenshot = false;
      });

      if (imageBytes == null) {
        _showSnackBar('Failed to capture screenshot');
        return;
      }

      // Build stats text
      final pingSamples = _samples.where((s) => s.pingSuccess != null).toList();
      final successCount = pingSamples
          .where((s) => s.pingSuccess == true)
          .length;
      final failCount = pingSamples.where((s) => s.pingSuccess == false).length;
      final totalPings = successCount + failCount;
      final successRate = totalPings > 0
          ? ((successCount / totalPings) * 100).toStringAsFixed(0)
          : 'N/A';
      final coverageCount = _aggregationResult?.coverages.length ?? 0;

      final statsText =
          'MeshCore Wardrive Coverage Map\n'
          '📍 ${_samples.length} samples • $coverageCount coverage areas\n'
          '✅ $successCount success • ❌ $failCount failed • $successRate% rate\n'
          '🔁 ${_repeaters.length} repeaters discovered';

      // Save temp file and share
      final tempDir = await getTemporaryDirectory();
      final file = File(
        '${tempDir.path}/meshcore_coverage_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(imageBytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'MeshCore Wardrive Coverage',
        text: statsText,
      );
    } catch (e) {
      setState(() {
        _hideUIForScreenshot = false;
      });
      _showSnackBar('Share failed: $e');
    }
  }

  void _showRepeaterFilterPicker() {
    // Collect all known repeater IDs from coverage data and discovered repeaters
    final Set<String> knownIds = {};
    if (_aggregationResult != null) {
      for (final cov in _aggregationResult!.coverages) {
        knownIds.addAll(cov.repeaters);
      }
    }
    for (final r in _repeaters) {
      knownIds.add(r.id);
    }

    if (knownIds.isEmpty) {
      _showSnackBar('No repeaters found yet - do some wardriving first!');
      return;
    }

    final sortedIds = knownIds.toList()..sort();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter by Repeater'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: sortedIds.length,
            itemBuilder: (context, index) {
              final id = sortedIds[index];
              final displayId = (id.length > 8 ? id.substring(0, 8) : id)
                  .toUpperCase();
              // Find matching repeater for name
              final repeater = _repeaters.cast<Repeater?>().firstWhere(
                (r) => r!.id == id,
                orElse: () => null,
              );
              final name = repeater?.name;
              final isSelected = _includeOnlyRepeaters == id;

              return ListTile(
                leading: Icon(
                  Icons.cell_tower,
                  color: isSelected ? Colors.blue : Colors.purple,
                ),
                title: Text(name ?? 'Repeater $displayId'),
                subtitle: Text(
                  displayId,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
                trailing: isSelected
                    ? const Icon(Icons.check_circle, color: Colors.blue)
                    : null,
                onTap: () async {
                  Navigator.pop(context);
                  setState(() {
                    _includeOnlyRepeaters = id;
                  });
                  await _settingsService.setIncludeOnlyRepeaters(id);
                  _loadSamples();
                  _showSnackBar('Showing coverage from $displayId');
                },
              );
            },
          ),
        ),
        actions: [
          if (_includeOnlyRepeaters != null &&
              _includeOnlyRepeaters!.isNotEmpty)
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                setState(() {
                  _includeOnlyRepeaters = null;
                });
                await _settingsService.setIncludeOnlyRepeaters(null);
                _loadSamples();
                _showSnackBar('Repeater filter cleared');
              },
              child: const Text(
                'Clear Filter',
                style: TextStyle(color: Colors.red),
              ),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _findCoverageGaps() {
    if (_aggregationResult == null || _aggregationResult!.coverages.isEmpty) {
      _showSnackBar('No coverage data yet - do some wardriving first!');
      return;
    }

    // Find coverage areas with low/zero success rate
    final gaps = <Coverage>[];
    for (final cov in _aggregationResult!.coverages) {
      final total = cov.received + cov.lost;
      if (total == 0) continue; // Skip GPS-only areas
      final successRate = cov.received / total;
      if (successRate < 0.3) {
        // Less than 30% success = gap
        gaps.add(cov);
      }
    }

    // Sort by success rate (worst first)
    gaps.sort((a, b) {
      final aRate = a.received / (a.received + a.lost);
      final bRate = b.received / (b.received + b.lost);
      return aRate.compareTo(bRate);
    });

    if (gaps.isEmpty) {
      _showSnackBar(
        'No coverage gaps found! All areas have >30% success rate.',
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Coverage Gaps (${gaps.length})'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: gaps.length,
            itemBuilder: (context, index) {
              final gap = gaps[index];
              final total = gap.received + gap.lost;
              final rate = total > 0
                  ? ((gap.received / total) * 100).toStringAsFixed(0)
                  : '0';
              return ListTile(
                leading: Icon(
                  Icons.warning,
                  color: double.parse(rate) == 0 ? Colors.red : Colors.orange,
                ),
                title: Text('$rate% success rate'),
                subtitle: Text(
                  '${gap.position.latitude.toStringAsFixed(4)}, '
                  '${gap.position.longitude.toStringAsFixed(4)}\n'
                  '${gap.received.toStringAsFixed(1)} received / ${gap.lost.toStringAsFixed(1)} lost',
                ),
                onTap: () {
                  Navigator.pop(context);
                  _mapController.move(gap.position, 15.0);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadCommunityCoverage() async {
    // Get endpoint to download from
    final endpoints = await _uploadService.getUploadEndpoints();

    String? selectedUrl;
    if (endpoints.length == 1) {
      selectedUrl = endpoints.first.url;
    } else {
      // Let user pick which endpoint to download from
      if (!mounted) return;
      selectedUrl = await showDialog<String>(
        context: context,
        builder: (ctx) => SimpleDialog(
          title: const Text('Download from'),
          children: endpoints
              .map(
                (e) => SimpleDialogOption(
                  onPressed: () => Navigator.pop(ctx, e.url),
                  child: Text(e.name),
                ),
              )
              .toList(),
        ),
      );
    }

    if (selectedUrl == null) return;

    _showSnackBar('Downloading coverage data...');

    final data = await _uploadService.downloadCoverage(
      selectedUrl,
      onProgress: (current, total) {
        // Update snackbar with progress (won't stack, just shows latest)
      },
    );
    if (data != null && data['coverage'] != null) {
      final coverage = data['coverage'] as Map<String, dynamic>;
      setState(() {
        _communityCoverage = coverage;
        _showCommunityCoverage = true;
      });
      _showSnackBar('Downloaded ${coverage.length} coverage cells');
    } else {
      // Try loading from cache
      final cached = await _uploadService.loadCachedCoverage();
      if (cached != null && cached['coverage'] != null) {
        setState(() {
          _communityCoverage = cached['coverage'] as Map<String, dynamic>;
          _showCommunityCoverage = true;
        });
        _showSnackBar('Loaded cached coverage (offline)');
      } else {
        _showSnackBar(
          'Download failed: ${_uploadService.lastDownloadError ?? 'unknown error'}',
        );
      }
    }
  }

  Widget _buildCommunityCoverageLayer() {
    if (_communityCoverage == null) return const SizedBox.shrink();

    final polygons = <Polygon>[];
    final bounds = _mapController.camera.visibleBounds;

    _communityCoverage!.forEach((hash, cellData) {
      if (cellData is! Map<String, dynamic>) return;
      final received = (cellData['received'] as num?)?.toDouble() ?? 0;
      final lost = (cellData['lost'] as num?)?.toDouble() ?? 0;
      final total = received + lost;
      if (total == 0) return;

      // Decode geohash to center position
      try {
        final center = GeohashUtils.posFromHash(hash);

        // Viewport culling
        if (!bounds.contains(center)) return;

        final successRate = received / total;
        final color = successRate >= 0.7
            ? const Color(0x4400CC00)
            : successRate >= 0.3
            ? const Color(0x44CCCC00)
            : const Color(0x44CC0000);

        // Approximate cell size from geohash precision
        final precision = hash.length;
        final latDelta = precision >= 7
            ? 0.0007
            : precision >= 6
            ? 0.005
            : 0.04;
        final lonDelta = precision >= 7
            ? 0.001
            : precision >= 6
            ? 0.01
            : 0.08;

        final points = [
          LatLng(center.latitude - latDelta, center.longitude - lonDelta),
          LatLng(center.latitude - latDelta, center.longitude + lonDelta),
          LatLng(center.latitude + latDelta, center.longitude + lonDelta),
          LatLng(center.latitude + latDelta, center.longitude - lonDelta),
        ];

        polygons.add(
          Polygon(
            points: points,
            color: color,
            borderColor: const Color(0x8800AAEE),
            borderStrokeWidth: 1,
            isFilled: true,
          ),
        );
      } catch (_) {}
    });

    return PolygonLayer(polygons: polygons);
  }

  void _handleMapTap(LatLng point) {
    if (!_showCommunityCoverage || _communityCoverage == null) return;

    // Check if tap hits a community coverage cell
    for (final entry in _communityCoverage!.entries) {
      final hash = entry.key;
      final cellData = entry.value;
      if (cellData is! Map<String, dynamic>) continue;

      try {
        final center = GeohashUtils.posFromHash(hash);
        final precision = hash.length;
        final latDelta = precision >= 7
            ? 0.0007
            : precision >= 6
            ? 0.005
            : 0.04;
        final lonDelta = precision >= 7
            ? 0.001
            : precision >= 6
            ? 0.01
            : 0.08;

        if (point.latitude >= center.latitude - latDelta &&
            point.latitude <= center.latitude + latDelta &&
            point.longitude >= center.longitude - lonDelta &&
            point.longitude <= center.longitude + lonDelta) {
          _showCommunityCellInfo(hash, cellData);
          return;
        }
      } catch (_) {}
    }
  }

  void _showCommunityCellInfo(String hash, Map<String, dynamic> cell) {
    final received = (cell['received'] as num?)?.toDouble() ?? 0;
    final lost = (cell['lost'] as num?)?.toDouble() ?? 0;
    final total = received + lost;
    final samples = cell['samples'] ?? 0;
    final successRate = total > 0
        ? ((received / total) * 100).toStringAsFixed(1)
        : '0';
    final lastUpdate = cell['lastUpdate'] as String? ?? 'Unknown';
    final appVersion = cell['appVersion'] as String? ?? 'Unknown';

    // Build repeater list
    String repeatersText = 'None';
    final repeaters = cell['repeaters'];
    if (repeaters is Map<String, dynamic> && repeaters.isNotEmpty) {
      repeatersText = repeaters.entries
          .map((e) {
            final rep = e.value as Map<String, dynamic>;
            final name = rep['name'] ?? e.key;
            final rssi = rep['rssi'];
            final snr = rep['snr'];
            return '$name${rssi != null ? ' (RSSI: $rssi' : ''}${snr != null
                ? ', SNR: $snr)'
                : rssi != null
                ? ')'
                : ''}';
          })
          .join('\n');
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Community Coverage'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Success Rate: $successRate%',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text('Received: ${received.toStringAsFixed(1)}'),
            Text('Lost: ${lost.toStringAsFixed(1)}'),
            Text('Samples: $samples'),
            const SizedBox(height: 8),
            const Text(
              'Repeaters:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(repeatersText, style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 8),
            Text(
              'Last Update: ${DateTime.tryParse(lastUpdate)?.toLocal().toString().substring(0, 16) ?? lastUpdate}',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
            Text(
              'App Version: $appVersion',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<UploadEndpoint?> _showEditEndpointDialog(
    UploadEndpoint existing,
  ) async {
    final nameController = TextEditingController(text: existing.name);
    final urlController = TextEditingController(text: existing.url);

    return await showDialog<UploadEndpoint>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Upload Site'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Site Name'),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: urlController,
              decoration: const InputDecoration(labelText: 'API URL'),
              keyboardType: TextInputType.url,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (nameController.text.isNotEmpty &&
                  urlController.text.isNotEmpty) {
                Navigator.pop(
                  context,
                  UploadEndpoint(
                    name: nameController.text,
                    url: urlController.text,
                  ),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<UploadEndpoint?> _showAddEndpointDialog() async {
    final nameController = TextEditingController();
    final urlController = TextEditingController();

    return await showDialog<UploadEndpoint>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Upload Site'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Site Name',
                hintText: 'e.g., My Personal Map',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: urlController,
              decoration: const InputDecoration(
                labelText: 'API URL',
                hintText: 'https://your-site.pages.dev/api/samples',
              ),
              keyboardType: TextInputType.url,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (nameController.text.isNotEmpty &&
                  urlController.text.isNotEmpty) {
                Navigator.pop(
                  context,
                  UploadEndpoint(
                    name: nameController.text,
                    url: urlController.text,
                  ),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
