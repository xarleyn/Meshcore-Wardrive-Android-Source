# In-app localization (en / ru, more later)

Date: 2026-08-20

## Problem

The app is English-only. User-visible copy is hardcoded in Dart widgets,
services, the Android home-screen widget, and a few tests. There is no
`l10n.yaml`, no ARB catalog, and `MaterialApp` does not set
`localizationsDelegates` or `locale`. Users need Russian now, and a way to
switch language inside the app without changing the phone language. More
locales will be added later.

## Goals

- Official Flutter `gen_l10n` + ARB catalogs (not easy_localization, slang, or
  a hand-rolled map).
- English is the template locale. Russian ships in the same work.
- In-app language control: **System default**, **English**, **Русский**.
- Switching language rebuilds the UI immediately and persists across launches.
- Adding a later locale is a new `app_<code>.arb`, a `supportedLocales` entry,
  and a row in the language picker — not a UI rewrite.
- User-visible Flutter copy, Material/Cupertino widget chrome, notifications,
  home-widget status strings, and locale-sensitive dates are localized.
- Widget tests that assert copy go through `AppLocalizations`, not raw English
  literals, once that screen is migrated.

## Non-goals

- RTL layouts (Arabic, Hebrew) until such a locale is added.
- Crowdin / OTA translation updates.
- Translating debug log *payloads*, protocol dumps, SQL, KML/GPX tag names,
  SharedPreferences keys, URLs, device/repeater names, or geohashes.
