import '../../models/location_quality_settings.dart';
import '../../services/location_service.dart';
import '../../services/screen_wake_service.dart';
import '../../services/settings_service.dart';
import '../../services/sound_service.dart';

class MapSettingsSnapshot {
  const MapSettingsSnapshot({
    required this.showSamples,
    required this.showGpsSamples,
    required this.showCoverage,
    required this.mapLodEnabled,
    required this.showEdges,
    required this.showRepeaters,
    required this.colorMode,
    required this.pingIntervalMeters,
    required this.coveragePrecision,
    required this.ignoredRepeaterPrefix,
    required this.includeOnlyRepeaters,
    required this.filterEdgesByWhitelist,
    required this.distanceUnit,
    required this.colorBlindMode,
    required this.discoveryTimeoutSeconds,
    required this.thoroughResponseCollection,
    required this.fuelUnit,
    required this.showRouteTrail,
    required this.showHeatmap,
    required this.showPredictionRings,
    required this.showRadioPosition,
    required this.beaconDbWifiPositioning,
    required this.locationQualitySettings,
    required this.showDucting,
    required this.mapThemeMode,
    required this.pingMode,
    required this.pingTimeInterval,
    required this.soundEnabled,
    required this.vibrationEnabled,
    required this.lockRotationNorth,
    required this.keepScreenOn,
    required this.currentLocationMarkerStyle,
    required this.showSuccessfulOnly,
    required this.optimisticDisplay,
    required this.compassCalibrationQuietUntil,
    required this.deadZoneAlertsEnabled,
    required this.newRepeaterAlertsEnabled,
    required this.linkLossAlertsEnabled,
    required this.batterySaverEnabled,
    required this.carpeaterEnabled,
    required this.carpeaterRepeaterId,
    required this.carpeaterPassword,
    required this.carpeaterInterval,
  });

  final bool showSamples;
  final bool showGpsSamples;
  final bool showCoverage;
  final bool mapLodEnabled;
  final bool showEdges;
  final bool showRepeaters;
  final String colorMode;
  final double pingIntervalMeters;
  final int coveragePrecision;
  final String? ignoredRepeaterPrefix;
  final String? includeOnlyRepeaters;
  final bool filterEdgesByWhitelist;
  final String distanceUnit;
  final String colorBlindMode;
  final int discoveryTimeoutSeconds;
  final bool thoroughResponseCollection;
  final String fuelUnit;
  final bool showRouteTrail;
  final bool showHeatmap;
  final bool showPredictionRings;
  final bool showRadioPosition;
  final bool beaconDbWifiPositioning;
  final LocationQualitySettings locationQualitySettings;
  final bool showDucting;
  final MapThemeMode mapThemeMode;
  final String pingMode;
  final int pingTimeInterval;
  final bool soundEnabled;
  final bool vibrationEnabled;
  final bool lockRotationNorth;
  final bool keepScreenOn;
  final CurrentLocationMarkerStyle currentLocationMarkerStyle;
  final bool showSuccessfulOnly;
  final bool optimisticDisplay;
  final DateTime? compassCalibrationQuietUntil;
  final bool deadZoneAlertsEnabled;
  final bool newRepeaterAlertsEnabled;
  final bool linkLossAlertsEnabled;
  final bool batterySaverEnabled;
  final bool carpeaterEnabled;
  final String? carpeaterRepeaterId;
  final String? carpeaterPassword;
  final int carpeaterInterval;
}

abstract interface class MapSettingsRuntime {
  Future<void> apply(MapSettingsSnapshot settings);
}

class DefaultMapSettingsRuntime implements MapSettingsRuntime {
  DefaultMapSettingsRuntime({
    required LocationService locationService,
    SoundService? soundService,
    ScreenWakeService? screenWakeService,
  }) : _locationService = locationService,
       _soundService = soundService ?? SoundService(),
       _screenWakeService = screenWakeService ?? ScreenWakeService.instance;

  final LocationService _locationService;
  final SoundService _soundService;
  final ScreenWakeService _screenWakeService;

