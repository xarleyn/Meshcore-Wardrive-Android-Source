# Localization Implementation Plan

> **Status: executed and shipped.** Localization (gen_l10n, EN+RU catalogs,
> in-app language switcher) went out in v1.0.43; the `- [ ]` checkboxes below
> are kept as written in the original plan.

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship official Flutter gen_l10n with English + Russian catalogs, an in-app language switcher, and all user-visible copy moved off string literals.

**Architecture:** ARB catalogs generate `AppLocalizations`. `SettingsService` stores `app_locale` (`system` / `en` / `ru`). `MyApp` passes `locale` into `MaterialApp` (null = follow device). Widgets use `AppLocalizations.of(context)`; services use `lookupAppLocalizations(AppLocale.resolve(...))`. Android XML labels for the home widget use `values` / `values-ru`.

**Tech Stack:** Flutter `gen_l10n`, `flutter_localizations`, `intl` 0.20.x, SharedPreferences, existing `SettingsService` / `MyApp` theme pattern.

**Spec:** `docs/superpowers/specs/2026-08-20-localization-design.md`

**Toolchain:** every Flutter/Dart command from repo root after sourcing `.toolchain/env.ps1` (see AGENTS.md).

```powershell
. .\.toolchain\env.ps1
flutter gen-l10n
dart format lib test
flutter analyze
flutter test
```

On Git Bash: `powershell.exe -NoProfile -Command ". .\\.toolchain\\env.ps1; flutter gen-l10n"`

---

## File map

| File | Responsibility |
| --- | --- |
| `l10n.yaml` | gen_l10n config |
| `pubspec.yaml` | `flutter_localizations`, `intl` bump, `generate: true` |
| `lib/l10n/app_en.arb` | Template catalog |
| `lib/l10n/app_ru.arb` | Russian catalog (same keys) |
| `lib/l10n/generated/` | Committed generated Dart |
| `lib/l10n/app_locale.dart` | `AppLocalePreference`, `AppLocale.resolve` |
| `lib/l10n/achievement_l10n.dart` | `id` → title/description (Task 8) |
| `lib/main.dart` | Load/set preference, `MaterialApp` delegates + locale |
| `lib/services/settings_service.dart` | Persist + export `app_locale` |
| `lib/screens/settings/sections/app_device_section.dart` | Language tile |
| `lib/screens/map_screen.dart` | Language dialog + later map copy |
| `test/helpers/l10n_harness.dart` | Widget test wrapper |
| `test/app_locale_test.dart` | Resolve + persistence |
| `android/.../values/strings.xml` | Widget XML labels |
| `android/.../values-ru/strings.xml` | Russian widget XML labels |

Do not edit `lib/l10n/generated/` by hand. Regenerate with `flutter gen-l10n` after every ARB change.

Extraction tasks (4–8) are larger than a typical 2–5 minute step: they are mechanical catalog moves, not design work. Splitting each string into its own TDD cycle would thrash context. Follow the protocol below and commit once per task.

---

## Agent extraction protocol

Use this for Tasks 4–8. Do not invent a second i18n layer.

1. Find user-visible literals in the files listed for that task (`Text('…')`, `title:`, `subtitle:`, `tooltip:`, `SnackBar`, `hintText`, `'title':` / `'desc':` in achievements).
2. Add the key to **both** `app_en.arb` and `app_ru.arb` in the same edit. English value = current UI string (fix obvious typos only). Russian = real translation using the spec glossary. Add `@key` with `description` on the template.
3. For counts, use ICU plurals (`one` / `few` / `many` / `other` on ru; `one` / `other` on en). Never `"$n repeater(s)"`.
4. Replace the literal with `AppLocalizations.of(context).theKey` (or a `final l10n = AppLocalizations.of(context)` at the top of `build` / the extension method). Remove `const` from that widget if it becomes non-const.
5. Leave debug `print`, preference keys, URLs, protocol names, and device-provided names alone.
6. Run `flutter gen-l10n`, then `dart format` on touched Dart files.
7. Update widget tests for those files to wrap with `pumpWithL10n` and `find.text(l10n.someKey)`.
8. Grep the task’s files for leftover Title-Case English UI strings. Fix before moving on.

