# MeshCore Wardrive Android App - Source Code

MeshCore Wardrive is an Android application for collecting and visualizing
MeshCore network coverage. It records GPS samples, communicates with a MeshCore
companion radio over USB or Bluetooth, and displays coverage on a Flutter map.

## 📥 Download Pre-built APK

**Latest Release:** [Download the xarleyn fork](https://github.com/xarleyn/Meshcore-Wardrive-Android-Source/releases)

The fork uses Android package ID `io.github.xarleyn.meshcore.wardrive`, so it
can coexist with the original app. The first fork-identity release is a clean
installation and does not migrate data from `mintylinux.meshcore.wardrive`.

## 🚀 Features

- Real-time GPS tracking with foreground service
- USB and Bluetooth connectivity for MeshCore companion radios
- Auto-ping functionality with configurable intervals (50m, 200m, 400m, 0.5 miles, 1 mile)
- Manual ping testing
- Success rate based coverage visualization with color coding
- Clickable coverage squares showing detailed statistics
- Repeater discovery and tracking
- Per-repeater coverage filtering
- Coverage gap finder for identifying dead zones
- Data export to JSON, CSV, GPX, and KML
- Share coverage map screenshots with stats
- Web map upload functionality (multi-site)
- Route trail with color-coded path
- Session history with notes and replay
- Offline map tile caching
- Heatmap overlay visualization
- Signal trend charts (RSSI, SNR, response time)
- Live speed display
- Repeater response time tracking
- Color blind accessibility modes
- Debug terminal with logging
- Independent light/dark/system themes for the interface and map
- Impossible Zones: discard GPS jumps into places you cannot physically be

## 🛠️ Development Setup

### Prerequisites

- Flutter SDK 3.47.1 or compatible (Dart 3.13)
- Android Studio or VS Code with Flutter extensions
- Android SDK with API level 24+
- A MeshCore companion radio device (for testing)

### Installation

1. Clone this repository:
```bash
git clone https://github.com/xarleyn/Meshcore-Wardrive-Android-Source.git
cd Meshcore-Wardrive-Android-Source
```

2. Install dependencies:
```bash
flutter pub get
```

3. Generate app icons:
```bash
dart run flutter_launcher_icons
```

4. Run on connected device:
```bash
flutter run
```

### Building Release APK

Configure the stable signing key once, then use the release script. It
bumps the base fork version and Android's build number (for example
`1.0.44-x` to `1.0.45-x`) while keeping the displayed version synchronized:

```powershell
.\tool\build_release.ps1
```

The APK will be located at: `build/app/outputs/flutter-apk/app-release.apk`

See [Android release builds](docs/development/releasing.md) for initial signing
setup, public version changes, and per-architecture builds.

## 📁 Project Structure

```
lib/
├── main.dart                        # App entry point and initialization
├── constants/
│   └── app_version.dart             # Version constant (synced by tool/version.dart)
├── l10n/                            # Localization inputs; generated outputs in l10n/generated/
├── models/
│   ├── models.dart                  # Core models (Sample, Coverage, Repeater, Edge, WSession, NodeData)
│   ├── impossible_zone.dart         # Impossible Zones
│   └── location_quality_settings.dart # GPS quality filter thresholds
├── screens/
│   ├── map_screen.dart              # Main map interface
│   ├── map/                         # Map screen building blocks
│   │   ├── map_screen_controller.dart   # Map data store, caching, level of detail
│   │   ├── map_settings_controller.dart # Settings snapshot handling
│   │   ├── map_runtime_bindings.dart    # Stream/timer wiring
│   │   ├── dialogs/                 # Marker, coverage, connection, upload, and tile dialogs
│   │   ├── layers/                  # Coverage, sample, repeater, route, and overlay layers
│   │   └── widgets/                 # Control panels, action buttons, banners
│   ├── settings/                    # Settings UI
│   │   ├── settings_screen.dart     # Settings screen shell
│   │   ├── settings_page.dart       # Settings page content
│   │   ├── settings_dialogs.dart    # Shared settings dialogs
│   │   ├── sections/                # Grouped settings sections (discovery, map display, ...)
│   │   └── widgets/                 # Settings dialogs and section headers
│   ├── analytics_screen.dart        # Coverage analytics
│   ├── session_history_screen.dart  # Session history viewer
│   ├── repeater_health_screen.dart  # Repeater health statistics
│   ├── signal_trend_screen.dart     # Signal trend charts
│   ├── achievements_screen.dart     # Achievements
│   ├── ducting_forecast_screen.dart # Ducting forecast
│   ├── device_comparison_screen.dart # Device comparison
│   ├── debug_log_screen.dart        # Debug terminal
│   └── debug_diagnostics_screen.dart # Advanced diagnostics
├── services/
│   ├── location_service.dart        # GPS tracking & auto-ping
│   ├── lora_companion_service.dart  # Companion radio communication (USB/BLE)
│   ├── meshcore_protocol.dart       # Companion radio protocol implementation
│   ├── database_service.dart        # SQLite database
│   ├── aggregation_service.dart     # Coverage calculation
│   ├── settings_service.dart        # User preferences & export/import
│   ├── upload_service.dart          # Web map upload
│   └── …                            # Backup, tiles, sound, Wi-Fi positioning, achievements, ...
├── widgets/                         # Shared widgets (play button, device picker, banners)
└── utils/                           # Helpers: geohash, sample export, color palettes,
                                      # ping distance/time options, compass calibration, ...
```

## Requirements

- Flutter 3.47.1 (Dart 3.13) or a compatible stable SDK.
- Android SDK (compile/target API 36, min API 24) and an Android device or emulator.
- A physical MeshCore companion radio for LoRa workflows.

## Development

```sh
flutter pub get
flutter analyze
flutter test
flutter run
```

Build a signed release APK with automatic build-number incrementing:

```powershell
.\tool\build_release.ps1
```

The generated APK is written below `build/app/outputs/flutter-apk/`. Do not
commit APK files. To publish from CI, set the signing secrets described in
[Android release builds](docs/development/releasing.md) and run the **Release
APK** workflow under Actions.

Continuous integration on `main` runs `dart format`, `flutter analyze`,
`flutter test`, and a debug APK build.

## Repository layout

```text
android/       Android host project and platform configuration
assets/        Source assets used during development and packaging
docs/          User, setup, protocol, and troubleshooting documentation
lib/           Flutter application source
  constants/   Application-wide constants
  l10n/        Localization inputs and generated outputs
  models/      Domain and persistence models
  screens/     UI screens (map, settings, analytics, and more)
  services/    Device, location, storage, and network services
  utils/       Reusable helpers
  widgets/     Reusable widgets shared across screens
test/          Automated tests
```

This repository intentionally targets Android. Generated host projects for
other Flutter platforms are not maintained here.

## Documentation

- [Documentation index](docs/README.md)
- [Getting started](docs/getting-started.md)
- [Installation](docs/INSTALLATION.md)
- [LoRa companion guide](docs/guides/lora-companion.md)
- [Carpeater mode guide](docs/guides/carpeater.md)
- [MeshCore authentication](docs/guides/meshcore-authentication.md) *(upstream MQTT only)*
- [Ping debugging](docs/development/debugging-pings.md)
- [Android release builds](docs/development/releasing.md)
- [Map screen refactoring plan](docs/development/map-screen-refactoring.md)
- [Changelog](CHANGELOG.md)

## Privacy

GPS samples are stored locally and are uploaded only when the user explicitly
chooses to share them.