  @override
  Future<void> apply(MapSettingsSnapshot settings) async {
    _soundService.setEnabled(settings.soundEnabled);
    _soundService.setVibrationEnabled(settings.vibrationEnabled);
    _locationService.setLinkLossAlertsEnabled(settings.linkLossAlertsEnabled);
    _locationService.setPingMode(settings.pingMode);
    _locationService.setPingTimeInterval(settings.pingTimeInterval);
    _locationService.setBatterySaverEnabled(settings.batterySaverEnabled);
    _locationService.setCarpeaterMode(settings.carpeaterEnabled);
    _locationService.setPingInterval(settings.pingIntervalMeters);
    _locationService.setWifiPositioningEnabled(
      settings.beaconDbWifiPositioning,
    );
    _locationService.setLocationQualitySettings(
      settings.locationQualitySettings,
    );
    _locationService.loraCompanion.setIgnoredRepeaterPrefix(
      settings.ignoredRepeaterPrefix,
    );
    await _screenWakeService.setAlwaysOn(settings.keepScreenOn);
  }
}

class MapSettingsController {
  MapSettingsController({
    required SettingsService settingsService,
    required MapSettingsRuntime runtime,
  }) : _settingsService = settingsService,
       _runtime = runtime;

  final SettingsService _settingsService;
  final MapSettingsRuntime _runtime;

  Future<MapSettingsSnapshot> loadAndApply() async {
    final settings = MapSettingsSnapshot(
      showSamples: await _settingsService.getShowSamples(),
      showGpsSamples: await _settingsService.getShowGpsSamples(),
      showCoverage: await _settingsService.getShowCoverage(),
      mapLodEnabled: await _settingsService.getMapLodEnabled(),
      showEdges: await _settingsService.getShowEdges(),
      showRepeaters: await _settingsService.getShowRepeaters(),
      colorMode: await _settingsService.getColorMode(),
      pingIntervalMeters: await _settingsService.getPingInterval(),
      coveragePrecision: await _settingsService.getCoveragePrecision(),
      ignoredRepeaterPrefix: await _settingsService.getIgnoredRepeaterPrefix(),
      includeOnlyRepeaters: await _settingsService.getIncludeOnlyRepeaters(),
      filterEdgesByWhitelist: await _settingsService
          .getFilterEdgesByWhitelist(),
      distanceUnit: await _settingsService.getDistanceUnit(),
      colorBlindMode: await _settingsService.getColorBlindMode(),
      discoveryTimeoutSeconds: await _settingsService.getDiscoveryTimeout(),
      thoroughResponseCollection: await _settingsService
          .getThoroughResponseCollection(),
      fuelUnit: await _settingsService.getFuelUnit(),
      showRouteTrail: await _settingsService.getShowRouteTrail(),
      showHeatmap: await _settingsService.getShowHeatmap(),
      showPredictionRings: await _settingsService.getShowPredictionRings(),
      showRadioPosition: await _settingsService.getShowRadioPosition(),
      beaconDbWifiPositioning: await _settingsService
          .getBeaconDbWifiPositioning(),
      locationQualitySettings: await _settingsService
          .getLocationQualitySettings(),
      showDucting: await _settingsService.getShowDucting(),
      mapThemeMode: await _settingsService.getMapThemeMode(),
      pingMode: await _settingsService.getPingMode(),
      pingTimeInterval: await _settingsService.getPingTimeInterval(),
      soundEnabled: await _settingsService.getSoundEnabled(),
      vibrationEnabled: await _settingsService.getVibrationEnabled(),
      lockRotationNorth: await _settingsService.getLockRotationNorth(),
      keepScreenOn: await _settingsService.getKeepScreenOn(),
      currentLocationMarkerStyle: await _settingsService
          .getCurrentLocationMarkerStyle(),
      showSuccessfulOnly: await _settingsService.getShowSuccessfulOnly(),
      optimisticDisplay: await _settingsService.getOptimisticDisplay(),
      compassCalibrationQuietUntil: await _settingsService
          .getCompassCalibrationQuietUntil(),
      deadZoneAlertsEnabled: await _settingsService.getDeadZoneAlertsEnabled(),
      newRepeaterAlertsEnabled: await _settingsService
          .getNewRepeaterAlertsEnabled(),
      linkLossAlertsEnabled: await _settingsService.getLinkLossAlertsEnabled(),
      batterySaverEnabled: await _settingsService.getBatterySaverEnabled(),
      carpeaterEnabled: await _settingsService.getCarpeaterEnabled(),
      carpeaterRepeaterId: await _settingsService.getCarpeaterRepeaterId(),
      carpeaterPassword: await _settingsService.getCarpeaterPassword(),
      carpeaterInterval: await _settingsService.getCarpeaterInterval(),
    );
    await _runtime.apply(settings);
    return settings;
  }
}