Example (settings switch):

Before:

```dart
SwitchListTile(
  title: const Text('Keep Screen On'),
  subtitle: const Text(
    'Prevent the screen from sleeping while the app is open',
  ),
```

`app_en.arb` excerpt:

```json
"settingsKeepScreenOn": "Keep Screen On",
"@settingsKeepScreenOn": {
  "description": "Settings toggle title; keeps the display awake"
},
"settingsKeepScreenOnSubtitle": "Prevent the screen from sleeping while the app is open",
"@settingsKeepScreenOnSubtitle": {
  "description": "Settings toggle subtitle for keep-screen-on"
}
```

`app_ru.arb` excerpt:

```json
"settingsKeepScreenOn": "Не гасить экран",
"settingsKeepScreenOnSubtitle": "Экран не переходит в сон, пока приложение открыто"
```

After:

```dart
SwitchListTile(
  title: Text(AppLocalizations.of(context).settingsKeepScreenOn),
  subtitle: Text(AppLocalizations.of(context).settingsKeepScreenOnSubtitle),
```

Plural example (en):

```json
"mapRepeatersFound": "{count, plural, one{Found {count} repeater} other{Found {count} repeaters}}",
"@mapRepeatersFound": {
  "description": "Snackbar after a repeater scan",
  "placeholders": {
    "count": {"type": "int"}
  }
}
```

Plural example (ru):

```json
"mapRepeatersFound": "{count, plural, one{Найден {count} репитер} few{Найдено {count} репитера} many{Найдено {count} репитеров} other{Найдено {count} репитера}}"
```

---

### Task 1: gen_l10n tooling

**Files:**
- Create: `l10n.yaml`
- Create: `lib/l10n/app_en.arb`
- Create: `lib/l10n/app_ru.arb`
- Modify: `pubspec.yaml`

- [ ] **Step 1: Add l10n.yaml**

```yaml
arb-dir: lib/l10n
template-arb-file: app_en.arb
output-dir: lib/l10n/generated
output-localization-file: app_localizations.dart
nullable-getter: false
preferred-supported-locales:
  - en
use-escaping: true
```

Do not set `synthetic-package`.

- [ ] **Step 2: Seed ARB files**

`lib/l10n/app_en.arb` (valid JSON; keep `@@locale`):

```json
{
  "@@locale": "en",
  "language": "Language",
  "@language": {
    "description": "Settings tile title for in-app language"
  },
  "languageSystem": "System default",
  "@languageSystem": {
    "description": "Language choice that follows the device locale"
  },
  "languageEnglish": "English",
  "@languageEnglish": {
    "description": "English endonym; do not translate in other ARBs"
  },
  "languageRussian": "Русский",
  "@languageRussian": {
    "description": "Russian endonym; do not translate in other ARBs"
  },
  "languagePickerTitle": "Choose language",
  "@languagePickerTitle": {
    "description": "Dialog title for the language picker"
  }
}
```

`lib/l10n/app_ru.arb`:

```json
{
  "@@locale": "ru",
  "language": "Язык",
  "languageSystem": "Системный язык",
  "languageEnglish": "English",
  "languageRussian": "Русский",
  "languagePickerTitle": "Выбор языка"
}
```

- [ ] **Step 3: Update pubspec.yaml**

Under `dependencies`, add:

```yaml
  flutter_localizations:
    sdk: flutter
```

Change `intl: ^0.19.0` to `intl: any` (resolves to the SDK-pinned 0.20.x).

Under `flutter:` add `generate: true` next to `uses-material-design: true`.

- [ ] **Step 4: Generate and verify**

```powershell
. .\.toolchain\env.ps1
flutter pub get
flutter gen-l10n
```

Expected: `lib/l10n/generated/app_localizations.dart`, `app_localizations_en.dart`, `app_localizations_ru.dart` exist. `AppLocalizations.of` return type is non-nullable.

- [ ] **Step 5: Commit**

```powershell
git add l10n.yaml pubspec.yaml pubspec.lock lib/l10n
git commit -m "$(cat <<'EOF'
Add Flutter gen_l10n catalogs for English and Russian.

EOF
)"
```

