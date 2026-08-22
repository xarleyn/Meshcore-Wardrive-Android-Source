import 'dart:async';
import 'dart:io' show Platform;
import 'dart:math';
import 'package:battery_plus/battery_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:permission_handler/permission_handler.dart' hide ServiceStatus;
import '../models/models.dart';
import '../models/location_quality_settings.dart';
import 'database_service.dart';
import 'lora_companion_service.dart';
import 'location_quality_filter.dart';
import 'bad_fix_monitor.dart';
import '../utils/geohash_utils.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import '../l10n/app_locale.dart';
import '../l10n/generated/app_localizations.dart';
import 'persistent_debug_logger.dart';
import 'screen_wake_service.dart';
import 'settings_service.dart';
import 'widget_service.dart';
import 'wifi_location_service.dart';
import 'ducting_service.dart';
import 'carpeater_service.dart';
import 'sound_service.dart';

enum LocationPositionSource { fused, wifi }

class LocationService {
  final DatabaseService _dbService = DatabaseService();
  final LoRaCompanionService _loraCompanion = LoRaCompanionService();
  final PersistentDebugLogger _logger = PersistentDebugLogger();
  final SettingsService _settings = SettingsService();
  final DuctingService _ductingService = DuctingService();
  final SoundService _soundService = SoundService();
  final LocationQualityFilter _qualityFilter = LocationQualityFilter();
  final LocationQualityFilter _wifiQualityFilter = LocationQualityFilter();
  final BadFixMonitor _badFixMonitor = BadFixMonitor();
  final WifiLocationService _wifiLocationService = WifiLocationService();
  String? _lastStartError;

  LocationService() {
    _carpeaterService = CarpeaterService(_loraCompanion, _settings);
    // Suspend radio-driven sampling while the device connection is lost...
    _disconnectSubscription = _loraCompanion.disconnectStream.listen((_) {
      // A disconnect made by the user is handled by the UI flow that asked
      // for it; only an unexpected loss arms the automatic resume below.
      if (_loraCompanion.userDisconnectRequested) return;
      if (_linkLossAlertsEnabled) {
        unawaited(_soundService.playLinkLost());
      }
      if (_autoPingEnabled) {
        _suspendAutoPingForReconnect();
      }
      if (_carpeaterModeEnabled && _isTracking) {
        _carpeaterNeighboursSubscription?.cancel();
        _carpeaterDiscoveryStartedSubscription?.cancel();
        _carpeaterService.stop();
        _carpeaterResumeOnReconnect = true;
        _logger.logServiceEvent('Carpeater paused: device link lost');
      }
    });
    // ...and resume it once ANY reconnection restores the link, whether the
    // automatic loop got there first or the user reconnected the device
    // manually. A deliberate disconnect never arms a resume, so sampling
    // stays off in that case.
    _connectedSubscription = _loraCompanion.connectedStream.listen((_) {
      if (_autoPingResumeOnReconnect) {
        enableAutoPing();
        _logger.logPingEvent('Auto-ping resumed after device reconnection');
      }
      if (_carpeaterResumeOnReconnect) {
        _carpeaterResumeOnReconnect = false;
        _restartCarpeaterAfterReconnect();
      }
    });
  }
  StreamSubscription<Position>? _positionStreamSubscription;
  StreamSubscription<ServiceStatus>? _locationServiceStatusSubscription;
  Timer? _positionWatchdogTimer;
  Timer? _positionRestartTimer;
  DateTime? _lastPositionEventAt;
  bool _positionSearchRequested = false;
  bool _positionStreamRestarting = false;
  int _positionStreamGeneration = 0;
  Timer? _wifiLocationTimer;
  bool _wifiPositioningEnabled = false;
  bool _wifiLookupInProgress = false;
  DateTime? _lastAcceptedWifiPositionAt;
  Position? _lastFusedPosition;
  LocationPositionSource _activePositionSource = LocationPositionSource.fused;
  bool _isTracking = false;
  bool _autoPingEnabled = false;
  bool _autoPingResumeOnReconnect = false;

  // Auto-ping pause while recent position fixes keep failing quality checks.
  bool _pingPauseEnabled = LocationQualitySettings.defaultPausePingsOnBadFixes;
  bool _pingPauseActive = false;

  // Subscriptions to the companion service connection lifecycle.
  StreamSubscription<void>? _disconnectSubscription;
  StreamSubscription<void>? _connectedSubscription;
  double _pingIntervalMeters = 805.0; // Default 0.5 miles
  LatLng? _lastPingPosition;

  // Ping mode: 'distance', 'time', or 'both'
  String _pingMode = 'time';
  int _pingTimeIntervalSeconds = 30;
  Timer? _timePingTimer;
  bool _pingInProgress = false; // Guard against overlapping pings
  DateTime? _lastPingTimestamp; // When the last ping was triggered (any source)

  // Distance tracking
  static const double _minimumRecordedMovementMeters = 5;
  double _totalDistanceMeters = 0.0;
  LatLng? _lastPosition;
  LatLng? _lastDistancePosition;
  LatLng? _lastRecordedPosition;

  // Session ping stats for live notification
  int _sessionPingCount = 0;
  int _sessionSuccessCount = 0;

  // Session tracking
  int? _currentSessionId;
  DateTime? _sessionStartTime;

  // Stream for broadcasting current position
  final _currentPositionController = StreamController<LatLng>.broadcast();
  Stream<LatLng> get currentPositionStream => _currentPositionController.stream;

  final _positionSourceController =
      StreamController<LocationPositionSource>.broadcast();
  Stream<LocationPositionSource> get positionSourceStream =>
      _positionSourceController.stream;
  LocationPositionSource get activePositionSource => _activePositionSource;

  // GPS course is used as a fallback when the device has no compass sensor.
  final _courseController = StreamController<double>.broadcast();
  Stream<double> get courseStream => _courseController.stream;

  // Stream for broadcasting when samples are saved
  final _sampleSavedController = StreamController<void>.broadcast();
  Stream<void> get sampleSavedStream => _sampleSavedController.stream;

  // Stream for broadcasting ping events
  final _pingEventController = StreamController<String>.broadcast();
  Stream<String> get pingEventStream => _pingEventController.stream;

  // Stream for broadcasting auto-ping pause changes (true = paused)
  final _pingPauseController = StreamController<bool>.broadcast();
  Stream<bool> get pingPauseStream => _pingPauseController.stream;

  /// Whether automatic pings are currently paused because the recent position
  /// fixes kept failing quality checks.
  bool get isPingPausedByBadFixes => _pingPauseActive;

  // Stream for broadcasting total distance updates
  final _totalDistanceController = StreamController<double>.broadcast();
  Stream<double> get totalDistanceStream => _totalDistanceController.stream;

  // Stream for broadcasting current speed (m/s)
  final _speedController = StreamController<double>.broadcast();
  Stream<double> get speedStream => _speedController.stream;
  double _currentSpeedMps = 0.0;
  double get currentSpeedMph => _currentSpeedMps * 2.23694;
  double get currentSpeedKmh => _currentSpeedMps * 3.6;

