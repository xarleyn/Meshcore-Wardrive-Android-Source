import '../../services/settings_service.dart';
import '../settings/sections/map_display_section.dart';
import '../settings/sections/statistics_section.dart';

/// Commands the settings pages run against the map screen.
///
/// Implemented by [MapUiController]. Methods that start with a synchronous
/// state update expose their prefix synchronously: pages call them without
/// awaiting and refresh their local page state immediately, while the
/// asynchronous persistence tail continues in the background.
abstract interface class MapUiActions {
  // Map display
  Future<void> setMapDisplaySetting(MapDisplaySetting setting, bool value);

  /// Applies the LOD precision bounds with symmetric clamping.
  void setMapLodPrecision({int? min, int? max});

  Future<void> persistMapLodMin(int value);
  Future<void> persistMapLodMax(int value);
  void setSampleMarkerRadius(double value);
  Future<void> persistSampleMarkerRadius(double value);
  Future<void> clearCommunityCoverage();

  // Location
  Future<void> setBeaconDbPositioning(bool value);
  Future<void> showLocationQuality();
  Future<void> setShowRadioPosition(bool value);
  Future<void> setShowDucting(bool value);

  // Discovery
  Future<void> setDiscoveryTimeout(int seconds);
  Future<void> setResponseCollectionMode(String mode);
  Future<void> editIgnoredRepeaters();
  Future<void> editIncludedRepeaters();
  Future<void> setFilterEdgesByWhitelist(bool value);
  Future<void> setPingMode(String mode);
  Future<void> editPingInterval();
  Future<void> setPingTimeInterval(int minutes);
  Future<void> editCoverageResolution();

  // Feedback
  Future<void> setSoundEnabled(bool value);
  Future<void> setVibrationEnabled(bool value);
  Future<void> setDeadZoneAlerts(bool value);
  Future<void> setNewRepeaterAlerts(bool value);
  Future<void> setLinkLossAlerts(bool value);

  // Carpeater
  Future<void> setCarpeaterEnabled(bool value);
  Future<void> setCarpeaterRepeaterId(String? id);
  Future<void> setCarpeaterPassword(String? password);
  Future<void> setCarpeaterInterval(int minutes);

  // App & device
  Future<void> setDeviceName(String? name);
  Future<void> setKeepScreenOn(bool value);
  Future<void> setBatterySaverEnabled(bool value);
  Future<void> setLockRotationNorth(bool value);
  Future<void> setCurrentLocationMarkerStyle(CurrentLocationMarkerStyle style);
  Future<void> calibrateCompass();
  Future<void> selectInterfaceTheme();
  Future<void> selectMapTheme();
  Future<void> selectLanguage();
  Future<void> scanForRepeaters();
  Future<void> refreshContacts();
  Future<void> setColorMode(String mode);
  Future<void> setDistanceUnit(String unit);
  Future<void> setFuelUnit(String unit);
  Future<void> setColorBlindMode(String mode);

  // Statistics
  Future<DrivingStatisticsValues> loadDrivingStatistics();
  Future<void> resetTotalDistance();
  Future<void> setVehicleMpg(double? mpg);
  Future<void> setGasPrice(double price);

  // Data management
  void openAnalytics();
  void openSessionHistory();
  Future<void> downloadCommunityCoverage();
  Future<void> clearSessionFilter();
  Future<void> exportData();
  Future<void> importData();
  Future<void> shareCoverageMap();
  void showRepeaterFilterPicker();
  Future<void> clearRepeaterFilter();
  Future<void> selectSourceFilter();
  Future<void> clearSourceFilter();
  Future<void> clearTileCache();
  Future<void> findCoverageGaps();

  /// Enables delete mode; callers close the settings pages first.
  void enableDeleteMode();
  Future<void> clearPlannedMarkers();

  /// Opens the add-privacy-zone flow centered on the map's current focus.
  Future<void> addPrivacyZone();
  Future<void> clearPrivacyZones();
  Future<void> clearMapData();
  Future<void> downloadOfflineTiles();

  // Backup
  Future<void> exportSettings();
  Future<void> importSettings();
  Future<void> exportDatabase();
  Future<void> importDatabase();

  // Online map
  Future<void> uploadSamples();
  Future<void> manageUploadSites();

  // System
  void openDebugDiagnostics();
  Future<void> checkForUpdates();
  Future<void> openGitHub();
}
