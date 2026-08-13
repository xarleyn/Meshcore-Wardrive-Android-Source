# AGENTS.md

## Scope

These instructions apply to the entire repository.

## Project overview

MeshCore Wardrive is an Android-only Flutter application. It records GPS
samples, communicates with MeshCore companion radios over USB or Bluetooth LE,
stores observations in SQLite, and renders aggregated coverage on a map.

## Source layout

- `lib/main.dart`: application entry point and top-level initialization.
- `lib/models/`: domain and persistence models.
- `lib/screens/`: Flutter screens and presentation logic.
- `lib/services/`: location, radio, protocol, storage, settings, logging, and
  upload integrations.
- `lib/utils/`: reusable helpers without UI responsibilities.
- `android/`: the only maintained Flutter host platform.
- `test/`: unit and widget tests.
- `docs/`: user and developer documentation.
- `assets/`: source assets; generated launch icons remain under `android/`.

Keep new code in the narrowest appropriate directory. Prefer extracting
reusable business logic from widgets into services or small domain-focused
classes. Do not introduce a new architectural layer for a single use case.

## Required workflow

Run commands from the repository root:

```sh
flutter pub get
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

Use `flutter run` for device validation. For release verification, use
`flutter build apk --release`; never commit files produced under `build/`.

When a change affects USB, Bluetooth, foreground location, Android permissions,
or a physical LoRa device, describe any manual device testing that remains.

## Code conventions

- Follow `analysis_options.yaml` and standard Dart/Flutter formatting.
- Use `lower_snake_case.dart` filenames, `UpperCamelCase` types, and
  `lowerCamelCase` members.
- Keep asynchronous lifecycle cleanup explicit: cancel subscriptions, timers,
  and device connections when their owner is disposed.
- Keep secrets and device credentials out of source control. Store runtime
  credentials with the existing secure-storage abstraction.
- Add or update tests for behavior that can be exercised without physical
  hardware. Isolate device and network boundaries so they can be faked.
- Avoid editing generated files unless the corresponding generator or Android
  configuration requires it.

## Documentation and repository hygiene

- Keep `README.md`, `CHANGELOG.md`, and `AGENTS.md` at the repository root.
- Put all other Markdown documentation under `docs/` and link it from
  `docs/README.md`.
- Put documentation images under `docs/assets/` and application source assets
  under `assets/`.
- Do not commit APK/AAB files, logs, IDE state, local SDKs, credentials, or build
  output. Distribute binaries through GitHub Releases.
- Update documentation and examples when changing commands, paths, settings, or
  user-visible behavior.

## Architecture notes

- `LocationService` coordinates GPS tracking and automatic pings.
- `LoRaCompanionService` owns USB/BLE radio communication and response handling.
- `MeshCoreProtocol` encodes and parses companion-radio frames.
- `DatabaseService` persists samples locally.
- `AggregationService` derives coverage cells from stored samples.
- `SettingsService` owns user preferences.

Preserve these ownership boundaries. In particular, protocol parsing should not
depend on widgets, and screens should not implement raw device framing.