---

### Task 2: AppLocale + Settings persistence

**Files:**
- Create: `lib/l10n/app_locale.dart`
- Create: `test/app_locale_test.dart`
- Modify: `lib/services/settings_service.dart`
- Modify: `test/settings_service_test.dart`

- [ ] **Step 1: Write failing tests in `test/app_locale_test.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_wardrive/l10n/app_locale.dart';
import 'package:meshcore_wardrive/services/settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppLocale.resolve', () {
    test('forced ru ignores device language', () {
      expect(
        AppLocale.resolve(AppLocalePreference.ru, const Locale('en', 'US')),
        const Locale('ru'),
      );
    });

    test('system uses device when supported', () {
      expect(
        AppLocale.resolve(AppLocalePreference.system, const Locale('ru', 'RU')),
        const Locale('ru'),
      );
    });

    test('system falls back to English for unsupported languages', () {
      expect(
        AppLocale.resolve(AppLocalePreference.system, const Locale('de')),
        const Locale('en'),
      );
    });
  });

  group('SettingsService app locale', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('defaults to system', () async {
      expect(
        await SettingsService().getAppLocalePreference(),
        AppLocalePreference.system,
      );
    });

    test('persists ru', () async {
      final settings = SettingsService();
      await settings.setAppLocalePreference(AppLocalePreference.ru);
      expect(
        await settings.getAppLocalePreference(),
        AppLocalePreference.ru,
      );
    });

    test('unknown stored value falls back to system', () async {
      SharedPreferences.setMockInitialValues({'app_locale': 'zh'});
      expect(
        await SettingsService().getAppLocalePreference(),
        AppLocalePreference.system,
      );
    });

    test('export includes app_locale when set', () async {
      await SettingsService().setAppLocalePreference(AppLocalePreference.en);
      final exported = await SettingsService().exportSettings();
      expect(exported['app_locale'], 'en');
    });
  });
}
```

- [ ] **Step 2: Run tests — expect FAIL** (missing types)

```powershell
. .\.toolchain\env.ps1
flutter test test/app_locale_test.dart
```

- [ ] **Step 3: Implement `lib/l10n/app_locale.dart`**

```dart
import 'package:flutter/material.dart';

import 'generated/app_localizations.dart';

enum AppLocalePreference { system, en, ru }

class AppLocale {
  static const List<Locale> supported = [Locale('en'), Locale('ru')];

  static AppLocalePreference parse(String? raw) {
    return switch (raw) {
      'en' => AppLocalePreference.en,
      'ru' => AppLocalePreference.ru,
      'system' || null => AppLocalePreference.system,
      _ => AppLocalePreference.system,
    };
  }

  static String persist(AppLocalePreference preference) => preference.name;

  static Locale resolve(AppLocalePreference preference, Locale system) {
    return switch (preference) {
      AppLocalePreference.en => const Locale('en'),
      AppLocalePreference.ru => const Locale('ru'),
      AppLocalePreference.system =>
        supported.any((locale) => locale.languageCode == system.languageCode)
            ? Locale(system.languageCode)
            : const Locale('en'),
    };
  }

  static AppLocalizations lookup(
    AppLocalePreference preference,
    Locale system,
  ) {
    return lookupAppLocalizations(resolve(preference, system));
  }
}
```

- [ ] **Step 4: Persist on SettingsService**

Add `_appLocaleKey = 'app_locale'`. Import `app_locale.dart`.

```dart
Future<AppLocalePreference> getAppLocalePreference() async {
  final prefs = await SharedPreferences.getInstance();
  return AppLocale.parse(prefs.getString(_appLocaleKey));
}

Future<void> setAppLocalePreference(AppLocalePreference value) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_appLocaleKey, AppLocale.persist(value));
}
```

Append `_appLocaleKey` to `_exportKeys` next to `'theme_mode'`.

- [ ] **Step 5: Run tests — expect PASS**

```powershell
. .\.toolchain\env.ps1
flutter test test/app_locale_test.dart test/settings_service_test.dart
```

- [ ] **Step 6: Commit**

