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
- `test/`: unit and widget tests, grouped into subdirectories by name prefix
  such as `test/bluetooth/` and `test/map/`; shared helpers stay in
  `test/helpers/`.
- `docs/`: user and developer documentation.
- `assets/`: source assets; generated launch icons remain under `android/`.

Keep new code in the narrowest appropriate directory. Prefer extracting
reusable business logic from widgets into services or small domain-focused
classes. Do not introduce a new architectural layer for a single use case.

## Required workflow

This checkout includes a repository-local Flutter, Dart, JDK, and Android SDK
under `.toolchain/`. On Windows, do not assume `flutter` or `dart` is available
on the global `PATH`. Dot-source the environment script in every fresh
PowerShell process before invoking either command:

```powershell
. .\.toolchain\env.ps1
flutter --version
```

Tool calls start fresh PowerShell processes, so source `env.ps1` in the same
command invocation as the Flutter or Dart command. Run all commands from the
repository root, for example:

```powershell
. .\.toolchain\env.ps1
flutter pub get
```

Then run the required workflow:

```sh
flutter pub get
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

`dart format --output=none --set-exit-if-changed` only verifies formatting. If
it reports changed files, first run `dart format` on the files being edited,
then repeat the verification command above.

Allow long-running Flutter and Gradle commands to finish; in particular, do
not launch concurrent release builds. If a build runner was interrupted and a
subsequent build reports that an intermediate file such as `base.jar` is in
use, first confirm that no build is still active. A stale Gradle daemon for this
project can then be stopped from `android/` with `gradlew.bat --stop` before
retrying once.

The full analyzer may report existing diagnostics outside the current change.
Still run it, and also use targeted analysis for edited files when needed to
verify that the change introduces no new diagnostics. Report pre-existing
diagnostics accurately instead of describing the full analysis as clean.

Use Git commits as recoverable checkpoints during substantial tasks. Commit
after each important, coherent milestone that leaves the repository in a
working state, and always create a final commit when the requested task is
complete. Before every commit, inspect the worktree, stage only files belonging
to the current task, and run verification appropriate to that milestone. Do
not commit known-broken intermediate states, unrelated user changes, generated
build output, or credentials. Do not amend, squash, or rewrite existing commits
unless the user explicitly requests it.

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
- Prefer placing new tests in the `test/` subdirectory matching the test name
  prefix, for example `bluetooth_scan_test.dart` under `test/bluetooth/`.
  Create a new prefix subdirectory when no matching one exists yet, and import
  shared helpers such as `test/helpers/l10n_harness.dart` with a relative path
  that accounts for the extra level.
- Avoid editing generated files unless the corresponding generator or Android
  configuration requires it.
- `lib/l10n/generated/app_localizations*.dart` are tracked, reproducible
  `gen_l10n` outputs. If they disappear during an agent or tool run, first use
  `git status`, `git diff --cached`, and `git log -- <paths>` to verify that
  `HEAD` still tracks them and that their deletion is neither committed nor an
  intentional user change. In that case, treat the deletion as tooling fallout,
  restore the files from `HEAD` with `git restore --worktree -- <paths>` or
  regenerate them with `flutter gen-l10n`, and do not stage the transient
  deletion. Do not restore them when deletion is committed, explicitly
  requested, or accompanied by intentional ARB, `l10n.yaml`, or `pubspec.yaml`
  changes that alter the generated output.

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
