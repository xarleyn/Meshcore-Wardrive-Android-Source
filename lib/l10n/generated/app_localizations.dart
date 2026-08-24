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

  /// Overview group header for map-related settings; shown in uppercase
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get settingsOverviewGroupMap;

  /// Overview group header for discovery, alerts, and Carpeater; shown in uppercase
  ///
  /// In en, this message translates to:
  /// **'Sampling & alerts'**
  String get settingsOverviewGroupSampling;

  /// Overview group header for app and statistics settings; shown in uppercase
  ///
  /// In en, this message translates to:
  /// **'App'**
  String get settingsOverviewGroupApp;

  /// Overview group header for data and backup settings; shown in uppercase
  ///
  /// In en, this message translates to:
  /// **'Data'**
  String get settingsOverviewGroupData;

  /// Overview group header for diagnostics and about; shown in uppercase
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsOverviewGroupSystem;

  /// One-line summary for the map display settings category
  ///
  /// In en, this message translates to:
  /// **'Coverage layers, samples, heatmap, and overlays'**
  String get settingsSectionMapDisplayDescription;

  /// One-line summary for the location settings category
  ///
  /// In en, this message translates to:
  /// **'GPS, Wi-Fi positioning, and radio location'**
  String get settingsSectionLocationDescription;

  /// One-line summary for the discovery settings category
  ///
  /// In en, this message translates to:
  /// **'Pings, timeouts, and repeater filters'**
  String get settingsSectionDiscoveryDescription;

  /// One-line summary for the feedback settings category
  ///
  /// In en, this message translates to:
  /// **'Sound, vibration, and alerts'**
  String get settingsSectionFeedbackDescription;

  /// One-line summary for the Carpeater settings category
  ///
  /// In en, this message translates to:
  /// **'Hop through a chosen repeater'**
  String get settingsSectionCarpeaterDescription;

  /// One-line summary for the app and device settings category
  ///
  /// In en, this message translates to:
  /// **'Theme, language, screen, and units'**
  String get settingsSectionAppDeviceDescription;

  /// One-line summary for the online map settings category
  ///
  /// In en, this message translates to:
  /// **'Upload samples to community coverage'**
  String get settingsSectionOnlineMapDescription;

  /// One-line summary for the statistics settings category
  ///
  /// In en, this message translates to:
  /// **'Distance driven and fuel estimates'**
  String get settingsSectionStatisticsDescription;

  /// One-line summary for the data management settings category
  ///
  /// In en, this message translates to:
  /// **'Export, import, filters, and privacy'**
  String get settingsSectionDataManagementDescription;

  /// One-line summary for the settings backup category
  ///
  /// In en, this message translates to:
  /// **'Export and restore app settings'**
  String get settingsSectionBackupDescription;

  /// One-line summary for the diagnostics settings category
  ///
  /// In en, this message translates to:
  /// **'Debug logs and device checks'**
  String get settingsSectionDiagnosticsDescription;

  /// One-line summary for the about settings category
  ///
  /// In en, this message translates to:
  /// **'Version, updates, and source'**
  String get settingsSectionAboutDescription;

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

  /// Location quality subsection header for the bad-fix ping pause
  ///
  /// In en, this message translates to:
  /// **'Auto-Ping Pause'**
  String get settingsSectionAutoPingPause;

  /// Toggle to pause automatic pings while position fixes are rejected
  ///
  /// In en, this message translates to:
  /// **'Pause Pings on Bad GPS'**
  String get settingsPingPauseOnBadFixes;

  /// Subtitle for the pause-pings-on-bad-fixes toggle
  ///
  /// In en, this message translates to:
  /// **'Stop automatic pings while recent position fixes are rejected; resume on the next valid fix'**
  String get settingsPingPauseOnBadFixesSubtitle;

  /// Tile title for the number of rejected fixes that pauses pinging
  ///
  /// In en, this message translates to:
  /// **'Consecutive Bad Fixes'**
  String get settingsPingPauseBadFixCount;

  /// Subtitle for the consecutive bad fixes threshold
  ///
  /// In en, this message translates to:
  /// **'Rejected fixes in a row before pings pause'**
  String get settingsPingPauseBadFixCountSubtitle;

  /// Dialog description for the consecutive bad fixes threshold
  ///
  /// In en, this message translates to:
  /// **'Number of rejected position fixes in a row that pauses automatic pinging until a valid fix arrives.'**
  String get settingsPingPauseBadFixCountDescription;

  /// Validation error for the consecutive bad fixes threshold
  ///
  /// In en, this message translates to:
  /// **'Enter a number between {min} and {max}'**
  String settingsEnterBadFixCount(int min, int max);

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

  /// Toggle for the LoRa device link loss sound alert
  ///
  /// In en, this message translates to:
  /// **'Link Loss Alert'**
  String get settingsLinkLossAlerts;

  /// Subtitle for the LoRa device link loss alert toggle
  ///
  /// In en, this message translates to:
  /// **'Beep when the LoRa device connection is lost'**
  String get settingsLinkLossAlertsSubtitle;

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

  /// Light theme option in interface/map theme pickers
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsThemeLight;

  /// Dark theme option in interface/map theme pickers
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsThemeDark;

  /// Follow-system theme option in interface/map theme pickers
  ///
  /// In en, this message translates to:
  /// **'System Default'**
  String get settingsThemeSystemDefault;

  /// Dialog title for choosing the app interface theme
  ///
  /// In en, this message translates to:
  /// **'Choose Interface Theme'**
  String get settingsChooseInterfaceTheme;

  /// Dialog title for choosing the map tile theme
  ///
  /// In en, this message translates to:
  /// **'Choose Map Theme'**
  String get settingsChooseMapTheme;

  /// Close button on map dialogs
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get mapClose;

  /// Delete button on map dialogs
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get mapDelete;

  /// OK button on map dialogs
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get mapOk;

  /// Dismiss permission/request dialogs without continuing
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get mapNotNow;

  /// Confirm permission/request dialogs
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get mapContinue;

  /// Share export or screenshot
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get mapShare;

  /// Confirm importing settings
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get mapImport;

  /// Confirm adding an upload site
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get mapAdd;

  /// Confirm downloading an update or tiles
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get mapDownload;

  /// Confirm sharing a screenshot
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get mapYes;

  /// Decline sharing a screenshot
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get mapNo;

  /// Exit map delete mode
  ///
  /// In en, this message translates to:
  /// **'EXIT'**
  String get mapExit;

  /// Connect to a LoRa companion
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get mapConnect;

  /// LoRa connection in progress
  ///
  /// In en, this message translates to:
  /// **'Connecting...'**
  String get mapConnecting;

  /// Discard an empty tracking session
  ///
  /// In en, this message translates to:
  /// **'Don\'\'t save'**
  String get mapDontSave;

  /// Snackbar when a never-before-seen repeater is found
  ///
  /// In en, this message translates to:
  /// **'🆕 New repeater discovered: {repeaterId}'**
  String mapNewRepeaterDiscovered(String repeaterId);

  /// Snackbar when entering a known dead zone cell
  ///
  /// In en, this message translates to:
  /// **'⚠️ Entering known dead zone ({cellHash})'**
  String mapEnteringDeadZone(String cellHash);

  /// Snackbar when battery saver activates
  ///
  /// In en, this message translates to:
  /// **'🔋 Battery saver ON — ping interval doubled'**
  String get mapBatterySaverOn;

  /// Snackbar when battery saver deactivates
  ///
  /// In en, this message translates to:
  /// **'🔋 Battery saver OFF — normal ping interval restored'**
  String get mapBatterySaverOff;

  /// Snackbar when automatic pings pause after repeated bad fixes
  ///
  /// In en, this message translates to:
  /// **'📡 Auto-ping paused: recent GPS fixes are unreliable'**
  String get mapPingPausedByBadFixes;

  /// Snackbar when automatic pings resume after a valid fix
  ///
  /// In en, this message translates to:
  /// **'📡 Auto-ping resumed: valid GPS fix received'**
  String get mapPingResumedByGoodFix;

  /// Snackbar after compass calibration completes
  ///
  /// In en, this message translates to:
  /// **'Compass calibrated'**
  String get mapCompassCalibrated;

  /// Title when stopping a session with no GPS points
  ///
  /// In en, this message translates to:
  /// **'Session is empty'**
  String get mapSessionEmptyTitle;

  /// Body when stopping a session with no GPS points
  ///
  /// In en, this message translates to:
  /// **'No GPS points were recorded. Save this session anyway?'**
  String get mapSessionEmptyBody;

  /// Snackbar after discarding an empty session with no history
  ///
  /// In en, this message translates to:
  /// **'Session discarded'**
  String get mapSessionDiscarded;

  /// Snackbar after discarding an empty session when older sessions exist
  ///
  /// In en, this message translates to:
  /// **'Session discarded — showing last saved session'**
  String get mapSessionDiscardedShowingLast;

  /// Snackbar when GPS tracking starts without auto-ping
  ///
  /// In en, this message translates to:
  /// **'Location tracking started'**
  String get mapLocationTrackingStarted;

  /// Snackbar when Carpeater starts with tracking
  ///
  /// In en, this message translates to:
  /// **'Carpeater mode started'**
  String get mapCarpeaterModeStarted;

  /// Snackbar when Carpeater fails to start
  ///
  /// In en, this message translates to:
  /// **'Carpeater failed — check settings'**
  String get mapCarpeaterFailedCheckSettings;

  /// Snackbar when tracking starts with auto-ping
  ///
  /// In en, this message translates to:
  /// **'Location tracking and auto-ping started'**
  String get mapLocationTrackingAndAutoPingStarted;

  /// Fallback snackbar when tracking fails to start
  ///
  /// In en, this message translates to:
  /// **'Failed to start location tracking. Check Android settings.'**
  String get mapFailedToStartTracking;

  /// Snackbar when starting a blank-map session
  ///
  /// In en, this message translates to:
  /// **'New session — showing this trip only'**
  String get mapNewSessionShowingTrip;

  /// Snackbar after loading a saved session on the map
  ///
  /// In en, this message translates to:
  /// **'Showing session from {timestamp}'**
  String mapShowingSessionFrom(String timestamp);

  /// Title of the precise-location permission dialog
  ///
  /// In en, this message translates to:
  /// **'Precise location required'**
  String get mapPreciseLocationRequiredTitle;

  /// Body of the precise-location permission dialog
  ///
  /// In en, this message translates to:
  /// **'Wardriving needs precise location. In Android app permissions, enable “Use precise location”, then tap Start again.'**
  String get mapPreciseLocationRequiredBody;

  /// Action to open Android app settings from a permission dialog
  ///
  /// In en, this message translates to:
  /// **'Open app settings'**
  String get mapOpenAppSettings;

  /// Title asking for background location
  ///
  /// In en, this message translates to:
  /// **'Allow location all the time'**
  String get mapAllowLocationAllTheTimeTitle;

  /// Body asking for background location
  ///
  /// In en, this message translates to:
  /// **'MeshCore Wardrive records while the screen is off or another app is open. Android needs location access set to “Allow all the time”.'**
  String get mapAllowLocationAllTheTimeBody;

  /// Title when background location was denied
  ///
  /// In en, this message translates to:
  /// **'Background location required'**
  String get mapBackgroundLocationRequiredTitle;

  /// Body when background location was denied
  ///
  /// In en, this message translates to:
  /// **'Select Permissions → Location → Allow all the time, then return and tap Start again.'**
  String get mapBackgroundLocationRequiredBody;

  /// Title asking to ignore battery optimizations
  ///
  /// In en, this message translates to:
  /// **'Unrestricted battery use'**
  String get mapUnrestrictedBatteryTitle;

  /// Body asking to ignore battery optimizations
  ///
  /// In en, this message translates to:
  /// **'Allow MeshCore Wardrive to ignore battery optimizations so Android does not pause GPS, radio communication, or Wi-Fi scans during a drive.'**
  String get mapUnrestrictedBatteryBody;

  /// Title asking to disable Wi-Fi scan throttling
  ///
  /// In en, this message translates to:
  /// **'Disable Wi-Fi scan throttling'**
  String get mapDisableWifiThrottlingTitle;

  /// Body asking to disable Wi-Fi scan throttling
  ///
  /// In en, this message translates to:
  /// **'Android does not let apps change this setting automatically. In Developer options, turn off “Wi-Fi scan throttling” for timely beaconDB position updates.'**
  String get mapDisableWifiThrottlingBody;

  /// Action to open Android developer options
  ///
  /// In en, this message translates to:
  /// **'Developer options'**
  String get mapDeveloperOptions;

  /// Title of the clear-map confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Clear Map History?'**
  String get mapClearMapHistoryTitle;

  /// Body of the clear-map confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete all {count} samples and coverage data from the map.\n\nThis action cannot be undone.'**
  String mapClearMapHistoryBody(int count);

  /// Confirm deleting all samples or a coverage cell
  ///
  /// In en, this message translates to:
  /// **'Delete All'**
  String get mapDeleteAll;

  /// Snackbar after clearing map history
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Deleted {count} sample} other{Deleted {count} samples}}'**
  String mapDeletedSamples(int count);

  /// Title of the export format picker
  ///
  /// In en, this message translates to:
  /// **'Export Format'**
  String get mapExportFormat;

  /// JSON export format description
  ///
  /// In en, this message translates to:
  /// **'Full data with all fields'**
  String get mapExportJsonSubtitle;

  /// CSV export format description
  ///
  /// In en, this message translates to:
  /// **'Spreadsheet-compatible'**
  String get mapExportCsvSubtitle;

  /// GPX export format description
  ///
  /// In en, this message translates to:
  /// **'GPS track for mapping apps'**
  String get mapExportGpxSubtitle;

  /// KML export format description
  ///
  /// In en, this message translates to:
  /// **'Google Earth format'**
  String get mapExportKmlSubtitle;

  /// Title of save-or-share export dialog
  ///
  /// In en, this message translates to:
  /// **'Export as {format}'**
  String mapExportAs(String format);

  /// Save an export to a folder
  ///
  /// In en, this message translates to:
  /// **'Save to Folder'**
  String get mapSaveToFolder;

  /// File-picker title when saving a data export
  ///
  /// In en, this message translates to:
  /// **'Save Export'**
  String get mapSaveExport;

  /// Snackbar after saving a data export
  ///
  /// In en, this message translates to:
  /// **'Exported {count} samples as {format}'**
  String mapExportedSamples(int count, String format);

  /// Share-sheet subject for a data export; brand untranslated
  ///
  /// In en, this message translates to:
  /// **'MeshCore Wardrive Export'**
  String get mapExportShareSubject;

  /// Share-sheet body for a data export
  ///
  /// In en, this message translates to:
  /// **'Exported {count} samples from MeshCore Wardrive'**
  String mapExportShareText(int count);

  /// Snackbar after sharing an export
  ///
  /// In en, this message translates to:
  /// **'Export shared'**
  String get mapExportShared;

  /// Snackbar when export fails
  ///
  /// In en, this message translates to:
  /// **'Export failed: {error}'**
  String mapExportFailed(String error);

  /// Snackbar prefix after importing samples
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Imported {count} sample} other{Imported {count} samples}}'**
  String mapImportedSamples(int count);

  /// Optional session count suffix after importing data
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{, {count} session} other{, {count} sessions}}'**
  String mapImportedSessionsSuffix(int count);

  /// Optional source suffix after importing data
  ///
  /// In en, this message translates to:
  /// **' from {sources}'**
  String mapImportedFromSources(String sources);

  /// Snackbar when import fails
  ///
  /// In en, this message translates to:
  /// **'Import failed: {error}'**
  String mapImportFailed(String error);

  /// File-picker title when saving a settings export
  ///
  /// In en, this message translates to:
  /// **'Save Settings'**
  String get mapSaveSettings;

  /// Snackbar after saving settings
  ///
  /// In en, this message translates to:
  /// **'Settings exported'**
  String get mapSettingsExported;

  /// Share-sheet text for exported settings
  ///
  /// In en, this message translates to:
  /// **'MeshCore Wardrive Settings'**
  String get mapSettingsShareText;

  /// Confirmation body before importing settings
  ///
  /// In en, this message translates to:
  /// **'This will overwrite your current app settings (display options, ping settings, upload servers, carpeater config, etc).\n\nYour wardrive data will NOT be affected.\n\nContinue?'**
  String get mapImportSettingsConfirm;

  /// Snackbar after importing settings
  ///
  /// In en, this message translates to:
  /// **'Imported {count} settings'**
  String mapImportedSettingsCount(int count);

  /// Snackbar when a settings file cannot be parsed
  ///
  /// In en, this message translates to:
  /// **'Invalid settings file: {error}'**
  String mapInvalidSettingsFile(String error);

  /// Title when dropping a planned repeater marker
  ///
  /// In en, this message translates to:
  /// **'Add Planned Repeater'**
  String get mapAddPlannedRepeater;

  /// Title of the action picker shown after a long press on the map
  ///
  /// In en, this message translates to:
  /// **'Add to map'**
  String get mapLongPressActionTitle;

  /// Description of the planned repeater long-press action
  ///
  /// In en, this message translates to:
  /// **'Mark a possible future repeater location'**
  String get mapLongPressPlannedRepeaterSubtitle;

  /// Description of the privacy zone long-press action
  ///
  /// In en, this message translates to:
  /// **'Exclude this area from uploads and exports'**
  String get mapLongPressPrivacyZoneSubtitle;

  /// Description of the impossible GPS zone long-press action
  ///
  /// In en, this message translates to:
  /// **'Reject unreliable GPS positions in this area'**
  String get mapLongPressImpossibleZoneSubtitle;

  /// Hint for an optional planned-repeater label
  ///
  /// In en, this message translates to:
  /// **'e.g., Hilltop near Tracyton'**
  String get mapPlannedRepeaterHint;

  /// Confirm adding a planned repeater marker
  ///
  /// In en, this message translates to:
  /// **'Add Marker'**
  String get mapAddMarker;

  /// Snackbar after adding a planned repeater
  ///
  /// In en, this message translates to:
  /// **'Planned repeater marker added'**
  String get mapPlannedRepeaterMarkerAdded;

  /// Fallback title for an unlabeled planned repeater
  ///
  /// In en, this message translates to:
  /// **'Planned Repeater'**
  String get mapPlannedRepeater;

  /// Latitude row in map info dialogs
  ///
  /// In en, this message translates to:
  /// **'Lat: {value}'**
  String mapLat(String value);

  /// Longitude row in map info dialogs
  ///
  /// In en, this message translates to:
  /// **'Lon: {value}'**
  String mapLon(String value);

  /// When a planned repeater marker was created
  ///
  /// In en, this message translates to:
  /// **'Added: {date}'**
  String mapAddedOn(String date);

  /// Snackbar after deleting a planned repeater marker
  ///
  /// In en, this message translates to:
  /// **'Marker deleted'**
  String get mapMarkerDeleted;

  /// Title of the add-privacy-zone dialog
  ///
  /// In en, this message translates to:
  /// **'Add Privacy Zone'**
  String get mapAddPrivacyZone;

  /// Explanation in the add-privacy-zone dialog
  ///
  /// In en, this message translates to:
  /// **'Data inside this zone will be excluded from uploads and exports.'**
  String get mapPrivacyZoneBlurb;

  /// Hint for an optional privacy-zone label
  ///
  /// In en, this message translates to:
  /// **'e.g., Home'**
  String get mapPrivacyZoneHint;

  /// Snackbar after adding a privacy zone
  ///
  /// In en, this message translates to:
  /// **'Privacy zone added'**
  String get mapPrivacyZoneAdded;

  /// Title of the delete-sample dialog
  ///
  /// In en, this message translates to:
  /// **'Delete Sample'**
  String get mapDeleteSample;

  /// Confirm deleting one sample; kind is success, fail, or gps
  ///
  /// In en, this message translates to:
  /// **'{kind, select, success{Delete this successful sample from {timestamp}?} fail{Delete this failed sample from {timestamp}?} other{Delete this GPS-only sample from {timestamp}?}}'**
  String mapDeleteSampleConfirm(String kind, String timestamp);

  /// Snackbar after deleting a sample
  ///
  /// In en, this message translates to:
  /// **'Sample deleted'**
  String get mapSampleDeleted;

  /// Title of the delete-coverage-cell dialog
  ///
  /// In en, this message translates to:
  /// **'Delete Coverage Cell'**
  String get mapDeleteCoverageCell;

  /// Body of the delete-coverage-cell dialog
  ///
  /// In en, this message translates to:
  /// **'Delete all {count} samples in this coverage area?\n\nCell: {cellId}\nThis cannot be undone.'**
  String mapDeleteCoverageCellBody(int count, String cellId);

  /// Snackbar after deleting a coverage cell
  ///
  /// In en, this message translates to:
  /// **'Deleted {count} samples from cell'**
  String mapDeletedSamplesFromCell(int count);

  /// Snackbar when delete-mode tap is too zoomed out
  ///
  /// In en, this message translates to:
  /// **'Zoom in to delete an individual coverage cell'**
  String get mapZoomToDeleteCell;

  /// Snackbar when a clustered sample cannot be deleted
  ///
  /// In en, this message translates to:
  /// **'Zoomed points are grouped; delete from coverage view'**
  String get mapZoomedPointsGrouped;

  /// Banner shown while map delete mode is active
  ///
  /// In en, this message translates to:
  /// **'DELETE MODE: Tap a coverage square or sample to delete'**
  String get mapDeleteModeBanner;

  /// Title when a newer app version exists
  ///
  /// In en, this message translates to:
  /// **'Update Available'**
  String get mapUpdateAvailable;

  /// Body of the update-available dialog
  ///
  /// In en, this message translates to:
  /// **'New version {latestVersion} is available!\n\nCurrent version: {currentVersion}\n\nWould you like to download it?'**
  String mapUpdateAvailableBody(String latestVersion, String currentVersion);

  /// Snackbar when the installed app is current
  ///
  /// In en, this message translates to:
  /// **'You\'\'re on the latest version!'**
  String get mapOnLatestVersion;

  /// Snackbar when update check fails
  ///
  /// In en, this message translates to:
  /// **'Could not check for updates'**
  String get mapCouldNotCheckUpdates;

  /// Snackbar when update check is offline
  ///
  /// In en, this message translates to:
  /// **'No internet connection. Try again when you are online.'**
  String get mapNoInternetTryAgain;

  /// Snackbar when update check times out
  ///
  /// In en, this message translates to:
  /// **'Update check timed out. Try again later.'**
  String get mapUpdateCheckTimedOut;

  /// Snackbar when the GitHub URL cannot be launched
  ///
  /// In en, this message translates to:
  /// **'Could not open GitHub'**
  String get mapCouldNotOpenGitHub;

  /// Snackbar when map follow-location is enabled
  ///
  /// In en, this message translates to:
  /// **'Auto-follow enabled'**
  String get mapAutoFollowEnabled;

  /// Snackbar when map follow-location is disabled
  ///
  /// In en, this message translates to:
  /// **'Auto-follow disabled'**
  String get mapAutoFollowDisabled;

  /// Snackbar after resetting map rotation
  ///
  /// In en, this message translates to:
  /// **'Map reset to north'**
  String get mapMapResetToNorth;

  /// Snackbar when heading-up rotation is enabled
  ///
  /// In en, this message translates to:
  /// **'Heading-up enabled'**
  String get mapHeadingUpEnabled;

  /// Snackbar when heading-up rotation is disabled
  ///
  /// In en, this message translates to:
  /// **'Heading-up disabled — map reset to north'**
  String get mapHeadingUpDisabled;

  /// Snackbar when screenshot capture returns no image
  ///
  /// In en, this message translates to:
  /// **'Failed to capture screenshot'**
  String get mapFailedToCaptureScreenshot;

  /// Snackbar after saving a screenshot
  ///
  /// In en, this message translates to:
  /// **'Screenshot saved to gallery!'**
  String get mapScreenshotSavedToGallery;

  /// Title after saving a screenshot
  ///
  /// In en, this message translates to:
  /// **'Screenshot Saved'**
  String get mapScreenshotSavedTitle;

  /// Prompt after saving a screenshot
  ///
  /// In en, this message translates to:
  /// **'Would you like to share the screenshot?'**
  String get mapShareScreenshotPrompt;

  /// Share-sheet text for a coverage screenshot
  ///
  /// In en, this message translates to:
  /// **'MeshCore Wardrive Coverage Map'**
  String get mapScreenshotShareText;

  /// Snackbar when gallery save fails
  ///
  /// In en, this message translates to:
  /// **'Failed to save screenshot'**
  String get mapFailedToSaveScreenshot;

  /// Snackbar when screenshot capture throws
  ///
  /// In en, this message translates to:
  /// **'Error capturing screenshot: {error}'**
  String mapErrorCapturingScreenshot(String error);

  /// AppBar tooltip for the debug log
  ///
  /// In en, this message translates to:
  /// **'Debug Terminal'**
  String get mapDebugTerminal;

  /// AppBar tooltip for capturing a screenshot
  ///
  /// In en, this message translates to:
  /// **'Screenshot'**
  String get mapScreenshotTooltip;

  /// Title of the map quick-settings card
  ///
  /// In en, this message translates to:
  /// **'Quick Settings'**
  String get mapQuickSettings;

  /// Quick-settings label for ping distance
  ///
  /// In en, this message translates to:
  /// **'Ping Dist: '**
  String get mapPingDist;

  /// Quick-settings label for discovery timeout
  ///
  /// In en, this message translates to:
  /// **'Timeout: '**
  String get mapTimeout;

  /// Quick-settings label for ping mode
  ///
  /// In en, this message translates to:
  /// **'Mode: '**
  String get mapMode;

  /// Compass FAB tooltip while heading-up is on
  ///
  /// In en, this message translates to:
  /// **'Stop heading-up and reset north'**
  String get mapStopHeadingUp;

  /// Compass FAB tooltip while heading-up is off
  ///
  /// In en, this message translates to:
  /// **'Rotate map with heading. Long-press to calibrate.'**
  String get mapRotateMapWithHeading;

  /// Compass FAB tooltip when rotation is locked north
  ///
  /// In en, this message translates to:
  /// **'Reset to North'**
  String get mapResetToNorth;

  /// Tracking FAB tooltip while a session is running
  ///
  /// In en, this message translates to:
  /// **'Stop tracking'**
  String get mapStopTracking;

  /// Tracking FAB tooltip while idle
  ///
  /// In en, this message translates to:
  /// **'Start tracking. Long-press for a blank-map session.'**
  String get mapStartTracking;

  /// Status when no LoRa companion is connected
  ///
  /// In en, this message translates to:
  /// **'No LoRa'**
  String get mapNoLora;

  /// Live sample count on the map status card
  ///
  /// In en, this message translates to:
  /// **'Samples: {count}'**
  String mapSamplesCount(String count);

  /// Snackbar when retrying Carpeater from the status chip
  ///
  /// In en, this message translates to:
  /// **'Retrying Carpeater...'**
  String get mapRetryingCarpeater;

  /// Snackbar when Carpeater retry succeeds
  ///
  /// In en, this message translates to:
  /// **'Carpeater reconnected'**
  String get mapCarpeaterReconnected;

  /// Snackbar when Carpeater retry fails
  ///
  /// In en, this message translates to:
  /// **'Carpeater retry failed'**
  String get mapCarpeaterRetryFailed;

  /// Carpeater status chip; CP abbreviation kept
  ///
  /// In en, this message translates to:
  /// **'CP: {state}'**
  String mapCarpeaterStatus(String state);

  /// Carpeater state: disabled
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get mapCarpeaterOff;

  /// Carpeater state: connecting
  ///
  /// In en, this message translates to:
  /// **'Connecting'**
  String get mapCarpeaterConnecting;

  /// Carpeater state: logging in
  ///
  /// In en, this message translates to:
  /// **'Login...'**
  String get mapCarpeaterLogin;

  /// Carpeater state: logged in
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get mapCarpeaterReady;

  /// Carpeater state: discovering
  ///
  /// In en, this message translates to:
  /// **'Scanning'**
  String get mapCarpeaterScanning;

  /// Carpeater state: fetching neighbours
  ///
  /// In en, this message translates to:
  /// **'Fetching'**
  String get mapCarpeaterFetching;

  /// Carpeater state: error
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get mapCarpeaterError;

  /// Atmospheric ducting status chip
  ///
  /// In en, this message translates to:
  /// **'Ducting: {risk}'**
  String mapDuctingStatus(String risk);

  /// Ducting risk: possible
  ///
  /// In en, this message translates to:
  /// **'Possible'**
  String get mapDuctingPossible;

  /// Ducting risk: likely
  ///
  /// In en, this message translates to:
  /// **'Likely'**
  String get mapDuctingLikely;

  /// Compact battery-saver badge on the status card
  ///
  /// In en, this message translates to:
  /// **'🔋 Saver'**
  String get mapBatterySaverBadge;

  /// Tooltip to disconnect the LoRa device
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get mapDisconnect;

  /// Tooltip to send a manual ping
  ///
  /// In en, this message translates to:
  /// **'Manual Ping'**
  String get mapManualPing;

  /// Snackbar when an action needs a connected radio
  ///
  /// In en, this message translates to:
  /// **'Connect LoRa device first'**
  String get mapConnectLoraFirst;

  /// Snackbar when a ping is blocked on GPS
  ///
  /// In en, this message translates to:
  /// **'Waiting for GPS location...'**
  String get mapWaitingForGps;

  /// Snackbar when a second ping is requested
  ///
  /// In en, this message translates to:
  /// **'A ping is already in progress'**
  String get mapPingAlreadyInProgress;

  /// Snackbar when a manual ping is sent
  ///
  /// In en, this message translates to:
  /// **'Sending ping...'**
  String get mapSendingPing;

  /// Snackbar when one repeater answers a ping
  ///
  /// In en, this message translates to:
  /// **'✅ Ping heard by {nodeId}'**
  String mapPingHeardBy(String nodeId);

  /// Snackbar when a ping discovers multiple repeaters
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{✅ Discovery complete: found {count} repeater} other{✅ Discovery complete: found {count} repeaters}}'**
  String mapDiscoveryComplete(int count);

  /// Snackbar when a ping times out
  ///
  /// In en, this message translates to:
  /// **'❌ No response - dead zone'**
  String get mapNoResponseDeadZone;

  /// Snackbar when a ping fails with an error
  ///
  /// In en, this message translates to:
  /// **'❌ Ping failed: {error}'**
  String mapPingFailed(String error);

  /// Title of the connection-method dialog
  ///
  /// In en, this message translates to:
  /// **'Connect LoRa Device'**
  String get mapConnectLoraDevice;

  /// Prompt in the connection-method dialog
  ///
  /// In en, this message translates to:
  /// **'Choose connection method:'**
  String get mapChooseConnectionMethod;

  /// Button to scan for USB companions
  ///
  /// In en, this message translates to:
  /// **'Scan USB Devices'**
  String get mapScanUsbDevices;

  /// Button to scan for Bluetooth companions
  ///
  /// In en, this message translates to:
  /// **'Scan Bluetooth'**
  String get mapScanBluetooth;

  /// Snackbar when USB scan finds nothing
  ///
  /// In en, this message translates to:
  /// **'No USB devices found'**
  String get mapNoUsbDevices;

  /// Title of the USB device picker
  ///
  /// In en, this message translates to:
  /// **'Select USB Device'**
  String get mapSelectUsbDevice;

  /// Fallback name when a USB device has no product name
  ///
  /// In en, this message translates to:
  /// **'USB Device'**
  String get mapUsbDeviceFallback;

  /// USB vendor and product IDs; VID/PID untranslated
  ///
  /// In en, this message translates to:
  /// **'VID: {vid}, PID: {pid}'**
  String mapVidPid(String vid, String pid);

  /// Snackbar after a USB connection succeeds
  ///
  /// In en, this message translates to:
  /// **'Connected via USB'**
  String get mapConnectedViaUsb;

  /// Snackbar when USB connect fails
  ///
  /// In en, this message translates to:
  /// **'Failed to connect USB device'**
  String get mapFailedConnectUsb;

  /// Snackbar when USB connect throws
  ///
  /// In en, this message translates to:
  /// **'USB error: {error}'**
  String mapUsbError(String error);

  /// Snackbar while connecting to a named Bluetooth device
  ///
  /// In en, this message translates to:
  /// **'Connecting to {name}...'**
  String mapConnectingTo(String name);

  /// Snackbar after a Bluetooth connection succeeds
  ///
  /// In en, this message translates to:
  /// **'Connected via Bluetooth!'**
  String get mapConnectedViaBluetooth;

  /// Snackbar when Bluetooth connect fails
  ///
  /// In en, this message translates to:
  /// **'Failed to connect Bluetooth device'**
  String get mapFailedConnectBluetooth;

  /// Title of the disconnect confirmation
  ///
  /// In en, this message translates to:
  /// **'Disconnect LoRa Device'**
  String get mapDisconnectLoraDevice;

  /// Body of the disconnect confirmation
  ///
  /// In en, this message translates to:
  /// **'Disconnect from your LoRa companion device?'**
  String get mapDisconnectConfirm;

  /// Snackbar after disconnecting LoRa
  ///
  /// In en, this message translates to:
  /// **'LoRa device disconnected'**
  String get mapLoraDisconnected;

  /// Snackbar when the LoRa connection dropped and automatic reconnection started
  ///
  /// In en, this message translates to:
  /// **'Connection lost. Reconnecting to {name}...'**
  String mapLoraReconnecting(String name);

  /// Snackbar when the LoRa device was reconnected automatically
  ///
  /// In en, this message translates to:
  /// **'Reconnected to {name}'**
  String mapLoraReconnected(String name);

  /// Snackbar while refreshing radio contacts
  ///
  /// In en, this message translates to:
  /// **'Refreshing contact list...'**
  String get mapRefreshingContactList;

  /// Snackbar after contact list refresh
  ///
  /// In en, this message translates to:
  /// **'Contact list updated'**
  String get mapContactListUpdated;

  /// Snackbar while scanning for repeaters
  ///
  /// In en, this message translates to:
  /// **'Scanning for repeaters...'**
  String get mapScanningForRepeaters;

  /// Snackbar when a repeater scan finds none
  ///
  /// In en, this message translates to:
  /// **'No repeaters found'**
  String get mapNoRepeatersFound;

  /// Snackbar after a repeater scan finds nodes
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Found {count} repeater} other{Found {count} repeaters}}'**
  String mapRepeatersFound(int count);

  /// Title of the sample details dialog
  ///
  /// In en, this message translates to:
  /// **'Sample Info'**
  String get mapSampleInfo;

  /// Label before ping success/fail/GPS-only
  ///
  /// In en, this message translates to:
  /// **'Status: '**
  String get mapStatusLabel;

  /// Sample ping status: success
  ///
  /// In en, this message translates to:
  /// **'✅ Success'**
  String get mapStatusSuccess;

  /// Sample ping status: failed
  ///
  /// In en, this message translates to:
  /// **'❌ Failed'**
  String get mapStatusFailed;

  /// Sample ping status: GPS-only
  ///
  /// In en, this message translates to:
  /// **'📍 GPS Only'**
  String get mapStatusGpsOnly;

  /// Sample timestamp row
  ///
  /// In en, this message translates to:
  /// **'Time: {timestamp}'**
  String mapTimeLabel(String timestamp);

  /// Label before the repeater name/id on a sample
  ///
  /// In en, this message translates to:
  /// **'Repeater: '**
  String get mapRepeaterLabel;

  /// Label before RSSI; RSSI untranslated
  ///
  /// In en, this message translates to:
  /// **'RSSI: '**
  String get mapRssiLabel;

  /// Label before SNR; SNR untranslated
  ///
  /// In en, this message translates to:
  /// **'SNR: '**
  String get mapSnrLabel;

  /// Label before ping response time
  ///
  /// In en, this message translates to:
  /// **'Response: '**
  String get mapResponseLabel;

  /// Hyperlink on the sample dialog opening the detailed measurement sheet
  ///
  /// In en, this message translates to:
  /// **'More details'**
  String get mapMoreDetails;

  /// Title of the detailed measurement bottom sheet
  ///
  /// In en, this message translates to:
  /// **'Measurement details'**
  String get mapSampleDetailsTitle;

  /// Label before a sample geohash
  ///
  /// In en, this message translates to:
  /// **'Geohash: '**
  String get mapGeohashLabel;

  /// Label before the companion radio device id
  ///
  /// In en, this message translates to:
  /// **'Device: '**
  String get mapDeviceLabel;

  /// Label before the operator/device source name of a sample
  ///
  /// In en, this message translates to:
  /// **'Source: '**
  String get mapSourceLabel;

  /// Header of the responder list in the detailed measurement sheet
  ///
  /// In en, this message translates to:
  /// **'Repeaters that responded ({count})'**
  String mapRespondersTitle(int count);

  /// Strongest RSSI across the responding repeaters
  ///
  /// In en, this message translates to:
  /// **'Best signal: {value}'**
  String mapBestSignal(String value);

  /// Shown when a failed ping has no recorded responses
  ///
  /// In en, this message translates to:
  /// **'No repeaters heard on this ping.'**
  String get mapNoResponders;

  /// Marks the tapped sample within the responder list
  ///
  /// In en, this message translates to:
  /// **'This measurement'**
  String get mapThisMeasurement;

  /// Label before ducting risk on sample info
  ///
  /// In en, this message translates to:
  /// **'Ducting: '**
  String get mapDuctingLabel;

  /// RSSI value with dBm unit symbol
  ///
  /// In en, this message translates to:
  /// **'RSSI: {value} dBm'**
  String mapRssiValue(String value);

  /// SNR value with dB unit symbol
  ///
  /// In en, this message translates to:
  /// **'SNR: {value} dB'**
  String mapSnrValue(String value);

  /// Title of the clustered-samples dialog
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} grouped sample} other{{count} grouped samples}}'**
  String mapGroupedSamples(int count);

  /// Successful ping count in a sample cluster
  ///
  /// In en, this message translates to:
  /// **'Successful: {count}'**
  String mapSuccessfulCount(int count);

  /// Failed ping count in a sample cluster
  ///
  /// In en, this message translates to:
  /// **'Failed: {count}'**
  String mapFailedCount(int count);

  /// GPS-only count in a sample cluster
  ///
  /// In en, this message translates to:
  /// **'GPS only: {count}'**
  String mapGpsOnlyCount(int count);

  /// Newest sample time in a cluster
  ///
  /// In en, this message translates to:
  /// **'Newest: {timestamp}'**
  String mapNewest(String timestamp);

  /// Hint in the clustered-samples dialog
  ///
  /// In en, this message translates to:
  /// **'Zoom in for a more detailed breakdown.'**
  String get mapZoomForBreakdown;

  /// Fallback repeater title when the radio has no name
  ///
  /// In en, this message translates to:
  /// **'Repeater {id}'**
  String mapRepeaterFallback(String id);

  /// Repeater ID row; ID untranslated
  ///
  /// In en, this message translates to:
  /// **'ID: {id}'**
  String mapIdLabel(String id);

  /// Snackbar after filtering coverage to one repeater
  ///
  /// In en, this message translates to:
  /// **'Filtering by {id}'**
  String mapFilteringBy(String id);

  /// Button to filter the map to this repeater
  ///
  /// In en, this message translates to:
  /// **'Filter by This'**
  String get mapFilterByThis;

  /// Button to pan the map to a repeater
  ///
  /// In en, this message translates to:
  /// **'Show on Map'**
  String get mapShowOnMap;

  /// Title of a coverage-cell details dialog
  ///
  /// In en, this message translates to:
  /// **'Coverage Square Info'**
  String get mapCoverageSquareInfo;

  /// Label before coverage sample count
  ///
  /// In en, this message translates to:
  /// **'Samples: '**
  String get mapSamplesLabel;

  /// Label before coverage success rate
  ///
  /// In en, this message translates to:
  /// **'Success Rate: '**
  String get mapSuccessRateLabel;

  /// Label before received ping count
  ///
  /// In en, this message translates to:
  /// **'Received: '**
  String get mapReceivedLabel;

  /// Label before lost ping count
  ///
  /// In en, this message translates to:
  /// **'Lost: '**
  String get mapLostLabel;

  /// Label before count of heard repeaters
  ///
  /// In en, this message translates to:
  /// **'Repeaters Heard: '**
  String get mapRepeatersHeard;

  /// Label before repeater ID list
  ///
  /// In en, this message translates to:
  /// **'Repeater IDs: '**
  String get mapRepeaterIds;

  /// Coverage success rate when there are no pings
  ///
  /// In en, this message translates to:
  /// **'No ping data'**
  String get mapNoPingData;

  /// Placeholder when a percentage cannot be computed
  ///
  /// In en, this message translates to:
  /// **'N/A'**
  String get mapNotAvailable;

  /// Title of the nearby-repeaters list
  ///
  /// In en, this message translates to:
  /// **'Nearby Repeaters ({count})'**
  String mapNearbyRepeaters(int count);

  /// Progress text while uploading to a named site
  ///
  /// In en, this message translates to:
  /// **'Uploading to {site}...'**
  String mapUploadingTo(String site);

  /// Progress text while uploading samples
  ///
  /// In en, this message translates to:
  /// **'Uploading samples...'**
  String get mapUploadingSamples;

  /// Upload batch progress
  ///
  /// In en, this message translates to:
  /// **'Batch {current} of {total}'**
  String mapUploadBatch(int current, int total);

  /// Title when every upload site succeeded
  ///
  /// In en, this message translates to:
  /// **'Upload Complete'**
  String get mapUploadComplete;

  /// Title when some upload sites failed
  ///
  /// In en, this message translates to:
  /// **'Upload Results'**
  String get mapUploadResults;

  /// Summary of multi-site upload results
  ///
  /// In en, this message translates to:
  /// **'Uploaded to {successCount} of {total} sites'**
  String mapUploadedToSites(int successCount, int total);

  /// Fallback site name for the legacy single-endpoint upload path
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get mapUploadFallbackName;

  /// Snackbar when upload throws
  ///
  /// In en, this message translates to:
  /// **'Upload error: {error}'**
  String mapUploadError(String error);

  /// Prompt in the manage-upload-sites sheet
  ///
  /// In en, this message translates to:
  /// **'Select which sites to upload to:'**
  String get mapSelectWhichSitesToUpload;

  /// Title of delete-upload-site confirmation
  ///
  /// In en, this message translates to:
  /// **'Delete Site'**
  String get mapDeleteSite;

  /// Confirm deleting a named upload site
  ///
  /// In en, this message translates to:
  /// **'Delete \"{name}\"?'**
  String mapDeleteSiteConfirm(String name);

  /// Button to add an upload endpoint
  ///
  /// In en, this message translates to:
  /// **'Add Site'**
  String get mapAddSite;

  /// Snackbar after saving upload site selection
  ///
  /// In en, this message translates to:
  /// **'Upload sites updated'**
  String get mapUploadSitesUpdated;

  /// Title of the edit-endpoint dialog
  ///
  /// In en, this message translates to:
  /// **'Edit Upload Site'**
  String get mapEditUploadSite;

  /// Upload endpoint name field
  ///
  /// In en, this message translates to:
  /// **'Site Name'**
  String get mapSiteName;

  /// Upload endpoint URL field; API untranslated
  ///
  /// In en, this message translates to:
  /// **'API URL'**
  String get mapApiUrl;

  /// Title of the add-endpoint dialog
  ///
  /// In en, this message translates to:
  /// **'Add Upload Site'**
  String get mapAddUploadSite;

  /// Hint for a new upload site name
  ///
  /// In en, this message translates to:
  /// **'e.g., My Personal Map'**
  String get mapSiteNameHint;

  /// Snackbar when offline tile download is unavailable
  ///
  /// In en, this message translates to:
  /// **'Tile cache not initialized'**
  String get mapTileCacheNotInitialized;

  /// Explanation in the offline-tile download dialog
  ///
  /// In en, this message translates to:
  /// **'Download map tiles for the current view area.'**
  String get mapDownloadTilesBlurb;

  /// Minimum zoom slider label
  ///
  /// In en, this message translates to:
  /// **'Min Zoom: {zoom}'**
  String mapMinZoom(String zoom);

  /// Maximum zoom slider label
  ///
  /// In en, this message translates to:
  /// **'Max Zoom: {zoom}'**
  String mapMaxZoom(String zoom);

  /// Estimated tile download size
  ///
  /// In en, this message translates to:
  /// **'{count} tiles (~{megabytes} MB)'**
  String mapTilesEstimate(int count, String megabytes);

  /// Warning when tile estimate is very large
  ///
  /// In en, this message translates to:
  /// **'Large download — consider a smaller area or zoom range'**
  String get mapLargeDownloadWarning;

  /// Title of the tile download progress dialog
  ///
  /// In en, this message translates to:
  /// **'Downloading Tiles'**
  String get mapDownloadingTiles;

  /// Tile download progress counts
  ///
  /// In en, this message translates to:
  /// **'{completed} / {total} tiles'**
  String mapTilesProgress(int completed, int total);

  /// Snackbar after tile download finishes
  ///
  /// In en, this message translates to:
  /// **'Downloaded {succeeded}/{total} tiles'**
  String mapDownloadedTiles(int succeeded, int total);

  /// Snackbar after cancelling tile download
  ///
  /// In en, this message translates to:
  /// **'Download cancelled ({count} tiles cached)'**
  String mapDownloadCancelled(int count);

  /// Snackbar when sharing a coverage image fails
  ///
  /// In en, this message translates to:
  /// **'Share failed: {error}'**
  String mapShareFailed(String error);

  /// Share-sheet subject for the coverage map image
  ///
  /// In en, this message translates to:
  /// **'MeshCore Wardrive Coverage'**
  String get mapCoverageShareSubject;

  /// Share-sheet body summarizing coverage stats
  ///
  /// In en, this message translates to:
  /// **'MeshCore Wardrive Coverage Map\n📍 {sampleCount} samples • {coverageCount} coverage areas\n✅ {successCount} success • ❌ {failCount} failed • {successRate}% rate\n🔁 {repeaterCount} repeaters discovered'**
  String mapCoverageShareText(
    String sampleCount,
    String coverageCount,
    String successCount,
    String failCount,
    String successRate,
    String repeaterCount,
  );

  /// Snackbar when repeater filter has no IDs
  ///
  /// In en, this message translates to:
  /// **'No repeaters found yet - do some wardriving first!'**
  String get mapNoRepeatersYet;

  /// Title of the repeater filter picker
  ///
  /// In en, this message translates to:
  /// **'Filter by Repeater'**
  String get mapFilterByRepeater;

  /// Snackbar after applying a repeater filter
  ///
  /// In en, this message translates to:
  /// **'Showing coverage from {id}'**
  String mapShowingCoverageFrom(String id);

  /// Snackbar after clearing the repeater filter
  ///
  /// In en, this message translates to:
  /// **'Repeater filter cleared'**
  String get mapRepeaterFilterCleared;

  /// Button to clear the repeater filter
  ///
  /// In en, this message translates to:
  /// **'Clear Filter'**
  String get mapClearFilter;

  /// Snackbar when coverage-gap search has no data
  ///
  /// In en, this message translates to:
  /// **'No coverage data yet - do some wardriving first!'**
  String get mapNoCoverageYet;

  /// Snackbar when no low-success coverage cells exist
  ///
  /// In en, this message translates to:
  /// **'No coverage gaps found! All areas have >30% success rate.'**
  String get mapNoCoverageGaps;

  /// Title of the coverage-gaps list
  ///
  /// In en, this message translates to:
  /// **'Coverage Gaps ({count})'**
  String mapCoverageGaps(int count);

  /// Title row for a coverage gap
  ///
  /// In en, this message translates to:
  /// **'{rate}% success rate'**
  String mapGapSuccessRate(String rate);

  /// Subtitle for a coverage gap
  ///
  /// In en, this message translates to:
  /// **'{coords}\n{received} received / {lost} lost'**
  String mapGapSubtitle(String coords, String received, String lost);

  /// Title when choosing a community-coverage source
  ///
  /// In en, this message translates to:
  /// **'Download from'**
  String get mapDownloadFrom;

  /// Snackbar while downloading community coverage
  ///
  /// In en, this message translates to:
  /// **'Downloading coverage data...'**
  String get mapDownloadingCoverage;

  /// Snackbar after community coverage download
  ///
  /// In en, this message translates to:
  /// **'Downloaded {count} coverage cells'**
  String mapDownloadedCoverageCells(int count);

  /// Snackbar when using cached community coverage
  ///
  /// In en, this message translates to:
  /// **'Loaded cached coverage (offline)'**
  String get mapLoadedCachedCoverage;

  /// Snackbar when community coverage download fails
  ///
  /// In en, this message translates to:
  /// **'Download failed: {error}'**
  String mapDownloadFailed(String error);

  /// Fallback error when no download error string is available
  ///
  /// In en, this message translates to:
  /// **'unknown error'**
  String get mapUnknownError;

  /// Community coverage cell success rate
  ///
  /// In en, this message translates to:
  /// **'Success Rate: {rate}%'**
  String mapCommunitySuccessRate(String rate);

  /// Header above community-coverage repeater list
  ///
  /// In en, this message translates to:
  /// **'Repeaters:'**
  String get mapRepeatersHeader;

  /// Community coverage last-update row
  ///
  /// In en, this message translates to:
  /// **'Last Update: {timestamp}'**
  String mapLastUpdate(String timestamp);

  /// Community coverage app-version row
  ///
  /// In en, this message translates to:
  /// **'App Version: {version}'**
  String mapAppVersionLabel(String version);

  /// Semantics label for the radio-position marker
  ///
  /// In en, this message translates to:
  /// **'Approximate radio position, uncertainty {uncertainty}'**
  String mapApproxRadioPositionUncertainty(String uncertainty);

  /// Snackbar when tapping the radio-position marker
  ///
  /// In en, this message translates to:
  /// **'Approximate radio position · {count} repeaters · ±{uncertainty}'**
  String mapApproxRadioPositionSnack(int count, String uncertainty);

  /// Semantics for the current-position marker on Wi-Fi
  ///
  /// In en, this message translates to:
  /// **'Current Wi-Fi location from beaconDB'**
  String get mapCurrentWifiLocation;

  /// Semantics for the current-position marker on fused GPS
  ///
  /// In en, this message translates to:
  /// **'Current fused Android location'**
  String get mapCurrentFusedLocation;

  /// Semantics for the heading-up location marker
  ///
  /// In en, this message translates to:
  /// **'{positionLabel}, heading {degrees} degrees'**
  String mapPositionHeadingSemantics(String positionLabel, String degrees);

  /// Analytics bottom tab label
  ///
  /// In en, this message translates to:
  /// **'Score'**
  String get analyticsTabScore;

  /// Analytics bottom tab label
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get analyticsTabTime;

  /// Analytics bottom tab label
  ///
  /// In en, this message translates to:
  /// **'Goals'**
  String get analyticsTabGoals;

  /// Analytics bottom tab and compare button
  ///
  /// In en, this message translates to:
  /// **'Compare'**
  String get analyticsTabCompare;

  /// Analytics bottom tab label
  ///
  /// In en, this message translates to:
  /// **'Repeaters'**
  String get analyticsTabRepeaters;

  /// Empty state when analytics has no ping samples
  ///
  /// In en, this message translates to:
  /// **'No ping data yet.\nDo some wardriving first!'**
  String get analyticsNoPingData;

  /// Empty state when analytics has no repeater samples
  ///
  /// In en, this message translates to:
  /// **'No repeater data yet.\nDo some wardriving first!'**
  String get analyticsNoRepeaterData;

  /// Coverage score card subtitle
  ///
  /// In en, this message translates to:
  /// **'Coverage Score'**
  String get analyticsCoverageScore;

  /// Coverage score statistic label
  ///
  /// In en, this message translates to:
  /// **'Cells'**
  String get analyticsStatCells;

  /// Coverage score statistic label
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get analyticsStatSuccess;

  /// Coverage score statistic label
  ///
  /// In en, this message translates to:
  /// **'Fresh'**
  String get analyticsStatFresh;

  /// Coverage score statistic label
  ///
  /// In en, this message translates to:
  /// **'Repeaters'**
  String get analyticsStatRepeaters;

  /// Score formula card title
  ///
  /// In en, this message translates to:
  /// **'How it\'\'s calculated'**
  String get analyticsHowCalculated;

  /// Coverage score formula
  ///
  /// In en, this message translates to:
  /// **'Score = Unique Cells × Success Rate × Freshness'**
  String get analyticsScoreFormula;

  /// Numeric breakdown of the coverage score
  ///
  /// In en, this message translates to:
  /// **'• {cells} cells × {rate} × {freshness} = {score}'**
  String analyticsScoreBreakdown(
    String cells,
    String rate,
    String freshness,
    String score,
  );

  /// Freshness weighting legend
  ///
  /// In en, this message translates to:
  /// **'• Freshness: <1d=100%, <7d=80%, <30d=50%, older=20%'**
  String get analyticsFreshnessLegend;

  /// Button to share coverage score
  ///
  /// In en, this message translates to:
  /// **'Share Score'**
  String get analyticsShareScore;

  /// Share-sheet body for coverage score
  ///
  /// In en, this message translates to:
  /// **'MeshCore Wardrive Score: {score} ({grade})\nCells: {cells} • Success: {success}% • Freshness: {freshness}%\nRepeaters: {repeaters} • Pings: {pings}'**
  String analyticsShareText(
    String score,
    String grade,
    String cells,
    String success,
    String freshness,
    String repeaters,
    String pings,
  );

  /// Time-of-day chart title
  ///
  /// In en, this message translates to:
  /// **'Success Rate by Hour'**
  String get analyticsSuccessRateByHour;

  /// Count of pings used in the hourly chart
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} ping analyzed} other{{count} pings analyzed}}'**
  String analyticsPingsAnalyzed(int count);

  /// Short ping count for tooltips and session pickers
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} ping} other{{count} pings}}'**
  String analyticsPingsCount(int count);

  /// Hourly bar chart tooltip
  ///
  /// In en, this message translates to:
  /// **'{time}\n{rate}% ({pings})'**
  String analyticsHourTooltip(String time, String rate, String pings);

  /// Best/worst hour section title
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get analyticsSummary;

  /// Best hour row label
  ///
  /// In en, this message translates to:
  /// **'Best hour'**
  String get analyticsBestHour;

  /// Worst hour row label
  ///
  /// In en, this message translates to:
  /// **'Worst hour'**
  String get analyticsWorstHour;

  /// Hour and success-rate value
  ///
  /// In en, this message translates to:
  /// **'{hour}:00 — {rate}%'**
  String analyticsHourValue(String hour, String rate);

  /// Time-of-day period section title
  ///
  /// In en, this message translates to:
  /// **'By Period'**
  String get analyticsByPeriod;

  /// Night period label
  ///
  /// In en, this message translates to:
  /// **'Night (0-6)'**
  String get analyticsPeriodNight;

  /// Morning period label
  ///
  /// In en, this message translates to:
  /// **'Morning (6-12)'**
  String get analyticsPeriodMorning;

  /// Afternoon period label
  ///
  /// In en, this message translates to:
  /// **'Afternoon (12-18)'**
  String get analyticsPeriodAfternoon;

  /// Evening period label
  ///
  /// In en, this message translates to:
  /// **'Evening (18-24)'**
  String get analyticsPeriodEvening;

  /// Placeholder when a period has no samples
  ///
  /// In en, this message translates to:
  /// **'No data'**
  String get analyticsNoData;

  /// Empty coverage-goal title
  ///
  /// In en, this message translates to:
  /// **'No coverage goal set'**
  String get analyticsNoCoverageGoal;

  /// Empty coverage-goal hint
  ///
  /// In en, this message translates to:
  /// **'Set a target area to track your wardriving progress.'**
  String get analyticsSetGoalHint;

  /// Button to create a coverage goal
  ///
  /// In en, this message translates to:
  /// **'Set Goal Area'**
  String get analyticsSetGoalArea;

  /// Coverage goal section title
  ///
  /// In en, this message translates to:
  /// **'Coverage Goal'**
  String get analyticsCoverageGoal;

  /// Edit coverage goal button
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get analyticsEdit;

  /// Coverage goal center and radius summary
  ///
  /// In en, this message translates to:
  /// **'Center: {lat}, {lon}\nRadius: {radius}'**
  String analyticsGoalCenterRadius(String lat, String lon, String radius);

  /// Label under the coverage-goal percent
  ///
  /// In en, this message translates to:
  /// **'covered'**
  String get analyticsCovered;

  /// Goal statistic label
  ///
  /// In en, this message translates to:
  /// **'Total cells in area'**
  String get analyticsTotalCellsInArea;

  /// Goal statistic for covered cells
  ///
  /// In en, this message translates to:
  /// **'Covered (>0% success)'**
  String get analyticsCoveredAboveZero;

  /// Goal statistic for partial cells
  ///
  /// In en, this message translates to:
  /// **'Partial (<30% success)'**
  String get analyticsPartialBelow30;

  /// Goal statistic for uncovered cells
  ///
  /// In en, this message translates to:
  /// **'Uncovered'**
  String get analyticsUncovered;

  /// Goal statistic for pings in the goal area
  ///
  /// In en, this message translates to:
  /// **'Pings in area'**
  String get analyticsPingsInArea;

  /// Goal radius in miles
  ///
  /// In en, this message translates to:
  /// **'{miles} miles'**
  String analyticsRadiusMiles(String miles);

  /// Goal radius in meters
  ///
  /// In en, this message translates to:
  /// **'{meters} m'**
  String analyticsRadiusMeters(String meters);

  /// Coverage goal radius option
  ///
  /// In en, this message translates to:
  /// **'1 mile'**
  String get analyticsMile1;

  /// Coverage goal radius option
  ///
  /// In en, this message translates to:
  /// **'5 miles'**
  String get analyticsMiles5;

  /// Coverage goal radius option
  ///
  /// In en, this message translates to:
  /// **'10 miles'**
  String get analyticsMiles10;

  /// Coverage goal radius option
  ///
  /// In en, this message translates to:
  /// **'25 miles'**
  String get analyticsMiles25;

  /// Set-goal dialog title
  ///
  /// In en, this message translates to:
  /// **'Set Coverage Goal'**
  String get analyticsSetCoverageGoal;

  /// Goal dialog when centering on GPS
  ///
  /// In en, this message translates to:
  /// **'Center: Your current GPS location'**
  String get analyticsCenterCurrentGps;

  /// Goal dialog center coordinates
  ///
  /// In en, this message translates to:
  /// **'Center: {lat}, {lon}'**
  String analyticsCenterCoords(String lat, String lon);

  /// Goal dialog radius heading
  ///
  /// In en, this message translates to:
  /// **'Radius:'**
  String get analyticsRadiusLabel;

  /// Confirm coverage goal button
  ///
  /// In en, this message translates to:
  /// **'Set Goal'**
  String get analyticsSetGoal;

  /// Empty state when fewer than two sessions exist
  ///
  /// In en, this message translates to:
  /// **'Need at least 2 completed sessions\nwith ping data to compare.'**
  String get analyticsNeedTwoSessions;

  /// Session comparison heading
  ///
  /// In en, this message translates to:
  /// **'Compare Sessions'**
  String get analyticsCompareSessions;

  /// Baseline session picker label
  ///
  /// In en, this message translates to:
  /// **'Session A (baseline)'**
  String get analyticsSessionABaseline;

  /// Compare session picker label
  ///
  /// In en, this message translates to:
  /// **'Session B (compare)'**
  String get analyticsSessionBCompare;

  /// Comparison row label
  ///
  /// In en, this message translates to:
  /// **'Samples'**
  String get analyticsSamples;

  /// Comparison row label
  ///
  /// In en, this message translates to:
  /// **'Success Rate'**
  String get analyticsSuccessRate;

  /// Comparison row label
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get analyticsDistance;

  /// Session distance in miles
  ///
  /// In en, this message translates to:
  /// **'{miles} mi'**
  String analyticsDistanceMiles(String miles);

  /// Comparison changes heading
  ///
  /// In en, this message translates to:
  /// **'Coverage Changes'**
  String get analyticsCoverageChanges;

  /// Comparison change row
  ///
  /// In en, this message translates to:
  /// **'New coverage'**
  String get analyticsNewCoverage;

  /// Comparison change row
  ///
  /// In en, this message translates to:
  /// **'Lost coverage'**
  String get analyticsLostCoverage;

  /// Comparison change row
  ///
  /// In en, this message translates to:
  /// **'Improved (>10%)'**
  String get analyticsImproved;

  /// Comparison change row
  ///
  /// In en, this message translates to:
  /// **'Degraded (>10%)'**
  String get analyticsDegraded;

  /// Comparison change row
  ///
  /// In en, this message translates to:
  /// **'Unchanged'**
  String get analyticsUnchanged;

  /// Session picker dialog option
  ///
  /// In en, this message translates to:
  /// **'{date} — {pings}, {rate}%'**
  String analyticsSessionOption(String date, String pings, String rate);

  /// Selected session summary
  ///
  /// In en, this message translates to:
  /// **'{date} — {pings}'**
  String analyticsSessionSelected(String date, String pings);

  /// Repeater reliability list count
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} repeater} other{{count} repeaters}}'**
  String analyticsRepeaterCount(int count);

  /// Sort dropdown prefix
  ///
  /// In en, this message translates to:
  /// **'Sort: '**
  String get analyticsSort;

  /// Repeater sort option
  ///
  /// In en, this message translates to:
  /// **'Reliability'**
  String get analyticsSortReliability;

  /// Repeater sort option
  ///
  /// In en, this message translates to:
  /// **'Response Time'**
  String get analyticsSortResponseTime;

  /// Repeater sort option
  ///
  /// In en, this message translates to:
  /// **'Ping Count'**
  String get analyticsSortPingCount;

  /// Repeater card mini-stat label
  ///
  /// In en, this message translates to:
  /// **'Pings'**
  String get analyticsMiniPings;

  /// Repeater card mini-stat label
  ///
  /// In en, this message translates to:
  /// **'Avg Response'**
  String get analyticsMiniAvgResponse;

  /// Repeater card mini-stat label
  ///
  /// In en, this message translates to:
  /// **'Consistency'**
  String get analyticsMiniConsistency;

  /// Repeater card mini-stat label
  ///
  /// In en, this message translates to:
  /// **'Trend'**
  String get analyticsMiniTrend;

  /// Average response time value
  ///
  /// In en, this message translates to:
  /// **'{ms} ms'**
  String analyticsAvgResponseMs(String ms);

  /// Repeater reliability trend label
  ///
  /// In en, this message translates to:
  /// **'{trend, select, improving{improving} degrading{degrading} other{stable}}'**
  String analyticsTrend(String trend);

  /// Repeater first/last seen line
  ///
  /// In en, this message translates to:
  /// **'First seen: {first} • Last: {last}'**
  String analyticsFirstLastSeen(String first, String last);

  /// Delete session dialog title
  ///
  /// In en, this message translates to:
  /// **'Delete Session?'**
  String get sessionDeleteTitle;

  /// Delete session dialog body
  ///
  /// In en, this message translates to:
  /// **'This will remove the session record. Sample data is not affected.'**
  String get sessionDeleteBody;

  /// Edit notes dialog title
  ///
  /// In en, this message translates to:
  /// **'Session Notes'**
  String get sessionNotesTitle;

  /// Session notes field hint
  ///
  /// In en, this message translates to:
  /// **'Add notes about this session...'**
  String get sessionNotesHint;

  /// Empty session history body
  ///
  /// In en, this message translates to:
  /// **'No sessions yet.\n\nStart tracking to record your first session!'**
  String get sessionEmpty;

  /// Tooltip to edit session notes
  ///
  /// In en, this message translates to:
  /// **'Edit Notes'**
  String get sessionEditNotes;

  /// Time range for an active session
  ///
  /// In en, this message translates to:
  /// **'{start} – In progress'**
  String sessionTimeInProgress(String start);

  /// Completed session time range
  ///
  /// In en, this message translates to:
  /// **'{start} – {end}'**
  String sessionTimeRange(String start, String end);

  /// Session duration in hours and minutes
  ///
  /// In en, this message translates to:
  /// **'{hours}h {minutes}m'**
  String sessionDurationHoursMinutes(int hours, int minutes);

  /// Session duration in minutes and seconds
  ///
  /// In en, this message translates to:
  /// **'{minutes}m {seconds}s'**
  String sessionDurationMinutesSeconds(int minutes, int seconds);

  /// Session duration in seconds
  ///
  /// In en, this message translates to:
  /// **'{seconds}s'**
  String sessionDurationSeconds(int seconds);

  /// Session distance in kilometers
  ///
  /// In en, this message translates to:
  /// **'{km} km'**
  String sessionDistanceKm(String km);

  /// Session distance in miles
  ///
  /// In en, this message translates to:
  /// **'{mi} mi'**
  String sessionDistanceMi(String mi);

  /// Session GPS point count
  ///
  /// In en, this message translates to:
  /// **'{count} pts'**
  String sessionPoints(int count);

  /// Successful ping count on a session card
  ///
  /// In en, this message translates to:
  /// **'{count} heard'**
  String sessionHeard(int count);

  /// Hint when a session can open the map
  ///
  /// In en, this message translates to:
  /// **'Tap to view on map'**
  String get sessionTapToViewOnMap;

  /// Empty repeater health body
  ///
  /// In en, this message translates to:
  /// **'No repeater data yet.\nDo some wardriving first!'**
  String get repeaterHealthEmpty;

  /// AppBar chip for offline repeaters
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} offline} other{{count} offline}}'**
  String repeaterHealthOfflineCount(int count);

  /// AppBar chip for degrading repeaters
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} degrading} other{{count} degrading}}'**
  String repeaterHealthDegradingCount(int count);

  /// Repeater health list count
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} repeater} other{{count} repeaters}}'**
  String repeaterHealthRepeaterCount(int count);

  /// Sort dropdown prefix
  ///
  /// In en, this message translates to:
  /// **'Sort: '**
  String get repeaterHealthSort;

  /// Repeater health sort option
  ///
  /// In en, this message translates to:
  /// **'Reliability'**
  String get repeaterHealthSortReliability;

  /// Repeater health sort option
  ///
  /// In en, this message translates to:
  /// **'Response Time'**
  String get repeaterHealthSortResponseTime;

  /// Repeater health sort option
  ///
  /// In en, this message translates to:
  /// **'Ping Count'**
  String get repeaterHealthSortPingCount;

  /// Repeater health sort option
  ///
  /// In en, this message translates to:
  /// **'Alerts First'**
  String get repeaterHealthSortAlertsFirst;

  /// Repeater card mini-stat label
  ///
  /// In en, this message translates to:
  /// **'Pings'**
  String get repeaterHealthMiniPings;

  /// Repeater card mini-stat label
  ///
  /// In en, this message translates to:
  /// **'Avg Resp'**
  String get repeaterHealthMiniAvgResp;

  /// Repeater card mini-stat label
  ///
  /// In en, this message translates to:
  /// **'Cells'**
  String get repeaterHealthMiniCells;

  /// Repeater card mini-stat label
  ///
  /// In en, this message translates to:
  /// **'Trend'**
  String get repeaterHealthMiniTrend;

  /// Average response time on a repeater card
  ///
  /// In en, this message translates to:
  /// **'{ms}ms'**
  String repeaterHealthAvgRespMs(String ms);

  /// Improving trend label
  ///
  /// In en, this message translates to:
  /// **'▲ Up'**
  String get repeaterHealthTrendUp;

  /// Degrading trend label
  ///
  /// In en, this message translates to:
  /// **'▼ Down'**
  String get repeaterHealthTrendDown;

  /// Stable trend label
  ///
  /// In en, this message translates to:
  /// **'— Stable'**
  String get repeaterHealthTrendStable;

  /// Repeater first/last seen line
  ///
  /// In en, this message translates to:
  /// **'First: {first} • Last: {last}'**
  String repeaterHealthFirstLast(String first, String last);

  /// Repeater first/last seen line when offline
  ///
  /// In en, this message translates to:
  /// **'First: {first} • Last: {last} • ⚠️ Offline {days}d'**
  String repeaterHealthFirstLastOffline(String first, String last, int days);

  /// Repeater detail AppBar title
  ///
  /// In en, this message translates to:
  /// **'Repeater {id}'**
  String repeaterHealthDetailTitle(String id);

  /// SNR chart title
  ///
  /// In en, this message translates to:
  /// **'SNR Over Time'**
  String get repeaterHealthSnrOverTime;

  /// Weekly chart title
  ///
  /// In en, this message translates to:
  /// **'Weekly Success Rate'**
  String get repeaterHealthWeeklySuccessRate;

  /// Time-of-day section title
  ///
  /// In en, this message translates to:
  /// **'Best Time of Day'**
  String get repeaterHealthBestTimeOfDay;

  /// Recent pings section title
  ///
  /// In en, this message translates to:
  /// **'Recent Pings'**
  String get repeaterHealthRecentPings;

  /// Detail summary label
  ///
  /// In en, this message translates to:
  /// **'Success Rate'**
  String get repeaterHealthSuccessRate;

  /// Detail summary label
  ///
  /// In en, this message translates to:
  /// **'Total Pings'**
  String get repeaterHealthTotalPings;

  /// Detail summary label
  ///
  /// In en, this message translates to:
  /// **'Heard'**
  String get repeaterHealthHeard;

  /// Detail summary label
  ///
  /// In en, this message translates to:
  /// **'Coverage'**
  String get repeaterHealthCoverage;

  /// Coverage cell count on the detail card
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} cell} other{{count} cells}}'**
  String repeaterHealthCellCount(int count);

  /// Degrading-rate warning on the detail card
  ///
  /// In en, this message translates to:
  /// **'7-day rate ({rate7}) dropped vs 30-day ({rate30})'**
  String repeaterHealthDegradingAlert(String rate7, String rate30);

  /// Average response footer on the detail card
  ///
  /// In en, this message translates to:
  /// **'Avg response: {value}'**
  String repeaterHealthAvgResponse(String value);

  /// Fallback when average response is missing
  ///
  /// In en, this message translates to:
  /// **'N/A'**
  String get repeaterHealthAvgResponseNa;

  /// Empty SNR chart
  ///
  /// In en, this message translates to:
  /// **'No SNR data'**
  String get repeaterHealthNoSnrData;

  /// Empty weekly chart
  ///
  /// In en, this message translates to:
  /// **'No data'**
  String get repeaterHealthNoData;

  /// Empty weekly chart after grouping
  ///
  /// In en, this message translates to:
  /// **'No weekly data'**
  String get repeaterHealthNoWeeklyData;

  /// Detail time-of-day period
  ///
  /// In en, this message translates to:
  /// **'Night (0-6)'**
  String get repeaterHealthPeriodNight;

  /// Detail time-of-day period
  ///
  /// In en, this message translates to:
  /// **'Morning (6-12)'**
  String get repeaterHealthPeriodMorning;

  /// Detail time-of-day period
  ///
  /// In en, this message translates to:
  /// **'Afternoon (12-18)'**
  String get repeaterHealthPeriodAfternoon;

  /// Detail time-of-day period
  ///
  /// In en, this message translates to:
  /// **'Evening (18-24)'**
  String get repeaterHealthPeriodEvening;

  /// Period success rate with ping count
  ///
  /// In en, this message translates to:
  /// **'{rate}% ({pings})'**
  String repeaterHealthPeriodRate(String rate, String pings);

  /// Weekly bar tooltip
  ///
  /// In en, this message translates to:
  /// **'{week}\n{rate}% ({pings})'**
  String repeaterHealthWeekTooltip(String week, String rate, String pings);

  /// Empty recent-pings list
  ///
  /// In en, this message translates to:
  /// **'No pings recorded'**
  String get repeaterHealthNoPingsRecorded;

  /// Empty device comparison body
  ///
  /// In en, this message translates to:
  /// **'No devices tracked yet.\n\nConnect a LoRa device and start wardriving — the app will automatically log which device you use.'**
  String get deviceComparisonEmpty;

  /// Tracked device count heading
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} device tracked} other{{count} devices tracked}}'**
  String deviceComparisonTracked(int count);

  /// Device comparison section title
  ///
  /// In en, this message translates to:
  /// **'Compare Devices'**
  String get deviceComparisonCompareDevices;

  /// First device dropdown hint
  ///
  /// In en, this message translates to:
  /// **'Device A'**
  String get deviceComparisonDeviceA;

  /// Second device dropdown hint
  ///
  /// In en, this message translates to:
  /// **'Device B'**
  String get deviceComparisonDeviceB;

  /// Between the two device dropdowns
  ///
  /// In en, this message translates to:
  /// **'vs'**
  String get deviceComparisonVs;

  /// Device card mini-stat label
  ///
  /// In en, this message translates to:
  /// **'Pings'**
  String get deviceComparisonMiniPings;

  /// Device card mini-stat label
  ///
  /// In en, this message translates to:
  /// **'Cells'**
  String get deviceComparisonMiniCells;

  /// Device card mini-stat label
  ///
  /// In en, this message translates to:
  /// **'Avg Resp'**
  String get deviceComparisonMiniAvgResp;

  /// Device card mini-stat label
  ///
  /// In en, this message translates to:
  /// **'Avg SNR'**
  String get deviceComparisonMiniAvgSnr;

  /// Average response on a device card
  ///
  /// In en, this message translates to:
  /// **'{ms}ms'**
  String deviceComparisonAvgRespMs(String ms);

  /// Device first/last used line
  ///
  /// In en, this message translates to:
  /// **'First: {first} • Last: {last}'**
  String deviceComparisonFirstLast(String first, String last);

  /// Comparison table header
  ///
  /// In en, this message translates to:
  /// **'Stat'**
  String get deviceComparisonStat;

  /// Comparison table header
  ///
  /// In en, this message translates to:
  /// **'Winner'**
  String get deviceComparisonWinner;

  /// Comparison row label
  ///
  /// In en, this message translates to:
  /// **'Total Pings'**
  String get deviceComparisonTotalPings;

  /// Comparison row label
  ///
  /// In en, this message translates to:
  /// **'Success Rate'**
  String get deviceComparisonSuccessRate;

  /// Comparison row label
  ///
  /// In en, this message translates to:
  /// **'Failures'**
  String get deviceComparisonFailures;

  /// Comparison row label
  ///
  /// In en, this message translates to:
  /// **'Unique Cells'**
  String get deviceComparisonUniqueCells;

  /// Comparison row label
  ///
  /// In en, this message translates to:
  /// **'Avg Response'**
  String get deviceComparisonAvgResponse;

  /// Comparison row label
  ///
  /// In en, this message translates to:
  /// **'Avg SNR'**
  String get deviceComparisonAvgSnr;

  /// Comparison row label
  ///
  /// In en, this message translates to:
  /// **'Avg RSSI'**
  String get deviceComparisonAvgRssi;

  /// Comparison winner when values are equal
  ///
  /// In en, this message translates to:
  /// **'Tie'**
  String get deviceComparisonTie;

  /// Signal trend metric segment; keep RSSI
  ///
  /// In en, this message translates to:
  /// **'RSSI'**
  String get signalTrendRssi;

  /// Signal trend metric segment; keep SNR
  ///
  /// In en, this message translates to:
  /// **'SNR'**
  String get signalTrendSnr;

  /// Signal trend metric segment
  ///
  /// In en, this message translates to:
  /// **'Response'**
  String get signalTrendResponse;

  /// Empty signal trend body
  ///
  /// In en, this message translates to:
  /// **'No signal data yet.\nDo some wardriving with pings enabled.'**
  String get signalTrendEmpty;

  /// Empty chart for the selected metric
  ///
  /// In en, this message translates to:
  /// **'No {label} data available.'**
  String signalTrendNoMetricData(String label);

  /// Metric name used in the empty-chart message
  ///
  /// In en, this message translates to:
  /// **'response time'**
  String get signalTrendResponseTimeLabel;

  /// Signal stats card label
  ///
  /// In en, this message translates to:
  /// **'Min'**
  String get signalTrendMin;

  /// Signal stats card label
  ///
  /// In en, this message translates to:
  /// **'Avg'**
  String get signalTrendAvg;

  /// Signal stats card label
  ///
  /// In en, this message translates to:
  /// **'Max'**
  String get signalTrendMax;

  /// Signal stats card label
  ///
  /// In en, this message translates to:
  /// **'Pts'**
  String get signalTrendPts;

  /// Ducting forecast AppBar title
  ///
  /// In en, this message translates to:
  /// **'Tropo Ducting Forecast'**
  String get ductingTitle;

  /// Tooltip to open the forecast website
  ///
  /// In en, this message translates to:
  /// **'Open in browser'**
  String get ductingOpenInBrowser;

  /// Forecast region dropdown label
  ///
  /// In en, this message translates to:
  /// **'Region'**
  String get ductingRegion;

  /// Forecast image error
  ///
  /// In en, this message translates to:
  /// **'Failed to load forecast image.\nCheck internet connection.'**
  String get ductingFailedToLoad;

  /// Forecast offset in hours
  ///
  /// In en, this message translates to:
  /// **'+{hours}h'**
  String ductingTimeHours(int hours);

  /// Forecast offset in whole days
  ///
  /// In en, this message translates to:
  /// **'+{days}d'**
  String ductingTimeDays(int days);

  /// Forecast offset in days and leftover hours
  ///
  /// In en, this message translates to:
  /// **'+{days}d {hours}h'**
  String ductingTimeDaysHours(int days, int hours);

  /// Current forecast frame index
  ///
  /// In en, this message translates to:
  /// **'{current} / {total}'**
  String ductingFrameIndex(int current, int total);

  /// Ducting intensity legend
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get ductingLegendNone;

  /// Ducting intensity legend
  ///
  /// In en, this message translates to:
  /// **'Marginal'**
  String get ductingLegendMarginal;

  /// Ducting intensity legend
  ///
  /// In en, this message translates to:
  /// **'Moderate'**
  String get ductingLegendModerate;

  /// Ducting intensity legend
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get ductingLegendHigh;

  /// Ducting intensity legend
  ///
  /// In en, this message translates to:
  /// **'Extreme'**
  String get ductingLegendExtreme;

  /// Forecast map attribution
  ///
  /// In en, this message translates to:
  /// **'Forecast © William R. Hepburn — dxinfocentre.com'**
  String get ductingAttribution;

  /// Ducting forecast region
  ///
  /// In en, this message translates to:
  /// **'Western North America'**
  String get ductingRegionWam;

  /// Ducting forecast region
  ///
  /// In en, this message translates to:
  /// **'Eastern North America'**
  String get ductingRegionEam;

  /// Ducting forecast region
  ///
  /// In en, this message translates to:
  /// **'Eastern North Pacific'**
  String get ductingRegionEnp;

  /// Ducting forecast region
  ///
  /// In en, this message translates to:
  /// **'Eastern South Pacific'**
  String get ductingRegionEsp;

  /// Ducting forecast region
  ///
  /// In en, this message translates to:
  /// **'Gulf-Caribbean'**
  String get ductingRegionCar;

  /// Ducting forecast region
  ///
  /// In en, this message translates to:
  /// **'Northern South America'**
  String get ductingRegionNsa;

  /// Ducting forecast region
  ///
  /// In en, this message translates to:
  /// **'Central South America'**
  String get ductingRegionSam;

  /// Ducting forecast region
  ///
  /// In en, this message translates to:
  /// **'South Atlantic'**
  String get ductingRegionSat;

  /// Ducting forecast region
  ///
  /// In en, this message translates to:
  /// **'North Atlantic'**
  String get ductingRegionNat;

  /// Ducting forecast region
  ///
  /// In en, this message translates to:
  /// **'Eastern North Atlantic'**
  String get ductingRegionEnt;

  /// Ducting forecast region
  ///
  /// In en, this message translates to:
  /// **'Northwestern Europe'**
  String get ductingRegionNwe;

  /// Ducting forecast region
  ///
  /// In en, this message translates to:
  /// **'Europe'**
  String get ductingRegionEur;

  /// Ducting forecast region
  ///
  /// In en, this message translates to:
  /// **'Eastern Europe'**
  String get ductingRegionEeu;

  /// Ducting forecast region
  ///
  /// In en, this message translates to:
  /// **'South Africa'**
  String get ductingRegionAfi;

  /// Ducting forecast region
  ///
  /// In en, this message translates to:
  /// **'Middle East'**
  String get ductingRegionMid;

  /// Ducting forecast region
  ///
  /// In en, this message translates to:
  /// **'North Central Asia'**
  String get ductingRegionNca;

  /// Ducting forecast region
  ///
  /// In en, this message translates to:
  /// **'Indian Ocean'**
  String get ductingRegionIno;

  /// Ducting forecast region
  ///
  /// In en, this message translates to:
  /// **'Southeast Asia'**
  String get ductingRegionSea;

  /// Ducting forecast region
  ///
  /// In en, this message translates to:
  /// **'Far East'**
  String get ductingRegionEas;

  /// Ducting forecast region
  ///
  /// In en, this message translates to:
  /// **'Eastern Siberia'**
  String get ductingRegionNea;

  /// Ducting forecast region
  ///
  /// In en, this message translates to:
  /// **'Australia & New Zealand'**
  String get ductingRegionAus;

  /// Ducting forecast region
  ///
  /// In en, this message translates to:
  /// **'Oceania'**
  String get ductingRegionOce;

  /// Ducting forecast region
  ///
  /// In en, this message translates to:
  /// **'Western North Pacific'**
  String get ductingRegionWnp;

  /// Snackbar when export has no logs
  ///
  /// In en, this message translates to:
  /// **'No logs to export'**
  String get debugLogNoLogsToExport;

  /// File picker title when exporting logs
  ///
  /// In en, this message translates to:
  /// **'Choose save location'**
  String get debugLogChooseSaveLocation;

  /// Snackbar after exporting logs
  ///
  /// In en, this message translates to:
  /// **'Logs saved to:\n{fileName}'**
  String debugLogSavedTo(String fileName);

  /// Tooltip when auto-scroll is enabled
  ///
  /// In en, this message translates to:
  /// **'Auto-scroll ON'**
  String get debugLogAutoScrollOn;

  /// Tooltip when auto-scroll is disabled
  ///
  /// In en, this message translates to:
  /// **'Auto-scroll OFF'**
  String get debugLogAutoScrollOff;

  /// Tooltip to export debug logs
  ///
  /// In en, this message translates to:
  /// **'Export logs'**
  String get debugLogExportLogs;

  /// Tooltip to clear debug logs
  ///
  /// In en, this message translates to:
  /// **'Clear logs'**
  String get debugLogClearLogs;

  /// Empty debug terminal body
  ///
  /// In en, this message translates to:
  /// **'No logs yet.\n\nConnect your LoRa device and start pinging!'**
  String get debugLogEmpty;

  /// Share-sheet subject for a debug log file
  ///
  /// In en, this message translates to:
  /// **'MeshCore Wardrive Debug Log'**
  String get debugDiagnosticsShareSubject;

  /// Share-sheet body for a debug log file
  ///
  /// In en, this message translates to:
  /// **'Debug log for troubleshooting GPS and auto-ping issues'**
  String get debugDiagnosticsShareText;

  /// Snackbar when sharing a log file fails
  ///
  /// In en, this message translates to:
  /// **'Error sharing file: {error}'**
  String debugDiagnosticsErrorSharing(String error);

  /// Delete log dialog title
  ///
  /// In en, this message translates to:
  /// **'Delete Log'**
  String get debugDiagnosticsDeleteTitle;

  /// Delete log dialog body
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this log file?'**
  String get debugDiagnosticsDeleteBody;

  /// Snackbar after deleting a log file
  ///
  /// In en, this message translates to:
  /// **'Log file deleted'**
  String get debugDiagnosticsLogDeleted;

  /// Snackbar when deleting a log file fails
  ///
  /// In en, this message translates to:
  /// **'Error deleting file: {error}'**
  String debugDiagnosticsErrorDeleting(String error);

  /// Snackbar when reading a log file fails
  ///
  /// In en, this message translates to:
  /// **'Error reading file: {error}'**
  String debugDiagnosticsErrorReading(String error);

  /// Tooltip to reload log files
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get debugDiagnosticsRefresh;

  /// Diagnostics intro heading
  ///
  /// In en, this message translates to:
  /// **'Troubleshooting Samsung Devices'**
  String get debugDiagnosticsSamsungTitle;

  /// Diagnostics intro body
  ///
  /// In en, this message translates to:
  /// **'This screen shows detailed debug logs for tracking GPS, auto-ping, and service events. If you\'\'re experiencing issues with auto-ping or GPS tracking, share the latest log file with the developer.'**
  String get debugDiagnosticsSamsungBody;

  /// Current debug-log session filename
  ///
  /// In en, this message translates to:
  /// **'Current session: {name}'**
  String debugDiagnosticsCurrentSession(String name);

  /// Fallback when no debug session file exists
  ///
  /// In en, this message translates to:
  /// **'Not started'**
  String get debugDiagnosticsNotStarted;

  /// Empty diagnostics log list
  ///
  /// In en, this message translates to:
  /// **'No debug logs found.\nStart tracking to generate logs.'**
  String get debugDiagnosticsEmpty;

  /// Log file menu action
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get debugDiagnosticsView;

  /// Share-sheet subject when viewing a log file
  ///
  /// In en, this message translates to:
  /// **'MeshCore Wardrive Debug Log: {fileName}'**
  String debugDiagnosticsShareSubjectWithFile(String fileName);

  /// Log file size in bytes
  ///
  /// In en, this message translates to:
  /// **'{bytes} B'**
  String debugDiagnosticsSizeBytes(int bytes);

  /// Log file size in kilobytes
  ///
  /// In en, this message translates to:
  /// **'{kb} KB'**
  String debugDiagnosticsSizeKb(String kb);

  /// Log file size in megabytes
  ///
  /// In en, this message translates to:
  /// **'{mb} MB'**
  String debugDiagnosticsSizeMb(String mb);

  /// Progress text when every achievement is unlocked
  ///
  /// In en, this message translates to:
  /// **'All achievements unlocked!'**
  String get achievementsAllUnlocked;

  /// Progress text for remaining achievements
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} remaining} other{{count} remaining}}'**
  String achievementsRemaining(int count);

  /// Unlock date line under an achievement
  ///
  /// In en, this message translates to:
  /// **'Unlocked {date}'**
  String achievementsUnlockedOn(String date);

  /// Map snackbar when an achievement unlocks
  ///
  /// In en, this message translates to:
  /// **'🏆 Achievement unlocked: {icon} {title}'**
  String achievementsUnlockedSnackbar(String icon, String title);

  /// Title for the first_ping achievement
  ///
  /// In en, this message translates to:
  /// **'First Ping'**
  String get achievementFirstPingTitle;

  /// Description for the first_ping achievement
  ///
  /// In en, this message translates to:
  /// **'Send your first ping'**
  String get achievementFirstPingDescription;

  /// Title for the pings_100 achievement
  ///
  /// In en, this message translates to:
  /// **'Century'**
  String get achievementPings100Title;

  /// Description for the pings_100 achievement
  ///
  /// In en, this message translates to:
  /// **'Send 100 pings'**
  String get achievementPings100Description;

  /// Title for the pings_1000 achievement
  ///
  /// In en, this message translates to:
  /// **'Kilopinger'**
  String get achievementPings1000Title;

  /// Description for the pings_1000 achievement
  ///
  /// In en, this message translates to:
  /// **'Send 1,000 pings'**
  String get achievementPings1000Description;

  /// Title for the pings_10000 achievement
  ///
  /// In en, this message translates to:
  /// **'Ping Lord'**
  String get achievementPings10000Title;

  /// Description for the pings_10000 achievement
  ///
  /// In en, this message translates to:
  /// **'Send 10,000 pings'**
  String get achievementPings10000Description;

  /// Title for the first_repeater achievement
  ///
  /// In en, this message translates to:
  /// **'First Contact'**
  String get achievementFirstRepeaterTitle;

  /// Description for the first_repeater achievement
  ///
  /// In en, this message translates to:
  /// **'Discover your first repeater'**
  String get achievementFirstRepeaterDescription;

  /// Title for the repeaters_10 achievement
  ///
  /// In en, this message translates to:
  /// **'Network Explorer'**
  String get achievementRepeaters10Title;

  /// Description for the repeaters_10 achievement
  ///
  /// In en, this message translates to:
  /// **'Discover 10 repeaters'**
  String get achievementRepeaters10Description;

  /// Title for the repeaters_50 achievement
  ///
  /// In en, this message translates to:
  /// **'Mesh Master'**
  String get achievementRepeaters50Title;

  /// Description for the repeaters_50 achievement
  ///
  /// In en, this message translates to:
  /// **'Discover 50 repeaters'**
  String get achievementRepeaters50Description;

  /// Title for the miles_10 achievement
  ///
  /// In en, this message translates to:
  /// **'Road Warrior'**
  String get achievementMiles10Title;

  /// Description for the miles_10 achievement
  ///
  /// In en, this message translates to:
  /// **'Drive 10 miles wardriving'**
  String get achievementMiles10Description;

  /// Title for the miles_100 achievement
  ///
  /// In en, this message translates to:
  /// **'Highway Hero'**
  String get achievementMiles100Title;

  /// Description for the miles_100 achievement
  ///
  /// In en, this message translates to:
  /// **'Drive 100 miles wardriving'**
  String get achievementMiles100Description;

  /// Title for the miles_500 achievement
  ///
  /// In en, this message translates to:
  /// **'Cross Country'**
  String get achievementMiles500Title;

  /// Description for the miles_500 achievement
  ///
  /// In en, this message translates to:
  /// **'Drive 500 miles wardriving'**
  String get achievementMiles500Description;

  /// Title for the cells_50 achievement
  ///
  /// In en, this message translates to:
  /// **'Area Scout'**
  String get achievementCells50Title;

  /// Description for the cells_50 achievement
  ///
  /// In en, this message translates to:
  /// **'Cover 50 unique cells'**
  String get achievementCells50Description;

  /// Title for the cells_500 achievement
  ///
  /// In en, this message translates to:
  /// **'Territory King'**
  String get achievementCells500Title;

  /// Description for the cells_500 achievement
  ///
  /// In en, this message translates to:
  /// **'Cover 500 unique cells'**
  String get achievementCells500Description;

  /// Title for the first_session achievement
  ///
  /// In en, this message translates to:
  /// **'Getting Started'**
  String get achievementFirstSessionTitle;

  /// Description for the first_session achievement
  ///
  /// In en, this message translates to:
  /// **'Complete your first session'**
  String get achievementFirstSessionDescription;

  /// Title for the sessions_50 achievement
  ///
  /// In en, this message translates to:
  /// **'Dedicated Driver'**
  String get achievementSessions50Title;

  /// Description for the sessions_50 achievement
  ///
  /// In en, this message translates to:
  /// **'Complete 50 sessions'**
  String get achievementSessions50Description;

  /// Title for the hidden smolensk_legend achievement
  ///
  /// In en, this message translates to:
  /// **'Be a Legend of Smolensk Mesh Networks'**
  String get achievementSmolenskLegendTitle;

  /// Description for the hidden smolensk_legend achievement
  ///
  /// In en, this message translates to:
  /// **'You know what you did.'**
  String get achievementSmolenskLegendDescription;

  /// Foreground notification title; keep identical across locales
  ///
  /// In en, this message translates to:
  /// **'MeshCore Wardrive'**
  String get notificationBrandTitle;

  /// Android notification channel name for location tracking
  ///
  /// In en, this message translates to:
  /// **'MeshCore Wardrive Location Tracking'**
  String get notificationChannelName;

  /// Android notification channel description for location tracking
  ///
  /// In en, this message translates to:
  /// **'This notification appears when location tracking is active'**
  String get notificationChannelDescription;

  /// Foreground notification text when tracking starts
  ///
  /// In en, this message translates to:
  /// **'Location tracking active'**
  String get notificationTrackingActive;

  /// Foreground notification text while a ping is in flight
  ///
  /// In en, this message translates to:
  /// **'Pinging...'**
  String get notificationPinging;

  /// Foreground notification text when a ping is heard
  ///
  /// In en, this message translates to:
  /// **'✅ Heard by {id}'**
  String notificationHeardBy(String id);

  /// Fallback node label in the heard-by notification
  ///
  /// In en, this message translates to:
  /// **'repeater'**
  String get notificationRepeaterFallback;

  /// Foreground notification text when a ping times out
  ///
  /// In en, this message translates to:
  /// **'❌ No response'**
  String get notificationNoResponse;

  /// Foreground notification live session stats
  ///
  /// In en, this message translates to:
  /// **'✅ {rate}% | 📍 {count} pings | 🛣️ {distance}mi'**
  String notificationLiveStats(String rate, int count, String distance);

  /// Foreground notification when Carpeater finds no neighbours
  ///
  /// In en, this message translates to:
  /// **'Carpeater: No neighbours'**
  String get notificationCarpeaterNoNeighbours;

  /// Foreground notification when Carpeater finds neighbours
  ///
  /// In en, this message translates to:
  /// **'Carpeater: {count} neighbours found'**
  String notificationCarpeaterNeighboursFound(int count);

  /// Steady foreground notification text in Carpeater mode
  ///
  /// In en, this message translates to:
  /// **'Carpeater mode active'**
  String get notificationCarpeaterActive;

  /// Foreground notification action button that stops location tracking
  ///
  /// In en, this message translates to:
  /// **'Stop Tracking'**
  String get notificationStopTracking;

  /// User-visible error when location permission is denied
  ///
  /// In en, this message translates to:
  /// **'Location permission was denied.'**
  String get locationPermissionDenied;

  /// User-visible error when location permission is denied forever
  ///
  /// In en, this message translates to:
  /// **'Location permission is permanently denied. Enable it in Android settings.'**
  String get locationPermissionPermanentlyDenied;

  /// User-visible error when Android location services are off
  ///
  /// In en, this message translates to:
  /// **'Android location services are disabled.'**
  String get locationServicesDisabled;

  /// User-visible error when tracking fails to start
  ///
  /// In en, this message translates to:
  /// **'Could not start Android location tracking: {error}'**
  String locationTrackingStartFailed(String error);

  /// Home widget status while a session is recording
  ///
  /// In en, this message translates to:
  /// **'Tracking'**
  String get widgetStatusTracking;

  /// Home widget status while not recording
  ///
  /// In en, this message translates to:
  /// **'Idle'**
  String get widgetStatusIdle;
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
