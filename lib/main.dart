import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'l10n/app_locale.dart';
import 'l10n/generated/app_localizations.dart';
import 'screens/map_screen.dart';
import 'services/internet_connectivity_service.dart';
import 'services/screen_wake_service.dart';
import 'services/settings_service.dart';
import 'widgets/offline_banner.dart';

void main() {
  // Lock to portrait mode (true north)
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  MyAppState createState() => MyAppState();

  static MyAppState? of(BuildContext context) {
    return context.findAncestorStateOfType<MyAppState>();
  }
}

class MyAppState extends State<MyApp> {
  InterfaceThemeMode _interfaceTheme = InterfaceThemeMode.system;
  AppLocalePreference _localePreference = AppLocalePreference.system;
  late final InternetConnectivityService _connectivityService;

  /// Material theme mode derived from the persisted interface preference;
  /// exposed for [ThemeFlow] dialogs.
  ThemeMode get themeMode => switch (_interfaceTheme) {
    InterfaceThemeMode.system => ThemeMode.system,
    InterfaceThemeMode.light => ThemeMode.light,
    InterfaceThemeMode.dark => ThemeMode.dark,
  };

  AppLocalePreference get localePreference => _localePreference;

  Locale? get _materialLocale {
    return switch (_localePreference) {
      AppLocalePreference.system => null,
      AppLocalePreference.en => const Locale('en'),
      AppLocalePreference.ru => const Locale('ru'),
    };
  }

  @override
  void initState() {
    super.initState();
    _connectivityService = InternetConnectivityService()..start();
    _loadThemeMode();
    _loadAppLocalePreference();
    _loadKeepScreenOn();
  }

  @override
  void dispose() {
    _connectivityService.dispose();
    super.dispose();
  }

  Future<void> _loadThemeMode() async {
    final preference = await SettingsService().getInterfaceThemeMode();
    if (!mounted) return;
    setState(() {
      _interfaceTheme = preference;
    });
  }

  Future<void> _loadKeepScreenOn() async {
    final keepScreenOn = await SettingsService().getKeepScreenOn();
    await ScreenWakeService.instance.setAlwaysOn(keepScreenOn);
  }

  Future<void> _loadAppLocalePreference() async {
    final preference = await SettingsService().getAppLocalePreference();
    if (!mounted) return;
    setState(() {
      _localePreference = preference;
    });
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final preference = switch (mode) {
      ThemeMode.system => InterfaceThemeMode.system,
      ThemeMode.light => InterfaceThemeMode.light,
      ThemeMode.dark => InterfaceThemeMode.dark,
    };
    setState(() {
      _interfaceTheme = preference;
    });
    await SettingsService().setInterfaceThemeMode(preference);
  }

  Future<void> setAppLocalePreference(AppLocalePreference preference) async {
    setState(() {
      _localePreference = preference;
    });
    await SettingsService().setAppLocalePreference(preference);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MeshCore Wardrive',
      locale: _materialLocale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => OfflineAppFrame(
        connectivity: _connectivityService,
        child: child ?? const SizedBox.shrink(),
      ),
      themeMode: themeMode,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF121212),
        cardColor: const Color(0xFF1E1E1E),
      ),
      home: const MapScreen(),
    );
  }
}