```powershell
git add lib/l10n/app_locale.dart lib/services/settings_service.dart test/app_locale_test.dart test/settings_service_test.dart
git commit -m "$(cat <<'EOF'
Persist in-app locale preference with system/en/ru resolution.

EOF
)"
```

---

### Task 3: MaterialApp wiring + language picker

**Files:**
- Modify: `lib/main.dart`
- Modify: `lib/screens/map_screen.dart` (theme-selector neighbors ~3814–3870)
- Modify: `lib/screens/settings/sections/app_device_section.dart`
- Create: `test/helpers/l10n_harness.dart`

- [ ] **Step 1: Add `test/helpers/l10n_harness.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_wardrive/l10n/generated/app_localizations.dart';

Future<AppLocalizations> pumpWithL10n(
  WidgetTester tester,
  Widget home, {
  Locale locale = const Locale('en'),
}) async {
  late AppLocalizations l10n;
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) {
          l10n = AppLocalizations.of(context);
          return home;
        },
      ),
    ),
  );
  return l10n;
}
```

- [ ] **Step 2: Wire MyApp**

Import `l10n/app_locale.dart` and `l10n/generated/app_localizations.dart`.

On `_MyAppState` add `AppLocalePreference _localePreference = AppLocalePreference.system;` and load it next to `_loadThemeMode` via `SettingsService().getAppLocalePreference()`.

```dart
Future<void> setAppLocalePreference(AppLocalePreference preference) async {
  setState(() {
    _localePreference = preference;
  });
  await SettingsService().setAppLocalePreference(preference);
}

Locale? get _materialLocale {
  return switch (_localePreference) {
    AppLocalePreference.system => null,
    AppLocalePreference.en => const Locale('en'),
    AppLocalePreference.ru => const Locale('ru'),
  };
}
```

On `MaterialApp`:

```dart
locale: _materialLocale,
localizationsDelegates: AppLocalizations.localizationsDelegates,
supportedLocales: AppLocalizations.supportedLocales,
```

Keep `title: 'MeshCore Wardrive'`. Do not add a redundant `flutter_localizations` import if the generated `localizationsDelegates` already includes the global delegates.

- [ ] **Step 3: Language dialog on MapScreen**

Mirror `_showInterfaceThemeSelector`. Add `_getAppLocalePreferenceText()` and `_showLanguageSelector()` that call `MyApp.of(context)!.setAppLocalePreference`. Dialog children: system / English / Russian using `AppLocalizations.of(context)` (`languageSystem`, `languageEnglish`, `languageRussian`, `languagePickerTitle`).

- [ ] **Step 4: Settings tile**

In `app_device_section.dart`, immediately after the Map Theme `ListTile`:

```dart
ListTile(
  title: Text(AppLocalizations.of(context).language),
  subtitle: Text(_getAppLocalePreferenceText()),
  trailing: const Icon(Icons.language),
  onTap: () {
    Navigator.pop(context);
    _showLanguageSelector();
  },
),
```

- [ ] **Step 5: Verify**

```powershell
. .\.toolchain\env.ps1
dart format lib/main.dart lib/screens/map_screen.dart lib/screens/settings/sections/app_device_section.dart lib/l10n test/helpers/l10n_harness.dart
flutter analyze lib/main.dart lib/l10n lib/screens/settings/sections/app_device_section.dart
flutter test test/app_locale_test.dart test/settings_service_test.dart
```

Expected: format clean, no new analyzer issues in those paths, tests pass.

- [ ] **Step 6: Commit**

```powershell
git add lib/main.dart lib/screens/map_screen.dart lib/screens/settings/sections/app_device_section.dart test/helpers/l10n_harness.dart
git commit -m "$(cat <<'EOF'
Wire MaterialApp locale and add a Settings language picker.

EOF
)"
```

---

### Task 4: Settings copy

**Files:**
- Modify: `lib/screens/settings/**`
- Modify: `test/settings_screen_test.dart`
- Modify: `test/upload_endpoint_selection_dialog_test.dart`
- Modify: ARB files + regenerate

`SettingsScreen` currently has `this.title = 'Settings'`. Change the main constructor so `title` is optional (`String? title`). In `build`, use `widget.title ?? AppLocalizations.of(context).settingsTitle`. Add `settingsTitle` and scroll tooltips (`Scroll to top` / `Scroll to bottom`) to both ARBs.

