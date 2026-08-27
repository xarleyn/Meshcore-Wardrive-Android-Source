import 'dart:async';
import 'dart:convert';
import 'dart:io';

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
import '../utils/session_map_view.dart';
import '../utils/community_coverage.dart';
import '../utils/bluetooth_scan.dart';
import '../utils/sample_export.dart';
import '../utils/ping_burst.dart';
import '../utils/update_check.dart';
import '../widgets/compass_calibration.dart';
import '../widgets/bluetooth_device_picker_dialog.dart';
import 'map/layers/coverage_prediction_layer.dart';
import 'map/layers/coverage_layer.dart';
import 'map/layers/community_coverage_layer.dart';
import 'map/layers/current_position_layer.dart';
import 'map/layers/edge_layer.dart';
import 'map/layers/planned_marker_layer.dart';
import 'map/layers/privacy_zone_layer.dart';
import 'map/layers/radio_position_layer.dart';
import 'map/layers/repeater_layer.dart';
import 'map/layers/route_trail_layer.dart';
import 'map/layers/sample_cluster_layer.dart';
import 'map/layers/sample_heatmap_layer.dart';
import 'map/dialogs/appearance_dialogs.dart';
import 'map/dialogs/connection_dialogs.dart';
import 'map/dialogs/coverage_tools_dialogs.dart';
import 'map/dialogs/map_entity_dialogs.dart';
import 'map/dialogs/map_workflow_dialogs.dart';
import 'map/dialogs/marker_dialogs.dart';
import 'map/dialogs/offline_tile_dialogs.dart';
import 'map/dialogs/upload_endpoint_dialog.dart';
import 'map/map_runtime_bindings.dart';
import 'map/map_screen_controller.dart';
import 'map/map_settings_controller.dart';
import 'map/widgets/delete_mode_banner.dart';
import 'map/widgets/map_action_buttons.dart';
import 'map/widgets/map_control_panel.dart';
import 'map/widgets/map_quick_settings_panel.dart';
import '../services/widget_service.dart';

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
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import 'dart:typed_data';

import 'debug_log_screen.dart';
import 'debug_diagnostics_screen.dart';
import 'session_history_screen.dart';
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
import '../services/achievement_service.dart';
import '../services/radio_position_estimator.dart';
import '../services/screen_wake_service.dart';
import '../services/android_tracking_settings_service.dart';
import 'settings/settings_screen.dart';
import 'settings/settings_dialogs.dart';
import 'settings/sections/about_section.dart';
import 'settings/sections/app_device_section.dart';
import 'settings/sections/backup_section.dart';
import 'settings/sections/carpeater_section.dart';
import 'settings/sections/diagnostics_section.dart';
import 'settings/sections/data_management_section.dart';
import 'settings/sections/discovery_section.dart';
import 'settings/sections/feedback_section.dart';
import 'settings/sections/location_section.dart';
import 'settings/sections/location_quality_section.dart';
import 'settings/sections/map_display_section.dart';
import 'settings/sections/online_map_section.dart';
import 'settings/sections/statistics_section.dart';

