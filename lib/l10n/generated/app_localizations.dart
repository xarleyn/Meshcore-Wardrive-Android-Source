import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ru'),
  ];

  /// Settings tile title for in-app language
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// Language choice that follows the device locale
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get languageSystem;

  /// English endonym; do not translate in other ARBs
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// Russian endonym; do not translate in other ARBs
  ///
  /// In en, this message translates to:
  /// **'Русский'**
  String get languageRussian;

  /// Dialog title for the language picker
  ///
  /// In en, this message translates to:
  /// **'Choose language'**
  String get languagePickerTitle;

  /// Settings screen AppBar title
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// Tooltip for scrolling settings to the top
  ///
  /// In en, this message translates to:
  /// **'Scroll to top'**
  String get settingsScrollToTop;

  /// Tooltip for scrolling settings to the bottom
  ///
  /// In en, this message translates to:
  /// **'Scroll to bottom'**
  String get settingsScrollToBottom;

  /// Cancel button on settings dialogs
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get settingsCancel;

  /// Save button on settings dialogs
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get settingsSave;

  /// Clear button that empties a value
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get settingsClear;

  /// Confirm upload in endpoint selection dialog
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get settingsUpload;

  /// Confirm reset action
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get settingsReset;

  /// Placeholder when an optional setting has no value
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get settingsNotSet;

  /// Dropdown option meaning no interval
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get settingsNone;

  /// Fallback when a coverage precision is unrecognized
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get settingsUnknown;

  /// Validation error for positive numeric settings
  ///
  /// In en, this message translates to:
  /// **'Enter a number greater than zero'**
  String get settingsEnterNumberGreaterThanZero;

  /// Settings section header
  ///
  /// In en, this message translates to:
  /// **'Map display'**
  String get settingsSectionMapDisplay;

  /// Settings section header
  ///
  /// In en, this message translates to:
  /// **'Location & positioning'**
  String get settingsSectionLocation;

  /// Settings section header
  ///
  /// In en, this message translates to:
  /// **'Feedback & alerts'**
  String get settingsSectionFeedback;

  /// Settings section header for Carpeater beta mode
  ///
  /// In en, this message translates to:
  /// **'Carpeater mode (Beta)'**
  String get settingsSectionCarpeater;

  /// Settings section header
  ///
  /// In en, this message translates to:
  /// **'App & device'**
  String get settingsSectionAppDevice;

  /// Settings section header
  ///
  /// In en, this message translates to:
  /// **'Discovery & sampling'**
  String get settingsSectionDiscovery;

  /// Settings section header
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get settingsSectionStatistics;

  /// Settings section header
  ///
  /// In en, this message translates to:
  /// **'Data management'**
  String get settingsSectionDataManagement;

  /// Settings section header
  ///
  /// In en, this message translates to:
  /// **'Settings backup'**
  String get settingsSectionBackup;

  /// Settings section header
  ///
  /// In en, this message translates to:
  /// **'Diagnostics'**
  String get settingsSectionDiagnostics;

  /// Settings section header
  ///
  /// In en, this message translates to:
  /// **'Online map'**
  String get settingsSectionOnlineMap;

  /// Settings section header
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsSectionAbout;

  /// Location quality subsection header
  ///
  /// In en, this message translates to:
  /// **'Thresholds'**
  String get settingsSectionThresholds;

  /// Location quality subsection header
  ///
  /// In en, this message translates to:
  /// **'Impossible Zones'**
  String get settingsSectionImpossibleZones;

  /// Toggle to show coverage squares on the map
  ///
  /// In en, this message translates to:
  /// **'Show Coverage Boxes'**
  String get settingsShowCoverageBoxes;

  /// Toggle title for map level-of-detail simplification
  ///
  /// In en, this message translates to:
  /// **'Simplify map at low zoom'**
  String get settingsSimplifyMapAtLowZoom;

  /// Subtitle for map simplification toggle
  ///
  /// In en, this message translates to:
  /// **'Group coverage and samples by geohash while zoomed out'**
  String get settingsSimplifyMapAtLowZoomSubtitle;

  /// Toggle to show sample markers
  ///
  /// In en, this message translates to:
  /// **'Show Samples'**
  String get settingsShowSamples;

  /// Toggle to show coverage edges
  ///
  /// In en, this message translates to:
  /// **'Show Edges'**
  String get settingsShowEdges;

  /// Toggle to show repeater markers
  ///
  /// In en, this message translates to:
  /// **'Show Repeaters'**
  String get settingsShowRepeaters;

  /// Toggle to show GPS-only sample markers
  ///
  /// In en, this message translates to:
  /// **'Show GPS Samples'**
  String get settingsShowGpsSamples;

  /// Subtitle for GPS sample toggle
  ///
  /// In en, this message translates to:
  /// **'Show blue GPS-only markers'**
  String get settingsShowGpsSamplesSubtitle;

  /// Toggle to hide failed pings
  ///
  /// In en, this message translates to:
  /// **'Show Successful Pings Only'**
  String get settingsShowSuccessfulPingsOnly;

  /// Subtitle for successful-pings-only toggle
  ///
  /// In en, this message translates to:
  /// **'Hide failed pings and GPS-only samples'**
  String get settingsShowSuccessfulPingsOnlySubtitle;

  /// Toggle to draw the driven path
  ///
  /// In en, this message translates to:
  /// **'Show Route Trail'**
  String get settingsShowRouteTrail;

  /// Subtitle for route trail toggle
  ///
  /// In en, this message translates to:
  /// **'Draw driven path on map'**
  String get settingsShowRouteTrailSubtitle;

  /// Toggle for downloaded community coverage overlay
  ///
  /// In en, this message translates to:
  /// **'Community Coverage'**
  String get settingsCommunityCoverage;

  /// Subtitle when community coverage is cached
  ///
  /// In en, this message translates to:
  /// **'Show downloaded coverage from web map'**
  String get settingsCommunityCoverageDownloaded;

  /// Subtitle when community coverage has not been downloaded
  ///
  /// In en, this message translates to:
  /// **'Download first from Data Management'**
  String get settingsCommunityCoverageNeedDownload;

  /// Tooltip to delete cached community coverage
  ///
  /// In en, this message translates to:
  /// **'Clear downloaded coverage'**
  String get settingsClearDownloadedCoverageTooltip;

  /// Snackbar after clearing community coverage
  ///
  /// In en, this message translates to:
  /// **'Community coverage cleared'**
  String get settingsCommunityCoverageCleared;

  /// Toggle for ping heatmap overlay
  ///
  /// In en, this message translates to:
  /// **'Show Heatmap'**
  String get settingsShowHeatmap;

  /// Subtitle for heatmap toggle
  ///
  /// In en, this message translates to:
  /// **'Heat gradient overlay of ping activity'**
  String get settingsShowHeatmapSubtitle;

  /// Toggle for estimated repeater coverage rings
  ///
  /// In en, this message translates to:
  /// **'Show Prediction Rings'**
  String get settingsShowPredictionRings;

  /// Subtitle for prediction rings toggle
  ///
  /// In en, this message translates to:
  /// **'Estimated repeater coverage radius'**
  String get settingsShowPredictionRingsSubtitle;

  /// Toggle title for beaconDB Wi-Fi positioning
  ///
  /// In en, this message translates to:
  /// **'beaconDB Wi-Fi Positioning'**
  String get settingsBeaconDbWifi;

  /// Subtitle explaining beaconDB Wi-Fi positioning
  ///
  /// In en, this message translates to:
  /// **'Prefer Wi-Fi location; sends nearby BSSIDs and signal levels to beaconDB. Cyan marker means Wi-Fi is active.'**
  String get settingsBeaconDbWifiSubtitle;

  /// Snackbar when beaconDB Wi-Fi positioning is turned on
  ///
  /// In en, this message translates to:
  /// **'beaconDB enabled: nearby BSSIDs will be shared'**
  String get settingsBeaconDbEnabledSnack;

  /// Tile and category page title for location quality filters
  ///
  /// In en, this message translates to:
  /// **'Location Quality Filters'**
  String get settingsLocationQualityFilters;

  /// Subtitle for location quality filters tile
  ///
  /// In en, this message translates to:
  /// **'Accuracy, implausible movement, and impossible locations'**
  String get settingsLocationQualityFiltersSubtitle;

  /// Toggle for radio-estimated position marker
  ///
  /// In en, this message translates to:
  /// **'Show Approximate Position'**
  String get settingsShowApproximatePosition;

  /// Subtitle for approximate position toggle
  ///
  /// In en, this message translates to:
  /// **'Display the grey radio-position estimate'**
  String get settingsShowApproximatePositionSubtitle;

  /// Tile title for tropospheric ducting forecast
  ///
  /// In en, this message translates to:
  /// **'Ducting Forecast'**
  String get settingsDuctingForecast;

  /// Subtitle for ducting forecast tile
  ///
  /// In en, this message translates to:
  /// **'6-day tropospheric ducting maps'**
  String get settingsDuctingForecastSubtitle;

  /// Toggle for atmospheric ducting monitoring
  ///
  /// In en, this message translates to:
  /// **'Atmospheric Ducting'**
  String get settingsAtmosphericDucting;

  /// Subtitle for atmospheric ducting toggle
  ///
  /// In en, this message translates to:
  /// **'Monitor ducting conditions (needs internet)'**
  String get settingsAtmosphericDuctingSubtitle;

  /// Toggle for ping sound feedback
  ///
  /// In en, this message translates to:
  /// **'Sound Feedback'**
  String get settingsSoundFeedback;

  /// Subtitle for sound feedback toggle
  ///
  /// In en, this message translates to:
  /// **'Play tones on ping results'**
  String get settingsSoundFeedbackSubtitle;

  /// Toggle for haptic ping feedback
  ///
  /// In en, this message translates to:
  /// **'Vibration Feedback'**
  String get settingsVibrationFeedback;

  /// Subtitle for vibration feedback toggle
  ///
  /// In en, this message translates to:
  /// **'Haptic feedback on ping results'**
  String get settingsVibrationFeedbackSubtitle;

  /// Toggle for dead zone notifications
  ///
  /// In en, this message translates to:
  /// **'Dead Zone Alerts'**
  String get settingsDeadZoneAlerts;

  /// Subtitle for dead zone alerts
  ///
  /// In en, this message translates to:
  /// **'Notify when entering a known dead zone'**
  String get settingsDeadZoneAlertsSubtitle;

  /// Toggle for new repeater discovery alerts
  ///
  /// In en, this message translates to:
  /// **'New Repeater Alerts'**
  String get settingsNewRepeaterAlerts;

  /// Subtitle for new repeater alerts
  ///
  /// In en, this message translates to:
  /// **'Notify when a never-before-seen repeater is discovered'**
  String get settingsNewRepeaterAlertsSubtitle;

  /// Toggle to enable Carpeater discovery mode
  ///
  /// In en, this message translates to:
  /// **'Enable Carpeater Mode'**
  String get settingsEnableCarpeaterMode;

  /// Subtitle when Carpeater mode is on
  ///
  /// In en, this message translates to:
  /// **'Using repeater for discovery'**
  String get settingsCarpeaterEnabledSubtitle;

  /// Subtitle when Carpeater mode is off
  ///
  /// In en, this message translates to:
  /// **'Use a repeater to discover neighbors\nRequires v1.14+ firmware on all repeaters'**
  String get settingsCarpeaterDisabledSubtitle;

  /// Carpeater target repeater tile and dialog title
  ///
  /// In en, this message translates to:
  /// **'Target Repeater'**
  String get settingsTargetRepeater;

  /// Label for Carpeater repeater ID field
  ///
  /// In en, this message translates to:
  /// **'Repeater ID Prefix'**
  String get settingsRepeaterIdPrefix;

  /// Hint for repeater ID prefix field
  ///
  /// In en, this message translates to:
  /// **'e.g., BAD5DC49'**
  String get settingsRepeaterIdHint;

  /// Carpeater admin password tile and dialog title
  ///
  /// In en, this message translates to:
  /// **'Admin Password'**
  String get settingsAdminPassword;

  /// Password field label
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get settingsPassword;

  /// Hint for repeater admin password field
  ///
  /// In en, this message translates to:
  /// **'Repeater admin password'**
  String get settingsRepeaterAdminPasswordHint;

  /// Carpeater discovery cycle interval
  ///
  /// In en, this message translates to:
  /// **'Cycle Interval'**
  String get settingsCycleInterval;

  /// Subtitle for cycle interval
  ///
  /// In en, this message translates to:
  /// **'Time between discovery cycles'**
  String get settingsCycleIntervalSubtitle;

  /// Device name tile and dialog title
  ///
  /// In en, this message translates to:
  /// **'Device Name'**
  String get settingsDeviceName;

  /// Subtitle when no device name is configured
  ///
  /// In en, this message translates to:
  /// **'Not set — used for multi-device wardrive'**
  String get settingsDeviceNameNotSet;

  /// Label for device name text field
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get settingsDeviceNameLabel;

  /// Hint for device name field
  ///
  /// In en, this message translates to:
  /// **'e.g., Chuck-Pixel'**
  String get settingsDeviceNameHint;

  /// Settings toggle title; keeps the display awake
  ///
  /// In en, this message translates to:
  /// **'Keep Screen On'**
  String get settingsKeepScreenOn;

  /// Settings toggle subtitle for keep-screen-on
  ///
  /// In en, this message translates to:
  /// **'Prevent the screen from sleeping while the app is open'**
  String get settingsKeepScreenOnSubtitle;

  /// Battery saver toggle title
  ///
  /// In en, this message translates to:
  /// **'Battery Saver'**
  String get settingsBatterySaver;

  /// Battery saver toggle subtitle
  ///
  /// In en, this message translates to:
  /// **'Auto-double ping interval when battery ≤20%'**
  String get settingsBatterySaverSubtitle;

  /// Toggle to lock map rotation to north
  ///
  /// In en, this message translates to:
  /// **'Lock Map Rotation'**
  String get settingsLockMapRotation;

  /// Subtitle for lock rotation toggle
  ///
  /// In en, this message translates to:
  /// **'Prevent map rotation'**
  String get settingsLockMapRotationSubtitle;

  /// Title for current location marker style
  ///
  /// In en, this message translates to:
  /// **'Current Location Marker'**
  String get settingsCurrentLocationMarker;

  /// Subtitle for current location marker style
  ///
  /// In en, this message translates to:
  /// **'The direction arrow follows the phone compass'**
  String get settingsCurrentLocationMarkerSubtitle;

  /// Circle location marker style
  ///
  /// In en, this message translates to:
  /// **'Circle'**
  String get settingsMarkerCircle;

  /// Compass arrow location marker style
  ///
  /// In en, this message translates to:
  /// **'Direction arrow'**
  String get settingsMarkerDirectionArrow;

  /// Tile to open compass calibration
  ///
  /// In en, this message translates to:
  /// **'Calibrate Compass'**
  String get settingsCalibrateCompass;

  /// Subtitle for compass calibration
  ///
  /// In en, this message translates to:
  /// **'Draw a figure-8 in the air if the heading looks wrong'**
  String get settingsCalibrateCompassSubtitle;

  /// Tile to choose app interface theme
  ///
  /// In en, this message translates to:
  /// **'Interface Theme'**
  String get settingsInterfaceTheme;

  /// Tile to choose map theme
  ///
  /// In en, this message translates to:
  /// **'Map Theme'**
  String get settingsMapTheme;

  /// Tile to scan for nearby LoRa repeaters
  ///
  /// In en, this message translates to:
  /// **'Scan for Repeaters'**
  String get settingsScanForRepeaters;

  /// Subtitle when no repeaters have been found yet
  ///
  /// In en, this message translates to:
  /// **'Find nearby LoRa nodes'**
  String get settingsScanFindNearby;

  /// Subtitle showing how many repeaters were found
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} repeater found} other{{count} repeaters found}}'**
  String settingsRepeatersFound(int count);

  /// Tile to refresh repeater names from the device
  ///
  /// In en, this message translates to:
  /// **'Refresh Contact List'**
  String get settingsRefreshContactList;

  /// Subtitle for refresh contact list
  ///
  /// In en, this message translates to:
  /// **'Update repeater names from device'**
  String get settingsRefreshContactListSubtitle;

  /// Coverage color mode setting
  ///
  /// In en, this message translates to:
  /// **'Color Mode'**
  String get settingsColorMode;

  /// Color coverage by signal quality
  ///
  /// In en, this message translates to:
  /// **'Quality'**
  String get settingsColorModeQuality;

  /// Color coverage by sample age
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get settingsColorModeAge;

  /// Color coverage by sample redundancy
  ///
  /// In en, this message translates to:
  /// **'Redundancy'**
  String get settingsColorModeRedundancy;

  /// Distance unit preference
  ///
  /// In en, this message translates to:
  /// **'Distance Unit'**
  String get settingsDistanceUnit;

  /// Miles distance unit option
  ///
  /// In en, this message translates to:
  /// **'Miles'**
  String get settingsMiles;

  /// Kilometers distance unit option
  ///
  /// In en, this message translates to:
  /// **'Kilometers'**
  String get settingsKilometers;

  /// Fuel unit preference
  ///
  /// In en, this message translates to:
  /// **'Fuel Unit'**
  String get settingsFuelUnit;

  /// Imperial fuel unit option
  ///
  /// In en, this message translates to:
  /// **'MPG / Gallons'**
  String get settingsFuelUnitImperial;

  /// Metric fuel unit option
  ///
  /// In en, this message translates to:
  /// **'L/100km / Litres'**
  String get settingsFuelUnitMetric;

  /// Color vision accessibility mode
  ///
  /// In en, this message translates to:
  /// **'Color Blind Mode'**
  String get settingsColorBlindMode;

  /// Default color vision option
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get settingsColorBlindNormal;

  /// Deuteranopia color-blind mode; keep medical term
  ///
  /// In en, this message translates to:
  /// **'Deuteranopia'**
  String get settingsColorBlindDeuteranopia;

  /// Protanopia color-blind mode; keep medical term
  ///
  /// In en, this message translates to:
  /// **'Protanopia'**
  String get settingsColorBlindProtanopia;

  /// Tritanopia color-blind mode; keep medical term
  ///
  /// In en, this message translates to:
  /// **'Tritanopia'**
  String get settingsColorBlindTritanopia;

  /// How long to wait for repeater responses
  ///
  /// In en, this message translates to:
  /// **'Discovery Timeout'**
  String get settingsDiscoveryTimeout;

  /// Subtitle for discovery timeout
  ///
  /// In en, this message translates to:
  /// **'How long to wait for repeater responses'**
  String get settingsDiscoveryTimeoutSubtitle;

  /// Toggle for waiting until discovery timeout
  ///
  /// In en, this message translates to:
  /// **'Thorough Response Collection'**
  String get settingsThoroughResponseCollection;

  /// Subtitle when thorough collection is enabled
  ///
  /// In en, this message translates to:
  /// **'Thorough: collect responses until the discovery timeout'**
  String get settingsThoroughOn;

  /// Subtitle when thorough collection is disabled
  ///
  /// In en, this message translates to:
  /// **'Fast: finish 3 seconds after the first response'**
  String get settingsThoroughOff;

  /// Tile and dialog to ignore repeater prefixes
  ///
  /// In en, this message translates to:
  /// **'Ignore Repeaters'**
  String get settingsIgnoreRepeaters;

  /// Subtitle listing ignored repeater prefixes
  ///
  /// In en, this message translates to:
  /// **'Ignoring: {prefix}'**
  String settingsIgnoringPrefix(String prefix);

  /// Subtitle when no ignore filter is set
  ///
  /// In en, this message translates to:
  /// **'Not filtering'**
  String get settingsNotFiltering;

  /// Tile and dialog for repeater whitelist
  ///
  /// In en, this message translates to:
  /// **'Include Only Repeaters'**
  String get settingsIncludeOnlyRepeaters;

  /// Subtitle listing whitelisted repeater prefixes
  ///
  /// In en, this message translates to:
  /// **'Whitelist: {prefixes}'**
  String settingsWhitelistPrefix(String prefixes);

  /// Subtitle when no repeater whitelist is set
  ///
  /// In en, this message translates to:
  /// **'Show all repeaters'**
  String get settingsShowAllRepeaters;

  /// Toggle to filter map edges by whitelist
  ///
  /// In en, this message translates to:
  /// **'Apply Whitelist to Edges'**
  String get settingsApplyWhitelistToEdges;

  /// Subtitle for whitelist-on-edges toggle
  ///
  /// In en, this message translates to:
  /// **'Only show edges for whitelisted repeaters'**
  String get settingsApplyWhitelistToEdgesSubtitle;

  /// How automatic pings are triggered
  ///
  /// In en, this message translates to:
  /// **'Ping Mode'**
  String get settingsPingMode;

  /// Ping when distance threshold is reached
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get settingsPingModeDistance;

  /// Ping on a time interval
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get settingsPingModeTime;

  /// Ping on both distance and time
  ///
  /// In en, this message translates to:
  /// **'Both'**
  String get settingsPingModeBoth;

  /// Tile for ping distance interval
  ///
  /// In en, this message translates to:
  /// **'Ping Distance'**
  String get settingsPingDistance;

  /// Tile for ping time interval
  ///
  /// In en, this message translates to:
  /// **'Ping Time Interval'**
  String get settingsPingTimeInterval;

  /// Coverage square size setting and dialog title
  ///
  /// In en, this message translates to:
  /// **'Coverage Resolution'**
  String get settingsCoverageResolution;

  /// Dialog title for choosing ping distance
  ///
  /// In en, this message translates to:
  /// **'Ping Interval'**
  String get settingsPingInterval;

  /// Prompt in ping interval dialog
  ///
  /// In en, this message translates to:
  /// **'How often should pings be sent?'**
  String get settingsPingIntervalPrompt;

  /// Frequent ping interval option
  ///
  /// In en, this message translates to:
  /// **'Frequent'**
  String get settingsPingFrequent;

  /// Frequent ping interval description
  ///
  /// In en, this message translates to:
  /// **'Every 50 meters'**
  String get settingsPingFrequentSubtitle;

  /// Normal ping interval option
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get settingsPingNormal;

  /// Normal ping interval description
  ///
  /// In en, this message translates to:
  /// **'Every 200 meters (~0.12 miles)'**
  String get settingsPingNormalSubtitle;

  /// Sparse ping interval option
  ///
  /// In en, this message translates to:
  /// **'Sparse'**
  String get settingsPingSparse;

  /// Sparse ping interval description
  ///
  /// In en, this message translates to:
  /// **'Every 0.5 miles (805 meters)'**
  String get settingsPingSparseSubtitle;

  /// Very sparse ping interval option
  ///
  /// In en, this message translates to:
  /// **'Very Sparse'**
  String get settingsPingVerySparse;

  /// Very sparse ping interval description
  ///
  /// In en, this message translates to:
  /// **'Every 1 mile (1609 meters)'**
  String get settingsPingVerySparseSubtitle;

  /// Snackbar after changing ping interval
  ///
  /// In en, this message translates to:
  /// **'Ping interval: {description}'**
  String settingsPingIntervalSet(String description);

  /// Ping interval description under 100 meters
  ///
  /// In en, this message translates to:
  /// **'{meters} meters (frequent)'**
  String settingsPingIntervalMetersFrequent(int meters);

  /// Ping interval description in meters
  ///
  /// In en, this message translates to:
  /// **'{meters} meters'**
  String settingsPingIntervalMeters(int meters);

  /// Ping interval description in miles with meters
  ///
  /// In en, this message translates to:
  /// **'{miles} miles ({meters}m)'**
  String settingsPingIntervalMiles(String miles, int meters);

  /// Prompt in coverage resolution dialog
  ///
  /// In en, this message translates to:
  /// **'Choose the size of coverage squares:'**
  String get settingsCoverageResolutionPrompt;

  /// Regional coverage resolution option
  ///
  /// In en, this message translates to:
  /// **'Regional'**
  String get settingsCoverageRegional;

  /// Regional coverage option subtitle
  ///
  /// In en, this message translates to:
  /// **'~20km squares (precision 4)'**
  String get settingsCoverageRegionalSubtitle;

  /// City-level coverage resolution option
  ///
  /// In en, this message translates to:
  /// **'City-level'**
  String get settingsCoverageCity;

  /// City-level coverage option subtitle
  ///
  /// In en, this message translates to:
  /// **'~5km squares (precision 5)'**
  String get settingsCoverageCitySubtitle;

  /// Neighborhood coverage resolution option
  ///
  /// In en, this message translates to:
  /// **'Neighborhood'**
  String get settingsCoverageNeighborhood;

  /// Neighborhood coverage option subtitle
  ///
  /// In en, this message translates to:
  /// **'~1.2km squares (precision 6, default)'**
  String get settingsCoverageNeighborhoodSubtitle;

  /// Street-level coverage resolution option
  ///
  /// In en, this message translates to:
  /// **'Street-level'**
  String get settingsCoverageStreet;

  /// Street-level coverage option subtitle
  ///
  /// In en, this message translates to:
  /// **'~153m squares (precision 7)'**
  String get settingsCoverageStreetSubtitle;

  /// Building-level coverage resolution option
  ///
  /// In en, this message translates to:
  /// **'Building-level'**
  String get settingsCoverageBuilding;

  /// Building-level coverage option subtitle
  ///
  /// In en, this message translates to:
  /// **'~38m squares (precision 8, detailed)'**
  String get settingsCoverageBuildingSubtitle;

  /// Regional coverage summary for tile and snackbar
  ///
  /// In en, this message translates to:
  /// **'Regional (~20km squares)'**
  String get settingsCoverageRegionalDesc;

  /// City-level coverage summary
  ///
  /// In en, this message translates to:
  /// **'City-level (~5km squares)'**
  String get settingsCoverageCityDesc;

  /// Neighborhood coverage summary
  ///
  /// In en, this message translates to:
  /// **'Neighborhood (~1.2km squares)'**
  String get settingsCoverageNeighborhoodDesc;

  /// Street-level coverage summary
  ///
  /// In en, this message translates to:
  /// **'Street-level (~153m squares)'**
  String get settingsCoverageStreetDesc;

  /// Building-level coverage summary
  ///
  /// In en, this message translates to:
  /// **'Building-level (~38m squares)'**
  String get settingsCoverageBuildingDesc;

  /// Snackbar after changing coverage resolution
  ///
  /// In en, this message translates to:
  /// **'Coverage resolution: {description}'**
  String settingsCoverageResolutionSet(String description);

  /// Label for comma-separated repeater prefixes
  ///
  /// In en, this message translates to:
  /// **'Repeater Prefixes'**
  String get settingsRepeaterPrefixes;

  /// Hint for ignore-repeaters field
  ///
  /// In en, this message translates to:
  /// **'e.g., 7E, A4F, BAD5'**
  String get settingsIgnoreRepeaterHint;

  /// Description in ignore-repeaters dialog
  ///
  /// In en, this message translates to:
  /// **'Filter out responses from your mobile repeater(s) to avoid false coverage. Enter repeater prefixes separated by commas:'**
  String get settingsIgnoreRepeaterDescription;

  /// Snackbar after saving ignored prefixes
  ///
  /// In en, this message translates to:
  /// **'Repeater prefix updated'**
  String get settingsRepeaterPrefixUpdated;

  /// Hint for include-only repeaters field
  ///
  /// In en, this message translates to:
  /// **'e.g., 7E3A, A4F2, 8B'**
  String get settingsIncludeOnlyHint;

  /// Description in include-only repeaters dialog
  ///
  /// In en, this message translates to:
  /// **'Show only samples from specific repeaters (whitelist). Enter repeater prefixes separated by commas:'**
  String get settingsIncludeOnlyDescription;

  /// Snackbar after saving repeater whitelist
  ///
  /// In en, this message translates to:
  /// **'Repeater whitelist updated'**
  String get settingsRepeaterWhitelistUpdated;

  /// Snackbar after restoring location quality defaults
  ///
  /// In en, this message translates to:
  /// **'Location quality filters reset'**
  String get settingsLocationQualityResetSnack;

  /// Location quality threshold title
  ///
  /// In en, this message translates to:
  /// **'Maximum Horizontal Error'**
  String get settingsMaxHorizontalError;

  /// Subtitle for maximum horizontal error
  ///
  /// In en, this message translates to:
  /// **'Reject positions with worse reported accuracy'**
  String get settingsMaxHorizontalErrorSubtitle;

  /// Dialog description for maximum horizontal error
  ///
  /// In en, this message translates to:
  /// **'Positions whose reported horizontal error is larger than this value are ignored.'**
  String get settingsMaxHorizontalErrorDescription;

  /// Airborne altitude threshold title
  ///
  /// In en, this message translates to:
  /// **'Airborne Altitude'**
  String get settingsAirborneAltitude;

  /// Subtitle for airborne altitude
  ///
  /// In en, this message translates to:
  /// **'Altitude used together with airborne speed'**
  String get settingsAirborneAltitudeSubtitle;

  /// Dialog description for airborne altitude
  ///
  /// In en, this message translates to:
  /// **'At or above this altitude, a position is ignored only when it also exceeds the airborne speed.'**
  String get settingsAirborneAltitudeDescription;

  /// Airborne speed threshold title
  ///
  /// In en, this message translates to:
  /// **'Airborne Speed'**
  String get settingsAirborneSpeed;

  /// Subtitle for airborne speed
  ///
  /// In en, this message translates to:
  /// **'Speed used together with airborne altitude'**
  String get settingsAirborneSpeedSubtitle;

  /// Dialog description for airborne speed
  ///
  /// In en, this message translates to:
  /// **'At or above this speed, a high-altitude position is treated as a probable flight.'**
  String get settingsAirborneSpeedDescription;

  /// Maximum plausible wardrive speed title
  ///
  /// In en, this message translates to:
  /// **'Maximum Wardrive Speed'**
  String get settingsMaxWardriveSpeed;

  /// Subtitle for maximum wardrive speed
  ///
  /// In en, this message translates to:
  /// **'Reject positions moving faster than this'**
  String get settingsMaxWardriveSpeedSubtitle;

  /// Dialog description for maximum wardrive speed
  ///
  /// In en, this message translates to:
  /// **'Positions moving at or above this speed are ignored as implausible wardrive data.'**
  String get settingsMaxWardriveSpeedDescription;

  /// Button to restore location quality defaults
  ///
  /// In en, this message translates to:
  /// **'Restore Defaults'**
  String get settingsRestoreDefaults;

  /// Explanation of impossible zones
  ///
  /// In en, this message translates to:
  /// **'Places you cannot physically be. GPS inside a zone is discarded and the last valid position is kept. Zones are not shown on the map.'**
  String get settingsImpossibleZonesBlurb;

  /// Tile and dialog title to add an impossible zone
  ///
  /// In en, this message translates to:
  /// **'Add Impossible Zone'**
  String get settingsAddImpossibleZone;

  /// Subtitle when no impossible zones exist
  ///
  /// In en, this message translates to:
  /// **'Uses current position or map center'**
  String get settingsImpossibleZoneEmptySubtitle;

  /// Count of configured impossible zones
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} zone} other{{count} zones}}'**
  String settingsImpossibleZoneCount(int count);

  /// Fallback label for a zone without a name
  ///
  /// In en, this message translates to:
  /// **'Unnamed zone'**
  String get settingsUnnamedZone;

  /// Tooltip to delete one impossible zone
  ///
  /// In en, this message translates to:
  /// **'Delete zone'**
  String get settingsDeleteZoneTooltip;

  /// Tile and dialog title to remove all impossible zones
  ///
  /// In en, this message translates to:
  /// **'Clear Impossible Zones'**
  String get settingsClearImpossibleZones;

  /// Subtitle to remove every configured zone
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Remove all {count} zone} other{Remove all {count} zones}}'**
  String settingsRemoveAllZones(int count);

  /// Confirmation body for clearing impossible zones
  ///
  /// In en, this message translates to:
  /// **'Remove all impossible zones? GPS inside those areas will no longer be discarded.'**
  String get settingsClearImpossibleZonesConfirm;

  /// Shows the chosen zone center coordinates
  ///
  /// In en, this message translates to:
  /// **'Center: {lat}, {lon}'**
  String settingsAddImpossibleZoneCenter(String lat, String lon);

  /// Explanation in add-impossible-zone dialog
  ///
  /// In en, this message translates to:
  /// **'GPS inside this area is treated as invalid and discarded.'**
  String get settingsAddImpossibleZoneBlurb;

  /// Optional zone label field
  ///
  /// In en, this message translates to:
  /// **'Label (optional)'**
  String get settingsLabelOptional;

  /// Hint for optional zone label
  ///
  /// In en, this message translates to:
  /// **'e.g., Airport'**
  String get settingsLabelHintAirport;

  /// Radius picker label
  ///
  /// In en, this message translates to:
  /// **'Radius:'**
  String get settingsRadius;

  /// 500 meter zone radius option
  ///
  /// In en, this message translates to:
  /// **'500m (~0.3 mi)'**
  String get settingsRadius500m;

  /// 1 kilometer zone radius option
  ///
  /// In en, this message translates to:
  /// **'1 km (~0.6 mi)'**
  String get settingsRadius1km;

  /// 2 kilometer zone radius option
  ///
  /// In en, this message translates to:
  /// **'2 km (~1.2 mi)'**
  String get settingsRadius2km;

  /// 5 kilometer zone radius option
  ///
  /// In en, this message translates to:
  /// **'5 km (~3 mi)'**
  String get settingsRadius5km;

  /// Confirm adding an impossible zone
  ///
  /// In en, this message translates to:
  /// **'Add Zone'**
  String get settingsAddZone;

  /// Snackbar after adding an impossible zone
  ///
  /// In en, this message translates to:
  /// **'Impossible zone added'**
  String get settingsImpossibleZoneAdded;

  /// Lifetime distance statistic
  ///
  /// In en, this message translates to:
  /// **'Total Distance Driven'**
  String get settingsTotalDistanceDriven;

  /// Tooltip to reset total distance
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get settingsResetTooltip;

  /// Dialog title to reset driven distance
  ///
  /// In en, this message translates to:
  /// **'Reset Distance'**
  String get settingsResetDistance;

  /// Confirmation body for resetting distance
  ///
  /// In en, this message translates to:
  /// **'Reset total distance driven to zero?'**
  String get settingsResetDistanceConfirm;

  /// Estimated fuel usage statistic
  ///
  /// In en, this message translates to:
  /// **'Estimated Fuel Used'**
  String get settingsEstimatedFuelUsed;

  /// Vehicle fuel economy setting
  ///
  /// In en, this message translates to:
  /// **'Vehicle Fuel Economy'**
  String get settingsVehicleFuelEconomy;

  /// Metric fuel economy field label
  ///
  /// In en, this message translates to:
  /// **'Litres per 100km (L/100km)'**
  String get settingsLitresPer100km;

  /// Imperial fuel economy field label
  ///
  /// In en, this message translates to:
  /// **'Miles Per Gallon (MPG)'**
  String get settingsMilesPerGallon;

  /// Hint for metric fuel economy
  ///
  /// In en, this message translates to:
  /// **'e.g., 9.4'**
  String get settingsHintMetricEconomy;

  /// Hint for imperial fuel economy
  ///
  /// In en, this message translates to:
  /// **'e.g., 25.0'**
  String get settingsHintImperialEconomy;

  /// Displayed metric fuel economy
  ///
  /// In en, this message translates to:
  /// **'{value} L/100km'**
  String settingsFuelEconomyMetric(String value);

  /// Displayed imperial fuel economy
  ///
  /// In en, this message translates to:
  /// **'{value} MPG'**
  String settingsFuelEconomyImperial(String value);

  /// Estimated litres used with cost
  ///
  /// In en, this message translates to:
  /// **'{amount} L (~\${cost} @ \${price}/L)'**
  String settingsFuelUsedLitres(String amount, String cost, String price);

  /// Estimated gallons used with cost
  ///
  /// In en, this message translates to:
  /// **'{amount} gal (~\${cost} @ \${price}/gal)'**
  String settingsFuelUsedGallons(String amount, String cost, String price);

  /// Metric fuel price setting
  ///
  /// In en, this message translates to:
  /// **'Fuel Price'**
  String get settingsFuelPrice;

  /// Imperial gas price setting
  ///
  /// In en, this message translates to:
  /// **'Gas Price'**
  String get settingsGasPrice;

  /// Metric fuel price field label
  ///
  /// In en, this message translates to:
  /// **'Price per Litre'**
  String get settingsPricePerLitre;

  /// Imperial gas price field label
  ///
  /// In en, this message translates to:
  /// **'Price per Gallon'**
  String get settingsPricePerGallon;

  /// Hint for metric fuel price
  ///
  /// In en, this message translates to:
  /// **'e.g., 1.85'**
  String get settingsHintFuelPrice;

  /// Hint for imperial gas price
  ///
  /// In en, this message translates to:
  /// **'e.g., 3.50'**
  String get settingsHintGasPrice;

  /// Displayed metric fuel price
  ///
  /// In en, this message translates to:
  /// **'\${price}/L'**
  String settingsFuelPriceDisplay(String price);

  /// Displayed imperial gas price
  ///
  /// In en, this message translates to:
  /// **'\${price}/gal'**
  String settingsGasPriceDisplay(String price);

  /// Tile to open analytics
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get settingsAnalytics;

  /// Subtitle for analytics tile
  ///
  /// In en, this message translates to:
  /// **'Time, goals, comparison & repeater stats'**
  String get settingsAnalyticsSubtitle;

  /// Tile to open achievements
  ///
  /// In en, this message translates to:
  /// **'Achievements'**
  String get settingsAchievements;

  /// Subtitle for achievements tile
  ///
  /// In en, this message translates to:
  /// **'Wardrive milestone badges'**
  String get settingsAchievementsSubtitle;

  /// Tile to compare companion devices
  ///
  /// In en, this message translates to:
  /// **'Device Comparison'**
  String get settingsDeviceComparison;

  /// Subtitle for device comparison
  ///
  /// In en, this message translates to:
  /// **'Compare LoRa companion performance'**
  String get settingsDeviceComparisonSubtitle;

  /// Tile to download community coverage
  ///
  /// In en, this message translates to:
  /// **'Download Community Coverage'**
  String get settingsDownloadCommunityCoverage;

  /// Subtitle when community coverage is cached
  ///
  /// In en, this message translates to:
  /// **'Cached — toggle in map layers'**
  String get settingsCommunityCoverageCached;

  /// Subtitle when community coverage is not cached
  ///
  /// In en, this message translates to:
  /// **'Pull coverage data from web map'**
  String get settingsPullCoverageFromWeb;

  /// Tile to open session history
  ///
  /// In en, this message translates to:
  /// **'Session History'**
  String get settingsSessionHistory;

  /// Subtitle when a session filter is active
  ///
  /// In en, this message translates to:
  /// **'Filtering by session'**
  String get settingsFilteringBySession;

  /// Subtitle when no session filter is active
  ///
  /// In en, this message translates to:
  /// **'View past wardrive sessions'**
  String get settingsViewPastSessions;

  /// Tooltip to clear session filter
  ///
  /// In en, this message translates to:
  /// **'Clear filter'**
  String get settingsClearFilterTooltip;

  /// Snackbar after clearing session filter
  ///
  /// In en, this message translates to:
  /// **'Session filter cleared'**
  String get settingsSessionFilterCleared;

  /// Tile to export samples
  ///
  /// In en, this message translates to:
  /// **'Export Data'**
  String get settingsExportData;

  /// Subtitle listing export formats
  ///
  /// In en, this message translates to:
  /// **'JSON, CSV, GPX, or KML'**
  String get settingsExportDataSubtitle;

  /// Tile to import samples
  ///
  /// In en, this message translates to:
  /// **'Import Data'**
  String get settingsImportData;

  /// Subtitle for import data
  ///
  /// In en, this message translates to:
  /// **'Load samples from file'**
  String get settingsImportDataSubtitle;

  /// Tile to screenshot and share the map
  ///
  /// In en, this message translates to:
  /// **'Share Coverage Map'**
  String get settingsShareCoverageMap;

  /// Subtitle for share coverage map
  ///
  /// In en, this message translates to:
  /// **'Screenshot + share in one tap'**
  String get settingsShareCoverageMapSubtitle;

  /// Tile to filter coverage by repeater
  ///
  /// In en, this message translates to:
  /// **'Filter by Repeater'**
  String get settingsFilterByRepeater;

  /// Subtitle when a repeater filter is active
  ///
  /// In en, this message translates to:
  /// **'Filtering: {prefixes}'**
  String settingsFilteringRepeater(String prefixes);

  /// Subtitle when no repeater filter is active
  ///
  /// In en, this message translates to:
  /// **'Show coverage from a specific repeater'**
  String get settingsShowCoverageFromRepeater;

  /// Snackbar after clearing repeater filter
  ///
  /// In en, this message translates to:
  /// **'Repeater filter cleared'**
  String get settingsRepeaterFilterCleared;

  /// Tile and dialog to filter by device/operator
  ///
  /// In en, this message translates to:
  /// **'Filter by Source'**
  String get settingsFilterBySource;

  /// Subtitle when a source filter is active
  ///
  /// In en, this message translates to:
  /// **'Showing: {source}'**
  String settingsShowingSource(String source);

  /// Subtitle when no source filter is active
  ///
  /// In en, this message translates to:
  /// **'Filter by device/operator'**
  String get settingsFilterByDeviceOperator;

  /// Snackbar after clearing source filter
  ///
  /// In en, this message translates to:
  /// **'Source filter cleared'**
  String get settingsSourceFilterCleared;

  /// Snackbar when no sources exist to filter
  ///
  /// In en, this message translates to:
  /// **'No source-tagged data yet'**
  String get settingsNoSourceTaggedData;

  /// Dialog option to clear source filter
  ///
  /// In en, this message translates to:
  /// **'Show All'**
  String get settingsShowAll;

  /// Snackbar after choosing a source filter
  ///
  /// In en, this message translates to:
  /// **'Showing data from: {source}'**
  String settingsShowingDataFrom(String source);

  /// Tile to find poor-signal areas
  ///
  /// In en, this message translates to:
  /// **'Find Coverage Gaps'**
  String get settingsFindCoverageGaps;

  /// Subtitle for find coverage gaps
  ///
  /// In en, this message translates to:
  /// **'Locate areas with poor signal'**
  String get settingsFindCoverageGapsSubtitle;

  /// Tile to enable sample/cell delete mode
  ///
  /// In en, this message translates to:
  /// **'Delete Mode'**
  String get settingsDeleteMode;

  /// Subtitle for delete mode
  ///
  /// In en, this message translates to:
  /// **'Tap to delete individual samples or cells'**
  String get settingsDeleteModeSubtitle;

  /// Snackbar after enabling delete mode
  ///
  /// In en, this message translates to:
  /// **'Delete mode ON — tap a coverage square or sample to delete'**
  String get settingsDeleteModeOn;

  /// Tile for planned repeater markers
  ///
  /// In en, this message translates to:
  /// **'Planned Repeaters'**
  String get settingsPlannedRepeaters;

  /// Count of planned repeater markers
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} marker — long-press map to add} other{{count} markers — long-press map to add}}'**
  String settingsPlannedMarkersSubtitle(int count);

  /// Dialog title to remove planned markers
  ///
  /// In en, this message translates to:
  /// **'Clear All Markers'**
  String get settingsClearAllMarkers;

  /// Confirmation body for clearing planned markers
  ///
  /// In en, this message translates to:
  /// **'Remove all planned repeater markers?'**
  String get settingsClearAllMarkersConfirm;

  /// Snackbar after clearing planned markers
  ///
  /// In en, this message translates to:
  /// **'All markers cleared'**
  String get settingsAllMarkersCleared;

  /// Tile for privacy zones
  ///
  /// In en, this message translates to:
  /// **'Privacy Zones'**
  String get settingsPrivacyZones;

  /// Count of privacy zones
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} zone — excludes data from uploads} other{{count} zones — excludes data from uploads}}'**
  String settingsPrivacyZonesSubtitle(int count);

  /// Tile and dialog title to remove privacy zones
  ///
  /// In en, this message translates to:
  /// **'Clear Privacy Zones'**
  String get settingsClearPrivacyZones;

  /// Confirmation body for clearing privacy zones
  ///
  /// In en, this message translates to:
  /// **'Remove all privacy zones? Data will no longer be filtered from uploads.'**
  String get settingsClearPrivacyZonesConfirm;

  /// Snackbar after clearing privacy zones
  ///
  /// In en, this message translates to:
  /// **'Privacy zones cleared'**
  String get settingsPrivacyZonesCleared;

  /// Tile to delete all samples and coverage
  ///
  /// In en, this message translates to:
  /// **'Clear Map'**
  String get settingsClearMap;

  /// Subtitle for clear map
  ///
  /// In en, this message translates to:
  /// **'Delete all samples and coverage'**
  String get settingsClearMapSubtitle;

  /// Tile to cache map tiles
  ///
  /// In en, this message translates to:
  /// **'Download Offline Tiles'**
  String get settingsDownloadOfflineTiles;

  /// Subtitle for offline tile download
  ///
  /// In en, this message translates to:
  /// **'Cache map tiles for current view'**
  String get settingsDownloadOfflineTilesSubtitle;

  /// Tile to remove cached map tiles
  ///
  /// In en, this message translates to:
  /// **'Clear Tile Cache'**
  String get settingsClearTileCache;

  /// Subtitle for clear tile cache
  ///
  /// In en, this message translates to:
  /// **'Remove cached offline map tiles'**
  String get settingsClearTileCacheSubtitle;

  /// Snackbar after clearing tile cache
  ///
  /// In en, this message translates to:
  /// **'Tile cache cleared'**
  String get settingsTileCacheCleared;

  /// Tile to export app settings
  ///
  /// In en, this message translates to:
  /// **'Export Settings'**
  String get settingsExportSettings;

  /// Subtitle for export settings
  ///
  /// In en, this message translates to:
  /// **'Save all app settings to file'**
  String get settingsExportSettingsSubtitle;

  /// Tile to import app settings
  ///
  /// In en, this message translates to:
  /// **'Import Settings'**
  String get settingsImportSettings;

  /// Subtitle for import settings
  ///
  /// In en, this message translates to:
  /// **'Load settings from file'**
  String get settingsImportSettingsSubtitle;

  /// Tile to open repeater health
  ///
  /// In en, this message translates to:
  /// **'Repeater Health'**
  String get settingsRepeaterHealth;

  /// Subtitle for repeater health
  ///
  /// In en, this message translates to:
  /// **'Per-repeater stats, trends & alerts'**
  String get settingsRepeaterHealthSubtitle;

  /// Tile to open signal trend charts
  ///
  /// In en, this message translates to:
  /// **'Signal Trends'**
  String get settingsSignalTrends;

  /// Subtitle for signal trends
  ///
  /// In en, this message translates to:
  /// **'RSSI, SNR & response time charts'**
  String get settingsSignalTrendsSubtitle;

  /// Tile to open debug logs
  ///
  /// In en, this message translates to:
  /// **'Debug Diagnostics'**
  String get settingsDebugDiagnostics;

  /// Subtitle for debug diagnostics
  ///
  /// In en, this message translates to:
  /// **'View debug logs for troubleshooting'**
  String get settingsDebugDiagnosticsSubtitle;

  /// Upload samples tile and dialog title
  ///
  /// In en, this message translates to:
  /// **'Upload Data'**
  String get settingsUploadData;

  /// Subtitle for upload data
  ///
  /// In en, this message translates to:
  /// **'Upload samples to web map'**
  String get settingsUploadDataSubtitle;

  /// Tile to edit upload endpoints
  ///
  /// In en, this message translates to:
  /// **'Manage Upload Sites'**
  String get settingsManageUploadSites;

  /// Subtitle for manage upload sites
  ///
  /// In en, this message translates to:
  /// **'Add/edit upload endpoints'**
  String get settingsManageUploadSitesSubtitle;

  /// Empty state in upload site picker
  ///
  /// In en, this message translates to:
  /// **'No upload sites configured'**
  String get settingsUploadNoSites;

  /// Prompt in upload site picker
  ///
  /// In en, this message translates to:
  /// **'Select sites to upload to:'**
  String get settingsUploadSelectSites;

  /// Tile to check for app updates
  ///
  /// In en, this message translates to:
  /// **'Check for Updates'**
  String get settingsCheckForUpdates;

  /// Shows the installed app version
  ///
  /// In en, this message translates to:
  /// **'Current version: v{version}'**
  String settingsAboutCurrentVersion(String version);

  /// Tile to open the GitHub repository
  ///
  /// In en, this message translates to:
  /// **'View on GitHub'**
  String get settingsViewOnGitHub;

  /// Subtitle for GitHub tile
  ///
  /// In en, this message translates to:
  /// **'Source code and releases'**
  String get settingsViewOnGitHubSubtitle;

  /// Visible text on the app-wide offline banner
  ///
  /// In en, this message translates to:
  /// **'You\'\'re offline - local tracking continues'**
  String get offlineBannerMessage;

  /// Accessibility label for the app-wide offline banner
  ///
  /// In en, this message translates to:
  /// **'You are offline. Local tracking continues.'**
  String get offlineBannerSemantics;

  /// Title on the map compass calibration banner
  ///
  /// In en, this message translates to:
  /// **'Compass needs calibration'**
  String get compassNeedsCalibration;

  /// Hint on the map compass calibration banner
  ///
  /// In en, this message translates to:
  /// **'Move the phone in a figure-8 if heading looks wrong.'**
  String get compassBannerHint;

  /// Dismiss the compass calibration banner for now
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get compassLater;

  /// Open the compass calibration sheet
  ///
  /// In en, this message translates to:
  /// **'Calibrate'**
  String get compassCalibrate;

  /// Status when compass sensor accuracy is already reliable
  ///
  /// In en, this message translates to:
  /// **'Sensor accuracy looks good'**
  String get compassSensorAccuracyGood;

  /// Status while the user is still moving the phone
  ///
  /// In en, this message translates to:
  /// **'Keep drawing a figure-8'**
  String get compassKeepDrawing;

  /// Status shown just before the calibration sheet closes
  ///
  /// In en, this message translates to:
  /// **'Calibration complete'**
  String get compassCalibrationComplete;

  /// Title of the compass calibration bottom sheet
  ///
  /// In en, this message translates to:
  /// **'Calibrate compass'**
  String get compassSheetTitle;

  /// Instructions on the compass calibration bottom sheet
  ///
  /// In en, this message translates to:
  /// **'Hold the phone and draw a figure-8 in the air until the bar fills.'**
  String get compassSheetInstructions;

  /// Default status before the user starts moving the phone
  ///
  /// In en, this message translates to:
  /// **'Move the phone through a figure-8'**
  String get compassMoveThroughFigureEight;

  /// Skip compass calibration without completing it
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get compassSkip;

  /// Accessibility label for the animated figure-8 graphic
  ///
  /// In en, this message translates to:
  /// **'Figure-8 calibration motion'**
  String get compassFigureEightSemantics;

  /// Title of the Bluetooth companion device picker
  ///
  /// In en, this message translates to:
  /// **'Select Bluetooth Device'**
  String get bluetoothSelectDevice;

  /// Subtitle for a remembered Bluetooth device
  ///
  /// In en, this message translates to:
  /// **'Previously used'**
  String get bluetoothPreviouslyUsed;

  /// Subtitle for a currently visible Bluetooth device
  ///
  /// In en, this message translates to:
  /// **'Nearby'**
  String get bluetoothNearby;

  /// Cancel button on the Bluetooth device picker
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get bluetoothCancel;

  /// Empty-state message when Bluetooth scan fails
  ///
  /// In en, this message translates to:
  /// **'Bluetooth error: {error}'**
  String bluetoothError(String error);

  /// Empty-state message while scanning for LoRa devices
  ///
  /// In en, this message translates to:
  /// **'Searching for LoRa devices...'**
  String get bluetoothSearching;

  /// Empty-state message when no LoRa devices were found
  ///
  /// In en, this message translates to:
  /// **'No LoRa devices found via Bluetooth'**
  String get bluetoothNoDevices;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