- [ ] **Step 1: Extract every user-visible string under `lib/screens/settings/`** using the extraction protocol. Include dialogs (Ignore Repeaters, upload endpoint copy, text-input Save/Cancel).

- [ ] **Step 2: Update tests** to `pumpWithL10n` (or a local `MaterialApp` with the same delegates). Assert `l10n.settingsTitle` instead of `'Settings'`. Keep structural tests (scroll buttons, text controller) intact.

- [ ] **Step 3: Verify**

```powershell
. .\.toolchain\env.ps1
flutter gen-l10n
dart format lib/screens/settings lib/l10n test/settings_screen_test.dart test/upload_endpoint_selection_dialog_test.dart test/helpers
flutter test test/settings_screen_test.dart test/upload_endpoint_selection_dialog_test.dart
```

Grep gate — remaining `const Text('` in settings should only be non-UI (empty, unit suffixes like `'m'`):

```powershell
rg -n "const Text\('" lib/screens/settings
```

- [ ] **Step 4: Commit**

```powershell
git add lib/screens/settings lib/l10n test/settings_screen_test.dart test/upload_endpoint_selection_dialog_test.dart
git commit -m "$(cat <<'EOF'
Localize Settings screens and dialogs.

EOF
)"
```

---

### Task 5: Shared widgets

**Files:**
- Modify: `lib/widgets/offline_banner.dart`
- Modify: `lib/widgets/compass_calibration.dart`
- Modify: `lib/widgets/bluetooth_device_picker_dialog.dart`
- Modify: `test/offline_banner_test.dart`
- Modify: `test/compass_calibration_sheet_test.dart`
- Modify: `test/bluetooth_device_picker_dialog_test.dart`
- Modify: ARB files + regenerate

- [ ] **Step 1: Extract copy** (offline banner text + semantics label; compass sheet; Bluetooth picker titles `Select Bluetooth Device`, `Previously used`, `Nearby`).

- [ ] **Step 2: Point tests at `pumpWithL10n`** and `find.text(l10n.…)` for chrome. Keep device-name fixtures (`MeshCore One`) untranslated.

- [ ] **Step 3: Add a Russian smoke assertion** in `offline_banner_test.dart`: pump with `locale: Locale('ru')`, go offline, `find.text` the Russian banner string.

- [ ] **Step 4: Verify**

```powershell
. .\.toolchain\env.ps1
flutter gen-l10n
flutter test test/offline_banner_test.dart test/compass_calibration_sheet_test.dart test/bluetooth_device_picker_dialog_test.dart
```

- [ ] **Step 5: Commit**

```powershell
git add lib/widgets lib/l10n test/offline_banner_test.dart test/compass_calibration_sheet_test.dart test/bluetooth_device_picker_dialog_test.dart
git commit -m "$(cat <<'EOF'
Localize offline banner, compass sheet, and Bluetooth picker.

EOF
)"
```

---

### Task 6: Map screen chrome

**Files:**
- Modify: `lib/screens/map_screen.dart` (user-visible copy only; do not refactor structure)
- Modify: ARB files + regenerate

Largest wave (~165 strings). Work top-to-bottom: permission dialogs, snackbars, FAB tooltips, bottom sheets, session empty dialog, theme dialogs. Use ICU for `Found N repeater(s)`.

Do **not** localize KML/GPX XML, screenshot filenames, or `DateFormat('yyyyMMdd_HHmmss')` patterns used as file names.

Replace remaining **display** `DateFormat('MMM d, h:mm a')` with locale-aware formatters using `Localizations.localeOf(context).toString()`.

- [ ] **Step 1: Extract map UI copy** via the extraction protocol.

- [ ] **Step 2: Verify**

```powershell
. .\.toolchain\env.ps1
flutter gen-l10n
dart format lib/screens/map_screen.dart lib/l10n
flutter analyze lib/screens/map_screen.dart
flutter test
```

Expected: existing tests pass. Analyzer: no new issues in `map_screen.dart`.

- [ ] **Step 3: Commit**

