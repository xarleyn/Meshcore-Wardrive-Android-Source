import 'package:latlong2/latlong.dart';

import '../../models/models.dart';
import 'map_settings_controller.dart';

/// Immutable values the settings pages read from the map screen.
///
/// Extends the persisted [MapSettingsSnapshot] with live screen values that
/// have no persisted counterpart (connection state, navigation data,
/// community coverage). The screen rebuilds it on every settings build so
/// pages always render current values.
class MapUiSnapshot extends MapSettingsSnapshot {
  const MapUiSnapshot({
    required super.showSamples,
    required super.showGpsSamples,
    required super.fixedSampleMarkerSizeEnabled,
    required super.sampleMarkerRadius,
    required super.showCoverage,
    required super.mapLodEnabled,
    required super.mapLodMinPrecision,
    required super.mapLodMaxPrecision,
    required super.sampleGeohashGrouping,
    required super.showEdges,
    required super.showRepeaters,
    required super.showPrivacyZones,
    required super.showGpsExclusionZones,
    required super.colorMode,
    required super.pingIntervalMeters,
    required super.coveragePrecision,
    required super.ignoredRepeaterPrefix,
    required super.includeOnlyRepeaters,
    required super.filterEdgesByWhitelist,
    required super.distanceUnit,
    required super.colorBlindMode,
    required super.discoveryTimeoutSeconds,
    required super.responseCollectionMode,
    required super.fuelUnit,
    required super.showRouteTrail,
    required super.showHeatmap,
    required super.showPredictionRings,
    required super.showRadioPosition,
    required super.beaconDbWifiPositioning,
    required super.locationQualitySettings,
    required super.showDucting,
    required super.mapThemeMode,
    required super.pingMode,
    required super.pingTimeInterval,
    required super.soundEnabled,
    required super.vibrationEnabled,
    required super.lockRotationNorth,
    required super.keepScreenOn,
    required super.currentLocationMarkerStyle,
    required super.showSuccessfulOnly,
    required super.optimisticDisplay,
    required super.compassCalibrationQuietUntil,
    required super.deadZoneAlertsEnabled,
    required super.newRepeaterAlertsEnabled,
    required super.linkLossAlertsEnabled,
    required super.batterySaverEnabled,
    required super.carpeaterEnabled,
    required super.carpeaterRepeaterId,
    required super.carpeaterPassword,
    required super.carpeaterInterval,
    required this.showCommunityCoverage,
    required this.communityCoverageAvailable,
    required this.sessionFiltered,
    required this.activeSourceFilter,
    required this.plannedMarkerCount,
    required this.privacyZoneCount,
    required this.loraConnected,
    required this.repeaterCount,
    required this.isTracking,
    required this.sessionDistanceMeters,
    required this.deviceName,
    required this.foundRepeaters,
    required this.samples,
    required this.currentPosition,
    required this.interfaceThemeDescription,
    required this.mapThemeDescription,
    required this.localePreferenceDescription,
  });

  /// Community coverage display toggle (screen-only, not persisted).
  final bool showCommunityCoverage;

  /// Whether cached community coverage exists on the device.
  final bool communityCoverageAvailable;

  /// Whether the map is currently filtered to a session or source.
  final bool sessionFiltered;

  final String? activeSourceFilter;

  final int plannedMarkerCount;
  final int privacyZoneCount;

  final bool loraConnected;
  final int repeaterCount;

  /// Whether a tracking session is running right now.
  final bool isTracking;

  /// Distance driven within the running session, in meters.
  final double sessionDistanceMeters;

  /// Device name as stored in settings.
  final Future<String?> deviceName;

  /// Repeater contacts known to the companion radio.
  final List<Repeater> foundRepeaters;

  final List<Sample> samples;
  final LatLng? currentPosition;

  final String interfaceThemeDescription;
  final String mapThemeDescription;
  final String localePreferenceDescription;
}
