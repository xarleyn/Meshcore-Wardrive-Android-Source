# Map screen refactoring plan

## Context

`lib/screens/map_screen.dart` has grown into the application's main integration
point. It currently combines map rendering, tracking lifecycle, radio state,
settings, data transfer, offline maps, community coverage, navigation, and
dialogs in one `State` object.

At the start of this refactoring the file contains approximately:

- 5,750 lines;
- 99 methods;
- 61 `setState` calls;
- 39 dialogs;
- 14 owned stream subscriptions.

The settings feature is physically split into part files, but those files use
extensions on `_MapScreenState`. This reduces individual file size without
reducing coupling.

## Goals

- Keep `MapScreen` as the composition root for the map feature.
- Separate pure data transformations from Flutter widgets and platform I/O.
- Make map layers and controls independently testable widgets.
- Give services and screen-specific controllers explicit ownership of timers,
  subscriptions, and asynchronous cleanup.
- Replace loosely typed dialog and map data where practical with typed values.
- Preserve existing behavior throughout incremental, reviewable commits.
- Reduce `map_screen.dart` to roughly 600-900 lines after the full refactoring.

## Non-goals

- Introducing a new application-wide architecture or state-management package.
- Rewriting `LocationService`, `LoRaCompanionService`, or database persistence.
- Changing map visuals, tracking behavior, export formats, or device protocols
  as part of mechanical extraction work.
- Moving code into `part` files solely to make the main file shorter.

## Target structure

```text
lib/screens/
  map_screen.dart
  map/
    map_view.dart
    map_screen_controller.dart
    layers/
      coverage_layer.dart
      sample_layer.dart
      repeater_layer.dart
      route_layer.dart
      position_layer.dart
      prediction_layer.dart
    widgets/
      map_control_panel.dart
      map_action_buttons.dart
      quick_settings_panel.dart
      delete_mode_banner.dart
    dialogs/
      map_entity_dialogs.dart
      connection_dialog.dart
      upload_dialogs.dart
      marker_dialogs.dart
lib/utils/
  sample_export.dart
  coverage_prediction.dart
```

The exact number of files may change as dependencies become clearer. Prefer a
cohesive 200-400 line file over many tiny single-use wrappers.

## Implementation stages

### Stage 1: pure logic and leaf widgets

- [x] Move CSV, GPX, and KML serialization into `SampleExport`.
- [x] Add deterministic unit tests for all export formats.
- [x] Move coverage prediction calculations into a pure typed utility.
- [x] Add unit tests for repeater matching, filtering, thresholds, and rings.
- [x] Extract coverage, sample, edge, prediction, route, heatmap, repeater, and
  current-position layers with constructor inputs.
- [x] Extract the remaining radio, privacy, marker, and community layers.
- [x] Extract the control panel, quick settings, action buttons, and banners.
- [x] Preserve existing rendering order and callback behavior.

### Stage 2: typed dialogs and workflows

- [x] Extract sample, sample-cluster, coverage, repeater, repeater-list, and
  community-cell dialogs into standalone widgets.
- [x] Extract planned-marker, privacy-zone, and destructive confirmation
  dialogs with typed results.
- [x] Extract permission, session, export, and settings-import decisions with
  typed results.
- [x] Extract repeater-filter and coverage-gap dialogs with typed results.
- [x] Extract connection, appearance, update, and screenshot decisions.
- [x] Extract the remaining workflow dialogs.
- [x] Return typed results from repeater and endpoint dialogs instead of
  mutating screen state directly.
- [x] Group upload endpoint editor dialogs with the upload feature UI.
- [x] Extract upload progress UI from the screen workflow.
- [x] Separate offline tile options and progress dialogs from map rendering.
- [x] Separate community coverage dialogs from map rendering.
- [x] Keep file picker, sharing, permissions, and navigation orchestration at a
  Flutter-facing boundary.

### Stage 3: map data controller

- [x] Introduce a screen-specific controller for samples, repeaters,
  aggregation, LOD caches, and session filtering.
- [x] Inject existing service dependencies instead of constructing
  `DatabaseService` repeatedly in UI handlers.
- [x] Expose explicit commands for refresh, delete, filtering, and session view
  changes.
- [x] Keep `BuildContext`, dialogs, navigation, and widget creation out of the
  controller.
- [x] Add controller tests with fake device and persistence boundaries.

### Stage 4: lifecycle and runtime bindings

- [x] Give every stream subscription and timer a clear owner.
- [x] Cancel the Carpeater and achievement subscriptions during disposal.
- [x] Guard asynchronous initialization against disposal and stale results.
- [x] Consolidate compass/heading update scheduling behind one lifecycle owner.
- [x] Remove the periodic full refresh where event-driven updates are
  sufficient, after measuring behavior.

### Stage 5: settings decoupling

- [ ] Replace settings extensions on `_MapScreenState` with explicit inputs,
  outputs, or a settings controller.
- [x] Load map-related preferences as a typed snapshot.
- [x] Apply service-side settings through explicit commands.
- [ ] Remove `part` dependencies between the settings feature and map screen.

## Extraction rules

- A map layer may depend on Flutter Map types and presentation helpers, but not
  on database, settings, upload, or device services.
- A pure utility must not depend on `BuildContext`, widgets, navigation, or
  platform plugins.
- A dialog owns only temporary form state. Persistent mutations happen after a
  typed result is returned to the caller.
- A controller may coordinate existing services but must not become a second
  monolithic copy of `_MapScreenState`.
- New behavior receives tests before or alongside extraction.

## Verification for every milestone

Run from the repository root after loading the local toolchain:

```powershell
. .\.toolchain\env.ps1
flutter pub get
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

Map rendering changes should also be checked on a device with `flutter run`.
Changes touching USB, Bluetooth, foreground location, Android permissions, or a
physical LoRa radio require manual device validation and must document what
remains untested.
