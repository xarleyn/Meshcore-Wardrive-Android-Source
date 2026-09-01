import '../../models/location_quality_settings.dart';
import '../../services/location_service.dart';
import '../../services/screen_wake_service.dart';
import '../../services/settings_service.dart';
import '../../services/sound_service.dart';

class MapSettingsSnapshot {
  const MapSettingsSnapshot({
    required this.showSamples,
    required this.showGpsSamples,
    required this.fixedSampleMarkerSizeEnabled,
    required this.sampleMarkerRadius,
    required this.showCoverage,
    required this.mapLodEnabled,
    required this.sampleGeohashGrouping,
    required this.showEdges,
    required this.showRepeaters,
    required this.showPrivacyZones,
    required this.showGpsExclusionZones,
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
  final bool fixedSampleMarkerSizeEnabled;
  final double sampleMarkerRadius;
  final bool showCoverage;
  final bool mapLodEnabled;
  final bool sampleGeohashGrouping;
  final bool showEdges;
  final bool showRepeaters;
  final bool showPrivacyZones;
  final bool showGpsExclusionZones;
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
    required this.locationService,
    SoundService? soundService,
    ScreenWakeService? screenWakeService,
  }) : _soundService = soundService ?? SoundService(),
       _screenWakeService = screenWakeService ?? ScreenWakeService.instance;

  final LocationService locationService;
  final SoundService _soundService;
  final ScreenWakeService _screenWakeService;

  @override
  Future<void> apply(MapSettingsSnapshot settings) async {
    _soundService.setEnabled(settings.soundEnabled);
    _soundService.setVibrationEnabled(settings.vibrationEnabled);
    locationService.setLinkLossAlertsEnabled(settings.linkLossAlertsEnabled);
    locationService.setPingMode(settings.pingMode);
    locationService.setPingTimeInterval(settings.pingTimeInterval);
    locationService.setBatterySaverEnabled(settings.batterySaverEnabled);
    locationService.setCarpeaterMode(settings.carpeaterEnabled);
    locationService.setPingInterval(settings.pingIntervalMeters);
    locationService.setWifiPositioningEnabled(settings.beaconDbWifiPositioning);
    locationService.setLocationQualitySettings(
      settings.locationQualitySettings,
    );
    locationService.loraCompanion.setIgnoredRepeaterPrefix(
      settings.ignoredRepeaterPrefix,
    );
    await _screenWakeService.setAlwaysOn(settings.keepScreenOn);
  }
}

class MapSettingsController {
  MapSettingsController({required this.settingsService, required this.runtime});

  final SettingsService settingsService;
  final MapSettingsRuntime runtime;

  Future<MapSettingsSnapshot> loadAndApply() async {
    final settings = MapSettingsSnapshot(
      showSamples: await settingsService.getShowSamples(),
      showGpsSamples: await settingsService.getShowGpsSamples(),
      fixedSampleMarkerSizeEnabled: await settingsService
          .getFixedSampleMarkerSizeEnabled(),
      sampleMarkerRadius: await settingsService.getSampleMarkerRadius(),
      showCoverage: await settingsService.getShowCoverage(),
      mapLodEnabled: await settingsService.getMapLodEnabled(),
      sampleGeohashGrouping: await settingsService.getSampleGeohashGrouping(),
      showEdges: await settingsService.getShowEdges(),
      showRepeaters: await settingsService.getShowRepeaters(),
      showPrivacyZones: await settingsService.getShowPrivacyZones(),
      showGpsExclusionZones: await settingsService.getShowGpsExclusionZones(),
      colorMode: await settingsService.getColorMode(),
      pingIntervalMeters: await settingsService.getPingInterval(),
      coveragePrecision: await settingsService.getCoveragePrecision(),
      ignoredRepeaterPrefix: await settingsService.getIgnoredRepeaterPrefix(),
      includeOnlyRepeaters: await settingsService.getIncludeOnlyRepeaters(),
      filterEdgesByWhitelist: await settingsService.getFilterEdgesByWhitelist(),
      distanceUnit: await settingsService.getDistanceUnit(),
      colorBlindMode: await settingsService.getColorBlindMode(),
      discoveryTimeoutSeconds: await settingsService.getDiscoveryTimeout(),
      thoroughResponseCollection: await settingsService
          .getThoroughResponseCollection(),
      fuelUnit: await settingsService.getFuelUnit(),
      showRouteTrail: await settingsService.getShowRouteTrail(),
      showHeatmap: await settingsService.getShowHeatmap(),
      showPredictionRings: await settingsService.getShowPredictionRings(),
      showRadioPosition: await settingsService.getShowRadioPosition(),
      beaconDbWifiPositioning: await settingsService
          .getBeaconDbWifiPositioning(),
      locationQualitySettings: await settingsService
          .getLocationQualitySettings(),
      showDucting: await settingsService.getShowDucting(),
      mapThemeMode: await settingsService.getMapThemeMode(),
      pingMode: await settingsService.getPingMode(),
      pingTimeInterval: await settingsService.getPingTimeInterval(),
      soundEnabled: await settingsService.getSoundEnabled(),
      vibrationEnabled: await settingsService.getVibrationEnabled(),
      lockRotationNorth: await settingsService.getLockRotationNorth(),
      keepScreenOn: await settingsService.getKeepScreenOn(),
      currentLocationMarkerStyle: await settingsService
          .getCurrentLocationMarkerStyle(),
      showSuccessfulOnly: await settingsService.getShowSuccessfulOnly(),
      optimisticDisplay: await settingsService.getOptimisticDisplay(),
      compassCalibrationQuietUntil: await settingsService
          .getCompassCalibrationQuietUntil(),
      deadZoneAlertsEnabled: await settingsService.getDeadZoneAlertsEnabled(),
      newRepeaterAlertsEnabled: await settingsService
          .getNewRepeaterAlertsEnabled(),
      linkLossAlertsEnabled: await settingsService.getLinkLossAlertsEnabled(),
      batterySaverEnabled: await settingsService.getBatterySaverEnabled(),
      carpeaterEnabled: await settingsService.getCarpeaterEnabled(),
      carpeaterRepeaterId: await settingsService.getCarpeaterRepeaterId(),
      carpeaterPassword: await settingsService.getCarpeaterPassword(),
      carpeaterInterval: await settingsService.getCarpeaterInterval(),
    );
    await runtime.apply(settings);
    return settings;
  }
}
