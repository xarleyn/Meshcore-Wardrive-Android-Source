# Map screen refactoring plan

> **Status: complete (2026-09-05).** All stages below are done. The remaining
> follow-up candidates live in the [refactoring audit](refactoring-audit.md)
> (service phase-splitting in §5.2, manifest hygiene in §3.9).
> `lib/screens/map_screen.dart` stands at 2,093 lines at the time of closing;
> the composition root deliberately kept the facades wiring, so the original
> aspirational 600-900-line target was dropped as unnecessary.

## Context

`lib/screens/map_screen.dart` started as the application's main integration
point. It combined map rendering, tracking lifecycle, radio state, settings,
data transfer, offline maps, community coverage, navigation, and dialogs in
one `State` object.

At the start of this refactoring the file contained approximately:

- 5,750 lines;
- 99 methods;
- 61 `setState` calls;
- 39 dialogs;
- 14 owned stream subscriptions.

The settings feature was physically split into part files, but those files
used extensions on `_MapScreenState`. This reduced individual file size
without reducing coupling.

The [refactoring audit](refactoring-audit.md) (2026-09-02) re-measured the
file at 3,261 lines after stages 1-4 below were completed, and defined a
follow-up composition-root slim-down (stage 6 below). As of 2026-09-02 the
file was 2,359 lines. Stage 6 (steps 1-12) is complete; the file settled at
2,093 lines with the settings pages fully decoupled.

## Goals

- Keep `MapScreen` as the composition root for the map feature.
- Separate pure data transformations from Flutter widgets and platform I/O.
- Make map layers and controls independently testable widgets.
- Give services and screen-specific controllers explicit ownership of timers,
  subscriptions, and asynchronous cleanup.
- Replace loosely typed dialog and map data where practical with typed values.
- Preserve existing behavior throughout incremental, reviewable commits.

## Non-goals

- Introducing a new application-wide architecture or state-management package.
- Rewriting `LocationService`, `LoRaCompanionService`, or database persistence.
- Changing map visuals, tracking behavior, export formats, or device protocols
  as part of mechanical extraction work.
- Moving code into `part` files solely to make the main file shorter.

## Current structure

```text
lib/screens/
  map_screen.dart                 # composition root: State, wiring, build
  map/
    map_screen_controller.dart    # MapDataStore: samples, aggregation, LOD, filtering
    map_settings_controller.dart  # typed settings snapshot and commands
    map_runtime_bindings.dart     # staged stream/timer wiring and ownership
    map_annotations_controller.dart # markers and privacy/exclusion zones
    map_ui_snapshot.dart          # immutable settings-page values
    map_ui_actions.dart           # typed settings-page command interface
    map_ui_controller.dart        # applies settings commands to the screen
    tracking_permissions.dart     # Android permission pre-flight for tracking
    tracking_flow.dart            # tracking start/stop and session settlement
    entity_info_flow.dart         # entity info dialogs, filters, coverage gaps
    screenshot_flow.dart          # capture/share sequence for the map screen
    connection_flow.dart          # USB/BLE connect, contacts, scanning
    data_io.dart                  # sample, settings, and database import/export
    layers/                       # independent map layers with constructor inputs
    widgets/                      # control panel, action buttons, layer stack, banners
    dialogs/                      # typed dialogs and screen workflows
  settings/
    map_settings_page.dart        # standalone settings UI built from snapshot + actions
    sections/                     # settings section widgets
lib/services/
  manual_ping_service.dart        # manual ping recording (extracted from the screen)
```

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

- [x] Replace settings extensions on `_MapScreenState` with explicit inputs,
  outputs, or a settings controller.
- [x] Load map-related preferences as a typed snapshot.
- [x] Apply service-side settings through explicit commands.
- [x] Remove `part` dependencies between the settings feature and map screen.

### Stage 6: composition-root slim-down (2026-09 audit)

Follows the step table in the [refactoring audit](refactoring-audit.md),
section 5.1. Each step is one commit with full verification. Status:

- [x] 1. Update check flow -> `map/dialogs/update_flow.dart` (095227a).
- [x] 2. Sample, settings, and database import/export -> `map/data_io.dart`
  (7b7eebb).
- [x] 3. Markers and zone persistence -> `map/map_annotations_controller.dart`
  (5f1e67b).
- [x] 4. Tracking permission flow -> `map/tracking_permissions.dart` (e24b6b4).
- [x] 5. Connection, contacts, and scanning -> `map/connection_flow.dart`
  (445acba).
- [x] 6. Deduplicate the two screenshot/share sequences ->
  `map/screenshot_flow.dart` (e19e418).
- [x] 7. Upload, community coverage, and offline tile flows ->
  `map/dialogs/upload_flows.dart` (558aeb7).
- [x] 8. Theme/language flows and ducting helpers ->
  `map/dialogs/theme_flows.dart` (286fa7a).
- [x] 9. Split `_initialize` into staged phases in
  `map_runtime_bindings.dart` (203b08d).
- [x] 10. Manual ping sample recording -> `lib/services/manual_ping_service.dart`
  (8cd89d1).
- [x] 11. `MapLayerStack` wired into `_buildMap`; typed callbacks
  (`MapPanelCallbacks`, `MapMenuCallbacks`) at every call site (23438ea).
- [x] 12. Decouple the settings pages from `_MapScreenState` via
  `MapUiSnapshot` + `MapUiActions` (`map_ui_snapshot.dart`,
  `map_ui_actions.dart`, `map_ui_controller.dart`,
  `settings/map_settings_page.dart`) (b7679a7).

Beyond the audit table, the same pattern produced two more screen facades:
entity info dialogs -> `map/entity_info_flow.dart` (b0d448a) and the
tracking/session lifecycle -> `map/tracking_flow.dart` (b3b3d17), plus an
audit-cleanup pass (tile URL constants, `PingSuccessStats`, named timing
constants, `Future<void>` async handlers; eba08de).

Steps 1-5 and 7-10 reduce `map_screen.dart` from 3,261 to 2,359 lines.
Steps 6, 11, and 12 (plus the entity-dialog and tracking-flow facades) bring
it to 2,093 lines and close stage 5 as well: no `part` files remain in
`lib/`. The composition root intentionally keeps the facade wiring and build
method; the earlier 600-900-line goal was dropped when the remaining code
turned out to be irreducible wiring rather than extractable features.

## Extraction rules

- A map layer may depend on Flutter Map types and presentation helpers, but not
  on database, settings, upload, or device services.
- A pure utility must not depend on `BuildContext`, widgets, navigation, or
  platform plugins.
- A dialog owns only temporary form state. Persistent mutations happen after a
  typed result is returned to the caller.
- A controller may coordinate existing services but must not become a second
  monolithic copy of `_MapScreenState`.
- A flow facade is constructed once (`late final` on the screen), so every
  mutable screen value it reads must resolve through a callback getter
  (`bool Function()`, `List<T> Function()`, ...), never a captured value.
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