part 'settings/settings_page.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  // App version is imported from constants/app_version.dart

  final LocationService _locationService = LocationService();
  final DatabaseService _databaseService = DatabaseService();
  final MapController _mapController = MapController();
  final UploadService _uploadService = UploadService();
  final SettingsService _settingsService = SettingsService();
  final ScreenshotController _screenshotController = ScreenshotController();
  final AndroidTrackingSettingsService _androidTrackingSettings =
      AndroidTrackingSettingsService();
  final MapRuntimeBindings _runtimeBindings = MapRuntimeBindings();
  late final MapSettingsController _mapSettingsController;
  int _initializationGeneration = 0;

  bool _isTracking = false;
  bool _isConnecting = false;
  late final MapScreenController _mapDataController;
  int get _sampleCount => _mapDataController.sampleCount;
  List<Sample> get _samples => _mapDataController.samples;

  /// Samples visible under the "successful pings only" display filter; used
  /// by every sample-derived layer such as the route trail and heatmap.
  List<Sample> get _displaySamples => _mapDataController.displaySamples(
    showSuccessfulOnly: _showSuccessfulOnly,
  );
  AggregationResult? get _aggregationResult => _mapDataController.aggregation;
  List<Repeater> get _repeaters => _mapDataController.repeaters;
  SessionMapView get _sessionMapView => _mapDataController.sessionView;
  set _sessionMapView(SessionMapView view) =>
      _mapDataController.setSessionView(view);
  String? get _activeSourceFilter => _mapDataController.sourceFilter;
  set _activeSourceFilter(String? source) =>
      _mapDataController.setSourceFilter(source);

  double _mapLodZoom = 13;
  final LayerHitNotifier<Coverage> _coverageHitNotifier = ValueNotifier(null);
  final LayerHitNotifier<SampleCluster> _sampleHitNotifier = ValueNotifier(
    null,
  );
  String _colorMode = 'quality';
  bool _showSamples = false;
  bool _showGpsSamples = true; // Show GPS-only samples (null pingSuccess)
  bool _fixedSampleMarkerSizeEnabled = false;
  double _sampleMarkerRadius = SettingsService.defaultSampleMarkerRadius;
  bool _showSuccessfulOnly = false; // Show only samples with successful pings
  bool _optimisticDisplay =
      false; // Coverage stays green on any success, ignoring losses
  bool _showCoverage = true; // Show coverage boxes
  bool _mapLodEnabled = true; // Coarsen coverage/samples at low zoom
  bool _sampleGeohashGrouping =
      false; // Merge samples per geohash cell into one tappable marker
  bool _showEdges = true;
  bool _showRepeaters = true;
  bool _autoPingEnabled = false;
  String? _ignoredRepeaterPrefix;
  String?
  _includeOnlyRepeaters; // Comma-separated list of repeater prefixes to show
  bool _filterEdgesByWhitelist = false; // Whether to apply whitelist to edges
  double _pingIntervalMeters = 805.0; // Default 0.5 miles
  int _coveragePrecision = 7; // Default precision 7 (~150m squares)

  LatLng? _currentPosition;
  InitialMapCamera? _sampleMapCamera;
  bool _mapReady = false;
  bool _hasAppliedInitialSampleCamera = false;

  // Ping visual indicator
  bool _showPingPulse = false;

  // Coarse radio-derived position. This is kept visually separate from GPS.
  PingResult? _latestPingResult;
  RadioPositionEstimate? _radioPositionEstimate;

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
  bool _hasCompassHeading = false;
  bool _followHeading = false;
  final CompassAccuracyMonitor _compassAccuracyMonitor =
      CompassAccuracyMonitor();
  CompassAccuracyStatus _compassAccuracyStatus = CompassAccuracyStatus.unknown;
  DateTime? _compassCalibrationQuietUntil;

  // Route trail
  bool _showRouteTrail = false;

  // Offline tile cache
  CacheStore? _tileCacheStore;

  // Map theme is independent from the Material interface theme.
  MapThemeMode _mapThemeMode = MapThemeMode.system;

  // Heatmap
  bool _showHeatmap = false;
  final StreamController<void> _heatmapRebuildStream =
      StreamController.broadcast();

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

  // Quick settings overlay
  bool _showQuickSettings = false;

  // Alert toggles
  bool _deadZoneAlertsEnabled = true;
  bool _newRepeaterAlertsEnabled = true;
  bool _linkLossAlertsEnabled = true;

  // Community coverage (downloaded from web map)
  Map<String, dynamic>? _communityCoverage;
  bool _showCommunityCoverage = false;

  // Carpeater mode
  bool _carpeaterEnabled = false;
  String? _carpeaterRepeaterId;
  String? _carpeaterPassword;
  int _carpeaterInterval = 30;
  CarpeaterState _carpeaterState = CarpeaterState.disabled;

  @override
  void initState() {
    super.initState();
    _mapDataController = MapScreenController(
      store: DatabaseMapDataStore(_databaseService),
    );
    _mapSettingsController = MapSettingsController(
      settingsService: _settingsService,
      runtime: DefaultMapSettingsRuntime(locationService: _locationService),
    );
    _initialize(++_initializationGeneration);
  }

  Future<void> _initialize(int generation) async {
    // Initialize tile cache store
    final cacheDir = await getApplicationDocumentsDirectory();
    if (!_isInitializationCurrent(generation)) return;
    _tileCacheStore = FileCacheStore('${cacheDir.path}/tile_cache');

    // Initialize home screen widget
    await WidgetService.initialize();
    if (!_isInitializationCurrent(generation)) return;

    // Load saved settings
    await _loadSettings();
    if (!_isInitializationCurrent(generation)) return;

    // Load planned markers and privacy zones
    await _loadMarkers();
    if (!_isInitializationCurrent(generation)) return;
    await _loadPrivacyZones();
    if (!_isInitializationCurrent(generation)) return;
    await _loadImpossibleZones();
    if (!_isInitializationCurrent(generation)) return;

    // Subscribe to battery updates
    final loraService = _locationService.loraCompanion;
    _runtimeBindings.bind(
      MapRuntimeSubscription.battery,
      loraService.batteryStream,
      (percent) {
        if (!mounted) return;
        setState(() {
          _batteryPercent = percent;
        });
      },
    );

    _runtimeBindings.bind(
      MapRuntimeSubscription.radioPosition,
      loraService.pingResults,
      (result) {
        if (!mounted) return;
        _runtimeBindings.cancelTimer(MapRuntimeTimer.radioPositionExpiry);
        setState(() {
          _latestPingResult = result.status == PingStatus.success
              ? result
              : null;
          _radioPositionEstimate = _calculateRadioPositionEstimate(_repeaters);
        });
        if (result.status == PingStatus.success) {
          _runtimeBindings.scheduleTimer(
            MapRuntimeTimer.radioPositionExpiry,
            const Duration(minutes: 2),
            () {
              if (!mounted) return;
              setState(() {
                _latestPingResult = null;
                _radioPositionEstimate = null;
              });
            },
          );
        }
      },
    );

    // Subscribe to automatic reconnection status updates
    _runtimeBindings.bind(
      MapRuntimeSubscription.reconnect,
      loraService.reconnectStateStream,
      (status) {
        if (!mounted) return;
        final name = status.deviceName;
        if (status.restored && name != null) {
          _showSnackBar(AppLocalizations.of(context).mapLoraReconnected(name));
        } else if (status.active && status.nextAttempt == 1 && name != null) {
          _showSnackBar(AppLocalizations.of(context).mapLoraReconnecting(name));
        }
        // Refresh connection badges and the home screen widget.
        _loadSamples();
      },
    );

    // Subscribe to Carpeater state changes
    _runtimeBindings.bind(
      MapRuntimeSubscription.carpeater,
      _locationService.carpeaterService.stateStream,
      (state) {
        if (!mounted) return;
        setState(() {
          _carpeaterState = state;
        });
      },
    );

    // Subscribe to position updates
    _runtimeBindings.bind(
      MapRuntimeSubscription.position,
      _locationService.currentPositionStream,
      (position) {
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
      },
    );

    _runtimeBindings.bind(
      MapRuntimeSubscription.positionSource,
      _locationService.positionSourceStream,
      (source) {
        if (!mounted) return;
        setState(() {
          _positionSource = source;
        });
      },
    );

    _runtimeBindings.bind(
      MapRuntimeSubscription.course,
      _locationService.courseStream,
      (heading) {
        if (!_hasCompassHeading) {
          _scheduleHeadingUpdate(heading, factor: 1);
        }
      },
    );

    _syncCompassSubscription();

    // Subscribe to sample saved events - reload map when new samples are saved
    _runtimeBindings.bind(
      MapRuntimeSubscription.sampleSaved,
      _locationService.sampleSavedStream,
      (_) => _loadSamples(),
    );

    // Subscribe to ping events for visual feedback
    _runtimeBindings.bind(
      MapRuntimeSubscription.pingEvent,
      _locationService.pingEventStream,
      (event) {
        if (event != 'pinging' || !mounted) return;
        setState(() {
          _showPingPulse = true;
        });
        _runtimeBindings.scheduleTimer(
          MapRuntimeTimer.pingPulse,
          const Duration(seconds: 2),
          () {
            if (!mounted) return;
            setState(() {
              _showPingPulse = false;
            });
          },
        );
      },
    );

    // Subscribe to new repeater discovery alerts
    _runtimeBindings.bind(
      MapRuntimeSubscription.newRepeater,
      _locationService.loraCompanion.newRepeaterStream,
      (repeaterId) {
        if (!mounted) return;
        SoundService().playPingSuccessGood();
        _showSnackBar(
          AppLocalizations.of(context).mapNewRepeaterDiscovered(repeaterId),
        );
      },
    );

    // Subscribe to dead zone alerts
    _runtimeBindings.bind(
      MapRuntimeSubscription.deadZone,
      _locationService.deadZoneStream,
      (cellHash) {
        if (!mounted) return;
        _showSnackBar(
          AppLocalizations.of(context).mapEnteringDeadZone(cellHash),
        );
      },
    );

    // Subscribe to battery saver mode changes
    _runtimeBindings.bind(
      MapRuntimeSubscription.batterySaver,
      _locationService.batterySaverStream,
      (active) {
        if (!mounted) return;
        setState(() {
          _batterySaverActive = active;
        });
        final l10n = AppLocalizations.of(context);
        _showSnackBar(
          active ? l10n.mapBatterySaverOn : l10n.mapBatterySaverOff,
        );
      },
    );

    // Subscribe to auto-ping pause changes caused by bad GPS fixes
    _runtimeBindings.bind(
      MapRuntimeSubscription.pingPause,
      _locationService.pingPauseStream,
      (paused) {
        if (!mounted) return;
        final l10n = AppLocalizations.of(context);
        _showSnackBar(
          paused ? l10n.mapPingPausedByBadFixes : l10n.mapPingResumedByGoodFix,
        );
      },
    );

    // Subscribe to achievement unlocks
    _runtimeBindings.bind(
      MapRuntimeSubscription.achievement,
      AchievementService().unlockStream,
      (achievement) {
        if (!mounted) return;
        final l10n = AppLocalizations.of(context);
        final copy = achievementCopy(l10n, achievement.id);
        _showSnackBar(
          l10n.achievementsUnlockedSnackbar(achievement.icon, copy.title),
        );
      },
    );

    // Check achievements on startup
    AchievementService().checkAndUnlock();

    // Load known repeater IDs from DB so only truly new ones trigger alerts
    final knownIds = await _databaseService.getDistinctRepeaterIds();
    if (!_isInitializationCurrent(generation)) return;
    await _locationService.loraCompanion.loadKnownRepeaterIds(knownIds);
    if (!_isInitializationCurrent(generation)) return;

    // Load alert toggle settings
    final newRepeaterAlerts = await _settingsService
        .getNewRepeaterAlertsEnabled();
    if (!_isInitializationCurrent(generation)) return;
    _locationService.loraCompanion.setNewRepeaterAlertsEnabled(
      newRepeaterAlerts,
    );

    // Update distance immediately instead of waiting for a periodic map refresh.
    _runtimeBindings.bind(
      MapRuntimeSubscription.distance,
      _locationService.totalDistanceStream,
      (_) {
        if (!mounted) return;
        setState(() {
          _totalDistance = _distanceUnit == 'miles'
              ? _locationService.totalDistanceMiles
              : _locationService.totalDistanceKm;
        });
      },
    );

    // Update speed immediately instead of waiting for a periodic map refresh.
    _runtimeBindings.bind(
      MapRuntimeSubscription.speed,
      _locationService.speedStream,
      (_) {
        if (!mounted) return;
        setState(() {
          _currentSpeed = _distanceUnit == 'miles'
              ? _locationService.currentSpeedMph
              : _locationService.currentSpeedKmh;
        });
      },
    );

    await _loadSamples();
    if (!_isInitializationCurrent(generation)) return;
    await _locationService.startPositionSearch();
    if (!_isInitializationCurrent(generation)) return;

    // Load cached community coverage for offline viewing
    final cached = await _uploadService.loadCachedCoverage();
    if (!_isInitializationCurrent(generation)) return;
    if (cached != null && cached['coverage'] != null) {
      setState(() {
        _communityCoverage = cached['coverage'] as Map<String, dynamic>;
      });
    }
  }

  bool _isInitializationCurrent(int generation) =>
      mounted && generation == _initializationGeneration;

  Future<void> _loadSettings() async {
    final settings = await _mapSettingsController.loadAndApply();
    if (!mounted) return;
    setState(() {
      _showSamples = settings.showSamples;
      _showGpsSamples = settings.showGpsSamples;
      _fixedSampleMarkerSizeEnabled = settings.fixedSampleMarkerSizeEnabled;
      _sampleMarkerRadius = settings.sampleMarkerRadius;
      _showCoverage = settings.showCoverage;
      _mapLodEnabled = settings.mapLodEnabled;
      _sampleGeohashGrouping = settings.sampleGeohashGrouping;
      _showEdges = settings.showEdges;
      _showRepeaters = settings.showRepeaters;
      _colorMode = settings.colorMode;
      _pingIntervalMeters = settings.pingIntervalMeters;
      _coveragePrecision = settings.coveragePrecision;
      _ignoredRepeaterPrefix = settings.ignoredRepeaterPrefix;
      _includeOnlyRepeaters = settings.includeOnlyRepeaters;
      _filterEdgesByWhitelist = settings.filterEdgesByWhitelist;
      _distanceUnit = settings.distanceUnit;
      _colorBlindMode = settings.colorBlindMode;
      _discoveryTimeoutSeconds = settings.discoveryTimeoutSeconds;
      _thoroughResponseCollection = settings.thoroughResponseCollection;
      _fuelUnit = settings.fuelUnit;
      _showRouteTrail = settings.showRouteTrail;
      _showHeatmap = settings.showHeatmap;
      _showPredictionRings = settings.showPredictionRings;
      _showRadioPosition = settings.showRadioPosition;
      _beaconDbWifiPositioning = settings.beaconDbWifiPositioning;
      _locationQualitySettings = settings.locationQualitySettings;
      _showDucting = settings.showDucting;
      _mapThemeMode = settings.mapThemeMode;
      _pingMode = settings.pingMode;
      _pingTimeInterval = settings.pingTimeInterval;
      _soundEnabled = settings.soundEnabled;
      _vibrationEnabled = settings.vibrationEnabled;
      _lockRotationNorth = settings.lockRotationNorth;
      _keepScreenOn = settings.keepScreenOn;
      _currentLocationMarkerStyle = settings.currentLocationMarkerStyle;
      _showSuccessfulOnly = settings.showSuccessfulOnly;
      _optimisticDisplay = settings.optimisticDisplay;
      _compassCalibrationQuietUntil = settings.compassCalibrationQuietUntil;
      _deadZoneAlertsEnabled = settings.deadZoneAlertsEnabled;
      _newRepeaterAlertsEnabled = settings.newRepeaterAlertsEnabled;
      _linkLossAlertsEnabled = settings.linkLossAlertsEnabled;
      _batterySaverEnabled = settings.batterySaverEnabled;
      _carpeaterEnabled = settings.carpeaterEnabled;
      _carpeaterRepeaterId = settings.carpeaterRepeaterId;
      _carpeaterPassword = settings.carpeaterPassword;
      _carpeaterInterval = settings.carpeaterInterval;
    });
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
    _runtimeBindings.cancelSubscription(MapRuntimeSubscription.compass);
    _hasCompassHeading = false;
    _compassAccuracyMonitor.reset();
    if (_compassAccuracyStatus != CompassAccuracyStatus.unknown) {
      _compassAccuracyStatus = CompassAccuracyStatus.unknown;
    }

    if (!_compassInUse) {
      return;
    }

    final compassEvents = FlutterCompass.events;
    if (compassEvents == null) return;
    _runtimeBindings.bind(
      MapRuntimeSubscription.compass,
      compassEvents,
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
      onError: (_, _) {
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
    if (_runtimeBindings.hasActiveTimer(MapRuntimeTimer.headingUpdate)) return;

    _applyPendingHeading();
    _runtimeBindings.scheduleTimer(
      MapRuntimeTimer.headingUpdate,
      const Duration(milliseconds: 80),
      _applyPendingHeading,
      replace: false,
    );
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
    final loraService = _locationService.loraCompanion;
    final discoveredRepeaters = loraService.discoveredRepeaters;
    final isConnected = loraService.isDeviceConnected;
    final connType = loraService.connectionType;
    final dataChanged = await _mapDataController.refresh(
      discoveredRepeaters: discoveredRepeaters,
      coveragePrecision: _coveragePrecision,
      optimisticDisplay: _optimisticDisplay,
    );
    if (!mounted) return;

    final newAutoPing = _locationService.isAutoPingEnabled;
    final connectionChanged =
        _loraConnected != isConnected ||
        _connectionType != connType ||
        _autoPingEnabled != newAutoPing;
    if (dataChanged || connectionChanged) {
      setState(() {
        _loraConnected = isConnected;
        _connectionType = connType;
        _autoPingEnabled = newAutoPing;
        if (dataChanged) {
          _radioPositionEstimate = _calculateRadioPositionEstimate(_repeaters);
        }
      });
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
      sampleCount: _sampleCount,
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
    _mapDataController.setSessionView(view);
    _loadSamples();
  }

  Future<bool?> _confirmSaveEmptySession() {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const SaveEmptySessionDialog(),
    );
  }

  Future<void> _handleStoppedSession(int? sessionId) async {
    if (sessionId == null || !mounted) return;

    final sessions = await _mapDataController.getSessions();
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

    await _mapDataController.deleteSession(sessionId);
    final remaining = await _mapDataController.getSessions();
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
        if (!mounted) return;
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
        if (!mounted) return;
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
      if (!mounted) return false;
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
      if (!mounted) return false;
      final l10n = AppLocalizations.of(context);
      final shouldRequest = await _showRequestDialog(
        title: l10n.mapAllowLocationAllTheTimeTitle,
        message: l10n.mapAllowLocationAllTheTimeBody,
      );
      if (!shouldRequest) return false;

      backgroundStatus = await Permission.locationAlways.request();
      if (!backgroundStatus.isGranted) {
        if (!mounted) return false;
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
      if (!mounted) return false;
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
          builder: (context) =>
              ContinueRequestDialog(title: title, message: message),
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
      builder: (context) => OpenSettingsDialog(
        title: title,
        message: message,
        actionLabel: actionLabel,
      ),
    );
    if (shouldOpen != true) return false;
    return onOpen();
  }

  Future<void> _clearData() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => ClearMapHistoryDialog(sampleCount: _sampleCount),
    );

    if (confirmed == true) {
      await _locationService.clearAllSamples();
      await _loadSamples();
      _showSnackBar(l10n.mapDeletedSamples(_sampleCount));
    }
  }

  Future<void> _exportData() async {
    // Ask user for export format
    final format = await showDialog<SampleExportFormat>(
      context: context,
      builder: (context) => const SampleExportFormatDialog(),
    );

    if (format == null) return;

    // Ask save or share
    if (!mounted) return;
    final choice = await showDialog<ExportDestination>(
      context: context,
      builder: (context) => ExportDestinationDialog(
        title: AppLocalizations.of(context).mapExportAs(format.displayName),
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
        case SampleExportFormat.csv:
          content = SampleExport.buildCsv(samples);
          extension = 'csv';
          fileName = 'meshcore_export_$timestamp.csv';
          break;
        case SampleExportFormat.gpx:
          content = SampleExport.buildGpx(samples);
          extension = 'gpx';
          fileName = 'meshcore_export_$timestamp.gpx';
          break;
        case SampleExportFormat.kml:
          content = SampleExport.buildKml(samples);
          extension = 'kml';
          fileName = 'meshcore_export_$timestamp.kml';
          break;
        case SampleExportFormat.json:
          // Include discovered repeater contacts in the export
          final repeaterJsonList = _repeaters
              .where(
                (r) =>
                    r.position.latitude != 0.0 || r.position.longitude != 0.0,
              )
              .map((r) => r.toJson())
              .toList();
          final data = await _databaseService.exportAllData(
            repeaters: repeaterJsonList,
          );
          content = jsonEncode(data);
          extension = 'json';
          fileName = 'meshcore_export_$timestamp.json';
      }

      if (choice == ExportDestination.save) {
        if (!mounted) return;
        await FilePicker.platform.saveFile(
          dialogTitle: AppLocalizations.of(context).mapSaveExport,
          fileName: fileName,
          type: FileType.custom,
          allowedExtensions: [extension],
          bytes: utf8.encode(content),
        );
        if (!mounted) return;
        _showSnackBar(
          AppLocalizations.of(context)
              .mapExportedSamples(samples.length, format.displayName),
        );
      } else if (choice == ExportDestination.share) {
        final directory = await getExternalStorageDirectory();
        final file = File('${directory!.path}/$fileName');
        await file.writeAsString(content);

        if (!mounted) return;
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(file.path)],
            subject: AppLocalizations.of(context).mapExportShareSubject,
            text: AppLocalizations.of(context)
                .mapExportShareText(samples.length),
          ),
        );
        if (!mounted) return;
        _showSnackBar(AppLocalizations.of(context).mapExportShared);
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(AppLocalizations.of(context).mapExportFailed('$e'));
    }
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
        final counts = await _databaseService.importAllData(jsonData);
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
      _mapDataController.invalidate();
      await _loadSamples();

      if (!mounted) return;
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
      if (!mounted) return;
      _showSnackBar(AppLocalizations.of(context).mapImportFailed('$e'));
    }
  }

  Future<void> _exportSettings() async {
    try {
      final jsonString = await _settingsService.exportSettingsJson();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = 'meshcore_settings_$timestamp.json';

      // Ask save or share
      if (!mounted) return;
      final choice = await showDialog<ExportDestination>(
        context: context,
        builder: (context) => ExportDestinationDialog(
          title: AppLocalizations.of(context).settingsExportSettings,
        ),
      );

      if (choice == null) return;

      if (choice == ExportDestination.save) {
        if (!mounted) return;
        await FilePicker.platform.saveFile(
          dialogTitle: AppLocalizations.of(context).mapSaveSettings,
          fileName: fileName,
          type: FileType.custom,
          allowedExtensions: ['json'],
          bytes: utf8.encode(jsonString),
        );
        if (!mounted) return;
        _showSnackBar(AppLocalizations.of(context).mapSettingsExported);
      } else if (choice == ExportDestination.share) {
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/$fileName');
        await file.writeAsString(jsonString);
        if (!mounted) return;
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(file.path)],
            text: AppLocalizations.of(context).mapSettingsShareText,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
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
        builder: (context) => const ImportSettingsConfirmationDialog(),
      );

      if (confirmed != true) return;

      final applied = await _settingsService.importSettingsJson(jsonString);

      // Reload settings to apply changes
      await _loadSettings();
      _mapDataController.invalidate();
      await _loadSamples();

      if (!mounted) return;
      _showSnackBar(
        AppLocalizations.of(context).mapImportedSettingsCount(applied),
      );
    } on FormatException catch (e) {
      if (!mounted) return;
      _showSnackBar(
        AppLocalizations.of(context).mapInvalidSettingsFile(e.message),
      );
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(AppLocalizations.of(context).mapImportFailed('$e'));
    }
  }

  // ============================================================================
  // PLANNED MARKERS
  // ============================================================================

  Future<void> _loadMarkers() async {
    final markers = await _databaseService.getAllMarkers();
    if (!mounted) return;
    setState(() {
      _plannedMarkers = markers;
    });
  }

  Future<void> _handleMapLongPress(LatLng point) async {
    final action = await showModalBottomSheet<MapLongPressAction>(
      context: context,
      showDragHandle: true,
      builder: (context) => const MapLongPressActionSheet(),
    );
    if (!mounted || action == null) return;

    switch (action) {
      case MapLongPressAction.plannedRepeater:
        await _addPlannedMarker(point);
        break;
      case MapLongPressAction.privacyZone:
        await _addPrivacyZone(point);
        break;
      case MapLongPressAction.impossibleZone:
        await _addImpossibleZone(point);
        break;
    }
  }

  Future<void> _addPlannedMarker(LatLng point) async {
    final label = await showDialog<String>(
      context: context,
      builder: (context) => AddPlannedMarkerDialog(position: point),
    );

    if (label != null) {
      await _databaseService.addMarker(
        point.latitude,
        point.longitude,
        label.isEmpty ? null : label,
      );
      await _loadMarkers();
      if (!mounted) return;
      _showSnackBar(AppLocalizations.of(context).mapPlannedRepeaterMarkerAdded);
    }
  }

  void _showMarkerInfo(Map<String, dynamic> marker) async {
    final lat = marker['lat'] as double;
    final lon = marker['lon'] as double;
    final label = marker['label'] as String?;
    final id = marker['id'] as int;
    final createdAt = DateTime.fromMillisecondsSinceEpoch(
      marker['created_at'] as int,
    );

    final action = await showDialog<PlannedMarkerAction>(
      context: context,
      builder: (context) => PlannedMarkerInfoDialog(
        latitude: lat,
        longitude: lon,
        label: label,
        createdAt: createdAt,
      ),
    );

    if (action != PlannedMarkerAction.delete) return;
    await _databaseService.deleteMarker(id);
    await _loadMarkers();
    if (!mounted) return;
    _showSnackBar(AppLocalizations.of(context).mapMarkerDeleted);
  }

  // ============================================================================
  // PRIVACY ZONES
  // ============================================================================

  Future<void> _loadPrivacyZones() async {
    final zones = await _databaseService.getAllPrivacyZones();
    if (!mounted) return;
    setState(() {
      _privacyZones = zones;
    });
  }

  Future<void> _loadImpossibleZones() async {
    final zones = await _databaseService.getAllImpossibleZones();
    if (!mounted) return;
    setState(() {
      _impossibleZones = zones;
    });
  }

  Future<void> _addPrivacyZone(LatLng center) async {
    final l10n = AppLocalizations.of(context);
    final draft = await showDialog<PrivacyZoneDraft>(
      context: context,
      builder: (context) => AddPrivacyZoneDialog(center: center),
    );

    if (draft != null) {
      await _databaseService.addPrivacyZone(
        center.latitude,
        center.longitude,
        draft.radiusMeters,
        draft.label,
      );
      await _loadPrivacyZones();
      if (!mounted) return;
      _showSnackBar(l10n.mapPrivacyZoneAdded);
    }
  }

  Future<void> _addImpossibleZone(LatLng center) async {
    final l10n = AppLocalizations.of(context);
    final draft = await showDialog<ImpossibleZoneDraft>(
      context: context,
      builder: (context) => AddImpossibleZoneDialog(center: center),
    );

    if (draft == null) return;
    await _databaseService.addImpossibleZone(
      draft.center.latitude,
      draft.center.longitude,
      draft.radiusMeters,
      draft.label,
    );
    await _loadImpossibleZones();
    if (!mounted) return;
    _showSnackBar(l10n.settingsImpossibleZoneAdded);
  }

  // ============================================================================
  // DELETE MODE
  // ============================================================================

  void _deleteSample(Sample sample) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => DeleteSampleConfirmationDialog(sample: sample),
    );

    if (confirmed == true) {
      await _mapDataController.deleteSample(sample.id);
      await _loadSamples();
      if (!mounted) return;
      _showSnackBar(AppLocalizations.of(context).mapSampleDeleted);
    }
  }

  void _deleteCoverageCell(Coverage coverage) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) =>
          DeleteCoverageConfirmationDialog(coverage: coverage),
    );

    if (confirmed == true) {
      final deleted = await _mapDataController.deleteCoverage(coverage.id);
      await _loadSamples();
      if (!mounted) return;
      _showSnackBar(
        AppLocalizations.of(context).mapDeletedSamplesFromCell(deleted),
      );
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  void _updateMapState(VoidCallback callback) {
    if (!mounted) return;
    setState(callback);
  }

  int get _coverageLodPrecision {
    return _mapDataController.coverageLodPrecision(
      zoom: _mapLodZoom,
      enabled: _mapLodEnabled,
      maxPrecision: _coveragePrecision,
    );
  }

  int get _sampleLodPrecision {
    return _mapDataController.sampleLodPrecision(
      zoom: _mapLodZoom,
      enabled: _mapLodEnabled,
    );
  }

  void _updateMapLodZoom(double zoom) {
    if (!_mapLodEnabled) {
      _mapLodZoom = zoom;
      return;
    }

    final oldCoveragePrecision = _coverageLodPrecision;
    final oldSamplePrecision = _sampleLodPrecision;
    final newCoveragePrecision = _mapDataController.coverageLodPrecision(
      zoom: zoom,
      enabled: true,
      maxPrecision: _coveragePrecision,
    );
    final newSamplePrecision = _mapDataController.sampleLodPrecision(
      zoom: zoom,
      enabled: true,
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

  List<SampleCluster> _sampleClustersForCurrentLod() {
    return _mapDataController.sampleClusters(
      zoom: _mapLodZoom,
      lodEnabled: _mapLodEnabled,
      groupByGeohash: _sampleGeohashGrouping,
      showGpsSamples: _showGpsSamples,
      showSuccessfulOnly: _showSuccessfulOnly,
      includeOnlyRepeaters: _includeOnlyRepeaters,
    );
  }

  Future<void> _checkForUpdates() async {
    try {
      final response = await http
          .get(Uri.parse(updateCheckApiUrl))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final releases = jsonDecode(response.body) as List<dynamic>;
        final latestVersion = releases.isEmpty
            ? null
            : versionFromReleaseTag(releases.first['tag_name'].toString());

        if (!mounted) return;
        if (latestVersion == null) {
          _showSnackBar(AppLocalizations.of(context).mapCouldNotCheckUpdates);
        } else if (latestVersion == appVersion) {
          _showSnackBar(AppLocalizations.of(context).mapOnLatestVersion);
        } else {
          final shouldDownload = await showDialog<bool>(
            context: context,
            builder: (context) => UpdateAvailableDialog(
              latestVersion: latestVersion,
              currentVersion: appVersion,
            ),
          );
          if (shouldDownload == true) await _openGitHub();
        }
      } else {
        if (!mounted) return;
        _showSnackBar(AppLocalizations.of(context).mapCouldNotCheckUpdates);
      }
    } on SocketException {
      if (!mounted) return;
      _showSnackBar(AppLocalizations.of(context).mapNoInternetTryAgain);
    } on TimeoutException {
      if (!mounted) return;
      _showSnackBar(AppLocalizations.of(context).mapUpdateCheckTimedOut);
    } catch (_) {
      if (!mounted) return;
      _showSnackBar(AppLocalizations.of(context).mapCouldNotCheckUpdates);
    }
  }

  Future<void> _openGitHub() async {
    final url = Uri.parse(updateCheckReleasesUrl);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
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
        if (!mounted) return;
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
        if (!mounted) return;
        _showSnackBar(AppLocalizations.of(context).mapScreenshotSavedToGallery);

        // Ask if user wants to share
        if (!mounted) return;
        final shouldShare = await showDialog<bool>(
          context: context,
          builder: (context) => const ShareScreenshotDialog(),
        );
        if (shouldShare != true || !mounted) return;
        final shareText = AppLocalizations.of(context).mapScreenshotShareText;
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/meshcore_screenshot.png');
        await file.writeAsBytes(imageBytes);
        if (!mounted) return;
        await SharePlus.instance.share(
          ShareParams(files: [XFile(file.path)], text: shareText),
        );
      } else {
        if (!mounted) return;
        _showSnackBar(AppLocalizations.of(context).mapFailedToSaveScreenshot);
      }
    } catch (e) {
      // Restore UI on error
      setState(() {
        _hideUIForScreenshot = false;
      });
      if (!mounted) return;
      _showSnackBar(
        AppLocalizations.of(context).mapErrorCapturingScreenshot('$e'),
      );
    }
  }

  @override
  void dispose() {
    _initializationGeneration++;
    _runtimeBindings.dispose();
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
            if (!_hideUIForScreenshot)
              MapControlPanel(
                loraConnected: _loraConnected,
                isConnecting: _isConnecting,
                connectionType: _connectionType,
                batteryPercent: _batteryPercent,
                sampleCount: _sampleCount,
                isTracking: _isTracking,
                totalDistance: _totalDistance,
                currentSpeed: _currentSpeed,
                distanceUnit: _distanceUnit,
                carpeaterEnabled: _carpeaterEnabled,
                carpeaterState: _carpeaterState,
                ductingLabel:
                    _showDucting && _currentDuctingRisk != DuctingRisk.unknown
                    ? _localizedDuctingRisk(l10n, _currentDuctingRisk)
                    : null,
                ductingColor:
                    _showDucting && _currentDuctingRisk != DuctingRisk.unknown
                    ? _getDuctingColor(_currentDuctingRisk)
                    : null,
                batterySaverActive: _batterySaverActive,
                onConnect: _showConnectionDialog,
                onDisconnect: _disconnectLoRa,
                onManualPing: _manualPing,
                onCarpeaterRetry: () async {
                  _showSnackBar(l10n.mapRetryingCarpeater);
                  final ok = await _locationService.startCarpeater();
                  if (!mounted) return;
                  _showSnackBar(
                    ok
                        ? l10n.mapCarpeaterReconnected
                        : l10n.mapCarpeaterRetryFailed,
                  );
                },
              ),
            if (_showQuickSettings)
              MapQuickSettingsPanel(
                pingIntervalMeters: _pingIntervalMeters,
                discoveryTimeoutSeconds: _discoveryTimeoutSeconds,
                pingMode: _pingMode,
                onClose: () => setState(() => _showQuickSettings = false),
                onPingIntervalChanged: (value) async {
                  setState(() => _pingIntervalMeters = value);
                  _locationService.setPingInterval(value);
                  await _settingsService.setPingInterval(value);
                },
                onDiscoveryTimeoutChanged: (value) async {
                  setState(() => _discoveryTimeoutSeconds = value);
                  await _settingsService.setDiscoveryTimeout(value);
                },
                onPingModeChanged: (value) async {
                  setState(() => _pingMode = value);
                  await _settingsService.setPingMode(value);
                  _locationService.setPingMode(value);
                },
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
              DeleteModeBanner(
                onExit: () => setState(() => _deleteMode = false),
              ),
          ],
        ),
      ),
      floatingActionButton: _hideUIForScreenshot
          ? null
          : MapActionButtons(
              isTracking: _isTracking,
              compassInUse: _compassInUse,
              lockRotationNorth: _lockRotationNorth,
              followHeading: _followHeading,
              compassAccuracyStatus: _compassAccuracyStatus,
              followLocation: _followLocation,
              onCompassPressed: _handleCompassButton,
              onCompassLongPressed: () =>
                  _openCompassCalibration(snoozeOnDismiss: false),
              onLocationPressed: _toggleFollowLocation,
              onToggleTracking: _toggleTracking,
              onStartFreshSession: () => _toggleTracking(freshSession: true),
              onToggleQuickSettings: () =>
                  setState(() => _showQuickSettings = !_showQuickSettings),
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
        if (_showRouteTrail)
          RouteTrailLayer(
            samples: _displaySamples,
            colorBlindMode: _colorBlindMode,
          ),
        if (_showHeatmap)
          SampleHeatmapLayer(
            samples: _displaySamples,
            reset: _heatmapRebuildStream.stream,
          ),
        if (_showPredictionRings)
          CoveragePredictionLayer(
            samples: _displaySamples,
            repeaters: _repeaters,
            includeOnlyRepeaters: _includeOnlyRepeaters,
          ),
        PrivacyZoneLayer(zones: _privacyZones),
        if (_showCommunityCoverage && _communityCoverage != null)
          CommunityCoverageLayer(
            rawCoverage: _communityCoverage!,
            precision: _coverageLodPrecision,
            visibleBounds: _mapController.camera.visibleBounds,
          ),
        if (_showCoverage) ..._buildCoverageLayers(),
        if (_showSamples) _buildSampleLayer(),
        if (_showEdges) _buildEdgeLayer(),
        if (_showRepeaters)
          RepeaterLayer(
            repeaters: _repeaters,
            colorBlindMode: _colorBlindMode,
            onRepeaterTap: _showRepeaterInfo,
          ),
        if (_showRadioPosition && _radioPositionEstimate != null)
          RadioPositionLayer(
            estimate: _radioPositionEstimate!,
            onTap: _showSnackBar,
          ),
        PlannedMarkerLayer(
          markers: _plannedMarkers,
          onMarkerTap: _showMarkerInfo,
        ),
        if (_currentPosition != null && !_hideUIForScreenshot)
          CurrentPositionLayer(
            position: _currentPosition!,
            style: _currentLocationMarkerStyle,
            source: _positionSource,
            heading: _currentHeading,
            showPingPulse: _showPingPulse,
          ),
      ],
    );
  }

  List<Widget> _buildCoverageLayers() {
    if (_aggregationResult == null) return [];
    final lod = _mapDataController.coverageLod(
      zoom: _mapLodZoom,
      enabled: _mapLodEnabled,
      maxPrecision: _coveragePrecision,
      successfulOnly: _showSuccessfulOnly,
    );
    return [
      CoverageLayer(
        coverages: lod.coverages,
        colorMode: _colorMode,
        colorBlindMode: _colorBlindMode,
        hitNotifier: _coverageHitNotifier,
        onCoverageTap: (coverage) {
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
      ),
    ];
  }

  Widget _buildSampleLayer() {
    if (_samples.isEmpty) return const SizedBox.shrink();
    final clusters = _sampleClustersForCurrentLod();
    return SampleClusterLayer(
      clusters: clusters,
      colorBlindMode: _colorBlindMode,
      fixedRadius: _fixedSampleMarkerSizeEnabled ? _sampleMarkerRadius : null,
      hitNotifier: _sampleHitNotifier,
      onClusterTap: (cluster) {
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
    );
  }

  Widget _buildEdgeLayer() {
    if (_aggregationResult == null) return const SizedBox.shrink();
    final lod = _mapDataController.coverageLod(
      zoom: _mapLodZoom,
      enabled: _mapLodEnabled,
      maxPrecision: _coveragePrecision,
      successfulOnly: _showSuccessfulOnly,
    );
    return EdgeLayer(
      edges: lod.edges,
      filterByWhitelist: _filterEdgesByWhitelist,
      includeOnlyRepeaters: _includeOnlyRepeaters,
    );
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
        await _databaseService.insertSample(sample);
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
      await _databaseService.insertSample(sample);
    }

    // Reload samples to update map
    await _loadSamples();

    // Show result
    if (pingSuccess) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      final summary = responses.length == 1
          ? l10n.mapPingHeardBy(_shortNodeId(responses.single.nodeId))
          : l10n.mapDiscoveryComplete(responses.length);
      _showSnackBar(summary);
    } else if (result.status == PingStatus.timeout) {
      if (!mounted) return;
      _showSnackBar(AppLocalizations.of(context).mapNoResponseDeadZone);
    } else {
      if (!mounted) return;
      _showSnackBar(
        AppLocalizations.of(context).mapPingFailed('${result.error}'),
      );
    }
  }

  String _shortNodeId(String nodeId) {
    return (nodeId.length > 8 ? nodeId.substring(0, 8) : nodeId).toUpperCase();
  }

  void _showConnectionDialog() async {
    final method = await showDialog<ConnectionMethod>(
      context: context,
      builder: (context) => const ConnectionMethodDialog(),
    );
    switch (method) {
      case ConnectionMethod.usb:
        await _connectUsb();
      case ConnectionMethod.bluetooth:
        await _connectBluetooth();
      case null:
        return;
    }
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
        builder: (context) => UsbDeviceDialog(devices: devices),
      );

      if (selected != null) {
        final connected = await _locationService.loraCompanion.connectUsb(
          selected,
        );
        if (connected) {
          if (!mounted) return;
          _showSnackBar(AppLocalizations.of(context).mapConnectedViaUsb);
          await _loadSamples();
        } else {
          if (!mounted) return;
          _showSnackBar(AppLocalizations.of(context).mapFailedConnectUsb);
        }
      }
    } catch (e) {
      if (!mounted) return;
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
        for (final row in await _databaseService.getAllDevices())
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

      if (!mounted) return;
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
        if (!mounted) return;
        _showSnackBar(AppLocalizations.of(context).mapConnectedViaBluetooth);
        await _loadSamples();
      } else {
        if (!mounted) return;
        _showSnackBar(AppLocalizations.of(context).mapFailedConnectBluetooth);
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(AppLocalizations.of(context).bluetoothError('$e'));
    } finally {
      if (mounted) setState(() => _isConnecting = false);
    }
  }

  Future<void> _disconnectLoRa() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => const DisconnectDeviceDialog(),
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
      if (!mounted) return;
      _showSnackBar(AppLocalizations.of(context).mapLoraDisconnected);
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

    if (!mounted) return;
    _showSnackBar(AppLocalizations.of(context).mapContactListUpdated);
  }

  Future<void> _scanForRepeaters() async {
    if (!_loraConnected) {
      _showSnackBar(AppLocalizations.of(context).mapConnectLoraFirst);
      return;
    }

    _showSnackBar(AppLocalizations.of(context).mapScanningForRepeaters);

    final repeaters = await _locationService.loraCompanion.scanForRepeaters();

    setState(() => _mapDataController.replaceRepeaters(repeaters));

    if (repeaters.isEmpty) {
      if (!mounted) return;
      _showSnackBar(AppLocalizations.of(context).mapNoRepeatersFound);
    } else {
      if (!mounted) return;
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
      builder: (context) => const InterfaceThemeDialog(),
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
      builder: (context) => const AppLocaleDialog(),
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
      builder: (context) => const MapThemeDialog(),
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
    final repeaterName = sample.path != null
        ? _getRepeaterName(sample.path)
        : null;
    final idOrName = repeaterName ?? sample.path ?? l10n.settingsUnknown;
    final repeaterDisplay =
        repeaterName ??
        (idOrName.length > 8
            ? idOrName.substring(0, 8).toUpperCase()
            : idOrName.toUpperCase());
    final ductingRisk = sample.ductingRisk;

    showDialog(
      context: context,
      builder: (context) => SampleInfoDialog(
        sample: sample,
        responses: PingBurst.responsesFor(sample, _samples),
        repeaterDisplay: repeaterDisplay,
        resolveRepeaterName: _getRepeaterName,
        ductingLabel: ductingRisk == null
            ? null
            : _localizedDuctingRisk(l10n, ductingRisk),
        ductingColor: ductingRisk == null
            ? null
            : _getDuctingColor(ductingRisk),
      ),
    );
  }

  void _showSampleClusterInfo(SampleCluster cluster) {
    showDialog<void>(
      context: context,
      builder: (context) => SampleClusterInfoDialog(
        cluster: cluster,
        resolveRepeaterName: _getRepeaterName,
      ),
    );
  }

  Future<void> _showRepeaterInfo(Repeater repeater) async {
    final action = await showDialog<RepeaterInfoAction>(
      context: context,
      builder: (context) => RepeaterInfoDialog(repeater: repeater),
    );
    if (!mounted) return;

    if (action == RepeaterInfoAction.showOnMap) {
      _mapController.move(repeater.position, 15.0);
      return;
    }
    if (action != RepeaterInfoAction.filter || !mounted) return;

    final shortId =
        (repeater.id.length > 8 ? repeater.id.substring(0, 8) : repeater.id)
            .toUpperCase();
    final message = AppLocalizations.of(context).mapFilteringBy(shortId);
    setState(() => _includeOnlyRepeaters = repeater.id);
    await _settingsService.setIncludeOnlyRepeaters(repeater.id);
    await _loadSamples();
    if (mounted) _showSnackBar(message);
  }

  void _showCoverageInfo(Coverage coverage) {
    showDialog(
      context: context,
      builder: (context) => CoverageInfoDialog(
        coverage: coverage,
        cellSamples: _coverageCellSamples(coverage.id),
        resolveRepeaterName: _getRepeaterName,
      ),
    );
  }

  /// Samples belonging to the coverage cell with [coverageId].
  ///
  /// Cell ids may be LOD-coarsened, so membership is decided by geohash
  /// prefix: a sample's full-precision key always starts with every coarser
  /// cell key that contains it.
  List<Sample> _coverageCellSamples(String coverageId) {
    final precision = coverageId.length;
    final matches = _samples.where((sample) {
      final hash = sample.geohash;
      if (hash.length >= precision) {
        return hash.substring(0, precision) == coverageId;
      }
      return GeohashUtils.coverageKey(
            sample.position.latitude,
            sample.position.longitude,
            precision: precision,
          ) ==
          coverageId;
    }).toList();
    matches.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return matches;
  }

  Future<void> _showRepeatersDialog() async {
    final result = await showDialog<RepeaterListResult>(
      context: context,
      builder: (context) => RepeaterListDialog(repeaters: _repeaters),
    );
    if (result == null || !mounted) return;
    if (result.action == RepeaterListAction.showOnMap) {
      _mapController.move(result.repeater.position, 15.0);
    } else {
      await _showRepeaterInfo(result.repeater);
    }
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

    // Build repeater names map from discovered repeaters and LoRa service
    final repeaterNames = <String, String>{};
    for (final repeater in _repeaters) {
      if (repeater.name != null) {
        repeaterNames[repeater.id] = repeater.name!;
      }
    }

    final loraService = _locationService.loraCompanion;
    for (final contact in loraService.discoveredRepeaters) {
      if (contact.name != null && !repeaterNames.containsKey(contact.id)) {
        repeaterNames[contact.id] = contact.name!;
      }
    }

    final outcome = await showDialog<UploadProgressOutcome>(
      context: context,
      barrierDismissible: false,
      builder: (context) => UploadProgressDialog(
        upload: (onProgress) async {
          if (selectedSites.isNotEmpty && endpoints.isNotEmpty) {
            return _uploadService.uploadToSelectedEndpoints(
              endpointNames: selectedSites,
              repeaterNames: repeaterNames,
              onProgress: onProgress,
            );
          }

          final result = await _uploadService.uploadAllSamples(
            repeaterNames: repeaterNames,
            onProgress: (current, total) => onProgress('', current, total),
          );
          return {UploadService.defaultEndpointName: result};
        },
      ),
    );

    if (outcome == null || !mounted) return;
    if (outcome.error != null) {
      _showSnackBar(
        AppLocalizations.of(context).mapUploadError('${outcome.error}'),
      );
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (context) => UploadResultsDialog(results: outcome.results!),
    );
  }

  Future<void> _manageUploadSites() async {
    final endpoints = await _uploadService.getUploadEndpoints();
    final selectedNames = await _uploadService.getSelectedEndpoints();

    if (!mounted) return;
    final configuration = await showModalBottomSheet<UploadSitesConfiguration>(
      context: context,
      isScrollControlled: true,
      builder: (context) => ManageUploadSitesSheet(
        initialEndpoints: endpoints,
        initiallySelectedNames: selectedNames,
      ),
    );

    if (configuration == null) return;
    await _uploadService.setUploadEndpoints(configuration.endpoints);
    await _uploadService.setSelectedEndpoints(configuration.selectedNames);
    if (!mounted) return;
    _showSnackBar(AppLocalizations.of(context).mapUploadSitesUpdated);
  }

  Future<void> _showOfflineTileDownload() async {
    if (_tileCacheStore == null) {
      _showSnackBar(AppLocalizations.of(context).mapTileCacheNotInitialized);
      return;
    }

    final bounds = _mapController.camera.visibleBounds;
    final currentZoom = _mapController.camera.zoom.floor();
    final isDarkMode = _usesDarkMapTiles(context);

    final options = await showDialog<OfflineTileDownloadOptions>(
      context: context,
      builder: (context) =>
          OfflineTileDownloadDialog(bounds: bounds, initialZoom: currentZoom),
    );

    if (options == null || !mounted) return;

    final urlTemplate = isDarkMode
        ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png'
        : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

    final cacheDir =
        '${(await getApplicationDocumentsDirectory()).path}/tile_cache';
    final downloader = TileDownloadService(cacheDir);
    final totalTiles = TileDownloadService.estimateTileCount(
      bounds.southWest,
      bounds.northEast,
      options.minZoom,
      options.maxZoom,
    );

    if (!mounted) return;
    final outcome = await showDialog<OfflineTileDownloadOutcome>(
      context: context,
      barrierDismissible: false,
      builder: (context) => OfflineTileDownloadProgressDialog(
        totalTiles: totalTiles,
        download: (onProgress) => downloader.downloadTiles(
          sw: bounds.southWest,
          ne: bounds.northEast,
          minZoom: options.minZoom,
          maxZoom: options.maxZoom,
          urlTemplate: urlTemplate,
          onProgress: onProgress,
        ),
        onCancel: downloader.cancel,
      ),
    );

    if (outcome == null || !mounted) return;
    final l10n = AppLocalizations.of(context);
    if (outcome.cancelled) {
      _showSnackBar(l10n.mapDownloadCancelled(outcome.completed));
    } else {
      _showSnackBar(l10n.mapDownloadedTiles(outcome.succeeded, totalTiles));
    }
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
        if (!mounted) return;
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
      if (!mounted) return;
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

      if (!mounted) return;
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
      if (!mounted) return;
      _showSnackBar(AppLocalizations.of(context).mapShareFailed('$e'));
    }
  }

  void _showRepeaterFilterPicker() async {
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

    final result = await showDialog<RepeaterFilterResult>(
      context: context,
      builder: (context) => RepeaterFilterDialog(
        repeaterIds: sortedIds,
        repeaters: _repeaters,
        selectedId: _includeOnlyRepeaters,
      ),
    );

    if (result == null || !mounted) return;
    final selectedId = result.action == RepeaterFilterAction.clear
        ? null
        : result.repeaterId;
    setState(() => _includeOnlyRepeaters = selectedId);
    await _settingsService.setIncludeOnlyRepeaters(selectedId);
    _loadSamples();
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    final message = selectedId == null
        ? l10n.mapRepeaterFilterCleared
        : l10n.mapShowingCoverageFrom(
            (selectedId.length > 8 ? selectedId.substring(0, 8) : selectedId)
                .toUpperCase(),
          );
    _showSnackBar(message);
  }

  void _findCoverageGaps() async {
    if (_aggregationResult == null || _aggregationResult!.coverages.isEmpty) {
      _showSnackBar(AppLocalizations.of(context).mapNoCoverageYet);
      return;
    }

    final gaps = coverageGaps(_aggregationResult!.coverages);

    if (gaps.isEmpty) {
      _showSnackBar(AppLocalizations.of(context).mapNoCoverageGaps);
      return;
    }

    final selected = await showDialog<Coverage>(
      context: context,
      builder: (context) => CoverageGapsDialog(gaps: gaps),
    );
    if (selected != null) _mapController.move(selected.position, 15.0);
  }

  Future<void> _downloadCommunityCoverage() async {
    // Get endpoint to download from
    final endpoints = await _uploadService.getUploadEndpoints();

    UploadEndpoint? selectedEndpoint;
    if (endpoints.length == 1) {
      selectedEndpoint = endpoints.first;
    } else {
      // Let user pick which endpoint to download from
      if (!mounted) return;
      selectedEndpoint = await showDialog<UploadEndpoint>(
        context: context,
        builder: (context) =>
            CommunityCoverageEndpointDialog(endpoints: endpoints),
      );
    }

    if (selectedEndpoint == null) return;

    if (!mounted) return;
    _showSnackBar(AppLocalizations.of(context).mapDownloadingCoverage);

    final data = await _uploadService.downloadCoverage(
      selectedEndpoint.url,
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
      if (!mounted) return;
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
        if (!mounted) return;
        _showSnackBar(AppLocalizations.of(context).mapLoadedCachedCoverage);
      } else {
        if (!mounted) return;
        _showSnackBar(
          AppLocalizations.of(context).mapDownloadFailed(
            _uploadService.lastDownloadError ??
                AppLocalizations.of(context).mapUnknownError,
          ),
        );
      }
    }
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
    showDialog(
      context: context,
      builder: (context) => CommunityCellInfoDialog(cell: cell),
    );
  }
}
