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
}