```powershell
git add lib/screens/map_screen.dart lib/l10n
git commit -m "$(cat <<'EOF'
Localize map chrome, dialogs, and snackbars.

EOF
)"
```

---

### Task 7: Remaining screens

**Files:**
- Modify: `lib/screens/analytics_screen.dart`
- Modify: `lib/screens/session_history_screen.dart`
- Modify: `lib/screens/repeater_health_screen.dart`
- Modify: `lib/screens/device_comparison_screen.dart`
- Modify: `lib/screens/signal_trend_screen.dart`
- Modify: `lib/screens/ducting_forecast_screen.dart`
- Modify: `lib/screens/debug_log_screen.dart` (chrome only, not log lines)
- Modify: `lib/screens/debug_diagnostics_screen.dart`
- Modify: `lib/screens/achievements_screen.dart` (static chrome; achievement titles wait for Task 8)
- Modify: ARB files + regenerate

Localize axis labels, empty states, buttons. Pass `locale` into `DateFormat` constructors that produce visible dates.

- [ ] **Step 1: Extract each screen** using the protocol. One commit for the wave unless a screen fails analyze — then split only that file.

- [ ] **Step 2: Verify**

```powershell
. .\.toolchain\env.ps1
flutter gen-l10n
dart format lib/screens lib/l10n
flutter test
```

- [ ] **Step 3: Commit**

```powershell
git add lib/screens lib/l10n
git commit -m "$(cat <<'EOF'
Localize analytics, history, diagnostics, and related screens.

EOF
)"
```

---

### Task 8: Achievements, notifications, home widget Dart strings

**Files:**
- Create: `lib/l10n/achievement_l10n.dart`
- Modify: `lib/services/achievement_service.dart`
- Modify: `lib/screens/achievements_screen.dart`
- Modify: `lib/screens/map_screen.dart` (unlock snackbar)
- Modify: `lib/services/location_service.dart`
- Modify: `lib/services/widget_service.dart`
- Modify: `lib/services/upload_service.dart` (comment only)
- Modify: ARB files + regenerate

- [ ] **Step 1: Achievement IDs stay; copy moves to ARB**

`achievement_l10n.dart` maps each `id` from `_definitions` to title + description via `AppLocalizations`. Use an exhaustive `switch` so a new id without a key fails analysis.

Strip `'title'` / `'desc'` from `_definitions`. `Achievement` keeps `id`, `icon`, unlock metadata. The screen (and map snackbar) look up copy by id. Do not pass `AppLocalizations` into `AchievementService`.

- [ ] **Step 2: LocationService notifications**

Replace hardcoded `notificationTitle` / `notificationText` / `channelName` / `channelDescription` with `AppLocale.lookup(await SettingsService().getAppLocalePreference(), WidgetsBinding.instance.platformDispatcher.locale)`.

Add `Future<void> refreshNotificationCopy()` that no-ops when not tracking and otherwise calls `_updateLiveNotification()` (or the carpeater variant if that mode is active).

From `_showLanguageSelector` after a successful preference change, `await _locationService.refreshNotificationCopy()`.

- [ ] **Step 3: WidgetService**

Replace `'Tracking'` / `'Idle'` with l10n from `AppLocale.lookup` (same resolve as notifications). Dynamic connection labels stay.

- [ ] **Step 4: Upload URL comment**

On `UploadService.defaultApiUrlForLocale`, add a comment that this uses **device** `Platform.localeName`, not the in-app UI language. No behavior change.

- [ ] **Step 5: Verify**

```powershell
. .\.toolchain\env.ps1
flutter gen-l10n
flutter analyze lib/services/location_service.dart lib/services/widget_service.dart lib/services/achievement_service.dart lib/l10n
flutter test
```

- [ ] **Step 6: Commit**

```powershell
git add lib/l10n lib/services/achievement_service.dart lib/services/location_service.dart lib/services/widget_service.dart lib/services/upload_service.dart lib/screens/achievements_screen.dart lib/screens/map_screen.dart
git commit -m "$(cat <<'EOF'
Localize achievements, foreground notifications, and widget status.

EOF
)"
```

---

### Task 9: Android widget XML labels

