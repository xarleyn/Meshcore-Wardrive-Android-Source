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
import '../models/impossible_zone.dart';
import '../services/location_service.dart';
import '../services/aggregation_service.dart';
import '../services/map_lod_service.dart';
import '../services/lora_companion_service.dart';
import '../services/database_service.dart';
import '../services/upload_service.dart';
import '../services/settings_service.dart';
import '../utils/geohash_utils.dart';
import '../utils/initial_map_camera.dart';
import '../utils/compass_calibration.dart';
import '../utils/heading_utils.dart';
import '../utils/discovery_timeout_options.dart';
import '../utils/ping_distance_options.dart';
import '../utils/session_map_view.dart';
import '../utils/color_blind_palette.dart';
import '../utils/community_coverage.dart';
import '../utils/bluetooth_scan.dart';
import '../widgets/compass_calibration.dart';
import '../widgets/tracking_play_button.dart';
import '../widgets/bluetooth_device_picker_dialog.dart';
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
import '../l10n/achievement_l10n.dart';
import '../l10n/app_locale.dart';
import '../l10n/generated/app_localizations.dart';
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
  bool? _cachedCoverageLodEnabled;
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
  bool _mapLodEnabled = true; // Coarsen coverage/samples at low zoom
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
  InitialMapCamera? _sampleMapCamera;
  bool _mapReady = false;
  bool _hasAppliedInitialSampleCamera = false;
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
  final CompassAccuracyMonitor _compassAccuracyMonitor =
      CompassAccuracyMonitor();
  CompassAccuracyStatus _compassAccuracyStatus = CompassAccuracyStatus.unknown;
  DateTime? _compassCalibrationQuietUntil;

  // Route trail
  bool _showRouteTrail = false;

  // Session filter
  SessionMapView _sessionMapView = const SessionMapView.all();

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
  List<ImpossibleZone> _impossibleZones = [];

  // Battery saver mode
  bool _batterySaverActive = false;
  bool _batterySaverEnabled = true;
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
    await _loadImpossibleZones();

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
          if (mounted) {
            _mapController.move(position, InitialMapCamera.fallbackZoom);
          }
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
            _showSnackBar(
              AppLocalizations.of(context).mapNewRepeaterDiscovered(repeaterId),
            );
          }
        });

    // Subscribe to dead zone alerts
    _deadZoneSubscription = _locationService.deadZoneStream.listen((cellHash) {
      if (mounted) {
        _showSnackBar(
          AppLocalizations.of(context).mapEnteringDeadZone(cellHash),
        );
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
        final l10n = AppLocalizations.of(context);
        _showSnackBar(
          active ? l10n.mapBatterySaverOn : l10n.mapBatterySaverOff,
        );
      }
    });

    // Subscribe to achievement unlocks
    AchievementService().unlockStream.listen((achievement) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        final copy = achievementCopy(l10n, achievement.id);
        _showSnackBar(
          l10n.achievementsUnlockedSnackbar(achievement.icon, copy.title),
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
    final mapLodEnabled = await _settingsService.getMapLodEnabled();
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
      _mapLodEnabled = mapLodEnabled;
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
    final compassQuietUntil = await _settingsService
        .getCompassCalibrationQuietUntil();
    setState(() {
      _lockRotationNorth = lockRotation;
      _keepScreenOn = keepScreenOn;
      _currentLocationMarkerStyle = currentLocationMarkerStyle;
      _showSuccessfulOnly = showSuccessfulOnly;
      _compassCalibrationQuietUntil = compassQuietUntil;
    });
    await ScreenWakeService.instance.setAlwaysOn(keepScreenOn);

    // Load alert toggles
    final deadZoneAlerts = await _settingsService.getDeadZoneAlertsEnabled();
    final newRepeaterAlerts = await _settingsService
        .getNewRepeaterAlertsEnabled();
    final batterySaverEnabled = await _settingsService.getBatterySaverEnabled();
    setState(() {
      _deadZoneAlertsEnabled = deadZoneAlerts;
      _newRepeaterAlertsEnabled = newRepeaterAlerts;
      _batterySaverEnabled = batterySaverEnabled;
    });
    _locationService.setBatterySaverEnabled(batterySaverEnabled);

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

  bool get _compassInUse =>
      _currentLocationMarkerStyle == CurrentLocationMarkerStyle.arrow;

  bool get _showCompassCalibrationBanner {
    return CompassCalibrationPolicy.shouldShowBanner(
      status: _compassAccuracyStatus,
      compassInUse: _compassInUse,
      now: DateTime.now(),
      quietUntil: _compassCalibrationQuietUntil,
    );
  }

  void _syncCompassSubscription() {
    _compassSubscription?.cancel();
    _compassSubscription = null;
    _hasCompassHeading = false;
    _compassAccuracyMonitor.reset();
    if (_compassAccuracyStatus != CompassAccuracyStatus.unknown) {
      _compassAccuracyStatus = CompassAccuracyStatus.unknown;
    }

    if (!_compassInUse) {
      return;
    }

    _compassSubscription = FlutterCompass.events?.listen(
      (event) {
        final heading = event.heading;
        if (heading != null && heading.isFinite) {
          _hasCompassHeading = true;
          _scheduleHeadingUpdate(heading);
        }

        final status = _compassAccuracyMonitor.observe(
          now: DateTime.now(),
          heading: heading,
          accuracy: event.accuracy,
        );
        if (status != _compassAccuracyStatus && mounted) {
          setState(() {
            _compassAccuracyStatus = status;
          });
        }
      },
      onError: (_) {
        _hasCompassHeading = false;
      },
    );
  }

  Future<void> _quietCompassCalibration(Duration duration) async {
    final until = DateTime.now().add(duration);
    if (mounted) {
      setState(() {
        _compassCalibrationQuietUntil = until;
      });
    }
    await _settingsService.setCompassCalibrationQuietUntil(until);
  }

  Future<void> _openCompassCalibration({required bool snoozeOnDismiss}) async {
    final completed = await showCompassCalibrationSheet(context);
    if (!mounted) return;
    if (completed == true) {
      await _quietCompassCalibration(
        CompassCalibrationPolicy.postSuccessQuietDuration,
      );
      if (mounted) {
        _showSnackBar(AppLocalizations.of(context).mapCompassCalibrated);
      }
      return;
    }
    if (snoozeOnDismiss) {
      await _quietCompassCalibration(CompassCalibrationPolicy.snoozeDuration);
    }
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
      var samples = _sessionMapView.visibleSamples(
        await _locationService.getAllSamples(),
      );

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

    _maybeApplyInitialSampleCamera();
  }

  void _maybeApplyInitialSampleCamera() {
    if (_hasAppliedInitialSampleCamera || _currentPosition != null) return;

    final camera = InitialMapCamera.fromPositions(
      _samples.map((sample) => sample.position),
    );
    if (camera == null) return;

    _sampleMapCamera = camera;
    if (!_mapReady || !mounted) return;

    _hasAppliedInitialSampleCamera = true;
    _mapController.move(camera.center, camera.zoom);
  }

  void _applySessionMapView(SessionMapView view) {
    _sessionMapView = view;
    _lastAggregatedSampleCount = -1;
    _loadSamples();
  }

  Future<bool?> _confirmSaveEmptySession() {
    final l10n = AppLocalizations.of(context);
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(l10n.mapSessionEmptyTitle),
        content: Text(l10n.mapSessionEmptyBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.mapDontSave),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.settingsSave),
          ),
        ],
      ),
    );
  }

  Future<void> _handleStoppedSession(int? sessionId) async {
    if (sessionId == null || !mounted) return;

    final db = DatabaseService();
    final sessions = await db.getAllSessions();
    if (!mounted) return;
    WSession? finalized;
    for (final session in sessions) {
      if (session.id == sessionId) {
        finalized = session;
        break;
      }
    }
    if (finalized == null) return;

    if (!SessionMapView.isEmptySession(finalized.sampleCount)) {
      _applySessionMapView(_sessionMapView.afterStopWithSamples(finalized));
      return;
    }

    final save = await _confirmSaveEmptySession();
    if (!mounted) return;
    if (save != false) {
      if (_sessionMapView.scope == SessionMapScope.session) {
        _applySessionMapView(SessionMapView.session(finalized));
      }
      return;
    }

    await db.deleteSession(sessionId);
    final remaining = await db.getAllSessions();
    if (!mounted) return;
    if (_sessionMapView.scope != SessionMapScope.session) return;

    _applySessionMapView(_sessionMapView.afterDiscardingEmpty(remaining));
    final l10n = AppLocalizations.of(context);
    if (remaining.isEmpty) {
      _showSnackBar(l10n.mapSessionDiscarded);
    } else {
      _showSnackBar(l10n.mapSessionDiscardedShowingLast);
    }
  }

  Future<void> _toggleTracking({bool freshSession = false}) async {
    if (_isTracking) {
      // Persist session distance before stopping
      final sessionMeters = _locationService.totalDistanceMeters;
      if (sessionMeters > 0) {
        await _settingsService.addToTotalDistanceDriven(sessionMeters);
      }
      final sessionId = _locationService.currentSessionId;
      // Stop tracking and auto-ping
      await _locationService.stopTracking();
      _locationService.disableAutoPing();
      setState(() {
        _isTracking = false;
        _autoPingEnabled = false;
      });
      await _handleStoppedSession(sessionId);
      // Check for newly unlocked achievements
      AchievementService().checkAndUnlock();
    } else {
      if (!await _prepareAndroidTracking()) return;

      // Start tracking
      final started = await _locationService.startTracking();
      if (started) {
        final l10n = AppLocalizations.of(context);
        String startMessage = l10n.mapLocationTrackingStarted;
        // Auto-enable ping or Carpeater if LoRa is connected
        if (_loraConnected && _carpeaterEnabled) {
          _locationService.setCarpeaterMode(true);
          final carpeaterStarted = await _locationService.startCarpeater();
          setState(() {
            _isTracking = true;
            _autoPingEnabled = false;
          });
          startMessage = carpeaterStarted
              ? l10n.mapCarpeaterModeStarted
              : l10n.mapCarpeaterFailedCheckSettings;
        } else if (_loraConnected) {
          _locationService.enableAutoPing();
          setState(() {
            _isTracking = true;
            _autoPingEnabled = true;
          });
          startMessage = l10n.mapLocationTrackingAndAutoPingStarted;
        } else {
          setState(() {
            _isTracking = true;
          });
        }
        _onTrackingStarted(
          freshSession: freshSession,
          startMessage: startMessage,
        );
      } else {
        _showSnackBar(
          _locationService.lastStartError ??
              AppLocalizations.of(context).mapFailedToStartTracking,
        );
      }
    }
  }

  void _onTrackingStarted({
    required bool freshSession,
    required String startMessage,
  }) {
    if (freshSession) {
      final sessionId = _locationService.currentSessionId;
      final startTime = _locationService.sessionStartTime;
      if (sessionId != null && startTime != null) {
        _applySessionMapView(
          _sessionMapView.afterFreshStart(
            WSession(id: sessionId, startTime: startTime),
          ),
        );
        _showSnackBar(AppLocalizations.of(context).mapNewSessionShowingTrip);
        return;
      }
    }
    _applySessionMapView(_sessionMapView.afterShortPressStart());
    _showSnackBar(startMessage);
  }

  Future<bool> _prepareAndroidTracking() async {
    if (!Platform.isAndroid) return true;

    final foregroundStatus = await Permission.locationWhenInUse.request();
    if (!foregroundStatus.isGranted) return true;

    final accuracy = await Geolocator.getLocationAccuracy();
    if (accuracy != LocationAccuracyStatus.precise) {
      final l10n = AppLocalizations.of(context);
      await _showSettingsDialog(
        title: l10n.mapPreciseLocationRequiredTitle,
        message: l10n.mapPreciseLocationRequiredBody,
        actionLabel: l10n.mapOpenAppSettings,
        onOpen: openAppSettings,
      );
      return false;
    }

    var backgroundStatus = await Permission.locationAlways.status;
    if (!backgroundStatus.isGranted) {
      final l10n = AppLocalizations.of(context);
      final shouldRequest = await _showRequestDialog(
        title: l10n.mapAllowLocationAllTheTimeTitle,
        message: l10n.mapAllowLocationAllTheTimeBody,
      );
      if (!shouldRequest) return false;

      backgroundStatus = await Permission.locationAlways.request();
      if (!backgroundStatus.isGranted) {
        final l10n = AppLocalizations.of(context);
        await _showSettingsDialog(
          title: l10n.mapBackgroundLocationRequiredTitle,
          message: l10n.mapBackgroundLocationRequiredBody,
          actionLabel: l10n.mapOpenAppSettings,
          onOpen: openAppSettings,
        );
        return false;
      }
    }

    final batteryStatus = await Permission.ignoreBatteryOptimizations.status;
    if (!batteryStatus.isGranted) {
      final l10n = AppLocalizations.of(context);
      final shouldRequest = await _showRequestDialog(
        title: l10n.mapUnrestrictedBatteryTitle,
        message: l10n.mapUnrestrictedBatteryBody,
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

    final l10n = AppLocalizations.of(context);
    final openedSettings = await _showSettingsDialog(
      title: l10n.mapDisableWifiThrottlingTitle,
      message: l10n.mapDisableWifiThrottlingBody,
      actionLabel: l10n.mapDeveloperOptions,
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
                child: Text(AppLocalizations.of(context).mapNotNow),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(AppLocalizations.of(context).mapContinue),
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
            child: Text(AppLocalizations.of(context).mapNotNow),
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
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.mapClearMapHistoryTitle),
        content: Text(
          l10n.mapClearMapHistoryBody(_sampleCount),
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.settingsCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.mapDeleteAll),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _locationService.clearAllSamples();
      await _loadSamples();
      _showSnackBar(l10n.mapDeletedSamples(_sampleCount));
    }
  }

  Future<void> _exportData() async {
    // Ask user for export format
    final format = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).mapExportFormat),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.code),
              title: const Text('JSON'),
              subtitle: Text(
                AppLocalizations.of(context).mapExportJsonSubtitle,
              ),
              onTap: () => Navigator.pop(context, 'json'),
            ),
            ListTile(
              leading: const Icon(Icons.table_chart),
              title: const Text('CSV'),
              subtitle: Text(AppLocalizations.of(context).mapExportCsvSubtitle),
              onTap: () => Navigator.pop(context, 'csv'),
            ),
            ListTile(
              leading: const Icon(Icons.route),
              title: const Text('GPX'),
              subtitle: Text(AppLocalizations.of(context).mapExportGpxSubtitle),
              onTap: () => Navigator.pop(context, 'gpx'),
            ),
            ListTile(
              leading: const Icon(Icons.map),
              title: const Text('KML'),
              subtitle: Text(AppLocalizations.of(context).mapExportKmlSubtitle),
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
        title: Text(
          AppLocalizations.of(context).mapExportAs(format.toUpperCase()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'save'),
            child: Text(AppLocalizations.of(context).mapSaveToFolder),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'share'),
            child: Text(AppLocalizations.of(context).mapShare),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context).settingsCancel),
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
          dialogTitle: AppLocalizations.of(context).mapSaveExport,
          fileName: fileName,
          type: FileType.custom,
          allowedExtensions: [extension],
          bytes: utf8.encode(content),
        );
        _showSnackBar(
          AppLocalizations.of(context)
              .mapExportedSamples(samples.length, format.toUpperCase()),
        );
      } else if (choice == 'share') {
        final directory = await getExternalStorageDirectory();
        final file = File('${directory!.path}/$fileName');
        await file.writeAsString(content);

        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(file.path)],
            subject: AppLocalizations.of(context).mapExportShareSubject,
            text: AppLocalizations.of(context)
                .mapExportShareText(samples.length),
          ),
        );
        _showSnackBar(AppLocalizations.of(context).mapExportShared);
      }
    } catch (e) {
      _showSnackBar(AppLocalizations.of(context).mapExportFailed('$e'));
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

      final l10n = AppLocalizations.of(context);
      final sessionLabel = totalSessionsImported > 0
          ? l10n.mapImportedSessionsSuffix(totalSessionsImported)
          : '';
      final sourceLabel = sources.isNotEmpty
          ? l10n.mapImportedFromSources(sources.join(', '))
          : '';
      _showSnackBar(
        '${l10n.mapImportedSamples(totalSamplesImported)}$sessionLabel$sourceLabel',
      );
    } catch (e) {
      _showSnackBar(AppLocalizations.of(context).mapImportFailed('$e'));
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
          title: Text(AppLocalizations.of(context).settingsExportSettings),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, 'save'),
              child: Text(AppLocalizations.of(context).mapSaveToFolder),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, 'share'),
              child: Text(AppLocalizations.of(context).mapShare),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context).settingsCancel),
            ),
          ],
        ),
      );

      if (choice == null) return;

      if (choice == 'save') {
        await FilePicker.platform.saveFile(
          dialogTitle: AppLocalizations.of(context).mapSaveSettings,
          fileName: fileName,
          type: FileType.custom,
          allowedExtensions: ['json'],
          bytes: utf8.encode(jsonString),
        );
        _showSnackBar(AppLocalizations.of(context).mapSettingsExported);
      } else if (choice == 'share') {
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/$fileName');
        await file.writeAsString(jsonString);
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(file.path)],
            text: AppLocalizations.of(context).mapSettingsShareText,
          ),
        );
      }
    } catch (e) {
      _showSnackBar(AppLocalizations.of(context).mapExportFailed('$e'));
    }
  }

  Future<void> _importSettings() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.isEmpty) return;
      final pickedFile = result.files.single;

      final file = File(pickedFile.path!);
      final jsonString = await file.readAsString();

      // Show confirmation dialog
      if (!mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(AppLocalizations.of(context).settingsImportSettings),
          content: Text(AppLocalizations.of(context).mapImportSettingsConfirm),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(AppLocalizations.of(context).settingsCancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(AppLocalizations.of(context).mapImport),
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

      _showSnackBar(
        AppLocalizations.of(context).mapImportedSettingsCount(applied),
      );
    } on FormatException catch (e) {
      _showSnackBar(
        AppLocalizations.of(context).mapInvalidSettingsFile(e.message),
      );
    } catch (e) {
      _showSnackBar(AppLocalizations.of(context).mapImportFailed('$e'));
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
        title: Text(AppLocalizations.of(ctx).mapAddPlannedRepeater),
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
              decoration: InputDecoration(
                labelText: AppLocalizations.of(ctx).settingsLabelOptional,
                hintText: AppLocalizations.of(ctx).mapPlannedRepeaterHint,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(ctx).settingsCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: Text(AppLocalizations.of(ctx).mapAddMarker),
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
      _showSnackBar(AppLocalizations.of(context).mapPlannedRepeaterMarkerAdded);
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
        title: Text(label ?? AppLocalizations.of(ctx).mapPlannedRepeater),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppLocalizations.of(ctx).mapLat(lat.toStringAsFixed(6))),
            Text(AppLocalizations.of(ctx).mapLon(lon.toStringAsFixed(6))),
            Text(
              AppLocalizations.of(ctx).mapAddedOn(
                DateFormat.yMMMd(Localizations.localeOf(ctx).toString())
                    .format(createdAt),
              ),
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
              _showSnackBar(AppLocalizations.of(context).mapMarkerDeleted);
            },
            child: Text(
              AppLocalizations.of(ctx).mapDelete,
              style: const TextStyle(color: Colors.red),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(ctx).mapClose),
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

  Future<void> _loadImpossibleZones() async {
    final zones = await DatabaseService().getAllImpossibleZones();
    if (!mounted) return;
    setState(() {
      _impossibleZones = zones;
    });
  }

  Future<void> _addPrivacyZone(LatLng center) async {
    final l10n = AppLocalizations.of(context);
    final radiusOptions = [
      {'label': l10n.settingsRadius500m, 'meters': 500.0},
      {'label': l10n.settingsRadius1km, 'meters': 1000.0},
      {'label': l10n.settingsRadius2km, 'meters': 2000.0},
      {'label': l10n.settingsRadius5km, 'meters': 5000.0},
    ];
    double selectedRadius = 1000.0;
    final labelController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(l10n.mapAddPrivacyZone),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.settingsAddImpossibleZoneCenter(
                  center.latitude.toStringAsFixed(5),
                  center.longitude.toStringAsFixed(5),
                ),
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.mapPrivacyZoneBlurb,
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: labelController,
                decoration: InputDecoration(
                  labelText: l10n.settingsLabelOptional,
                  hintText: l10n.mapPrivacyZoneHint,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.settingsRadius,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
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
              child: Text(l10n.settingsCancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.settingsAddZone),
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
      _showSnackBar(l10n.mapPrivacyZoneAdded);
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
        title: Text(AppLocalizations.of(ctx).mapDeleteSample),
        content: Text(
          AppLocalizations.of(ctx).mapDeleteSampleConfirm(
            sample.pingSuccess == true
                ? 'success'
                : sample.pingSuccess == false
                ? 'fail'
                : 'gps',
            DateFormat.MMMd(Localizations.localeOf(ctx).toString())
                .add_Hm()
                .format(sample.timestamp),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppLocalizations.of(ctx).settingsCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              AppLocalizations.of(ctx).mapDelete,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await DatabaseService().deleteSample(sample.id);
      _lastAggregatedSampleCount = -1;
      await _loadSamples();
      _showSnackBar(AppLocalizations.of(context).mapSampleDeleted);
    }
  }

  void _deleteCoverageCell(Coverage coverage) async {
    final total = (coverage.received + coverage.lost).round();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(ctx).mapDeleteCoverageCell),
        content: Text(
          AppLocalizations.of(ctx)
              .mapDeleteCoverageCellBody(total, coverage.id),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppLocalizations.of(ctx).settingsCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              AppLocalizations.of(ctx).mapDeleteAll,
              style: const TextStyle(color: Colors.red),
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
      _showSnackBar(
        AppLocalizations.of(context).mapDeletedSamplesFromCell(deleted),
      );
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

  int get _coverageLodPrecision {
    if (!_mapLodEnabled) return _coveragePrecision;
    return MapLodService.precisionForZoom(
      _mapLodZoom,
      maxPrecision: _coveragePrecision,
    );
  }

  int get _sampleLodPrecision {
    if (!_mapLodEnabled) return 8;
    return MapLodService.precisionForZoom(_mapLodZoom, maxPrecision: 8);
  }

  void _updateMapLodZoom(double zoom) {
    if (!_mapLodEnabled) {
      _mapLodZoom = zoom;
      return;
    }

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
      _mapLodZoom = zoom;
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
      _cachedCoverageLodPrecision = null;
      _cachedCoverageLodEnabled = null;
      return;
    }
    if (identical(_cachedLodAggregation, aggregation) &&
        _cachedCoverageLodPrecision == precision &&
        _cachedCoverageLodEnabled == _mapLodEnabled) {
      return;
    }

    final coverages = _mapLodEnabled
        ? MapLodService.aggregateCoverages(
            aggregation.coverages,
            precision: precision,
          )
        : aggregation.coverages;
    _cachedLodAggregation = aggregation;
    _cachedCoverageLodPrecision = precision;
    _cachedCoverageLodEnabled = _mapLodEnabled;
    _cachedLodCoverages = coverages;
    _cachedLodEdges = _mapLodEnabled
        ? MapLodService.aggregateEdges(
            aggregation.edges,
            coverages,
            precision: precision,
          )
        : aggregation.edges;
  }

  List<SampleCluster> _sampleClustersForCurrentLod() {
    final filterKey = [
      _showGpsSamples,
      _showSuccessfulOnly,
      _includeOnlyRepeaters ?? '',
      _mapLodEnabled,
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
    _cachedSampleClusters = _mapLodEnabled
        ? MapLodService.aggregateSamples(filteredSamples, precision: precision)
        : MapLodService.individualSamples(filteredSamples);
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
            builder: (context) {
              final l10n = AppLocalizations.of(context);
              return AlertDialog(
                title: Text(l10n.mapUpdateAvailable),
                content: Text(
                  l10n.mapUpdateAvailableBody(latestVersion, appVersion),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(l10n.compassLater),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _openGitHub();
                    },
                    child: Text(l10n.mapDownload),
                  ),
                ],
              );
            },
          );
        } else {
          _showSnackBar(AppLocalizations.of(context).mapOnLatestVersion);
        }
      } else {
        _showSnackBar(AppLocalizations.of(context).mapCouldNotCheckUpdates);
      }
    } on SocketException {
      _showSnackBar(AppLocalizations.of(context).mapNoInternetTryAgain);
    } on TimeoutException {
      _showSnackBar(AppLocalizations.of(context).mapUpdateCheckTimedOut);
    } catch (_) {
      _showSnackBar(AppLocalizations.of(context).mapCouldNotCheckUpdates);
    }
  }

  Future<void> _openGitHub() async {
    final url = Uri.parse(
      'https://github.com/mintylinux/Meshcore-Wardrive-Android/releases',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      _showSnackBar(AppLocalizations.of(context).mapCouldNotOpenGitHub);
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
      _showSnackBar(AppLocalizations.of(context).mapAutoFollowEnabled);
    } else {
      _showSnackBar(AppLocalizations.of(context).mapAutoFollowDisabled);
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
      _showSnackBar(AppLocalizations.of(context).mapMapResetToNorth);
      return;
    }

    setState(() {
      _followHeading = !_followHeading;
    });

    if (_followHeading) {
      _rotateMapToHeading();
      _showSnackBar(AppLocalizations.of(context).mapHeadingUpEnabled);
    } else {
      _mapController.rotate(0);
      _showSnackBar(AppLocalizations.of(context).mapHeadingUpDisabled);
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
        _showSnackBar(
          AppLocalizations.of(context).mapFailedToCaptureScreenshot,
        );
        return;
      }

      // Save to gallery
      final String fileName =
          'meshcore_wardrive_${DateTime.now().millisecondsSinceEpoch}.png';
      final result = await SaverGallery.saveImage(
        imageBytes,
        quality: 100,
        fileName: fileName,
        androidRelativePath: 'MeshCore',
        skipIfExists: false,
      );

      if (result.isSuccess) {
        _showSnackBar(AppLocalizations.of(context).mapScreenshotSavedToGallery);

        // Ask if user wants to share
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(AppLocalizations.of(context).mapScreenshotSavedTitle),
            content: Text(
              AppLocalizations.of(context).mapShareScreenshotPrompt,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(AppLocalizations.of(context).mapNo),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  // Save temp file and share
                  final tempDir = await getTemporaryDirectory();
                  final file = File('${tempDir.path}/meshcore_screenshot.png');
                  await file.writeAsBytes(imageBytes);
                  await SharePlus.instance.share(
                    ShareParams(
                      files: [XFile(file.path)],
                      text: AppLocalizations.of(context).mapScreenshotShareText,
                    ),
                  );
                },
                child: Text(AppLocalizations.of(context).mapYes),
              ),
            ],
          ),
        );
      } else {
        _showSnackBar(AppLocalizations.of(context).mapFailedToSaveScreenshot);
      }
    } catch (e) {
      // Restore UI on error
      setState(() {
        _hideUIForScreenshot = false;
      });
      _showSnackBar(
        AppLocalizations.of(context).mapErrorCapturingScreenshot('$e'),
      );
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
    final l10n = AppLocalizations.of(context);
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
            tooltip: l10n.mapDebugTerminal,
          ),
          IconButton(
            icon: const Icon(Icons.camera_alt),
            onPressed: _captureScreenshot,
            tooltip: l10n.mapScreenshotTooltip,
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
                right: 88,
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
                            Text(
                              l10n.mapQuickSettings,
                              style: const TextStyle(
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
                            Text(
                              l10n.mapPingDist,
                              style: const TextStyle(fontSize: 12),
                            ),
                            PingDistanceDropdown(
                              value: _pingIntervalMeters,
                              onChanged: (v) async {
                                setState(() => _pingIntervalMeters = v);
                                _locationService.setPingInterval(v);
                                await _settingsService.setPingInterval(v);
                              },
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              l10n.mapTimeout,
                              style: const TextStyle(fontSize: 12),
                            ),
                            DiscoveryTimeoutDropdown(
                              value: _discoveryTimeoutSeconds,
                              onChanged: (v) async {
                                setState(() => _discoveryTimeoutSeconds = v);
                                await _settingsService.setDiscoveryTimeout(v);
                              },
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              l10n.mapMode,
                              style: const TextStyle(fontSize: 12),
                            ),
                            DropdownButton<String>(
                              value: _pingMode,
                              isDense: true,
                              items: [
                                DropdownMenuItem(
                                  value: 'distance',
                                  child: Text(
                                    l10n.settingsPingModeDistance,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 'time',
                                  child: Text(
                                    l10n.settingsPingModeTime,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 'both',
                                  child: Text(
                                    l10n.settingsPingModeBoth,
                                    style: const TextStyle(fontSize: 12),
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
            if (_showCompassCalibrationBanner && !_hideUIForScreenshot)
              CompassCalibrationMapBanner(
                onCalibrate: () =>
                    _openCompassCalibration(snoozeOnDismiss: true),
                onLater: () => _quietCompassCalibration(
                  CompassCalibrationPolicy.snoozeDuration,
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
                        Expanded(
                          child: Text(
                            l10n.mapDeleteModeBanner,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => setState(() => _deleteMode = false),
                          child: Text(
                            l10n.mapExit,
                            style: const TextStyle(
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
                GestureDetector(
                  onLongPress: () =>
                      _openCompassCalibration(snoozeOnDismiss: false),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      FloatingActionButton(
                        heroTag: 'compass',
                        mini: true,
                        onPressed: _handleCompassButton,
                        tooltip: _compassInUse && !_lockRotationNorth
                            ? _followHeading
                                  ? l10n.mapStopHeadingUp
                                  : l10n.mapRotateMapWithHeading
                            : l10n.mapResetToNorth,
                        backgroundColor: _followHeading ? Colors.blue : null,
                        child: const Icon(Icons.navigation),
                      ),
                      if (_compassInUse &&
                          _compassAccuracyStatus ==
                              CompassAccuracyStatus.needsCalibration)
                        const Positioned(
                          right: 0,
                          top: 0,
                          child: Icon(
                            Icons.error,
                            size: 14,
                            color: Colors.orange,
                          ),
                        ),
                    ],
                  ),
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
                TrackingPlayButton(
                  isTracking: _isTracking,
                  onToggle: _toggleTracking,
                  onStartFreshSession: () =>
                      _toggleTracking(freshSession: true),
                  onToggleQuickSettings: () =>
                      setState(() => _showQuickSettings = !_showQuickSettings),
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
        initialCenter:
            _currentPosition ??
            _sampleMapCamera?.center ??
            InitialMapCamera.fallbackCenter,
        initialZoom: _currentPosition != null
            ? InitialMapCamera.fallbackZoom
            : (_sampleMapCamera?.zoom ?? InitialMapCamera.fallbackZoom),
        minZoom: 3.0,
        maxZoom: 18.0,
        onMapReady: () {
          _mapReady = true;
          _maybeApplyInitialSampleCamera();
        },
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
            _showSnackBar(AppLocalizations.of(context).mapZoomToDeleteCell);
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
          _showSnackBar(AppLocalizations.of(context).mapZoomedPointsGrouped);
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
              label: AppLocalizations.of(context)
                  .mapApproxRadioPositionUncertainty(uncertaintyText),
              button: true,
              child: GestureDetector(
                onTap: () => _showSnackBar(
                  AppLocalizations.of(context).mapApproxRadioPositionSnack(
                    estimate.repeaterCount,
                    uncertaintyText,
                  ),
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
    final l10n = AppLocalizations.of(context);
    final positionLabel = _positionSource == LocationPositionSource.wifi
        ? l10n.mapCurrentWifiLocation
        : l10n.mapCurrentFusedLocation;
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
      label: l10n.mapPositionHeadingSemantics(
        positionLabel,
        '${_currentHeading.round()}',
      ),
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
    final l10n = AppLocalizations.of(context);
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
                    : l10n.mapNoLora,
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
                      l10n.mapSamplesCount('$_sampleCount'),
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
                                  _showSnackBar(l10n.mapRetryingCarpeater);
                                  final ok = await _locationService
                                      .startCarpeater();
                                  _showSnackBar(
                                    ok
                                        ? l10n.mapCarpeaterReconnected
                                        : l10n.mapCarpeaterRetryFailed,
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
                                  l10n.mapCarpeaterStatus(
                                    _carpeaterStateLabel(l10n),
                                  ),
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
                            color: _getDuctingColor(_currentDuctingRisk)
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _getDuctingColor(_currentDuctingRisk),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            l10n.mapDuctingStatus(
                              _localizedDuctingRisk(l10n, _currentDuctingRisk),
                            ),
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
                          child: Text(
                            l10n.mapBatterySaverBadge,
                            style: const TextStyle(
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
                    _isConnecting ? l10n.mapConnecting : l10n.mapConnect,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              if (_loraConnected) ...[
                IconButton(
                  icon: const Icon(Icons.link_off, size: 16),
                  onPressed: _disconnectLoRa,
                  tooltip: l10n.mapDisconnect,
                  color: Colors.red,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.send, size: 18),
                  onPressed: _manualPing,
                  tooltip: l10n.mapManualPing,
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
      _showSnackBar(AppLocalizations.of(context).mapConnectLoraFirst);
      return;
    }

    if (_currentPosition == null) {
      _showSnackBar(AppLocalizations.of(context).mapWaitingForGps);
      return;
    }

    if (_locationService.loraCompanion.isPingInProgress) {
      _showSnackBar(AppLocalizations.of(context).mapPingAlreadyInProgress);
      return;
    }

    _showSnackBar(AppLocalizations.of(context).mapSendingPing);
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
      final l10n = AppLocalizations.of(context);
      final summary = responses.length == 1
          ? l10n.mapPingHeardBy(_shortNodeId(responses.single.nodeId))
          : l10n.mapDiscoveryComplete(responses.length);
      _showSnackBar(summary);
    } else if (result.status == PingStatus.timeout) {
      _showSnackBar(AppLocalizations.of(context).mapNoResponseDeadZone);
    } else {
      _showSnackBar(
        AppLocalizations.of(context).mapPingFailed('${result.error}'),
      );
    }
  }

  String _shortNodeId(String nodeId) {
    return (nodeId.length > 8 ? nodeId.substring(0, 8) : nodeId).toUpperCase();
  }

  void _showConnectionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).mapConnectLoraDevice),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context).mapChooseConnectionMethod,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _connectUsb();
              },
              icon: const Icon(Icons.usb),
              label: Text(AppLocalizations.of(context).mapScanUsbDevices),
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
              label: Text(AppLocalizations.of(context).mapScanBluetooth),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 40),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context).mapClose),
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
        _showSnackBar(AppLocalizations.of(context).mapNoUsbDevices);
        return;
      }

      final selected = await showDialog<UsbDevice>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(AppLocalizations.of(context).mapSelectUsbDevice),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: devices.map((device) {
              return ListTile(
                title: Text(
                  device.productName ??
                      AppLocalizations.of(context).mapUsbDeviceFallback,
                ),
                subtitle: Text(
                  AppLocalizations.of(context)
                      .mapVidPid('${device.vid}', '${device.pid}'),
                ),
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
          _showSnackBar(AppLocalizations.of(context).mapConnectedViaUsb);
          await _loadSamples();
        } else {
          _showSnackBar(AppLocalizations.of(context).mapFailedConnectUsb);
        }
      }
    } catch (e) {
      _showSnackBar(AppLocalizations.of(context).mapUsbError('$e'));
    } finally {
      if (mounted) setState(() => _isConnecting = false);
    }
  }

  Future<void> _connectBluetooth() async {
    if (_isConnecting) return;
    setState(() => _isConnecting = true);
    try {
      final recent = await _settingsService.getRecentBluetoothDevices();
      final tracked = [
        for (final row in await DatabaseService().getAllDevices())
          if (row['connection_type'] == 'bluetooth')
            KnownBluetoothDevice(
              remoteId:
                  bluetoothRemoteIdFromStoredId('${row['public_key'] ?? ''}') ??
                  '',
              name: '${row['name'] ?? ''}',
            ),
      ].where((device) => device.remoteId.isNotEmpty).toList();
      final bonded = await _locationService.loraCompanion
          .getBondedCompanionDevices();
      final known = collectKnownBluetoothDevices(
        recent: recent,
        tracked: tracked,
        bonded: bonded,
      );

      if (!mounted) return;
      final selected = await showDialog<BluetoothScanEntry>(
        context: context,
        builder: (context) => BluetoothDevicePickerDialog(
          scan: _locationService.loraCompanion.watchBluetoothScan(
            knownDevices: known,
          ),
        ),
      );

      if (selected == null) return;

      _showSnackBar(
        AppLocalizations.of(context).mapConnectingTo(selected.displayName),
      );

      final connected = await _locationService.loraCompanion.connectBluetooth(
        BluetoothDevice.fromId(selected.remoteId),
      );
      if (connected) {
        await _settingsService.rememberBluetoothDevice(
          remoteId: selected.remoteId,
          name: _locationService.loraCompanion.deviceName ?? selected.name,
        );
        _showSnackBar(AppLocalizations.of(context).mapConnectedViaBluetooth);
        await _loadSamples();
      } else {
        _showSnackBar(AppLocalizations.of(context).mapFailedConnectBluetooth);
      }
    } catch (e) {
      _showSnackBar(AppLocalizations.of(context).bluetoothError('$e'));
    } finally {
      if (mounted) setState(() => _isConnecting = false);
    }
  }

  Future<void> _disconnectLoRa() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).mapDisconnectLoraDevice),
        content: Text(AppLocalizations.of(context).mapDisconnectConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context).settingsCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppLocalizations.of(context).mapDisconnect),
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
      _showSnackBar(AppLocalizations.of(context).mapLoraDisconnected);
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

  String _carpeaterStateLabel(AppLocalizations l10n) {
    switch (_carpeaterState) {
      case CarpeaterState.disabled:
        return l10n.mapCarpeaterOff;
      case CarpeaterState.connecting:
        return l10n.mapCarpeaterConnecting;
      case CarpeaterState.loggingIn:
        return l10n.mapCarpeaterLogin;
      case CarpeaterState.loggedIn:
        return l10n.mapCarpeaterReady;
      case CarpeaterState.discovering:
        return l10n.mapCarpeaterScanning;
      case CarpeaterState.fetchingNeighbours:
        return l10n.mapCarpeaterFetching;
      case CarpeaterState.error:
        return l10n.mapCarpeaterError;
    }
  }

  String _localizedDuctingRisk(AppLocalizations l10n, String risk) {
    switch (risk) {
      case DuctingRisk.none:
        return l10n.settingsNone;
      case DuctingRisk.possible:
        return l10n.mapDuctingPossible;
      case DuctingRisk.likely:
        return l10n.mapDuctingLikely;
      default:
        return l10n.settingsUnknown;
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
      _showSnackBar(AppLocalizations.of(context).mapConnectLoraFirst);
      return;
    }

    _showSnackBar(AppLocalizations.of(context).mapRefreshingContactList);

    // Request full contact list from device
    await _locationService.loraCompanion.refreshContactList();

    // Give it a moment to process
    await Future.delayed(const Duration(seconds: 2));

    _showSnackBar(AppLocalizations.of(context).mapContactListUpdated);
  }

  Future<void> _scanForRepeaters() async {
    if (!_loraConnected) {
      _showSnackBar(AppLocalizations.of(context).mapConnectLoraFirst);
      return;
    }

    _showSnackBar(AppLocalizations.of(context).mapScanningForRepeaters);

    final repeaters = await _locationService.loraCompanion.scanForRepeaters();

    setState(() {
      _repeaters = repeaters;
    });

    if (repeaters.isEmpty) {
      _showSnackBar(AppLocalizations.of(context).mapNoRepeatersFound);
    } else {
      _showSnackBar(
        AppLocalizations.of(context).mapRepeatersFound(repeaters.length),
      );
      _showRepeatersDialog();
    }
  }

  void _openSessionHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SessionHistoryScreen(
          onSessionSelected: (session) {
            _applySessionMapView(SessionMapView.session(session));
            _showSnackBar(
              AppLocalizations.of(context).mapShowingSessionFrom(
                DateFormat.MMMd(Localizations.localeOf(context).toString())
                    .add_Hm()
                    .format(session.startTime),
              ),
            );
          },
          onSessionDeleted: (deletedId, remaining) {
            _applySessionMapView(
              _sessionMapView.afterDeletingSession(
                deletedId: deletedId,
                remainingNewestFirst: remaining,
              ),
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
    final l10n = AppLocalizations.of(context);
    final appState = MyApp.of(context);
    if (appState == null) return l10n.settingsThemeSystemDefault;

    switch (appState.themeMode) {
      case ThemeMode.light:
        return l10n.settingsThemeLight;
      case ThemeMode.dark:
        return l10n.settingsThemeDark;
      case ThemeMode.system:
        return l10n.settingsThemeSystemDefault;
    }
  }

  Future<void> _showInterfaceThemeSelector() async {
    final appState = MyApp.of(context);
    if (appState == null) return;

    final selected = await showDialog<ThemeMode>(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context);
        return AlertDialog(
          title: Text(l10n.settingsChooseInterfaceTheme),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(l10n.settingsThemeLight),
                leading: const Icon(Icons.light_mode),
                onTap: () => Navigator.pop(context, ThemeMode.light),
              ),
              ListTile(
                title: Text(l10n.settingsThemeDark),
                leading: const Icon(Icons.dark_mode),
                onTap: () => Navigator.pop(context, ThemeMode.dark),
              ),
              ListTile(
                title: Text(l10n.settingsThemeSystemDefault),
                leading: const Icon(Icons.brightness_auto),
                onTap: () => Navigator.pop(context, ThemeMode.system),
              ),
            ],
          ),
        );
      },
    );

    if (selected != null) {
      await appState.setThemeMode(selected);
    }
  }

  String _getAppLocalePreferenceText() {
    final l10n = AppLocalizations.of(context);
    switch (MyApp.of(context)?.localePreference) {
      case AppLocalePreference.en:
        return l10n.languageEnglish;
      case AppLocalePreference.ru:
        return l10n.languageRussian;
      case AppLocalePreference.system:
      case null:
        return l10n.languageSystem;
    }
  }

  Future<void> _showLanguageSelector() async {
    final appState = MyApp.of(context);
    if (appState == null) return;

    final selected = await showDialog<AppLocalePreference>(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context);
        return AlertDialog(
          title: Text(l10n.languagePickerTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(l10n.languageSystem),
                leading: const Icon(Icons.brightness_auto),
                onTap: () => Navigator.pop(context, AppLocalePreference.system),
              ),
              ListTile(
                title: Text(l10n.languageEnglish),
                leading: const Icon(Icons.language),
                onTap: () => Navigator.pop(context, AppLocalePreference.en),
              ),
              ListTile(
                title: Text(l10n.languageRussian),
                leading: const Icon(Icons.language),
                onTap: () => Navigator.pop(context, AppLocalePreference.ru),
              ),
            ],
          ),
        );
      },
    );

    if (selected != null) {
      await appState.setAppLocalePreference(selected);
      await _locationService.refreshNotificationCopy();
    }
  }

  String _getMapThemeModeText() {
    final l10n = AppLocalizations.of(context);
    switch (_mapThemeMode) {
      case MapThemeMode.light:
        return l10n.settingsThemeLight;
      case MapThemeMode.dark:
        return l10n.settingsThemeDark;
      case MapThemeMode.system:
        return l10n.settingsThemeSystemDefault;
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
      builder: (context) {
        final l10n = AppLocalizations.of(context);
        return AlertDialog(
          title: Text(l10n.settingsChooseMapTheme),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(l10n.settingsThemeLight),
                leading: const Icon(Icons.light_mode),
                onTap: () => Navigator.pop(context, MapThemeMode.light),
              ),
              ListTile(
                title: Text(l10n.settingsThemeDark),
                leading: const Icon(Icons.dark_mode),
                onTap: () => Navigator.pop(context, MapThemeMode.dark),
              ),
              ListTile(
                title: Text(l10n.settingsThemeSystemDefault),
                leading: const Icon(Icons.brightness_auto),
                onTap: () => Navigator.pop(context, MapThemeMode.system),
              ),
            ],
          ),
        );
      },
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
    final l10n = AppLocalizations.of(context);
    final timestamp = DateFormat.yMMMd(
      Localizations.localeOf(context).toString(),
    ).add_Hms().format(sample.timestamp);
    final hasSignalData = sample.rssi != null || sample.snr != null;
    final pingStatus = sample.pingSuccess == true
        ? l10n.mapStatusSuccess
        : sample.pingSuccess == false
        ? l10n.mapStatusFailed
        : l10n.mapStatusGpsOnly;

    // Get repeater name if available (sample.path holds repeater/node ID)
    final repeaterName = sample.path != null
        ? _getRepeaterName(sample.path)
        : null;
    final idOrName = repeaterName ?? sample.path ?? l10n.settingsUnknown;
    final repeaterDisplay = (repeaterName != null)
        ? repeaterName
        : (idOrName.length > 8
              ? idOrName.substring(0, 8).toUpperCase()
              : idOrName.toUpperCase());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.mapSampleInfo),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  l10n.mapStatusLabel,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(pingStatus),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              l10n.mapTimeLabel(timestamp),
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 8),
            Text(l10n.mapLat(sample.position.latitude.toStringAsFixed(6))),
            Text(l10n.mapLon(sample.position.longitude.toStringAsFixed(6))),
            if (sample.path != null) ...[
              const Divider(height: 16),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    l10n.mapRepeaterLabel,
                    style: const TextStyle(fontWeight: FontWeight.bold),
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
                  Text(
                    l10n.mapRssiLabel,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text('${sample.rssi} dBm'),
                ],
              ),
            if (sample.snr != null)
              Row(
                children: [
                  Text(
                    l10n.mapSnrLabel,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text('${sample.snr} dB'),
                ],
              ),
            if (sample.responseTimeMs != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    l10n.mapResponseLabel,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text('${sample.responseTimeMs} ms'),
                ],
              ),
            ],
            if (sample.ductingRisk != null) ...[
              const Divider(height: 16),
              Row(
                children: [
                  Text(
                    l10n.mapDuctingLabel,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _getDuctingColor(sample.ductingRisk!)
                          .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _localizedDuctingRisk(l10n, sample.ductingRisk!),
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
            child: Text(AppLocalizations.of(context).mapClose),
          ),
        ],
      ),
    );
  }

  void _showSampleClusterInfo(SampleCluster cluster) {
    final l10n = AppLocalizations.of(context);
    final newestTimestamp = DateFormat.yMMMd(
      Localizations.localeOf(context).toString(),
    ).add_Hms().format(cluster.newestSample.timestamp);
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.mapGroupedSamples(cluster.sampleCount)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.mapSuccessfulCount(cluster.successfulCount)),
            Text(l10n.mapFailedCount(cluster.failedCount)),
            Text(l10n.mapGpsOnlyCount(cluster.gpsOnlyCount)),
            const SizedBox(height: 8),
            Text(l10n.mapNewest(newestTimestamp)),
            const SizedBox(height: 8),
            Text(l10n.mapZoomForBreakdown),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context).mapClose),
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
              AppLocalizations.of(context).mapRepeaterFallback(
                (repeater.id.length > 8
                        ? repeater.id.substring(0, 8)
                        : repeater.id)
                    .toUpperCase(),
              ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context).mapIdLabel(
                (repeater.id.length > 8
                        ? repeater.id.substring(0, 8)
                        : repeater.id)
                    .toUpperCase(),
              ),
              style: const TextStyle(fontFamily: 'monospace'),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)
                  .mapLat(repeater.position.latitude.toStringAsFixed(6)),
            ),
            Text(
              AppLocalizations.of(context)
                  .mapLon(repeater.position.longitude.toStringAsFixed(6)),
            ),
            if (repeater.rssi != null) const SizedBox(height: 8),
            if (repeater.rssi != null)
              Text(
                AppLocalizations.of(context).mapRssiValue('${repeater.rssi}'),
              ),
            if (repeater.snr != null)
              Text(AppLocalizations.of(context).mapSnrValue('${repeater.snr}')),
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
                AppLocalizations.of(context).mapFilteringBy(
                  (repeater.id.length > 8
                          ? repeater.id.substring(0, 8)
                          : repeater.id)
                      .toUpperCase(),
                ),
              );
            },
            child: Text(AppLocalizations.of(context).mapFilterByThis),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _mapController.move(repeater.position, 15.0);
            },
            child: Text(AppLocalizations.of(context).mapShowOnMap),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context).mapClose),
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
        : AppLocalizations.of(context).mapNotAvailable;
    final reliabilityText = total > 0
        ? '$successRate%'
        : AppLocalizations.of(context).mapNoPingData;

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
        : AppLocalizations.of(context).settingsNone;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).mapCoverageSquareInfo),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  AppLocalizations.of(context).mapSamplesLabel,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(totalDisplay),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  AppLocalizations.of(context).mapSuccessRateLabel,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(reliabilityText),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  AppLocalizations.of(context).mapReceivedLabel,
                  style: const TextStyle(
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
                Text(
                  AppLocalizations.of(context).mapLostLabel,
                  style: const TextStyle(
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
                  Text(
                    AppLocalizations.of(context).mapRepeatersHeard,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text('${uniquePrefixes.length}'),
                ],
              ),
            if (coverage.received > 0) const SizedBox(height: 4),
            if (coverage.received > 0)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context).mapRepeaterIds,
                    style: const TextStyle(fontWeight: FontWeight.bold),
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
            child: Text(AppLocalizations.of(context).mapClose),
          ),
        ],
      ),
    );
  }

  void _showRepeatersDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          AppLocalizations.of(context).mapNearbyRepeaters(_repeaters.length),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _repeaters.length,
            itemBuilder: (context, index) {
              final repeater = _repeaters[index];
              return ListTile(
                leading: const Icon(Icons.cell_tower, color: Colors.purple),
                title: Text(
                  repeater.name ??
                      AppLocalizations.of(context)
                          .mapRepeaterFallback(repeater.id),
                ),
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
            child: Text(AppLocalizations.of(context).mapClose),
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
                      ? AppLocalizations.of(context).mapUploadingTo(currentSite)
                      : AppLocalizations.of(context).mapUploadingSamples,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                if (totalBatches > 1)
                  Text(
                    AppLocalizations.of(context)
                        .mapUploadBatch(currentBatch, totalBatches),
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
        results = {AppLocalizations.of(context).mapUploadFallbackName: result};
      }

      if (mounted) {
        Navigator.pop(context); // Close loading dialog

        // Show results
        final allSuccess = results.values.every((r) => r.success);
        final successCount = results.values.where((r) => r.success).length;

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(
              allSuccess
                  ? AppLocalizations.of(context).mapUploadComplete
                  : AppLocalizations.of(context).mapUploadResults,
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (results.length > 1)
                  Text(
                    AppLocalizations.of(context)
                        .mapUploadedToSites(successCount, results.length),
                  ),
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
                child: Text(AppLocalizations.of(context).mapOk),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        _showSnackBar(AppLocalizations.of(context).mapUploadError('$e'));
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
                    children: [
                      Text(
                        AppLocalizations.of(context).settingsManageUploadSites,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    AppLocalizations.of(context).mapSelectWhichSitesToUpload,
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  if (endpoints.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        AppLocalizations.of(context).settingsUploadNoSites,
                      ),
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
                                    title: Text(
                                      AppLocalizations.of(ctx).mapDeleteSite,
                                    ),
                                    content: Text(
                                      AppLocalizations.of(ctx)
                                          .mapDeleteSiteConfirm(endpoint.name),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, false),
                                        child: Text(
                                          AppLocalizations.of(ctx)
                                              .settingsCancel,
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, true),
                                        style: TextButton.styleFrom(
                                          foregroundColor: Colors.red,
                                        ),
                                        child: Text(
                                          AppLocalizations.of(ctx).mapDelete,
                                        ),
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
                        label: Text(AppLocalizations.of(context).mapAddSite),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          AppLocalizations.of(context).settingsCancel,
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          await _uploadService.setSelectedEndpoints(
                            selectedNames,
                          );
                          Navigator.pop(context);
                          _showSnackBar(
                            AppLocalizations.of(context).mapUploadSitesUpdated,
                          );
                        },
                        child: Text(AppLocalizations.of(context).settingsSave),
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
      _showSnackBar(AppLocalizations.of(context).mapTileCacheNotInitialized);
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
              title: Text(
                AppLocalizations.of(context).settingsDownloadOfflineTiles,
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppLocalizations.of(context).mapDownloadTilesBlurb),
                  const SizedBox(height: 16),
                  Text(AppLocalizations.of(context).mapMinZoom('$minZoom')),
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
                  Text(AppLocalizations.of(context).mapMaxZoom('$maxZoom')),
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
                    AppLocalizations.of(context)
                        .mapTilesEstimate(tileCount, estimatedMB),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (tileCount > 5000)
                    Text(
                      AppLocalizations.of(context).mapLargeDownloadWarning,
                      style: const TextStyle(
                        color: Colors.orange,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(AppLocalizations.of(context).settingsCancel),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, {
                    'minZoom': minZoom,
                    'maxZoom': maxZoom,
                  }),
                  child: Text(AppLocalizations.of(context).mapDownload),
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
                      _showSnackBar(
                        AppLocalizations.of(context)
                            .mapDownloadedTiles(succeeded, totalTiles),
                      );
                    }
                  });
            }

            final progress = totalTiles > 0 ? completed / totalTiles : 0.0;

            return AlertDialog(
              title: Text(AppLocalizations.of(context).mapDownloadingTiles),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LinearProgressIndicator(value: progress),
                  const SizedBox(height: 12),
                  Text(
                    AppLocalizations.of(context)
                        .mapTilesProgress(completed, totalTiles),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    downloadCancelled = true;
                    downloader.cancel();
                    Navigator.pop(context);
                    _showSnackBar(
                      AppLocalizations.of(context)
                          .mapDownloadCancelled(completed),
                    );
                  },
                  child: Text(AppLocalizations.of(context).settingsCancel),
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
        _showSnackBar(
          AppLocalizations.of(context).mapFailedToCaptureScreenshot,
        );
        return;
      }

      // Build stats text
      final pingSamples = _samples.where((s) => s.pingSuccess != null).toList();
      final successCount = pingSamples
          .where((s) => s.pingSuccess == true)
          .length;
      final failCount = pingSamples.where((s) => s.pingSuccess == false).length;
      final totalPings = successCount + failCount;
      final l10n = AppLocalizations.of(context);
      final successRate = totalPings > 0
          ? ((successCount / totalPings) * 100).toStringAsFixed(0)
          : l10n.mapNotAvailable;
      final coverageCount = _aggregationResult?.coverages.length ?? 0;

      final statsText = l10n.mapCoverageShareText(
        '${_samples.length}',
        '$coverageCount',
        '$successCount',
        '$failCount',
        successRate,
        '${_repeaters.length}',
      );

      // Save temp file and share
      final tempDir = await getTemporaryDirectory();
      final file = File(
        '${tempDir.path}/meshcore_coverage_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(imageBytes);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          subject: AppLocalizations.of(context).mapCoverageShareSubject,
          text: statsText,
        ),
      );
    } catch (e) {
      setState(() {
        _hideUIForScreenshot = false;
      });
      _showSnackBar(AppLocalizations.of(context).mapShareFailed('$e'));
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
      _showSnackBar(AppLocalizations.of(context).mapNoRepeatersYet);
      return;
    }

    final sortedIds = knownIds.toList()..sort();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).mapFilterByRepeater),
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
                title: Text(
                  name ??
                      AppLocalizations.of(context)
                          .mapRepeaterFallback(displayId),
                ),
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
                  _showSnackBar(
                    AppLocalizations.of(context)
                        .mapShowingCoverageFrom(displayId),
                  );
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
                _showSnackBar(
                  AppLocalizations.of(context).mapRepeaterFilterCleared,
                );
              },
              child: Text(
                AppLocalizations.of(context).mapClearFilter,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context).settingsCancel),
          ),
        ],
      ),
    );
  }

  void _findCoverageGaps() {
    if (_aggregationResult == null || _aggregationResult!.coverages.isEmpty) {
      _showSnackBar(AppLocalizations.of(context).mapNoCoverageYet);
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
      _showSnackBar(AppLocalizations.of(context).mapNoCoverageGaps);
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).mapCoverageGaps(gaps.length)),
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
                title: Text(
                  AppLocalizations.of(context).mapGapSuccessRate(rate),
                ),
                subtitle: Text(
                  AppLocalizations.of(context).mapGapSubtitle(
                    '${gap.position.latitude.toStringAsFixed(4)}, '
                    '${gap.position.longitude.toStringAsFixed(4)}',
                    gap.received.toStringAsFixed(1),
                    gap.lost.toStringAsFixed(1),
                  ),
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
            child: Text(AppLocalizations.of(context).mapClose),
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
          title: Text(AppLocalizations.of(ctx).mapDownloadFrom),
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

    _showSnackBar(AppLocalizations.of(context).mapDownloadingCoverage);

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
      _showSnackBar(
        AppLocalizations.of(context)
            .mapDownloadedCoverageCells(coverage.length),
      );
    } else {
      // Try loading from cache
      final cached = await _uploadService.loadCachedCoverage();
      if (cached != null && cached['coverage'] != null) {
        setState(() {
          _communityCoverage = cached['coverage'] as Map<String, dynamic>;
          _showCommunityCoverage = true;
        });
        _showSnackBar(AppLocalizations.of(context).mapLoadedCachedCoverage);
      } else {
        _showSnackBar(
          AppLocalizations.of(context).mapDownloadFailed(
            _uploadService.lastDownloadError ??
                AppLocalizations.of(context).mapUnknownError,
          ),
        );
      }
    }
  }

  Widget _buildCommunityCoverageLayer() {
    if (_communityCoverage == null) return const SizedBox.shrink();

    final polygons = <Polygon>[];
    final bounds = _mapController.camera.visibleBounds;
    final cells = CommunityCoverage.aggregate(
      _communityCoverage!,
      precision: _coverageLodPrecision,
    );

    for (final cell in cells.values) {
      final total = cell.received + cell.lost;
      if (total == 0) continue;
      if (!cell.intersectsViewport(
        south: bounds.south,
        north: bounds.north,
        west: bounds.west,
        east: bounds.east,
      )) {
        continue;
      }

      final successRate = cell.received / total;
      final color = successRate >= 0.7
          ? const Color(0x2200CC00)
          : successRate >= 0.3
          ? const Color(0x22CCCC00)
          : const Color(0x22CC0000);

      polygons.add(
        Polygon(
          points: cell.polygonPoints,
          color: color,
          borderColor: const Color(0x4400AAEE),
          borderStrokeWidth: 1,
        ),
      );
    }

    return PolygonLayer(polygons: polygons);
  }

  void _handleMapTap(LatLng point) {
    if (!_showCommunityCoverage || _communityCoverage == null) return;

    final cells = CommunityCoverage.aggregate(
      _communityCoverage!,
      precision: _coverageLodPrecision,
    );
    final hit = CommunityCoverage.hitTest(cells, point);
    if (hit != null) {
      _showCommunityCellInfo(hit);
    }
  }

  void _showCommunityCellInfo(CommunityCoverageCell cell) {
    final total = cell.received + cell.lost;
    final successRate = total > 0
        ? ((cell.received / total) * 100).toStringAsFixed(1)
        : '0';
    final l10n = AppLocalizations.of(context);
    final lastUpdate = cell.lastUpdate.isEmpty
        ? l10n.settingsUnknown
        : cell.lastUpdate;
    final appVersion = cell.appVersion.isEmpty
        ? l10n.settingsUnknown
        : cell.appVersion;

    String repeatersText = l10n.settingsNone;
    if (cell.repeaters.isNotEmpty) {
      repeatersText = cell.repeaters.entries
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

    final parsedLastUpdate = DateTime.tryParse(lastUpdate);
    final lastUpdateDisplay = parsedLastUpdate == null
        ? lastUpdate
        : DateFormat.yMMMd(Localizations.localeOf(context).toString())
              .add_Hm()
              .format(parsedLastUpdate.toLocal());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.settingsCommunityCoverage),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.mapCommunitySuccessRate(successRate),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text('${l10n.mapReceivedLabel}${cell.received.toStringAsFixed(1)}'),
            Text('${l10n.mapLostLabel}${cell.lost.toStringAsFixed(1)}'),
            Text(l10n.mapSamplesCount('${cell.samples}')),
            const SizedBox(height: 8),
            Text(
              l10n.mapRepeatersHeader,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(repeatersText, style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 8),
            Text(
              l10n.mapLastUpdate(lastUpdateDisplay),
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
            Text(
              l10n.mapAppVersionLabel(appVersion),
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.mapClose),
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
        title: Text(AppLocalizations.of(context).mapEditUploadSite),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context).mapSiteName,
              ),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: urlController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context).mapApiUrl,
              ),
              keyboardType: TextInputType.url,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context).settingsCancel),
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
            child: Text(AppLocalizations.of(context).settingsSave),
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
        title: Text(AppLocalizations.of(context).mapAddUploadSite),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context).mapSiteName,
                hintText: AppLocalizations.of(context).mapSiteNameHint,
              ),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: urlController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context).mapApiUrl,
                hintText: 'https://your-site.pages.dev/api/samples',
              ),
              keyboardType: TextInputType.url,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context).settingsCancel),
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
            child: Text(AppLocalizations.of(context).mapAdd),
          ),
        ],
      ),
    );
  }
}