- Changing how the default Meshcoretel upload URL is chosen (see
  [Upload endpoint](#upload-endpoint)).
- Splitting `map_screen.dart` except where a localization change already
  touches a settings `part` file.
- Localizing the brand name **MeshCore Wardrive** (keep as-is in all locales).

## Decision: official gen_l10n

Use the Flutter SDK pipeline:

1. `flutter_localizations` from the SDK.
2. `intl` resolved to the version `flutter_localizations` pins (currently
   `0.20.2` in `.toolchain/flutter`; the app still depends on `^0.19.0` and
   must bump).
3. `flutter: generate: true` in `pubspec.yaml`.
4. Root `l10n.yaml` + `lib/l10n/app_en.arb` (template) + `lib/l10n/app_ru.arb`.
5. Generated Dart under `lib/l10n/generated/`, **committed** (synthetic
   `package:flutter_gen` is removed in this Flutter toolchain; do not set
   `synthetic-package`).

Do not add a third-party i18n runtime. Type-safe getters and ICU plurals are
the reason this stack scales to many languages.

## File layout

| Path | Role |
| --- | --- |
| `l10n.yaml` | gen_l10n config |
| `lib/l10n/app_en.arb` | Template strings + `@key` descriptions |
| `lib/l10n/app_ru.arb` | Russian translations, same keys |
| `lib/l10n/generated/` | Committed `app_localizations*.dart` |
| `lib/l10n/app_locale.dart` | Preference enum, resolve, `lookup` helper |
| `lib/services/settings_service.dart` | Persist preference |
| `lib/main.dart` | `MaterialApp.locale`, delegates, load/save |
| `test/helpers/l10n_harness.dart` | Widget-test `MaterialApp` wrapper |
| `android/app/src/main/res/values/strings.xml` | Widget XML labels (en) |
| `android/app/src/main/res/values-ru/strings.xml` | Widget XML labels (ru) |

`l10n.yaml`:

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

- `nullable-getter: false` → `AppLocalizations.of(context)` is non-null under
  `MaterialApp`.
- Do **not** put `synthetic-package` in this file (removed; `true` is an error).
- Both ARB files must contain the same keys in every commit that adds a key.
- Every template key has an `@key` object with `description` (and
  `placeholders` when used).

Import generated code as
`package:meshcore_wardrive/l10n/generated/app_localizations.dart`.

## Locale preference

Stored in SharedPreferences key `app_locale`. Values:

| Stored value | Meaning | `MaterialApp.locale` |
| --- | --- | --- |
| `system` (default) | Follow the device | `null` (Flutter resolves) |
| `en` | Force English | `Locale('en')` |
| `ru` | Force Russian | `Locale('ru')` |

Unknown stored values fall back to `system`.

Resolution for code that has no `BuildContext` (notifications, widget updates):

- `system` → device `languageCode` if it is `en` or `ru`, else `en`.
- `en` / `ru` → that language.
- Then `lookupAppLocalizations(resolved)`.

`ru_RU` matches `Locale('ru')` via Flutter’s default locale matching. Do not
add country variants unless a future locale actually needs a script/region
split (e.g. `zh_Hans` / `zh_Hant`).

`MyApp` owns the runtime preference the same way it owns `ThemeMode`: load in
`initState`, `setAppLocalePreference` writes prefs and `setState`. Settings
backup/restore includes `app_locale` in `_exportKeys`.

## Language picker

Place a `ListTile` in **Settings → App & device**, immediately after **Map
Theme**. Tapping it opens a dialog matching the theme selectors.

Rows:

1. System default — translated (`languageSystem`).
2. English — endonym, **identical in every ARB**.
3. Русский — endonym, **identical in every ARB**.

Endonyms are never translated. The tile subtitle shows the current choice
(translated system label, or the endonym).

Changing the preference must rebuild `MaterialApp` so routes already on the
stack pick up the new `Localizations`. If tracking is active, refresh the
foreground notification in the same call path (see
[Services without context](#services-without-context)).

## Access patterns

**Widgets** (preferred):

```dart
final l10n = AppLocalizations.of(context);
Text(l10n.settingsTitle)
```

Never cache `AppLocalizations` on `State` across locale changes; read it in
`build` / the current event handler.

**Services / isolates with a locale:**

```dart
final l10n = lookupAppLocalizations(AppLocale.resolve(preference, systemLocale));
```

`AppLocale` lives in `lib/l10n/app_locale.dart` and is unit-tested without
widgets.

Drop `const` on any `Text` / `ListTile` that takes a localized string.

## ARB conventions

- Keys: `lowerCamelCase`, prefixed by area: `settings…`, `map…`,
  `notification…`, `achievement…`, `widget…`, `offline…`, `compass…`.
- Placeholders: ICU `{name}` with `@key.placeholders` typed (`String`, `int`,
  `num`).
- Counts: ICU `{count, plural, ...}`. Russian must define `one`, `few`,
  `many`, and `other`. Do not concatenate `"repeater(s)"` in Dart.
- Select: use `{gender, select, ...}` / similar only when a real grammatical
  split exists. Do not overuse.
- Quotes inside strings: rely on `use-escaping: true`.
- Do not embed `DateFormat` pattern *output* in ARB; format dates in Dart with
  a locale, then pass the formatted string in, **or** use ARB placeholders of
  type `String`. Prefer `DateFormat.yMMMd(localeName)` / `DateFormat.Hm` over
  hardcoded `'MMM d, h:mm a'` so Russian does not show AM/PM.

### Glossary (Russian)

Keep MeshCore / radio terms consistent:

| English | Russian |
| --- | --- |
| ping | пинг |
| repeater | репитер |
| coverage | покрытие |
| sample (GPS / radio) | замер |
| wardrive / wardriving | вардрайв |
| MeshCore, LoRa, SNR, RSSI, dBm | unchanged |
| session | сессия |
| heatmap | тепловая карта |
| dead zone | мёртвая зона |

## What stays English / untranslated

- `print` / `PersistentDebugLogger` lines and on-disk log file contents.
- MeshCore frame bytes, channel names as protocol identifiers, CSV headers that
  are a file-format contract (unless a dedicated *export* UI string).
- Preference keys, SQL identifiers, asset paths, URLs.
- Repeater / Bluetooth device names from the radio.
- Unit *symbols*: `dBm`, `dB`, `MHz`, `m`, `km`, `%`. Words around them
  (`Success rate`, `Distance`) are localized. `mi` / `mph` stay as symbols when
  the user chose imperial units.

## Services without context

### LocationService (foreground notification)

Strings such as `Location tracking active`, `Pinging...`, `Carpeater mode active`,
channel name/description, and the live stats line are ARB keys. On each
`updateService` / `startService`, resolve l10n via `AppLocale` +
`SettingsService.getAppLocalePreference()`.

When the user changes language while tracking, the language picker (owned by
`MapScreen`, which already holds `LocationService`) calls
`LocationService.refreshNotificationCopy()` after
`MyApp.setAppLocalePreference`. That method no-ops when not tracking and
otherwise re-runs the current live-stats (or Carpeater) notification update.
Do not import `LocationService` from `MyApp`.

### WidgetService

`Tracking` / `Idle` come from ARB and are written with
`HomeWidget.saveWidgetData`. Static XML labels (`Samples`, `Success`,
`Distance`, `LoRa`, title) use Android `strings.xml` / `values-ru`.

### AchievementService

Keep `id` + `icon` in the service. Stop storing English `title` / `desc` as
source of truth. UI maps `id` → `l10n.achievementFirstPingTitle` (and
description) through a switch/map in `lib/l10n` or next to the achievements
screen. Unlock snackbars on the map use the same map.

## Upload endpoint

`UploadService.defaultApiUrlForLocale` continues to use
**`Platform.localeName` (device)**, not the in-app UI language. A user who
forces English on a Russian phone must not be retargeted to the global API on
the next default-URL evaluation. Document this in a code comment so a later
change is deliberate.

## Android resources

- `values/strings.xml`: existing `app_name` plus widget label keys.
- `values-ru/strings.xml`: Russian widget labels.
- Android *will* follow the **device** locale for XML resources, which can
  disagree with the in-app override. Acceptable for the home widget chrome;
  dynamic status (`Idle` / `Tracking`) follows the in-app language because it
  is pushed from Dart. Do not build a second Flutter-to-Resources locale
  bridge in this project.

## Testing

- Unit: `AppLocale.resolve` (system en/ru/fr → en fallback, forced en/ru).
- Unit: `SettingsService` get/set/fallback for `app_locale`; included in
  export map.
- Widget: `test/helpers/l10n_harness.dart` wraps `MaterialApp` with
  `AppLocalizations.localizationsDelegates`,
  `AppLocalizations.supportedLocales`, and an explicit `locale`.
- After a screen is migrated, tests `find.text` using
  `AppLocalizationsEn().key` / `AppLocalizationsRu().key` (or the harness
  `l10n`), not a duplicated English literal.
- One smoke test: pump a migrated widget at `Locale('ru')` and expect a known
  Russian string.
- `flutter gen-l10n` must succeed with both ARBs in sync.

Do not add a full `MapScreen` widget test; it still constructs platform
services.

## Documentation

- `CHANGELOG.md`: user-visible language setting + Russian UI.
- `docs/README.md`: link this spec and the implementation plan.
- `docs/getting-started.md`: one sentence that language is in Settings →
  App & device, defaulting to the system language.

## Implementation shape (for the plan)

Work in waves on a feature branch. Each wave keeps `app_en.arb` and
`app_ru.arb` in lockstep and leaves the app compiling.

1. Tooling + preference + picker (rest of UI still English if locale is ru).
2. Test harness; migrate existing widget tests as their widgets gain l10n.
3. Settings (`lib/screens/settings/**`).
4. Shared widgets (offline banner, compass, Bluetooth picker).
5. Map chrome in `map_screen.dart` (dialogs, snackbars, FABs, permission copy).
6. Remaining screens (analytics, session history, diagnostics, …).
7. Achievements, notifications, Dart-side widget status, `DateFormat` locales.
8. Android `values-ru` widget labels.
9. Grep gate + changelog.

Mixed English/Russian during waves 1–7 is acceptable on the branch. The
feature is not done until the grep gate in the plan passes.

## Success criteria

- User can set System / English / Русский; the choice survives process death.
- With Russian selected, settings, map chrome, snackbars, notifications, and
  migrated screens are Russian; Material widgets (back, time pickers) follow
  `ru`.
- Forcing English on a `ru` device does not change Meshcoretel default URL
  logic.
- A new locale is additive: ARB + picker row + `values-<code>` if the widget
  has labels.
- `dart format`, `flutter analyze` on touched files, and `flutter test` pass.
