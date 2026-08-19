// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get language => 'Language';

  @override
  String get languageSystem => 'System default';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageRussian => 'Русский';

  @override
  String get languagePickerTitle => 'Choose language';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsScrollToTop => 'Scroll to top';

  @override
  String get settingsScrollToBottom => 'Scroll to bottom';

  @override
  String get settingsCancel => 'Cancel';

  @override
  String get settingsSave => 'Save';

  @override
  String get settingsClear => 'Clear';

  @override
  String get settingsUpload => 'Upload';

  @override
  String get settingsReset => 'Reset';

  @override
  String get settingsNotSet => 'Not set';

  @override
  String get settingsNone => 'None';

  @override
  String get settingsUnknown => 'Unknown';

  @override
  String get settingsEnterNumberGreaterThanZero =>
      'Enter a number greater than zero';

  @override
  String get settingsSectionMapDisplay => 'Map display';

  @override
  String get settingsSectionLocation => 'Location & positioning';

  @override
  String get settingsSectionFeedback => 'Feedback & alerts';

  @override
  String get settingsSectionCarpeater => 'Carpeater mode (Beta)';

  @override
  String get settingsSectionAppDevice => 'App & device';

  @override
  String get settingsSectionDiscovery => 'Discovery & sampling';

  @override
  String get settingsSectionStatistics => 'Statistics';

  @override
  String get settingsSectionDataManagement => 'Data management';

  @override
  String get settingsSectionBackup => 'Settings backup';

  @override
  String get settingsSectionDiagnostics => 'Diagnostics';

  @override
  String get settingsSectionOnlineMap => 'Online map';

  @override
  String get settingsSectionAbout => 'About';

  @override
  String get settingsSectionThresholds => 'Thresholds';

  @override
  String get settingsSectionImpossibleZones => 'Impossible Zones';

  @override
  String get settingsShowCoverageBoxes => 'Show Coverage Boxes';

  @override
  String get settingsSimplifyMapAtLowZoom => 'Simplify map at low zoom';

  @override
  String get settingsSimplifyMapAtLowZoomSubtitle =>
      'Group coverage and samples by geohash while zoomed out';

  @override
  String get settingsShowSamples => 'Show Samples';

  @override
  String get settingsShowEdges => 'Show Edges';

  @override
  String get settingsShowRepeaters => 'Show Repeaters';

  @override
  String get settingsShowGpsSamples => 'Show GPS Samples';

  @override
  String get settingsShowGpsSamplesSubtitle => 'Show blue GPS-only markers';

  @override
  String get settingsShowSuccessfulPingsOnly => 'Show Successful Pings Only';

  @override
  String get settingsShowSuccessfulPingsOnlySubtitle =>
      'Hide failed pings and GPS-only samples';

  @override
  String get settingsShowRouteTrail => 'Show Route Trail';

  @override
  String get settingsShowRouteTrailSubtitle => 'Draw driven path on map';

  @override
  String get settingsCommunityCoverage => 'Community Coverage';

  @override
  String get settingsCommunityCoverageDownloaded =>
      'Show downloaded coverage from web map';

  @override
  String get settingsCommunityCoverageNeedDownload =>
      'Download first from Data Management';

  @override
  String get settingsClearDownloadedCoverageTooltip =>
      'Clear downloaded coverage';

  @override
  String get settingsCommunityCoverageCleared => 'Community coverage cleared';

  @override
  String get settingsShowHeatmap => 'Show Heatmap';

  @override
  String get settingsShowHeatmapSubtitle =>
      'Heat gradient overlay of ping activity';

  @override
  String get settingsShowPredictionRings => 'Show Prediction Rings';

  @override
  String get settingsShowPredictionRingsSubtitle =>
      'Estimated repeater coverage radius';

  @override
  String get settingsBeaconDbWifi => 'beaconDB Wi-Fi Positioning';

  @override
  String get settingsBeaconDbWifiSubtitle =>
      'Prefer Wi-Fi location; sends nearby BSSIDs and signal levels to beaconDB. Cyan marker means Wi-Fi is active.';

  @override
  String get settingsBeaconDbEnabledSnack =>
      'beaconDB enabled: nearby BSSIDs will be shared';

  @override
  String get settingsLocationQualityFilters => 'Location Quality Filters';

  @override
  String get settingsLocationQualityFiltersSubtitle =>
      'Accuracy, implausible movement, and impossible locations';

  @override
  String get settingsShowApproximatePosition => 'Show Approximate Position';

  @override
  String get settingsShowApproximatePositionSubtitle =>
      'Display the grey radio-position estimate';

  @override
  String get settingsDuctingForecast => 'Ducting Forecast';

  @override
  String get settingsDuctingForecastSubtitle =>
      '6-day tropospheric ducting maps';

  @override
  String get settingsAtmosphericDucting => 'Atmospheric Ducting';

  @override
  String get settingsAtmosphericDuctingSubtitle =>
      'Monitor ducting conditions (needs internet)';

  @override
  String get settingsSoundFeedback => 'Sound Feedback';

  @override
  String get settingsSoundFeedbackSubtitle => 'Play tones on ping results';

  @override
  String get settingsVibrationFeedback => 'Vibration Feedback';

  @override
  String get settingsVibrationFeedbackSubtitle =>
      'Haptic feedback on ping results';

  @override
  String get settingsDeadZoneAlerts => 'Dead Zone Alerts';

  @override
  String get settingsDeadZoneAlertsSubtitle =>
      'Notify when entering a known dead zone';

  @override
  String get settingsNewRepeaterAlerts => 'New Repeater Alerts';

  @override
  String get settingsNewRepeaterAlertsSubtitle =>
      'Notify when a never-before-seen repeater is discovered';

  @override
  String get settingsEnableCarpeaterMode => 'Enable Carpeater Mode';

  @override
  String get settingsCarpeaterEnabledSubtitle => 'Using repeater for discovery';

  @override
  String get settingsCarpeaterDisabledSubtitle =>
      'Use a repeater to discover neighbors\nRequires v1.14+ firmware on all repeaters';

  @override
  String get settingsTargetRepeater => 'Target Repeater';

  @override
  String get settingsRepeaterIdPrefix => 'Repeater ID Prefix';

  @override
  String get settingsRepeaterIdHint => 'e.g., BAD5DC49';

  @override
  String get settingsAdminPassword => 'Admin Password';

  @override
  String get settingsPassword => 'Password';

  @override
  String get settingsRepeaterAdminPasswordHint => 'Repeater admin password';

  @override
  String get settingsCycleInterval => 'Cycle Interval';

  @override
  String get settingsCycleIntervalSubtitle => 'Time between discovery cycles';

  @override
  String get settingsDeviceName => 'Device Name';

  @override
  String get settingsDeviceNameNotSet =>
      'Not set — used for multi-device wardrive';

  @override
  String get settingsDeviceNameLabel => 'Name';

  @override
  String get settingsDeviceNameHint => 'e.g., Chuck-Pixel';

  @override
  String get settingsKeepScreenOn => 'Keep Screen On';

  @override
  String get settingsKeepScreenOnSubtitle =>
      'Prevent the screen from sleeping while the app is open';

  @override
  String get settingsBatterySaver => 'Battery Saver';

  @override
  String get settingsBatterySaverSubtitle =>
      'Auto-double ping interval when battery ≤20%';

  @override
  String get settingsLockMapRotation => 'Lock Map Rotation';

  @override
  String get settingsLockMapRotationSubtitle => 'Prevent map rotation';

  @override
  String get settingsCurrentLocationMarker => 'Current Location Marker';

  @override
  String get settingsCurrentLocationMarkerSubtitle =>
      'The direction arrow follows the phone compass';

  @override
  String get settingsMarkerCircle => 'Circle';

  @override
  String get settingsMarkerDirectionArrow => 'Direction arrow';

  @override
  String get settingsCalibrateCompass => 'Calibrate Compass';

  @override
  String get settingsCalibrateCompassSubtitle =>
      'Draw a figure-8 in the air if the heading looks wrong';

  @override
  String get settingsInterfaceTheme => 'Interface Theme';

  @override
  String get settingsMapTheme => 'Map Theme';

  @override
  String get settingsScanForRepeaters => 'Scan for Repeaters';

  @override
  String get settingsScanFindNearby => 'Find nearby LoRa nodes';

  @override
  String settingsRepeatersFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count repeaters found',
      one: '$count repeater found',
    );
    return '$_temp0';
  }

  @override
  String get settingsRefreshContactList => 'Refresh Contact List';

  @override
  String get settingsRefreshContactListSubtitle =>
      'Update repeater names from device';

  @override
  String get settingsColorMode => 'Color Mode';

  @override
  String get settingsColorModeQuality => 'Quality';

  @override
  String get settingsColorModeAge => 'Age';

  @override
  String get settingsColorModeRedundancy => 'Redundancy';

  @override
  String get settingsDistanceUnit => 'Distance Unit';

  @override
  String get settingsMiles => 'Miles';

  @override
  String get settingsKilometers => 'Kilometers';

  @override
  String get settingsFuelUnit => 'Fuel Unit';

  @override
  String get settingsFuelUnitImperial => 'MPG / Gallons';

  @override
  String get settingsFuelUnitMetric => 'L/100km / Litres';

  @override
  String get settingsColorBlindMode => 'Color Blind Mode';

  @override
  String get settingsColorBlindNormal => 'Normal';

  @override
  String get settingsColorBlindDeuteranopia => 'Deuteranopia';

  @override
  String get settingsColorBlindProtanopia => 'Protanopia';

  @override
  String get settingsColorBlindTritanopia => 'Tritanopia';

  @override
  String get settingsDiscoveryTimeout => 'Discovery Timeout';

  @override
  String get settingsDiscoveryTimeoutSubtitle =>
      'How long to wait for repeater responses';

  @override
  String get settingsThoroughResponseCollection =>
      'Thorough Response Collection';

  @override
  String get settingsThoroughOn =>
      'Thorough: collect responses until the discovery timeout';

  @override
  String get settingsThoroughOff =>
      'Fast: finish 3 seconds after the first response';

  @override
  String get settingsIgnoreRepeaters => 'Ignore Repeaters';

  @override
  String settingsIgnoringPrefix(String prefix) {
    return 'Ignoring: $prefix';
  }

  @override
  String get settingsNotFiltering => 'Not filtering';

  @override
  String get settingsIncludeOnlyRepeaters => 'Include Only Repeaters';

  @override
  String settingsWhitelistPrefix(String prefixes) {
    return 'Whitelist: $prefixes';
  }

  @override
  String get settingsShowAllRepeaters => 'Show all repeaters';

  @override
  String get settingsApplyWhitelistToEdges => 'Apply Whitelist to Edges';

  @override
  String get settingsApplyWhitelistToEdgesSubtitle =>
      'Only show edges for whitelisted repeaters';

  @override
  String get settingsPingMode => 'Ping Mode';

  @override
  String get settingsPingModeDistance => 'Distance';

  @override
  String get settingsPingModeTime => 'Time';

  @override
  String get settingsPingModeBoth => 'Both';

  @override
  String get settingsPingDistance => 'Ping Distance';

  @override
  String get settingsPingTimeInterval => 'Ping Time Interval';

  @override
  String get settingsCoverageResolution => 'Coverage Resolution';

  @override
  String get settingsPingInterval => 'Ping Interval';

  @override
  String get settingsPingIntervalPrompt => 'How often should pings be sent?';

  @override
  String get settingsPingFrequent => 'Frequent';

  @override
  String get settingsPingFrequentSubtitle => 'Every 50 meters';

  @override
  String get settingsPingNormal => 'Normal';

  @override
  String get settingsPingNormalSubtitle => 'Every 200 meters (~0.12 miles)';

  @override
  String get settingsPingSparse => 'Sparse';

  @override
  String get settingsPingSparseSubtitle => 'Every 0.5 miles (805 meters)';

  @override
  String get settingsPingVerySparse => 'Very Sparse';

  @override
  String get settingsPingVerySparseSubtitle => 'Every 1 mile (1609 meters)';

  @override
  String settingsPingIntervalSet(String description) {
    return 'Ping interval: $description';
  }

  @override
  String settingsPingIntervalMetersFrequent(int meters) {
    return '$meters meters (frequent)';
  }

  @override
  String settingsPingIntervalMeters(int meters) {
    return '$meters meters';
  }

  @override
  String settingsPingIntervalMiles(String miles, int meters) {
    return '$miles miles (${meters}m)';
  }

  @override
  String get settingsCoverageResolutionPrompt =>
      'Choose the size of coverage squares:';

  @override
  String get settingsCoverageRegional => 'Regional';

  @override
  String get settingsCoverageRegionalSubtitle => '~20km squares (precision 4)';

  @override
  String get settingsCoverageCity => 'City-level';

  @override
  String get settingsCoverageCitySubtitle => '~5km squares (precision 5)';

  @override
  String get settingsCoverageNeighborhood => 'Neighborhood';

  @override
  String get settingsCoverageNeighborhoodSubtitle =>
      '~1.2km squares (precision 6, default)';

  @override
  String get settingsCoverageStreet => 'Street-level';

  @override
  String get settingsCoverageStreetSubtitle => '~153m squares (precision 7)';

  @override
  String get settingsCoverageBuilding => 'Building-level';

  @override
  String get settingsCoverageBuildingSubtitle =>
      '~38m squares (precision 8, detailed)';

  @override
  String get settingsCoverageRegionalDesc => 'Regional (~20km squares)';

  @override
  String get settingsCoverageCityDesc => 'City-level (~5km squares)';

  @override
  String get settingsCoverageNeighborhoodDesc =>
      'Neighborhood (~1.2km squares)';

  @override
  String get settingsCoverageStreetDesc => 'Street-level (~153m squares)';

  @override
  String get settingsCoverageBuildingDesc => 'Building-level (~38m squares)';

  @override
  String settingsCoverageResolutionSet(String description) {
    return 'Coverage resolution: $description';
  }

  @override
  String get settingsRepeaterPrefixes => 'Repeater Prefixes';

  @override
  String get settingsIgnoreRepeaterHint => 'e.g., 7E, A4F, BAD5';

  @override
  String get settingsIgnoreRepeaterDescription =>
      'Filter out responses from your mobile repeater(s) to avoid false coverage. Enter repeater prefixes separated by commas:';

  @override
  String get settingsRepeaterPrefixUpdated => 'Repeater prefix updated';

  @override
  String get settingsIncludeOnlyHint => 'e.g., 7E3A, A4F2, 8B';

  @override
  String get settingsIncludeOnlyDescription =>
      'Show only samples from specific repeaters (whitelist). Enter repeater prefixes separated by commas:';

  @override
  String get settingsRepeaterWhitelistUpdated => 'Repeater whitelist updated';

  @override
  String get settingsLocationQualityResetSnack =>
      'Location quality filters reset';

  @override
  String get settingsMaxHorizontalError => 'Maximum Horizontal Error';

  @override
  String get settingsMaxHorizontalErrorSubtitle =>
      'Reject positions with worse reported accuracy';

  @override
  String get settingsMaxHorizontalErrorDescription =>
      'Positions whose reported horizontal error is larger than this value are ignored.';

  @override
  String get settingsAirborneAltitude => 'Airborne Altitude';

  @override
  String get settingsAirborneAltitudeSubtitle =>
      'Altitude used together with airborne speed';

  @override
  String get settingsAirborneAltitudeDescription =>
      'At or above this altitude, a position is ignored only when it also exceeds the airborne speed.';

  @override
  String get settingsAirborneSpeed => 'Airborne Speed';

  @override
  String get settingsAirborneSpeedSubtitle =>
      'Speed used together with airborne altitude';

  @override
  String get settingsAirborneSpeedDescription =>
      'At or above this speed, a high-altitude position is treated as a probable flight.';

  @override
  String get settingsMaxWardriveSpeed => 'Maximum Wardrive Speed';

  @override
  String get settingsMaxWardriveSpeedSubtitle =>
      'Reject positions moving faster than this';

  @override
  String get settingsMaxWardriveSpeedDescription =>
      'Positions moving at or above this speed are ignored as implausible wardrive data.';

  @override
  String get settingsRestoreDefaults => 'Restore Defaults';

  @override
  String get settingsImpossibleZonesBlurb =>
      'Places you cannot physically be. GPS inside a zone is discarded and the last valid position is kept. Zones are not shown on the map.';

  @override
  String get settingsAddImpossibleZone => 'Add Impossible Zone';

  @override
  String get settingsImpossibleZoneEmptySubtitle =>
      'Uses current position or map center';

  @override
  String settingsImpossibleZoneCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count zones',
      one: '$count zone',
    );
    return '$_temp0';
  }

  @override
  String get settingsUnnamedZone => 'Unnamed zone';

  @override
  String get settingsDeleteZoneTooltip => 'Delete zone';

  @override
  String get settingsClearImpossibleZones => 'Clear Impossible Zones';

  @override
  String settingsRemoveAllZones(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Remove all $count zones',
      one: 'Remove all $count zone',
    );
    return '$_temp0';
  }

  @override
  String get settingsClearImpossibleZonesConfirm =>
      'Remove all impossible zones? GPS inside those areas will no longer be discarded.';

  @override
  String settingsAddImpossibleZoneCenter(String lat, String lon) {
    return 'Center: $lat, $lon';
  }

  @override
  String get settingsAddImpossibleZoneBlurb =>
      'GPS inside this area is treated as invalid and discarded.';

  @override
  String get settingsLabelOptional => 'Label (optional)';

  @override
  String get settingsLabelHintAirport => 'e.g., Airport';

  @override
  String get settingsRadius => 'Radius:';

  @override
  String get settingsRadius500m => '500m (~0.3 mi)';

  @override
  String get settingsRadius1km => '1 km (~0.6 mi)';

  @override
  String get settingsRadius2km => '2 km (~1.2 mi)';

  @override
  String get settingsRadius5km => '5 km (~3 mi)';

  @override
  String get settingsAddZone => 'Add Zone';

  @override
  String get settingsImpossibleZoneAdded => 'Impossible zone added';

  @override
  String get settingsTotalDistanceDriven => 'Total Distance Driven';

  @override
  String get settingsResetTooltip => 'Reset';

  @override
  String get settingsResetDistance => 'Reset Distance';

  @override
  String get settingsResetDistanceConfirm =>
      'Reset total distance driven to zero?';

  @override
  String get settingsEstimatedFuelUsed => 'Estimated Fuel Used';

  @override
  String get settingsVehicleFuelEconomy => 'Vehicle Fuel Economy';

  @override
  String get settingsLitresPer100km => 'Litres per 100km (L/100km)';

  @override
  String get settingsMilesPerGallon => 'Miles Per Gallon (MPG)';

  @override
  String get settingsHintMetricEconomy => 'e.g., 9.4';

  @override
  String get settingsHintImperialEconomy => 'e.g., 25.0';

  @override
  String settingsFuelEconomyMetric(String value) {
    return '$value L/100km';
  }

  @override
  String settingsFuelEconomyImperial(String value) {
    return '$value MPG';
  }

  @override
  String settingsFuelUsedLitres(String amount, String cost, String price) {
    return '$amount L (~\$$cost @ \$$price/L)';
  }

  @override
  String settingsFuelUsedGallons(String amount, String cost, String price) {
    return '$amount gal (~\$$cost @ \$$price/gal)';
  }

  @override
  String get settingsFuelPrice => 'Fuel Price';

  @override
  String get settingsGasPrice => 'Gas Price';

  @override
  String get settingsPricePerLitre => 'Price per Litre';

  @override
  String get settingsPricePerGallon => 'Price per Gallon';

  @override
  String get settingsHintFuelPrice => 'e.g., 1.85';

  @override
  String get settingsHintGasPrice => 'e.g., 3.50';

  @override
  String settingsFuelPriceDisplay(String price) {
    return '\$$price/L';
  }

  @override
  String settingsGasPriceDisplay(String price) {
    return '\$$price/gal';
  }

  @override
  String get settingsAnalytics => 'Analytics';

  @override
  String get settingsAnalyticsSubtitle =>
      'Time, goals, comparison & repeater stats';

  @override
  String get settingsAchievements => 'Achievements';

  @override
  String get settingsAchievementsSubtitle => 'Wardrive milestone badges';

  @override
  String get settingsDeviceComparison => 'Device Comparison';

  @override
  String get settingsDeviceComparisonSubtitle =>
      'Compare LoRa companion performance';

  @override
  String get settingsDownloadCommunityCoverage => 'Download Community Coverage';

  @override
  String get settingsCommunityCoverageCached => 'Cached — toggle in map layers';

  @override
  String get settingsPullCoverageFromWeb => 'Pull coverage data from web map';

  @override
  String get settingsSessionHistory => 'Session History';

  @override
  String get settingsFilteringBySession => 'Filtering by session';

  @override
  String get settingsViewPastSessions => 'View past wardrive sessions';

  @override
  String get settingsClearFilterTooltip => 'Clear filter';

  @override
  String get settingsSessionFilterCleared => 'Session filter cleared';

  @override
  String get settingsExportData => 'Export Data';

  @override
  String get settingsExportDataSubtitle => 'JSON, CSV, GPX, or KML';

  @override
  String get settingsImportData => 'Import Data';

  @override
  String get settingsImportDataSubtitle => 'Load samples from file';

  @override
  String get settingsShareCoverageMap => 'Share Coverage Map';

  @override
  String get settingsShareCoverageMapSubtitle =>
      'Screenshot + share in one tap';

  @override
  String get settingsFilterByRepeater => 'Filter by Repeater';

  @override
  String settingsFilteringRepeater(String prefixes) {
    return 'Filtering: $prefixes';
  }

  @override
  String get settingsShowCoverageFromRepeater =>
      'Show coverage from a specific repeater';

  @override
  String get settingsRepeaterFilterCleared => 'Repeater filter cleared';

  @override
  String get settingsFilterBySource => 'Filter by Source';

  @override
  String settingsShowingSource(String source) {
    return 'Showing: $source';
  }

  @override
  String get settingsFilterByDeviceOperator => 'Filter by device/operator';

  @override
  String get settingsSourceFilterCleared => 'Source filter cleared';

  @override
  String get settingsNoSourceTaggedData => 'No source-tagged data yet';

  @override
  String get settingsShowAll => 'Show All';

  @override
  String settingsShowingDataFrom(String source) {
    return 'Showing data from: $source';
  }

  @override
  String get settingsFindCoverageGaps => 'Find Coverage Gaps';

  @override
  String get settingsFindCoverageGapsSubtitle =>
      'Locate areas with poor signal';

  @override
  String get settingsDeleteMode => 'Delete Mode';

  @override
  String get settingsDeleteModeSubtitle =>
      'Tap to delete individual samples or cells';

  @override
  String get settingsDeleteModeOn =>
      'Delete mode ON — tap a coverage square or sample to delete';

  @override
  String get settingsPlannedRepeaters => 'Planned Repeaters';

  @override
  String settingsPlannedMarkersSubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count markers — long-press map to add',
      one: '$count marker — long-press map to add',
    );
    return '$_temp0';
  }

  @override
  String get settingsClearAllMarkers => 'Clear All Markers';

  @override
  String get settingsClearAllMarkersConfirm =>
      'Remove all planned repeater markers?';

  @override
  String get settingsAllMarkersCleared => 'All markers cleared';

  @override
  String get settingsPrivacyZones => 'Privacy Zones';

  @override
  String settingsPrivacyZonesSubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count zones — excludes data from uploads',
      one: '$count zone — excludes data from uploads',
    );
    return '$_temp0';
  }

  @override
  String get settingsClearPrivacyZones => 'Clear Privacy Zones';

  @override
  String get settingsClearPrivacyZonesConfirm =>
      'Remove all privacy zones? Data will no longer be filtered from uploads.';

  @override
  String get settingsPrivacyZonesCleared => 'Privacy zones cleared';

  @override
  String get settingsClearMap => 'Clear Map';

  @override
  String get settingsClearMapSubtitle => 'Delete all samples and coverage';

  @override
  String get settingsDownloadOfflineTiles => 'Download Offline Tiles';

  @override
  String get settingsDownloadOfflineTilesSubtitle =>
      'Cache map tiles for current view';

  @override
  String get settingsClearTileCache => 'Clear Tile Cache';

  @override
  String get settingsClearTileCacheSubtitle =>
      'Remove cached offline map tiles';

  @override
  String get settingsTileCacheCleared => 'Tile cache cleared';

  @override
  String get settingsExportSettings => 'Export Settings';

  @override
  String get settingsExportSettingsSubtitle => 'Save all app settings to file';

  @override
  String get settingsImportSettings => 'Import Settings';

  @override
  String get settingsImportSettingsSubtitle => 'Load settings from file';

  @override
  String get settingsRepeaterHealth => 'Repeater Health';

  @override
  String get settingsRepeaterHealthSubtitle =>
      'Per-repeater stats, trends & alerts';

  @override
  String get settingsSignalTrends => 'Signal Trends';

  @override
  String get settingsSignalTrendsSubtitle => 'RSSI, SNR & response time charts';

  @override
  String get settingsDebugDiagnostics => 'Debug Diagnostics';

  @override
  String get settingsDebugDiagnosticsSubtitle =>
      'View debug logs for troubleshooting';

  @override
  String get settingsUploadData => 'Upload Data';

  @override
  String get settingsUploadDataSubtitle => 'Upload samples to web map';

  @override
  String get settingsManageUploadSites => 'Manage Upload Sites';

  @override
  String get settingsManageUploadSitesSubtitle => 'Add/edit upload endpoints';

  @override
  String get settingsUploadNoSites => 'No upload sites configured';

  @override
  String get settingsUploadSelectSites => 'Select sites to upload to:';

  @override
  String get settingsCheckForUpdates => 'Check for Updates';

  @override
  String settingsAboutCurrentVersion(String version) {
    return 'Current version: v$version';
  }

  @override
  String get settingsViewOnGitHub => 'View on GitHub';

  @override
  String get settingsViewOnGitHubSubtitle => 'Source code and releases';

  @override
  String get offlineBannerMessage =>
      'You\'re offline - local tracking continues';

  @override
  String get offlineBannerSemantics =>
      'You are offline. Local tracking continues.';

  @override
  String get compassNeedsCalibration => 'Compass needs calibration';

  @override
  String get compassBannerHint =>
      'Move the phone in a figure-8 if heading looks wrong.';

  @override
  String get compassLater => 'Later';

  @override
  String get compassCalibrate => 'Calibrate';

  @override
  String get compassSensorAccuracyGood => 'Sensor accuracy looks good';

  @override
  String get compassKeepDrawing => 'Keep drawing a figure-8';

  @override
  String get compassCalibrationComplete => 'Calibration complete';

  @override
  String get compassSheetTitle => 'Calibrate compass';

  @override
  String get compassSheetInstructions =>
      'Hold the phone and draw a figure-8 in the air until the bar fills.';

  @override
  String get compassMoveThroughFigureEight =>
      'Move the phone through a figure-8';

  @override
  String get compassSkip => 'Skip';

  @override
  String get compassFigureEightSemantics => 'Figure-8 calibration motion';

  @override
  String get bluetoothSelectDevice => 'Select Bluetooth Device';

  @override
  String get bluetoothPreviouslyUsed => 'Previously used';

  @override
  String get bluetoothNearby => 'Nearby';

  @override
  String get bluetoothCancel => 'Cancel';

  @override
  String bluetoothError(String error) {
    return 'Bluetooth error: $error';
  }

  @override
  String get bluetoothSearching => 'Searching for LoRa devices...';

  @override
  String get bluetoothNoDevices => 'No LoRa devices found via Bluetooth';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsThemeSystemDefault => 'System Default';

  @override
  String get settingsChooseInterfaceTheme => 'Choose Interface Theme';

  @override
  String get settingsChooseMapTheme => 'Choose Map Theme';

  @override
  String get mapClose => 'Close';

  @override
  String get mapDelete => 'Delete';

  @override
  String get mapOk => 'OK';

  @override
  String get mapNotNow => 'Not now';

  @override
  String get mapContinue => 'Continue';

  @override
  String get mapShare => 'Share';

  @override
  String get mapImport => 'Import';

  @override
  String get mapAdd => 'Add';

  @override
  String get mapDownload => 'Download';

  @override
  String get mapYes => 'Yes';

  @override
  String get mapNo => 'No';

  @override
  String get mapExit => 'EXIT';

  @override
  String get mapConnect => 'Connect';

  @override
  String get mapConnecting => 'Connecting...';

  @override
  String get mapDontSave => 'Don\'t save';

  @override
  String mapNewRepeaterDiscovered(String repeaterId) {
    return '🆕 New repeater discovered: $repeaterId';
  }

  @override
  String mapEnteringDeadZone(String cellHash) {
    return '⚠️ Entering known dead zone ($cellHash)';
  }

  @override
  String get mapBatterySaverOn => '🔋 Battery saver ON — ping interval doubled';

  @override
  String get mapBatterySaverOff =>
      '🔋 Battery saver OFF — normal ping interval restored';

  @override
  String get mapCompassCalibrated => 'Compass calibrated';

  @override
  String get mapSessionEmptyTitle => 'Session is empty';

  @override
  String get mapSessionEmptyBody =>
      'No GPS points were recorded. Save this session anyway?';

  @override
  String get mapSessionDiscarded => 'Session discarded';

  @override
  String get mapSessionDiscardedShowingLast =>
      'Session discarded — showing last saved session';

  @override
  String get mapLocationTrackingStarted => 'Location tracking started';

  @override
  String get mapCarpeaterModeStarted => 'Carpeater mode started';

  @override
  String get mapCarpeaterFailedCheckSettings =>
      'Carpeater failed — check settings';

  @override
  String get mapLocationTrackingAndAutoPingStarted =>
      'Location tracking and auto-ping started';

  @override
  String get mapFailedToStartTracking =>
      'Failed to start location tracking. Check Android settings.';

  @override
  String get mapNewSessionShowingTrip => 'New session — showing this trip only';

  @override
  String mapShowingSessionFrom(String timestamp) {
    return 'Showing session from $timestamp';
  }

  @override
  String get mapPreciseLocationRequiredTitle => 'Precise location required';

  @override
  String get mapPreciseLocationRequiredBody =>
      'Wardriving needs precise location. In Android app permissions, enable “Use precise location”, then tap Start again.';

  @override
  String get mapOpenAppSettings => 'Open app settings';

  @override
  String get mapAllowLocationAllTheTimeTitle => 'Allow location all the time';

  @override
  String get mapAllowLocationAllTheTimeBody =>
      'MeshCore Wardrive records while the screen is off or another app is open. Android needs location access set to “Allow all the time”.';

  @override
  String get mapBackgroundLocationRequiredTitle =>
      'Background location required';

  @override
  String get mapBackgroundLocationRequiredBody =>
      'Select Permissions → Location → Allow all the time, then return and tap Start again.';

  @override
  String get mapUnrestrictedBatteryTitle => 'Unrestricted battery use';

  @override
  String get mapUnrestrictedBatteryBody =>
      'Allow MeshCore Wardrive to ignore battery optimizations so Android does not pause GPS, radio communication, or Wi-Fi scans during a drive.';

  @override
  String get mapDisableWifiThrottlingTitle => 'Disable Wi-Fi scan throttling';

  @override
  String get mapDisableWifiThrottlingBody =>
      'Android does not let apps change this setting automatically. In Developer options, turn off “Wi-Fi scan throttling” for timely beaconDB position updates.';

  @override
  String get mapDeveloperOptions => 'Developer options';

  @override
  String get mapClearMapHistoryTitle => 'Clear Map History?';

  @override
  String mapClearMapHistoryBody(int count) {
    return 'This will permanently delete all $count samples and coverage data from the map.\n\nThis action cannot be undone.';
  }

  @override
  String get mapDeleteAll => 'Delete All';

  @override
  String mapDeletedSamples(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Deleted $count samples',
      one: 'Deleted $count sample',
    );
    return '$_temp0';
  }

  @override
  String get mapExportFormat => 'Export Format';

  @override
  String get mapExportJsonSubtitle => 'Full data with all fields';

  @override
  String get mapExportCsvSubtitle => 'Spreadsheet-compatible';

  @override
  String get mapExportGpxSubtitle => 'GPS track for mapping apps';

  @override
  String get mapExportKmlSubtitle => 'Google Earth format';

  @override
  String mapExportAs(String format) {
    return 'Export as $format';
  }

  @override
  String get mapSaveToFolder => 'Save to Folder';

  @override
  String get mapSaveExport => 'Save Export';

  @override
  String mapExportedSamples(int count, String format) {
    return 'Exported $count samples as $format';
  }

  @override
  String get mapExportShareSubject => 'MeshCore Wardrive Export';

  @override
  String mapExportShareText(int count) {
    return 'Exported $count samples from MeshCore Wardrive';
  }

  @override
  String get mapExportShared => 'Export shared';

  @override
  String mapExportFailed(String error) {
    return 'Export failed: $error';
  }

  @override
  String mapImportedSamples(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Imported $count samples',
      one: 'Imported $count sample',
    );
    return '$_temp0';
  }

  @override
  String mapImportedSessionsSuffix(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: ', $count sessions',
      one: ', $count session',
    );
    return '$_temp0';
  }

  @override
  String mapImportedFromSources(String sources) {
    return ' from $sources';
  }

  @override
  String mapImportFailed(String error) {
    return 'Import failed: $error';
  }

  @override
  String get mapSaveSettings => 'Save Settings';

  @override
  String get mapSettingsExported => 'Settings exported';

  @override
  String get mapSettingsShareText => 'MeshCore Wardrive Settings';

  @override
  String get mapImportSettingsConfirm =>
      'This will overwrite your current app settings (display options, ping settings, upload servers, carpeater config, etc).\n\nYour wardrive data will NOT be affected.\n\nContinue?';

  @override
  String mapImportedSettingsCount(int count) {
    return 'Imported $count settings';
  }

  @override
  String mapInvalidSettingsFile(String error) {
    return 'Invalid settings file: $error';
  }

  @override
  String get mapAddPlannedRepeater => 'Add Planned Repeater';

  @override
  String get mapPlannedRepeaterHint => 'e.g., Hilltop near Tracyton';

  @override
  String get mapAddMarker => 'Add Marker';

  @override
  String get mapPlannedRepeaterMarkerAdded => 'Planned repeater marker added';

  @override
  String get mapPlannedRepeater => 'Planned Repeater';

  @override
  String mapLat(String value) {
    return 'Lat: $value';
  }

  @override
  String mapLon(String value) {
    return 'Lon: $value';
  }

  @override
  String mapAddedOn(String date) {
    return 'Added: $date';
  }

  @override
  String get mapMarkerDeleted => 'Marker deleted';

  @override
  String get mapAddPrivacyZone => 'Add Privacy Zone';

  @override
  String get mapPrivacyZoneBlurb =>
      'Data inside this zone will be excluded from uploads and exports.';

  @override
  String get mapPrivacyZoneHint => 'e.g., Home';

  @override
  String get mapPrivacyZoneAdded => 'Privacy zone added';

  @override
  String get mapDeleteSample => 'Delete Sample';

  @override
  String mapDeleteSampleConfirm(String kind, String timestamp) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'success': 'Delete this successful sample from $timestamp?',
      'fail': 'Delete this failed sample from $timestamp?',
      'other': 'Delete this GPS-only sample from $timestamp?',
    });
    return '$_temp0';
  }

  @override
  String get mapSampleDeleted => 'Sample deleted';

  @override
  String get mapDeleteCoverageCell => 'Delete Coverage Cell';

  @override
  String mapDeleteCoverageCellBody(int count, String cellId) {
    return 'Delete all $count samples in this coverage area?\n\nCell: $cellId\nThis cannot be undone.';
  }

  @override
  String mapDeletedSamplesFromCell(int count) {
    return 'Deleted $count samples from cell';
  }

  @override
  String get mapZoomToDeleteCell =>
      'Zoom in to delete an individual coverage cell';

  @override
  String get mapZoomedPointsGrouped =>
      'Zoomed points are grouped; delete from coverage view';

  @override
  String get mapDeleteModeBanner =>
      'DELETE MODE: Tap a coverage square or sample to delete';

  @override
  String get mapUpdateAvailable => 'Update Available';

  @override
  String mapUpdateAvailableBody(String latestVersion, String currentVersion) {
    return 'New version $latestVersion is available!\n\nCurrent version: $currentVersion\n\nWould you like to download it?';
  }

  @override
  String get mapOnLatestVersion => 'You\'re on the latest version!';

  @override
  String get mapCouldNotCheckUpdates => 'Could not check for updates';

  @override
  String get mapNoInternetTryAgain =>
      'No internet connection. Try again when you are online.';

  @override
  String get mapUpdateCheckTimedOut =>
      'Update check timed out. Try again later.';

  @override
  String get mapCouldNotOpenGitHub => 'Could not open GitHub';

  @override
  String get mapAutoFollowEnabled => 'Auto-follow enabled';

  @override
  String get mapAutoFollowDisabled => 'Auto-follow disabled';

  @override
  String get mapMapResetToNorth => 'Map reset to north';

  @override
  String get mapHeadingUpEnabled => 'Heading-up enabled';

  @override
  String get mapHeadingUpDisabled => 'Heading-up disabled — map reset to north';

  @override
  String get mapFailedToCaptureScreenshot => 'Failed to capture screenshot';

  @override
  String get mapScreenshotSavedToGallery => 'Screenshot saved to gallery!';

  @override
  String get mapScreenshotSavedTitle => 'Screenshot Saved';

  @override
  String get mapShareScreenshotPrompt =>
      'Would you like to share the screenshot?';

  @override
  String get mapScreenshotShareText => 'MeshCore Wardrive Coverage Map';

  @override
  String get mapFailedToSaveScreenshot => 'Failed to save screenshot';

  @override
  String mapErrorCapturingScreenshot(String error) {
    return 'Error capturing screenshot: $error';
  }

  @override
  String get mapDebugTerminal => 'Debug Terminal';

  @override
  String get mapScreenshotTooltip => 'Screenshot';

  @override
  String get mapQuickSettings => 'Quick Settings';

  @override
  String get mapPingDist => 'Ping Dist: ';

  @override
  String get mapTimeout => 'Timeout: ';

  @override
  String get mapMode => 'Mode: ';

  @override
  String get mapStopHeadingUp => 'Stop heading-up and reset north';

  @override
  String get mapRotateMapWithHeading =>
      'Rotate map with heading. Long-press to calibrate.';

  @override
  String get mapResetToNorth => 'Reset to North';

  @override
  String get mapStopTracking => 'Stop tracking';

  @override
  String get mapStartTracking =>
      'Start tracking. Long-press for a blank-map session.';

  @override
  String get mapNoLora => 'No LoRa';

  @override
  String mapSamplesCount(String count) {
    return 'Samples: $count';
  }

  @override
  String get mapRetryingCarpeater => 'Retrying Carpeater...';

  @override
  String get mapCarpeaterReconnected => 'Carpeater reconnected';

  @override
  String get mapCarpeaterRetryFailed => 'Carpeater retry failed';

  @override
  String mapCarpeaterStatus(String state) {
    return 'CP: $state';
  }

  @override
  String get mapCarpeaterOff => 'Off';

  @override
  String get mapCarpeaterConnecting => 'Connecting';

  @override
  String get mapCarpeaterLogin => 'Login...';

  @override
  String get mapCarpeaterReady => 'Ready';

  @override
  String get mapCarpeaterScanning => 'Scanning';

  @override
  String get mapCarpeaterFetching => 'Fetching';

  @override
  String get mapCarpeaterError => 'Error';

  @override
  String mapDuctingStatus(String risk) {
    return 'Ducting: $risk';
  }

  @override
  String get mapDuctingPossible => 'Possible';

  @override
  String get mapDuctingLikely => 'Likely';

  @override
  String get mapBatterySaverBadge => '🔋 Saver';

  @override
  String get mapDisconnect => 'Disconnect';

  @override
  String get mapManualPing => 'Manual Ping';

  @override
  String get mapConnectLoraFirst => 'Connect LoRa device first';

  @override
  String get mapWaitingForGps => 'Waiting for GPS location...';

  @override
  String get mapPingAlreadyInProgress => 'A ping is already in progress';

  @override
  String get mapSendingPing => 'Sending ping...';

  @override
  String mapPingHeardBy(String nodeId) {
    return '✅ Ping heard by $nodeId';
  }

  @override
  String mapDiscoveryComplete(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '✅ Discovery complete: found $count repeaters',
      one: '✅ Discovery complete: found $count repeater',
    );
    return '$_temp0';
  }

  @override
  String get mapNoResponseDeadZone => '❌ No response - dead zone';

  @override
  String mapPingFailed(String error) {
    return '❌ Ping failed: $error';
  }

  @override
  String get mapConnectLoraDevice => 'Connect LoRa Device';

  @override
  String get mapChooseConnectionMethod => 'Choose connection method:';

  @override
  String get mapScanUsbDevices => 'Scan USB Devices';

  @override
  String get mapScanBluetooth => 'Scan Bluetooth';

  @override
  String get mapNoUsbDevices => 'No USB devices found';

  @override
  String get mapSelectUsbDevice => 'Select USB Device';

  @override
  String get mapUsbDeviceFallback => 'USB Device';

  @override
  String mapVidPid(String vid, String pid) {
    return 'VID: $vid, PID: $pid';
  }

  @override
  String get mapConnectedViaUsb => 'Connected via USB';

  @override
  String get mapFailedConnectUsb => 'Failed to connect USB device';

  @override
  String mapUsbError(String error) {
    return 'USB error: $error';
  }

  @override
  String mapConnectingTo(String name) {
    return 'Connecting to $name...';
  }

  @override
  String get mapConnectedViaBluetooth => 'Connected via Bluetooth!';

  @override
  String get mapFailedConnectBluetooth => 'Failed to connect Bluetooth device';

  @override
  String get mapDisconnectLoraDevice => 'Disconnect LoRa Device';

  @override
  String get mapDisconnectConfirm =>
      'Disconnect from your LoRa companion device?';

  @override
  String get mapLoraDisconnected => 'LoRa device disconnected';

  @override
  String get mapRefreshingContactList => 'Refreshing contact list...';

  @override
  String get mapContactListUpdated => 'Contact list updated';

  @override
  String get mapScanningForRepeaters => 'Scanning for repeaters...';

  @override
  String get mapNoRepeatersFound => 'No repeaters found';

  @override
  String mapRepeatersFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Found $count repeaters',
      one: 'Found $count repeater',
    );
    return '$_temp0';
  }

  @override
  String get mapSampleInfo => 'Sample Info';

  @override
  String get mapStatusLabel => 'Status: ';

  @override
  String get mapStatusSuccess => '✅ Success';

  @override
  String get mapStatusFailed => '❌ Failed';

  @override
  String get mapStatusGpsOnly => '📍 GPS Only';

  @override
  String mapTimeLabel(String timestamp) {
    return 'Time: $timestamp';
  }

  @override
  String get mapRepeaterLabel => 'Repeater: ';

  @override
  String get mapRssiLabel => 'RSSI: ';

  @override
  String get mapSnrLabel => 'SNR: ';

  @override
  String get mapResponseLabel => 'Response: ';

  @override
  String get mapDuctingLabel => 'Ducting: ';

  @override
  String mapRssiValue(String value) {
    return 'RSSI: $value dBm';
  }

  @override
  String mapSnrValue(String value) {
    return 'SNR: $value dB';
  }

  @override
  String mapGroupedSamples(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count grouped samples',
      one: '$count grouped sample',
    );
    return '$_temp0';
  }

  @override
  String mapSuccessfulCount(int count) {
    return 'Successful: $count';
  }

  @override
  String mapFailedCount(int count) {
    return 'Failed: $count';
  }

  @override
  String mapGpsOnlyCount(int count) {
    return 'GPS only: $count';
  }

  @override
  String mapNewest(String timestamp) {
    return 'Newest: $timestamp';
  }

  @override
  String get mapZoomForBreakdown => 'Zoom in for a more detailed breakdown.';

  @override
  String mapRepeaterFallback(String id) {
    return 'Repeater $id';
  }

  @override
  String mapIdLabel(String id) {
    return 'ID: $id';
  }

  @override
  String mapFilteringBy(String id) {
    return 'Filtering by $id';
  }

  @override
  String get mapFilterByThis => 'Filter by This';

  @override
  String get mapShowOnMap => 'Show on Map';

  @override
  String get mapCoverageSquareInfo => 'Coverage Square Info';

  @override
  String get mapSamplesLabel => 'Samples: ';

  @override
  String get mapSuccessRateLabel => 'Success Rate: ';

  @override
  String get mapReceivedLabel => 'Received: ';

  @override
  String get mapLostLabel => 'Lost: ';

  @override
  String get mapRepeatersHeard => 'Repeaters Heard: ';

  @override
  String get mapRepeaterIds => 'Repeater IDs: ';

  @override
  String get mapNoPingData => 'No ping data';

  @override
  String get mapNotAvailable => 'N/A';

  @override
  String mapNearbyRepeaters(int count) {
    return 'Nearby Repeaters ($count)';
  }

  @override
  String mapUploadingTo(String site) {
    return 'Uploading to $site...';
  }

  @override
  String get mapUploadingSamples => 'Uploading samples...';

  @override
  String mapUploadBatch(int current, int total) {
    return 'Batch $current of $total';
  }

  @override
  String get mapUploadComplete => 'Upload Complete';

  @override
  String get mapUploadResults => 'Upload Results';

  @override
  String mapUploadedToSites(int successCount, int total) {
    return 'Uploaded to $successCount of $total sites';
  }

  @override
  String get mapUploadFallbackName => 'Upload';

  @override
  String mapUploadError(String error) {
    return 'Upload error: $error';
  }

  @override
  String get mapSelectWhichSitesToUpload => 'Select which sites to upload to:';

  @override
  String get mapDeleteSite => 'Delete Site';

  @override
  String mapDeleteSiteConfirm(String name) {
    return 'Delete \"$name\"?';
  }

  @override
  String get mapAddSite => 'Add Site';

  @override
  String get mapUploadSitesUpdated => 'Upload sites updated';

  @override
  String get mapEditUploadSite => 'Edit Upload Site';

  @override
  String get mapSiteName => 'Site Name';

  @override
  String get mapApiUrl => 'API URL';

  @override
  String get mapAddUploadSite => 'Add Upload Site';

  @override
  String get mapSiteNameHint => 'e.g., My Personal Map';

  @override
  String get mapTileCacheNotInitialized => 'Tile cache not initialized';

  @override
  String get mapDownloadTilesBlurb =>
      'Download map tiles for the current view area.';

  @override
  String mapMinZoom(String zoom) {
    return 'Min Zoom: $zoom';
  }

  @override
  String mapMaxZoom(String zoom) {
    return 'Max Zoom: $zoom';
  }

  @override
  String mapTilesEstimate(int count, String megabytes) {
    return '$count tiles (~$megabytes MB)';
  }

  @override
  String get mapLargeDownloadWarning =>
      'Large download — consider a smaller area or zoom range';

  @override
  String get mapDownloadingTiles => 'Downloading Tiles';

  @override
  String mapTilesProgress(int completed, int total) {
    return '$completed / $total tiles';
  }

  @override
  String mapDownloadedTiles(int succeeded, int total) {
    return 'Downloaded $succeeded/$total tiles';
  }

  @override
  String mapDownloadCancelled(int count) {
    return 'Download cancelled ($count tiles cached)';
  }

  @override
  String mapShareFailed(String error) {
    return 'Share failed: $error';
  }

  @override
  String get mapCoverageShareSubject => 'MeshCore Wardrive Coverage';

  @override
  String mapCoverageShareText(
    String sampleCount,
    String coverageCount,
    String successCount,
    String failCount,
    String successRate,
    String repeaterCount,
  ) {
    return 'MeshCore Wardrive Coverage Map\n📍 $sampleCount samples • $coverageCount coverage areas\n✅ $successCount success • ❌ $failCount failed • $successRate% rate\n🔁 $repeaterCount repeaters discovered';
  }

  @override
  String get mapNoRepeatersYet =>
      'No repeaters found yet - do some wardriving first!';

  @override
  String get mapFilterByRepeater => 'Filter by Repeater';

  @override
  String mapShowingCoverageFrom(String id) {
    return 'Showing coverage from $id';
  }

  @override
  String get mapRepeaterFilterCleared => 'Repeater filter cleared';

  @override
  String get mapClearFilter => 'Clear Filter';

  @override
  String get mapNoCoverageYet =>
      'No coverage data yet - do some wardriving first!';

  @override
  String get mapNoCoverageGaps =>
      'No coverage gaps found! All areas have >30% success rate.';

  @override
  String mapCoverageGaps(int count) {
    return 'Coverage Gaps ($count)';
  }

  @override
  String mapGapSuccessRate(String rate) {
    return '$rate% success rate';
  }

  @override
  String mapGapSubtitle(String coords, String received, String lost) {
    return '$coords\n$received received / $lost lost';
  }

  @override
  String get mapDownloadFrom => 'Download from';

  @override
  String get mapDownloadingCoverage => 'Downloading coverage data...';

  @override
  String mapDownloadedCoverageCells(int count) {
    return 'Downloaded $count coverage cells';
  }

  @override
  String get mapLoadedCachedCoverage => 'Loaded cached coverage (offline)';

  @override
  String mapDownloadFailed(String error) {
    return 'Download failed: $error';
  }

  @override
  String get mapUnknownError => 'unknown error';

  @override
  String mapCommunitySuccessRate(String rate) {
    return 'Success Rate: $rate%';
  }

  @override
  String get mapRepeatersHeader => 'Repeaters:';

  @override
  String mapLastUpdate(String timestamp) {
    return 'Last Update: $timestamp';
  }

  @override
  String mapAppVersionLabel(String version) {
    return 'App Version: $version';
  }

  @override
  String mapApproxRadioPositionUncertainty(String uncertainty) {
    return 'Approximate radio position, uncertainty $uncertainty';
  }

  @override
  String mapApproxRadioPositionSnack(int count, String uncertainty) {
    return 'Approximate radio position · $count repeaters · ±$uncertainty';
  }

  @override
  String get mapCurrentWifiLocation => 'Current Wi-Fi location from beaconDB';

  @override
  String get mapCurrentFusedLocation => 'Current fused Android location';

  @override
  String mapPositionHeadingSemantics(String positionLabel, String degrees) {
    return '$positionLabel, heading $degrees degrees';
  }
}