  // Dead zone alerts — throttle to once per cell per session
  final Set<String> _deadZoneAlertedCells = {};
  final _deadZoneController = StreamController<String>.broadcast();
  Stream<String> get deadZoneStream => _deadZoneController.stream;
  bool _deadZoneAlertsEnabled = true;

  // Audible alert for an unexpected LoRa device link loss
  bool _linkLossAlertsEnabled = true;

  // Battery saver mode
  final Battery _battery = Battery();
  StreamSubscription<BatteryState>? _batteryStateSubscription;
  bool _batterySaverActive = false;
  bool _batterySaverEnabled = true;
  double _normalPingInterval = 805.0; // Saved before battery saver doubles it
  final _batterySaverController = StreamController<bool>.broadcast();
  Stream<bool> get batterySaverStream => _batterySaverController.stream;
  bool get isBatterySaverActive => _batterySaverActive;

  // Ducting monitoring
  bool _ductingEnabled = false;
  Timer? _ductingFetchTimer;

  // Carpeater mode
  late final CarpeaterService _carpeaterService;
  bool _carpeaterModeEnabled = false;
  bool _carpeaterResumeOnReconnect = false;
  StreamSubscription<List<Map<String, dynamic>>>?
  _carpeaterNeighboursSubscription;
  StreamSubscription<void>? _carpeaterDiscoveryStartedSubscription;
  LatLng? _carpeaterDiscoveryPosition; // GPS snapshot at moment of discovery

  /// Get ducting service for UI access
  DuctingService get ductingService => _ductingService;

  /// Get session ping stats
  int get sessionPingCount => _sessionPingCount;
  int get sessionSuccessCount => _sessionSuccessCount;
  int? get currentSessionId => _currentSessionId;
  DateTime? get sessionStartTime => _sessionStartTime;

  /// Localized copy for foreground notifications and start-error snackbars.
  Future<AppLocalizations> _lookupL10n() async {
    return AppLocale.lookup(
      await _settings.getAppLocalePreference(),
      WidgetsBinding.instance.platformDispatcher.locale,
    );
  }

  Future<void> _setNotificationText(
    String Function(AppLocalizations l10n) text,
  ) async {
    final l10n = await _lookupL10n();
    await FlutterForegroundTask.updateService(
      notificationTitle: l10n.notificationBrandTitle,
      notificationText: text(l10n),
      notificationButtons: [
        NotificationButton(id: 'stop', text: l10n.notificationStopTracking),
      ],
    );
  }

  /// Update foreground notification with live wardrive stats
  Future<void> _updateLiveNotification() async {
    if (!_isTracking) return;
    final rate = _sessionPingCount > 0
        ? ((_sessionSuccessCount / _sessionPingCount) * 100).toStringAsFixed(0)
        : '--';
    final dist = (_totalDistanceMeters / 1609.34).toStringAsFixed(1);
    await _setNotificationText(
      (l10n) => l10n.notificationLiveStats(rate, _sessionPingCount, dist),
    );
  }

  Future<void> _updateCarpeaterNotification() async {
    if (!_isTracking) return;
    await _setNotificationText((l10n) => l10n.notificationCarpeaterActive);
  }

  /// Re-apply localized foreground notification copy after a language change.
  Future<void> refreshNotificationCopy() async {
    if (!_isTracking) return;
    if (_carpeaterModeEnabled) {
      await _updateCarpeaterNotification();
    } else {
      await _updateLiveNotification();
    }
  }

  /// Get carpeater service for UI access
  CarpeaterService get carpeaterService => _carpeaterService;

  /// Enable or disable ducting monitoring at runtime
  void setDuctingEnabled(bool enabled) {
    _ductingEnabled = enabled;
    if (enabled && _isTracking && _lastPosition != null) {
      // Kick off an initial fetch and start periodic timer
      _ductingService.fetchAndCache(
        _lastPosition!.latitude,
        _lastPosition!.longitude,
      );
      _ductingFetchTimer?.cancel();
      _ductingFetchTimer = Timer.periodic(const Duration(minutes: 60), (
        _,
      ) async {
        if (_lastPosition != null) {
          await _ductingService.fetchAndCache(
            _lastPosition!.latitude,
            _lastPosition!.longitude,
          );
        }
      });
    } else if (!enabled) {
      _ductingFetchTimer?.cancel();
      _ductingFetchTimer = null;
    }
  }

  /// Enable or disable automatic battery-saver ping doubling.
  void setBatterySaverEnabled(bool enabled) {
    _batterySaverEnabled = enabled;
    if (!enabled) {
      _stopBatteryMonitoring();
      return;
    }
    if (_isTracking) {
      _startBatteryMonitoring();
    }
  }

  /// Enable or disable the audible alert played when the LoRa device link is
  /// lost unexpectedly.
  void setLinkLossAlertsEnabled(bool enabled) {
    _linkLossAlertsEnabled = enabled;
  }

  /// Enable the opt-in beaconDB Wi-Fi location source. A recent, valid Wi-Fi
  /// fix takes priority over Android's fused provider.
  void setWifiPositioningEnabled(bool enabled) {
    if (_wifiPositioningEnabled == enabled) return;
    _wifiPositioningEnabled = enabled;
    _wifiLocationTimer?.cancel();
    _wifiLocationTimer = null;

    if (enabled) {
      _startWifiLocationUpdates();
      return;
    }

    _lastAcceptedWifiPositionAt = null;
    _wifiQualityFilter.reset();
    final fusedPosition = _lastFusedPosition;
    if (fusedPosition != null) {
      _handleNewPosition(fusedPosition, source: LocationPositionSource.fused);
    }
  }

  /// Applies the same rejection thresholds to fused and Wi-Fi positions.
  void setLocationQualitySettings(LocationQualitySettings settings) {
    _qualityFilter.updateSettings(settings);
    _wifiQualityFilter.updateSettings(settings);
    _pingPauseEnabled = settings.pausePingsOnBadFixes;
    _badFixMonitor.requiredBadFixes = settings.pingPauseBadFixCount;
    if (!_pingPauseEnabled) _badFixMonitor.reset();
    _syncPingPauseState();
  }

  /// Re-evaluates the pause state and broadcasts transitions.
  void _syncPingPauseState() {
    final paused = _pingPauseEnabled && _badFixMonitor.isPaused;
    if (paused == _pingPauseActive) return;
    _pingPauseActive = paused;
    _pingPauseController.add(paused);
    if (paused) {
      unawaited(
        _logger.logPingEvent(
          'Auto-ping paused: ${_badFixMonitor.consecutiveBadFixes} '
          'consecutive bad position fixes (threshold: '
          '${_badFixMonitor.requiredBadFixes})',
        ),
      );
    } else {
      unawaited(
        _logger.logPingEvent('Auto-ping resumed after a valid position fix'),
      );
    }
  }