**Files:**
- Modify: `android/app/src/main/res/values/strings.xml`
- Create: `android/app/src/main/res/values-ru/strings.xml`
- Modify: `android/app/src/main/res/layout/wardrive_widget_layout.xml`

- [ ] **Step 1: Move hardcoded labels** into string resources. Point `android:text` at `@string/...`.

English keys: `widget_status_idle`, `widget_label_samples`, `widget_label_lora`, `widget_label_success`, `widget_label_distance`. Keep `app_name` as `MeshCore Wardrive`.

Russian: `Простой`, `Замеры`, `LoRa`, `Успех`, `Дистанция`. `app_name` unchanged.

- [ ] **Step 2: Commit**

```powershell
git add android/app/src/main/res
git commit -m "$(cat <<'EOF'
Localize Android home-widget XML labels.

EOF
)"
```

No Flutter test for XML. Device check: pin widget; XML chrome follows **device** locale; Dart-pushed status follows in-app language.

---

### Task 10: Grep gate, changelog, docs

**Files:**
- Modify: `CHANGELOG.md`
- Modify: `docs/README.md`
- Modify: `docs/getting-started.md`

- [ ] **Step 1: Grep gate on `lib/`**

```powershell
rg -n "Text\(\s*'" lib --glob "*.dart"
rg -n "title: '([A-Z][^']+)'" lib --glob "*.dart"
```

Allowlist: unit symbols, `'m'`, protocol names, debug field values, interpolated coordinates. Fix remaining sentences.

Confirm ARB key sets match (`@@locale` and `@metadata` ignored):

```powershell
python -c "import json,sys; p=sys.argv[1]; d=json.load(open(p,encoding='utf-8')); print('\n'.join(sorted(k for k in d if not k.startswith('@'))))" lib/l10n/app_en.arb > /tmp/en_keys.txt
python -c "import json,sys; p=sys.argv[1]; d=json.load(open(p,encoding='utf-8')); print('\n'.join(sorted(k for k in d if not k.startswith('@'))))" lib/l10n/app_ru.arb > /tmp/ru_keys.txt
diff -u /tmp/en_keys.txt /tmp/ru_keys.txt
```

Expected: no diff. On Windows without `/tmp`, write to `$TEMP`.

- [ ] **Step 2: Full verification**

```powershell
. .\.toolchain\env.ps1
flutter gen-l10n
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

If format fails, run `dart format lib test` and re-check. Report pre-existing analyzer diagnostics separately from new ones.

- [ ] **Step 3: Docs**

`CHANGELOG.md` under Unreleased → Added: in-app language (System / English / Русский) under Settings → App & device; Russian UI.

`docs/README.md`: link the spec and this plan.

`docs/getting-started.md`: one sentence pointing at the language setting.

- [ ] **Step 4: Commit**

```powershell
git add CHANGELOG.md docs lib/l10n
git commit -m "$(cat <<'EOF'
Document in-app language switching and finish localization docs.

EOF
)"
```

---

## Manual device checks (after Task 10)

Record in the PR:

- Settings → App & device → Language → Русский: settings, map snackbars, Material back button.
- Switch back to English; already-open routes rebuild via `MyApp` setState.
- Start tracking, switch language, confirm notification text updates.
- Home widget: status Idle/Tracking follows in-app language; XML labels follow device locale.
- Forced English on a `ru` phone: Meshcoretel default URL still uses `Platform.localeName`.

USB / BLE / foreground location behavior is unchanged; a short tracking session is still worth it if a radio is available.

---

## Spec coverage

| Spec section | Task |
| --- | --- |
| gen_l10n + ARB + committed generated Dart | 1 |
| `AppLocale` / prefs / export | 2 |
| `MaterialApp` locale + picker + endonyms | 3 |
| Settings copy + tests | 4 |
| Shared widgets + ru smoke test | 5 |
| Map chrome + display dates | 6 |
| Other screens | 7 |
| Achievements, notifications, widget Dart | 8 |
| Android XML `values-ru` | 9 |
| Grep gate, changelog, getting-started | 10 |
| Upload URL stays on `Platform.localeName` | 8 (comment only) |
| Non-goals (RTL, Crowdin, brand name) | not implemented |