  void _startWifiLocationUpdates() {
    if (!_wifiPositioningEnabled || !_positionSearchRequested) return;
    _wifiLocationTimer?.cancel();
    _lookupWifiPosition();
    _wifiLocationTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _lookupWifiPosition();
    });
  }

  Future<void> _lookupWifiPosition() async {
    if (!_wifiPositioningEnabled ||
        !_positionSearchRequested ||
        _wifiLookupInProgress) {
      return;
    }
    _wifiLookupInProgress = true;
    try {
      final estimate = await _wifiLocationService.locate();
      if (!_wifiPositioningEnabled ||
          !_positionSearchRequested ||
          estimate == null) {
        return;
      }

      await _logger.logLocationEvent(
        'beaconDB Wi-Fi estimate: ${estimate.position.latitude}, '
        '${estimate.position.longitude}, accuracy '
        '${estimate.accuracyMeters.toStringAsFixed(1)}m from '
        '${estimate.accessPointCount} access points',
      );
      _handleNewPosition(
        Position(
          latitude: estimate.position.latitude,
          longitude: estimate.position.longitude,
          timestamp: DateTime.now(),
          accuracy: estimate.accuracyMeters,
          altitude: 0,
          altitudeAccuracy: -1,
          heading: 0,
          headingAccuracy: -1,
          speed: 0,
          speedAccuracy: -1,
        ),
        source: LocationPositionSource.wifi,
      );
    } catch (e) {
      await _logger.logError('beaconDB Wi-Fi Location', e.toString());
    } finally {
      _wifiLookupInProgress = false;
    }
  }

  /// Enable or disable Carpeater mode at runtime
  void setCarpeaterMode(bool enabled) {
    final wasEnabled = _carpeaterModeEnabled;
    _carpeaterModeEnabled = enabled;
    _logger.logServiceEvent(
      'Carpeater mode ${enabled ? "enabled" : "disabled"}',
    );

    if (enabled &&
        !wasEnabled &&
        _isTracking &&
        _loraCompanion.isDeviceConnected) {
      // Switching to carpeater mid-tracking: disable auto-ping and start carpeater
      disableAutoPing();
      startCarpeater();
    } else if (!enabled && wasEnabled) {
      // Switching off carpeater: stop it and resume auto-ping if tracking
      _carpeaterResumeOnReconnect = false;
      _carpeaterNeighboursSubscription?.cancel();
      _carpeaterDiscoveryStartedSubscription?.cancel();
      _carpeaterService.stop();
      if (_isTracking && _loraCompanion.isDeviceConnected) {
        enableAutoPing();
      }
    }
  }

  /// Check if location permissions are granted
  Future<bool> checkPermissions() async {
    LocationPermission permission = await Geolocator.checkPermission();
    await _logger.logPermission('Location', permission.toString());

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      await _logger.logPermission(
        'Location (after request)',
        permission.toString(),
      );
      if (permission == LocationPermission.denied) {
        _lastStartError = (await _lookupL10n()).locationPermissionDenied;
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      await _logger.logPermission('Location', 'DENIED_FOREVER');
      _lastStartError =
          (await _lookupL10n()).locationPermissionPermanentlyDenied;
      return false;
    }

    return true;
  }

  /// Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Keep looking for a position while the map is open, even outside a
  /// recording session. Android's fused provider can use GNSS, Wi-Fi, and
  /// cellular signals; samples are persisted only while [_isTracking] is true.
  Future<bool> startPositionSearch() async {
    await _logger.init();
    _positionSearchRequested = true;

    final hasPermission = await checkPermissions();
    if (!hasPermission) return false;

    _monitorLocationServiceStatus();
    _startPositionWatchdog();
    _startWifiLocationUpdates();

    if (!await isLocationServiceEnabled()) {
      await _logger.logLocationEvent(
        'Position search is waiting for Android location services',
      );
      return false;
    }

    return _restartPositionStream(reason: 'position search started');
  }

  void _monitorLocationServiceStatus() {
    _locationServiceStatusSubscription ??= Geolocator.getServiceStatusStream()
        .listen((status) {
          if (!_positionSearchRequested) return;
          if (status == ServiceStatus.enabled) {
            _schedulePositionStreamRestart('location services enabled');
          } else {
            _lastPositionEventAt = null;
            _logger.logLocationEvent(
              'Position search paused: Android location services disabled',
            );
          }
        });
  }

  void _startPositionWatchdog() {
    _positionWatchdogTimer ??= Timer.periodic(const Duration(seconds: 15), (_) {
      if (!_positionSearchRequested || _positionStreamRestarting) return;
      final lastEvent = _lastPositionEventAt;
      final streamStalled =
          lastEvent != null &&
          DateTime.now().difference(lastEvent) > const Duration(seconds: 45);
      if (_positionStreamSubscription == null || streamStalled) {
        _schedulePositionStreamRestart(
          streamStalled ? 'no location updates for 45 seconds' : 'no stream',
        );
      }
    });
  }

  void _schedulePositionStreamRestart(String reason) {
    if (!_positionSearchRequested ||
        (_positionRestartTimer?.isActive ?? false)) {
      return;
    }
    _positionRestartTimer = Timer(const Duration(seconds: 2), () {
      _positionRestartTimer = null;
      _restartPositionStream(reason: reason);
    });
  }

  Future<bool> _restartPositionStream({required String reason}) async {
    if (!_positionSearchRequested || _positionStreamRestarting) return false;
    _positionStreamRestarting = true;
    final generation = ++_positionStreamGeneration;

    try {
      await _positionStreamSubscription?.cancel();
      _positionStreamSubscription = null;

      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        await _logger.logLocationEvent(
          'Position search paused: location permission unavailable',
        );
        return false;
      }
      if (!await isLocationServiceEnabled()) return false;

      final locationSettings = Platform.isAndroid
          ? AndroidSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter: 0,
              intervalDuration: const Duration(seconds: 5),
              forceLocationManager: false,
            )
          : const LocationSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter: 0,
            );

      _lastPositionEventAt = DateTime.now();
      _positionStreamSubscription =
          Geolocator.getPositionStream(
            locationSettings: locationSettings,
          ).listen(
            (position) {
              if (generation != _positionStreamGeneration) return;
              _lastPositionEventAt = DateTime.now();
              _handleNewPosition(
                position,
                source: LocationPositionSource.fused,
              );
            },
            onError: (Object error) {
              if (generation != _positionStreamGeneration) return;
              _logger.logError('Location Stream', error.toString());
              _schedulePositionStreamRestart('stream error: $error');
            },
            onDone: () {
              if (generation != _positionStreamGeneration) return;
              _positionStreamSubscription = null;
              _schedulePositionStreamRestart('stream closed');
            },
          );
      await _logger.logLocationEvent(
        'Position stream started ($reason; fused provider, 0m filter)',
      );
      return true;
    } catch (e) {
      await _logger.logError('Position Stream Restart', e.toString());
      _schedulePositionStreamRestart('restart failed');
      return false;
    } finally {
      _positionStreamRestarting = false;
    }
  }

  /// Get current position once
  Future<LatLng?> getCurrentPosition() async {
    try {
      final hasPermission = await checkPermissions();
      if (!hasPermission) return null;

      final isEnabled = await isLocationServiceEnabled();
      if (!isEnabled) return null;

      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: Platform.isAndroid
            ? AndroidSettings(
                accuracy: LocationAccuracy.high,
                distanceFilter: 0,
                forceLocationManager: false,
                timeLimit: const Duration(seconds: 20),
              )
            : const LocationSettings(
                accuracy: LocationAccuracy.high,
                distanceFilter: 0,
              ),
      );

      return LatLng(position.latitude, position.longitude);
    } catch (e) {
      debugPrint('Error getting current position: $e');
      return null;
    }
  }

  /// Initialize foreground service
  Future<void> _initForegroundTask() async {
    final l10n = await _lookupL10n();
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'meshcore_wardrive_location',
        channelName: l10n.notificationChannelName,
        channelDescription: l10n.notificationChannelDescription,
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(
          5000,
        ), // Update every 5 seconds
        autoRunOnBoot: false,
        autoRunOnMyPackageReplaced: false,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
  }

  /// Start tracking location
  Future<bool> startTracking() async {
    await _logger.init();
    await _logger.logServiceEvent('startTracking() called');
    _lastStartError = null;

    if (_isTracking) {
      await _logger.logServiceEvent('Already tracking - returning early');
      return true;
    }

    final hasPermission = await checkPermissions();
    if (!hasPermission) {
      await _logger.logError('Permissions', 'Location permission not granted');
      return false;
    }

    final isEnabled = await isLocationServiceEnabled();
    if (!isEnabled) {
      await _logger.logError('Location Service', 'GPS is disabled');
      _lastStartError = (await _lookupL10n()).locationServicesDisabled;
      return false;
    }

    // Request notification permission for Android 13+
    final notificationStatus = await Permission.notification.request();
    await _logger.logPermission('Notification', notificationStatus.toString());
    if (!notificationStatus.isGranted) {
      debugPrint(
        'Notification permission denied - foreground service may not work properly',
      );
    }

    try {
      // Initialize and start foreground service
      await _initForegroundTask();
      await _logger.logServiceEvent('Foreground task initialized');

      final l10n = await _lookupL10n();
      await FlutterForegroundTask.startService(
        serviceId: 256,
        notificationTitle: l10n.notificationBrandTitle,
        notificationText: l10n.notificationTrackingActive,
        notificationButtons: [
          NotificationButton(id: 'stop', text: l10n.notificationStopTracking),
        ],
        callback:
            null, // We handle location in Flutter, not in service callback
      );

      await _logger.logServiceEvent('Foreground service started successfully');
      debugPrint('Foreground service started');

      _qualityFilter.reset();
      _wifiQualityFilter.reset();
      // A new session starts with a clean bad-fix streak and active pings.
      _badFixMonitor.reset();
      _pingPauseActive = false;
      _positionSearchRequested = true;
      _monitorLocationServiceStatus();
      _startPositionWatchdog();
      if (_positionStreamSubscription == null &&
          !await _restartPositionStream(reason: 'tracking started')) {
        throw StateError('Could not start the Android position stream.');
      }

      // Enable wakelock to prevent screen from sleeping and stopping tracking
      await ScreenWakeService.instance.setTrackingActive(true);
      await _logger.logPowerEvent('Wakelock enabled');
      debugPrint('Wakelock enabled - app will stay active during tracking');

      // Reset the recording state before allowing stream events to be saved.
      _totalDistanceMeters = 0.0;
      _lastPosition = null;
      _lastDistancePosition = null;
      _lastRecordedPosition = null;
      _lastPingPosition = null;
      _lastPingTimestamp = null;
      _totalDistanceController.add(_totalDistanceMeters);
      _sessionStartTime = DateTime.now();
      _sessionPingCount = 0;
      _sessionSuccessCount = 0;
      _deadZoneAlertedCells.clear();
      _isTracking = true;
      WidgetService.updateTrackingStatus(true);

      // Start monitoring device battery for battery saver mode (if enabled)
      _batterySaverEnabled = await _settings.getBatterySaverEnabled();
      if (_batterySaverEnabled) {
        _startBatteryMonitoring();
      }

      // Load alert settings
      _deadZoneAlertsEnabled = await _settings.getDeadZoneAlertsEnabled();

      // Store connected device in DB if available
      try {
        final deviceId = _loraCompanion.connectedDeviceId;
        if (deviceId != null) {
          final deviceName = _loraCompanion.deviceName ?? 'Unknown';
          final connType =
              _loraCompanion.connectionType == ConnectionType.bluetooth
              ? 'bluetooth'
              : 'usb';
          await _dbService.upsertDevice(deviceId, deviceName, connType);
        }
      } catch (e) {
        await _logger.logError('Device Tracking', e.toString());
      }

      // Start ducting monitoring if enabled (non-blocking)
      _ductingEnabled = await _settings.getShowDucting();
      if (_ductingEnabled) {
        // Fire-and-forget initial fetch using the position stream (don't block with getCurrentPosition)
        _ductingFetchTimer?.cancel();
        _ductingFetchTimer = Timer.periodic(const Duration(minutes: 60), (
          _,
        ) async {
          if (_lastPosition != null) {
            await _ductingService.fetchAndCache(
              _lastPosition!.latitude,
              _lastPosition!.longitude,
            );
          }
        });
        // Kick off first fetch after a short delay so GPS has time to get a fix
        Future.delayed(const Duration(seconds: 5), () {
          if (_lastPosition != null) {
            _ductingService.fetchAndCache(
              _lastPosition!.latitude,
              _lastPosition!.longitude,
            );
          }
        });
      }

      // Create a new session record
      try {
        final session = WSession(startTime: _sessionStartTime!);
        _currentSessionId = await _dbService.createSession(session);
        await _logger.logServiceEvent(
          'Session created with ID: $_currentSessionId',
        );
      } catch (e) {
        await _logger.logError('Session Create', e.toString());
      }

      await _logger.logServiceEvent('Tracking started successfully');
      return true;
    } catch (e) {
      _isTracking = false;
      await _logger.logError('Start Tracking', e.toString());
      _lastStartError = (await _lookupL10n()).locationTrackingStartFailed('$e');
      debugPrint('Error starting location tracking: $e');
      await FlutterForegroundTask.stopService();
      await ScreenWakeService.instance.setTrackingActive(false);
      _schedulePositionStreamRestart('tracking start failed');
      return false;
    }
  }

  /// Get LoRa companion service
  LoRaCompanionService get loraCompanion => _loraCompanion;

  /// Enable auto-ping (requires LoRa device to be connected)
  void enableAutoPing() {
    final isConnected = _loraCompanion.isDeviceConnected;
    final connectionType = _loraCompanion.connectionType;
    _logger.logPingEvent(
      'enableAutoPing() called - Device connected: $isConnected, Type: ${connectionType.name}',
    );

    _autoPingResumeOnReconnect = false;
    if (isConnected) {
      _autoPingEnabled = true;
      _logger.logPingEvent(
        'Auto-ping enabled (mode: $_pingMode, distance: ${_pingIntervalMeters}m, time: ${_pingTimeIntervalSeconds}s)',
      );
      _restartTimePingTimer();
    } else {
      _logger.logPingEvent('Auto-ping enable FAILED - no device connected');
    }
  }

  /// Disable auto-ping
  void disableAutoPing() {
    _autoPingEnabled = false;
    _timePingTimer?.cancel();
    _timePingTimer = null;
    _autoPingResumeOnReconnect = false;
    _logger.logPingEvent('Auto-ping disabled');
  }

  /// Disable auto-ping because the device connection was lost unexpectedly.
  ///
  /// Unlike [disableAutoPing], the intent to ping is remembered so it can be
  /// resumed when the automatic reconnection restores the device.
  void _suspendAutoPingForReconnect() {
    _autoPingEnabled = false;
    _timePingTimer?.cancel();
    _timePingTimer = null;
    _autoPingResumeOnReconnect = true;
    _logger.logPingEvent('Auto-ping disabled (device disconnected)');
  }

  /// Check if auto-ping is enabled
  bool get isAutoPingEnabled => _autoPingEnabled;

  /// Check if ready for auto-ping
  bool get isReadyForAutoPing => _loraCompanion.isDeviceConnected;

  /// Set ping interval in meters
  void setPingInterval(double meters) {
    _pingIntervalMeters = meters;
  }

  /// Get current ping interval in meters
  double get pingIntervalMeters => _pingIntervalMeters;

  /// Set ping mode ('distance', 'time', or 'both')
  void setPingMode(String mode) {
    _pingMode = mode;
    _logger.logPingEvent('Ping mode set to: $mode');
    _restartTimePingTimer();
  }

  /// Get current ping mode
  String get pingMode => _pingMode;

  /// Set ping time interval in seconds
  void setPingTimeInterval(int seconds) {
    _pingTimeIntervalSeconds = seconds;
    _logger.logPingEvent('Ping time interval set to: ${seconds}s');
    _restartTimePingTimer();
  }

  /// Get current ping time interval in seconds
  int get pingTimeIntervalSeconds => _pingTimeIntervalSeconds;

  /// Start or restart the time-based ping timer
  void _restartTimePingTimer() {
    _timePingTimer?.cancel();
    _timePingTimer = null;

    if (!_isTracking || !_autoPingEnabled || _carpeaterModeEnabled) return;
    if (_pingMode == 'distance') {
      return; // No timer needed for distance-only mode
    }

    _timePingTimer = Timer.periodic(
      Duration(seconds: _pingTimeIntervalSeconds),
      (_) => _handleTimePing(),
    );
    _logger.logPingEvent(
      'Time-based ping timer started (${_pingTimeIntervalSeconds}s)',
    );
  }

  /// Handle a time-triggered ping
  void _handleTimePing() async {
    if (!_autoPingEnabled ||
        _carpeaterModeEnabled ||
        _pingInProgress ||
        _loraCompanion.isPingInProgress) {
      return;
    }
    if (!_loraCompanion.isDeviceConnected) return;
    // Recent fixes are unreliable; pinging a stale position would only
    // record garbage. Pinging resumes once a valid fix arrives.
    if (_pingPauseActive) return;

    final position = _lastPosition;
    if (position == null) return;

    // In 'both' mode, skip if a distance ping fired recently
    // (no point pinging the same spot twice)
    if (_pingMode == 'both' && _lastPingTimestamp != null) {
      final elapsed = DateTime.now().difference(_lastPingTimestamp!);
      if (elapsed.inSeconds < _pingTimeIntervalSeconds ~/ 2) {
        _logger.logPingEvent(
          'Time ping skipped — distance ping fired ${elapsed.inSeconds}s ago',
        );
        return;
      }
    }

    _pingInProgress = true;
    _lastPingPosition = position;
    _lastRecordedPosition = position;
    _lastPingTimestamp = DateTime.now();

    final geohash = GeohashUtils.sampleKey(
      position.latitude,
      position.longitude,
    );
    await _logger.logPingEvent(
      'Time-based ping triggered at ${position.latitude}, ${position.longitude}',
    );

    _pingEventController.add('pinging');
    _soundService.playPingSent();

    await _setNotificationText((l10n) => l10n.notificationPinging);

    _performPingInBackground(position, geohash);
  }

  /// Get total distance traveled in meters
  double get totalDistanceMeters => _totalDistanceMeters;

  /// Get total distance traveled in miles
  double get totalDistanceMiles => _totalDistanceMeters / 1609.34;

  /// Get total distance traveled in kilometers
  double get totalDistanceKm => _totalDistanceMeters / 1000.0;

  /// Handle new position from location stream
  void _handleNewPosition(
    Position position, {
    required LocationPositionSource source,
  }) async {
    final latLng = LatLng(position.latitude, position.longitude);
    await _logger.logLocationEvent(
      '${source.name} location update: ${latLng.latitude}, '
      '${latLng.longitude}, '
      'accuracy: ${position.accuracy}m, altitude: ${position.altitude}m, '
      'speed: ${(position.speed * 3.6).toStringAsFixed(1)}km/h',
    );

    final qualityFilter = source == LocationPositionSource.wifi
        ? _wifiQualityFilter
        : _qualityFilter;
    final rejectionReason = qualityFilter.rejectionReason(position);
    if (rejectionReason != null || !GeohashUtils.isValidLocation(latLng)) {
      final reason = rejectionReason ?? 'coordinates outside valid range';
      await _logger.logLocationEvent(
        '${source.name} location ignored: $reason',
      );
      debugPrint('Location ignored: $reason');
      _badFixMonitor.recordRejectedFix();
      _syncPingPauseState();
      return;
    }

    try {
      final impossible = await _dbService.findImpossibleZoneAt(
        latLng.latitude,
        latLng.longitude,
      );
      if (impossible != null) {
        await _logger.logLocationEvent(
          '${source.name} location ignored: ${impossible.rejectionReason}',
        );
        debugPrint('Location ignored: ${impossible.rejectionReason}');
        return;
      }
    } catch (e) {
      await _logger.logLocationEvent(
        '${source.name} location ignored: impossible zone check failed: $e',
      );
      debugPrint('Location ignored: impossible zone check failed: $e');
      return;
    }

    qualityFilter.accept(position);
    // A trustworthy fix clears the bad-fix streak, so a paused auto-ping
    // resumes with the next valid measurement.
    _badFixMonitor.recordAcceptedFix();
    _syncPingPauseState();

    if (source == LocationPositionSource.fused) {
      _lastFusedPosition = position;
      if (_hasFreshWifiPosition) return;
    } else {
      _lastAcceptedWifiPositionAt = DateTime.now();
    }

    _activatePositionSource(source);

    // Update speed (filter out invalid negative values)
    _currentSpeedMps = (position.speed >= 0) ? position.speed : 0.0;
    _speedController.add(_currentSpeedMps);
    if (_currentSpeedMps >= 0.5 &&
        position.heading.isFinite &&
        position.heading >= 0) {
      _courseController.add(position.heading % 360);
    }

    // Calculate distance at the same five-metre granularity previously
    // provided by Android's distance filter. The zero-metre provider filter is
    // now reserved for keeping the map marker and watchdog fresh.
    if (_isTracking && _lastDistancePosition != null) {
      final distanceMeters = Geolocator.distanceBetween(
        _lastDistancePosition!.latitude,
        _lastDistancePosition!.longitude,
        latLng.latitude,
        latLng.longitude,
      );
      if (distanceMeters >= _minimumRecordedMovementMeters) {
        _totalDistanceMeters += distanceMeters;
        _lastDistancePosition = latLng;
        _totalDistanceController.add(_totalDistanceMeters);
      }
    } else if (_isTracking) {
      _lastDistancePosition = latLng;
    }
    _lastPosition = latLng;

    // Broadcast current position to listeners
    _currentPositionController.add(latLng);

    // Outside an active wardrive session we still keep the current-position
    // marker fresh, but do not calculate trip distance or persist samples.
    if (!_isTracking) return;

    // Check if we should trigger a ping (but don't wait for it)
    final isConnected = _loraCompanion.isDeviceConnected;

    // Log detailed debug info on every GPS update when auto-ping is enabled
    if (_autoPingEnabled) {
      await _logger.logPingEvent(
        'Checking ping condition: autoPing=$_autoPingEnabled, deviceConnected=$isConnected, lastPingPos=${_lastPingPosition != null ? "set" : "null"}',
      );
    }

    if (_autoPingEnabled &&
        isConnected &&
        !_carpeaterModeEnabled &&
        !_pingInProgress &&
        !_loraCompanion.isPingInProgress &&
        !_pingPauseActive &&
        _pingMode != 'time') {
      bool shouldPing = false;

      if (_lastPingPosition == null) {
        // First ping
        shouldPing = true;
      } else {
        // Calculate distance from last ping
        final distance = Geolocator.distanceBetween(
          _lastPingPosition!.latitude,
          _lastPingPosition!.longitude,
          latLng.latitude,
          latLng.longitude,
        );

        await _logger.logPingEvent(
          'Distance from last ping: ${distance.toStringAsFixed(1)}m (threshold: ${_pingIntervalMeters}m)',
        );

        if (distance >= _pingIntervalMeters) {
          shouldPing = true;
        }
      }

      if (shouldPing) {
        // Keep a single radio ping active so its response window has one owner.
        _pingInProgress = true;
        _lastPingPosition = latLng;
        _lastRecordedPosition = latLng;
        _lastPingTimestamp = DateTime.now();
        await _logger.logPingEvent(
          'Distance-based ping triggered at ${latLng.latitude}, ${latLng.longitude}',
        );

        // Notify UI that ping is starting
        _pingEventController.add('pinging');
        _soundService.playPingSent();

        // Update foreground notification
        await _setNotificationText((l10n) => l10n.notificationPinging);

        // Start ping in background - don't wait for it
        debugPrint(
          'Triggering auto-ping via LoRa at ${latLng.latitude}, ${latLng.longitude}',
        );
        final geohash = GeohashUtils.sampleKey(
          position.latitude,
          position.longitude,
        );
        _performPingInBackground(latLng, geohash);
        return; // Don't save GPS sample when auto-pinging - wait for ping result
      }
    }

    final lastRecordedPosition = _lastRecordedPosition;
    if (lastRecordedPosition != null &&
        Geolocator.distanceBetween(
              lastRecordedPosition.latitude,
              lastRecordedPosition.longitude,
              latLng.latitude,
              latLng.longitude,
            ) <
            _minimumRecordedMovementMeters) {
      return;
    }
    _lastRecordedPosition = latLng;

    // Dead zone alert: check if current coverage cell is a known dead zone
    _checkDeadZone(latLng);

    // Create sample
    final geohash = GeohashUtils.sampleKey(
      position.latitude,
      position.longitude,
    );

    // Only save GPS sample if auto-ping is disabled or no ping triggered
    // Tag with ducting risk if monitoring is enabled
    String? ductingRisk;
    if (_ductingEnabled) {
      ductingRisk = await _ductingService.getCurrentRisk(DateTime.now());
      if (ductingRisk == DuctingRisk.unknown) ductingRisk = null;
    }

    final sample = Sample(
      id: _generateUniqueId(),
      position: latLng,
      timestamp: DateTime.now(),
      path: null,
      geohash: geohash,
      rssi: null,
      snr: null,
      pingSuccess: null, // GPS-only sample (no ping attempted)
      ductingRisk: ductingRisk,
    );

    // Save to database
    try {
      await _dbService.insertSample(sample);
      debugPrint(
        'Saved GPS sample: ${sample.id} at ${latLng.latitude}, ${latLng.longitude}',
      );
      // Notify listeners that a sample was saved
      _sampleSavedController.add(null);
    } catch (e) {
      debugPrint('Error saving sample: $e');
    }
  }

  bool get _hasFreshWifiPosition {
    final receivedAt = _lastAcceptedWifiPositionAt;
    return _wifiPositioningEnabled &&
        receivedAt != null &&
        DateTime.now().difference(receivedAt) < const Duration(seconds: 45);
  }

  void _activatePositionSource(LocationPositionSource source) {
    if (_activePositionSource == source) return;
    _activePositionSource = source;
    _lastPosition = null;
    _lastDistancePosition = null;
    _lastRecordedPosition = null;
    _lastPingPosition = null;
    _positionSourceController.add(source);
    _logger.logLocationEvent('Active position source: ${source.name}');
  }

  /// Start monitoring device battery level for battery saver mode
  void _startBatteryMonitoring() {
    _batteryStateSubscription?.cancel();
    _batteryStateSubscription = _battery.onBatteryStateChanged.listen((
      _,
    ) async {
      if (!_batterySaverEnabled) return;
      try {
        final level = await _battery.batteryLevel;
        if (level <= 20 && !_batterySaverActive) {
          _activateBatterySaver();
        } else if (level > 30 && _batterySaverActive) {
          _deactivateBatterySaver();
        }
      } catch (e) {
        // Battery API not available — ignore
      }
    });
    // Also check immediately
    _battery.batteryLevel
        .then((level) {
          if (!_batterySaverEnabled) return;
          if (level <= 20 && !_batterySaverActive) {
            _activateBatterySaver();
          }
        })
        .catchError((_) {});
  }

  void _stopBatteryMonitoring() {
    _batteryStateSubscription?.cancel();
    _batteryStateSubscription = null;
    if (_batterySaverActive) {
      _deactivateBatterySaver();
    }
  }

  void _activateBatterySaver() {
    if (!_batterySaverEnabled) return;
    _batterySaverActive = true;
    _normalPingInterval = _pingIntervalMeters;
    _pingIntervalMeters = _normalPingInterval * 2;
    _batterySaverController.add(true);
    _logger.logPowerEvent(
      'Battery saver ON — ping interval doubled to ${_pingIntervalMeters.toStringAsFixed(0)}m',
    );
  }

  void _deactivateBatterySaver() {
    _batterySaverActive = false;
    _pingIntervalMeters = _normalPingInterval;
    _batterySaverController.add(false);
    _logger.logPowerEvent(
      'Battery saver OFF — ping interval restored to ${_pingIntervalMeters.toStringAsFixed(0)}m',
    );
  }

  /// Check if the current position is in a known dead zone and alert once per cell
  void _checkDeadZone(LatLng latLng) async {
    if (!_deadZoneAlertsEnabled) return;
    try {
      final precision = await _settings.getCoveragePrecision();
      final cellHash = GeohashUtils.coverageKey(
        latLng.latitude,
        latLng.longitude,
        precision: precision,
      );
      if (_deadZoneAlertedCells.contains(cellHash)) return;

      final isDead = await _dbService.isDeadZoneCell(cellHash);
      if (isDead) {
        _deadZoneAlertedCells.add(cellHash);
        _deadZoneController.add(cellHash);
        _soundService.playPingFailed();
        await _logger.logPingEvent('Dead zone alert: cell $cellHash');
      }
    } catch (e) {
      // Non-critical — don't break GPS tracking
    }
  }

  /// Perform ping in background and update sample when complete
  void _performPingInBackground(LatLng latLng, String geohash) async {
    try {
      // Get user-configured discovery timeout
      final timeoutSeconds = await _settings.getDiscoveryTimeout();
      final collectUntilTimeout = await _settings
          .getThoroughResponseCollection();
      await _logger.logPingEvent(
        'Sending ping to LoRa device (timeout: ${timeoutSeconds}s)...',
      );
      final pingResult = await _loraCompanion.ping(
        latitude: latLng.latitude,
        longitude: latLng.longitude,
        timeoutSeconds: timeoutSeconds,
        waitForAllResponses: true,
        collectUntilTimeout: collectUntilTimeout,
      );

      final responses = pingResult.responses;
      final pingSuccess =
          pingResult.status == PingStatus.success && responses.isNotEmpty;
      final nodeId = pingResult.nodeId;

      await _logger.logPingEvent(
        'Ping result: ${pingResult.status.name}, Node: $nodeId, RSSI: ${pingResult.rssi}, SNR: ${pingResult.snr}',
      );
      debugPrint(
        'Ping complete: ${pingResult.status.name}, Node: $nodeId, RSSI: ${pingResult.rssi}, SNR: ${pingResult.snr}',
      );

      // Sound feedback for every unique response, or once for a dead zone.
      if (pingSuccess) {
        for (final response in responses) {
          await _soundService.playForPingResult(
            success: true,
            snr: response.snr,
            rssi: response.rssi,
          );
        }
      } else {
        await _soundService.playForPingResult(success: false);
      }

      // Update notification with result
      await _setNotificationText((l10n) {
        if (!pingSuccess) return l10n.notificationNoResponse;
        final label = (nodeId != null && nodeId.isNotEmpty)
            ? (nodeId.length > 8
                  ? nodeId.substring(0, 8).toUpperCase()
                  : nodeId.toUpperCase())
            : l10n.notificationRepeaterFallback;
        return l10n.notificationHeardBy(label);
      });

      // Update session stats
      _sessionPingCount++;
      if (pingSuccess) _sessionSuccessCount++;

      // Notify UI
      _pingEventController.add(pingSuccess ? 'success' : 'failed');

      // Update notification with live stats
      Future.delayed(const Duration(seconds: 3), () {
        _updateLiveNotification();
      });

      // Tag with ducting risk if monitoring is enabled
      String? ductingRisk;
      if (_ductingEnabled) {
        ductingRisk = await _ductingService.getCurrentRisk(DateTime.now());
        if (ductingRisk == DuctingRisk.unknown) ductingRisk = null;
      }

      if (pingSuccess) {
        // Persist every unique repeater response from this discovery cycle.
        for (final response in responses) {
          final sample = Sample(
            id: _generateUniqueId(),
            position: latLng,
            timestamp: DateTime.now(),
            path: response.nodeId,
            geohash: geohash,
            rssi: response.rssi,
            snr: response.snr,
            pingSuccess: true,
            responseTimeMs: response.responseTimeMs,
            ductingRisk: ductingRisk,
            deviceId: _loraCompanion.connectedDeviceId,
          );
          await _dbService.insertSample(sample);
        }
      } else {
        final sample = Sample(
          id: _generateUniqueId(),
          position: latLng,
          timestamp: DateTime.now(),
          geohash: geohash,
          pingSuccess: false,
          responseTimeMs: pingResult.responseTimeMs,
          ductingRisk: ductingRisk,
          deviceId: _loraCompanion.connectedDeviceId,
        );
        await _dbService.insertSample(sample);
      }
      // Notify listeners
      _sampleSavedController.add(null);
    } catch (e) {
      await _logger.logError('Background Ping', e.toString());
      debugPrint('Error during background ping: $e');
      // Save failed ping result
      final sample = Sample(
        id: _generateUniqueId(),
        position: latLng,
        timestamp: DateTime.now(),
        path: null,
        geohash: geohash,
        rssi: null,
        snr: null,
        pingSuccess: false,
        deviceId: _loraCompanion.connectedDeviceId,
      );
      await _dbService.insertSample(sample);
      // Notify listeners
      _sampleSavedController.add(null);
    } finally {
      _pingInProgress = false;
    }
  }

  /// Stop tracking location
  Future<void> stopTracking() async {
    _isTracking = false;
    await _logger.logServiceEvent('stopTracking() called');

    // Stop ducting monitoring
    _ductingFetchTimer?.cancel();
    _ductingFetchTimer = null;

    // Stop time-based ping timer
    _timePingTimer?.cancel();
    _timePingTimer = null;
    // A finished session must not resurrect sampling on a later reconnect.
    _autoPingResumeOnReconnect = false;
    _carpeaterResumeOnReconnect = false;

    // Stop battery monitoring and deactivate battery saver
    _stopBatteryMonitoring();

    // Stop Carpeater mode
    _carpeaterNeighboursSubscription?.cancel();
    _carpeaterDiscoveryStartedSubscription?.cancel();
    _carpeaterService.stop();

    // Stop foreground service
    await FlutterForegroundTask.stopService();
    await _logger.logServiceEvent('Foreground service stopped');

    // Release the tracking reason; Always On may still require the wakelock.
    await ScreenWakeService.instance.setTrackingActive(false);
    await _logger.logPowerEvent('Tracking wakelock released');
    debugPrint('Tracking wakelock released');

    // Finalize session
    if (_currentSessionId != null && _sessionStartTime != null) {
      try {
        final endTime = DateTime.now();
        final counts = await _dbService.getSessionSampleCounts(
          _sessionStartTime!,
          endTime,
        );
        final session = WSession(
          id: _currentSessionId,
          startTime: _sessionStartTime!,
          endTime: endTime,
          distanceMeters: _totalDistanceMeters,
          sampleCount: counts['total'] ?? 0,
          pingCount: counts['pings'] ?? 0,
          successCount: counts['successes'] ?? 0,
        );
        await _dbService.updateSession(session);
        await _logger.logServiceEvent(
          'Session $_currentSessionId finalized: ${counts['total']} samples, ${counts['pings']} pings, ${counts['successes']} successes, ${_totalDistanceMeters.toStringAsFixed(0)}m',
        );
      } catch (e) {
        await _logger.logError('Session Finalize', e.toString());
      }
      _currentSessionId = null;
      _sessionStartTime = null;
    }

    WidgetService.updateTrackingStatus(false);
    await _logger.logServiceEvent('Tracking stopped successfully');
  }

  /// Check if currently tracking
  bool get isTracking => _isTracking;

  /// Human-readable reason for the most recent start failure.
  String? get lastStartError => _lastStartError;

  /// Get all recorded samples
  Future<List<Sample>> getAllSamples() async {
    return await _dbService.getAllSamples();
  }

  /// Get sample count
  Future<int> getSampleCount() async {
    return await _dbService.getSampleCount();
  }

  /// Clear all samples
  Future<void> clearAllSamples() async {
    await _dbService.deleteAllSamples();
  }

  /// Export samples as JSON
  Future<List<Map<String, dynamic>>> exportSamples() async {
    return await _dbService.exportSamples();
  }

  /// Import samples from JSON file (returns count of imported samples)
  Future<int> importSamples(List<Map<String, dynamic>> jsonData) async {
    return await _dbService.importSamples(jsonData);
  }

  /// Get the debug log file path
  String? get debugLogPath => _logger.logFilePath;

  /// Generate a unique ID for samples
  String _generateUniqueId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(999999).toString().padLeft(6, '0');
    return '${timestamp}_$random';
  }

  /// Start Carpeater discovery and subscribe to results
  Future<bool> startCarpeater() async {
    // Subscribe to discovery started (snapshot GPS position)
    _carpeaterDiscoveryStartedSubscription = _carpeaterService
        .discoveryStartedStream
        .listen((_) {
          _carpeaterDiscoveryPosition = _lastPosition;
          _pingEventController.add('pinging');
          _soundService.playPingSent();
        });

    // Subscribe to neighbour results
    _carpeaterNeighboursSubscription = _carpeaterService.neighboursStream
        .listen(_onCarpeaterNeighbours);

    final started = await _carpeaterService.start();
    if (!started) {
      _carpeaterDiscoveryStartedSubscription?.cancel();
      _carpeaterNeighboursSubscription?.cancel();
    }
    return started;
  }

  /// Restart Carpeater sampling after a lost device link was restored.
  Future<void> _restartCarpeaterAfterReconnect() async {
    if (!_isTracking || !_loraCompanion.isDeviceConnected) return;
    await _logger.logServiceEvent(
      'Carpeater restarting after device reconnection',
    );
    final started = await startCarpeater();
    if (!started) {
      await _logger.logServiceEvent(
        'Carpeater restart failed after device reconnection',
      );
    }
  }

  /// Handle Carpeater neighbour results — save as samples
  void _onCarpeaterNeighbours(List<Map<String, dynamic>> neighbours) async {
    final position = _carpeaterDiscoveryPosition ?? _lastPosition;
    if (position == null) return;

    final geohash = GeohashUtils.sampleKey(
      position.latitude,
      position.longitude,
    );

    // Filter out the target repeater itself — it always shows up as its own neighbour
    final targetId = _carpeaterService.targetRepeaterId?.toUpperCase();
    final filtered = neighbours.where((n) {
      final pubkey = n['pubkey'] as String?;
      if (pubkey == null || targetId == null) return true;
      final nId = pubkey.length >= 8
          ? pubkey.substring(0, 8).toUpperCase()
          : pubkey.toUpperCase();
      return !nId.startsWith(targetId);
    }).toList();

    // Also filter ignored repeater prefixes if set (comma-separated)
    final ignoredPrefixStr = _loraCompanion.ignoredRepeaterPrefix;
    final results = ignoredPrefixStr != null && ignoredPrefixStr.isNotEmpty
        ? filtered.where((n) {
            final pubkey = n['pubkey'] as String?;
            if (pubkey == null) return true;
            final nId = pubkey.length >= 8
                ? pubkey.substring(0, 8).toUpperCase()
                : pubkey.toUpperCase();
            final prefixes = ignoredPrefixStr
                .split(',')
                .map((s) => s.trim().toUpperCase())
                .where((s) => s.isNotEmpty);
            return !prefixes.any((prefix) => nId.startsWith(prefix));
          }).toList()
        : filtered;

    // Get ducting risk if enabled
    String? ductingRisk;
    if (_ductingEnabled) {
      ductingRisk = await _ductingService.getCurrentRisk(DateTime.now());
      if (ductingRisk == DuctingRisk.unknown) ductingRisk = null;
    }

    if (results.isEmpty) {
      // Dead zone — repeater heard nobody
      final sample = Sample(
        id: _generateUniqueId(),
        position: position,
        timestamp: DateTime.now(),
        path: _carpeaterService.targetRepeaterId,
        geohash: geohash,
        pingSuccess: false,
        ductingRisk: ductingRisk,
        deviceId: _loraCompanion.connectedDeviceId,
      );
      await _dbService.insertSample(sample);
      _pingEventController.add('failed');
      _soundService.playPingFailed();
    } else {
      // Save one sample per neighbour
      for (final n in results) {
        final pubkey = n['pubkey'] as String?;
        final snr = (n['snr'] as num?)?.toInt();
        final repeaterId = pubkey != null && pubkey.length >= 8
            ? pubkey.substring(0, 8)
            : pubkey;

        final sample = Sample(
          id: _generateUniqueId(),
          position: position,
          timestamp: DateTime.now(),
          path: repeaterId,
          geohash: geohash,
          snr: snr,
          pingSuccess: true,
          ductingRisk: ductingRisk,
          deviceId: _loraCompanion.connectedDeviceId,
        );
        await _dbService.insertSample(sample);
      }
      _pingEventController.add('success');
      // Use best SNR from filtered results for sound quality
      final bestSnr = results
          .map((n) => (n['snr'] as num?)?.toInt())
          .where((s) => s != null)
          .fold<int?>(null, (best, s) => best == null || s! > best ? s : best);
      _soundService.playForPingResult(success: true, snr: bestSnr);
    }

    _sampleSavedController.add(null);

    await _setNotificationText(
      (l10n) => results.isEmpty
          ? l10n.notificationCarpeaterNoNeighbours
          : l10n.notificationCarpeaterNeighboursFound(results.length),
    );
    Future.delayed(const Duration(seconds: 3), () {
      _updateCarpeaterNotification();
    });
  }

  /// Dispose resources
  void dispose() {
    _positionSearchRequested = false;
    _wifiPositioningEnabled = false;
    _positionWatchdogTimer?.cancel();
    _positionRestartTimer?.cancel();
    _wifiLocationTimer?.cancel();
    _locationServiceStatusSubscription?.cancel();
    _positionStreamGeneration++;
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
    stopTracking();
    _disconnectSubscription?.cancel();
    _connectedSubscription?.cancel();
    _logger.close();
    _currentPositionController.close();
    _positionSourceController.close();
    _courseController.close();
    _sampleSavedController.close();
    _pingEventController.close();
    _totalDistanceController.close();
    _speedController.close();
    _deadZoneController.close();
    _batterySaverController.close();
    _batteryStateSubscription?.cancel();
    _carpeaterNeighboursSubscription?.cancel();
    _carpeaterDiscoveryStartedSubscription?.cancel();
    _carpeaterService.dispose();
    _loraCompanion.dispose();
    _wifiLocationService.dispose();
  }
}
