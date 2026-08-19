# Fresh session map view

Date: 2026-08-19

## Problem

Starting tracking always draws new samples on top of every previously stored
sample. The only way to see a blank map is Clear Map, which permanently deletes
data. Users need a way to start a new recording that looks empty while leaving
stored samples intact.

Session records (`WSession`) and a time-range map filter already exist via
Session History. They are not wired to the Play button.

## Goals

- Short press Play: start tracking and show **all** samples (the accumulated
  coverage blob), including new points.
- Long press Play (while not tracking): start tracking on a **blank** map that
  only shows this trip. Stored samples are not deleted.
- After stopping a long-press session, keep showing that session until the user
  clears the filter or starts with a short press.
- An empty session (zero GPS samples) asks whether to save it.
- Deleting the session currently on the map falls back to the latest remaining
  saved session, or to a blank map if none remain.
- Fix Quick Settings ping-distance dropdown crash when the saved interval is
  `50.0` (Frequent) or any value missing from the menu.

## Non-goals

- Binding samples to `session_id` (time-range filter stays).
- Deleting samples when a session record is deleted.
- Changing double-tap Play (Quick Settings) beyond the dropdown crash fix.
- Long-press behavior on Stop.

## Map sample scope

Three mutually exclusive views:

| Scope | What the map shows |
| --- | --- |
| `all` | Every stored sample |
| `session` | Samples in the selected `WSession` time range (`endTime` or `now` if in progress) |
| `empty` | No samples. Used when no saved session remains. Distinct from `all`. |

`scope == all` is the only state in which short-press tracking accumulates the
blob. `filter == null` must not be used as “empty”; that already means “show
all”.

## Play button

The existing Play FAB keeps short press and double-tap. Long-press is added on
the same control, matching the compass button pattern.

- **Short press, not tracking:** set scope to `all`, then start tracking as
  today (permissions, auto-ping / Carpeater).
- **Short press, tracking:** stop tracking. If this session has GPS samples and
  scope is `session`, keep that session (refresh `endTime`). If scope is `all`,
  stay on `all`.
- **Long press, not tracking:** start tracking, then set scope to `session` for
  the newly created `WSession`. Snackbar: the map shows this trip only. No
  confirmation dialog.
- **Long press, tracking:** no extra action (Stop is short press).
- **Double-tap:** still toggles Quick Settings.

## Empty session on stop

A session is empty only when it has **zero GPS samples** (`sampleCount == 0`
after finalize). Movement and ping counts are ignored.

On stop, after `LocationService.stopTracking()` finalizes the row:

1. If the session is not empty, do not prompt.
2. If empty, show: title `Session is empty`, body explaining it has no GPS
   points, actions `Save` and `Don't save`.

**Save:** keep the `WSession` row. If scope is `session`, stay on that empty
session (blank map). If scope is `all`, stay on `all`.

**Don't save:** delete the `WSession` row. If scope is `session`, switch to the
latest remaining saved session (newest `start_time`), or `empty` if none. If
scope is `all`, stay on `all`.

## Session History delete

Deleting a session still removes only the session row, not samples.

If the deleted session is the one currently shown (`scope == session` and
matching id), switch to the latest remaining saved session, or `empty` if none.
If the map is showing `all` or a different session, leave the map scope
unchanged.

Session History needs a delete callback so the map can apply this without
re-selecting.

## Data and ownership

- No schema migration. Samples stay unscoped; visibility is a time filter.
- `LocationService` already creates/finalizes `WSession` on start/stop. Expose
  `currentSessionId` and `sessionStartTime` so the map can attach the filter
  after a long-press start.
- Extract scope transitions and sample filtering into
  `lib/utils/session_map_view.dart` so they can be unit-tested without widgets
  or GPS.
- `MapScreen` owns UI: gestures, dialogs, snackbars, calling
  `startTracking` / `stopTracking`, reloading samples.
- In-progress session filter uses `endTime ?? now` so new samples appear.

Force reaggregation when scope changes (`_lastAggregatedSampleCount = -1`),
because total DB sample count may be unchanged.

## Quick Settings ping distance

Settings → Ping Distance includes Frequent (`50` m). Quick Settings only listed
200 / 400 / 805 / 1609, so `DropdownButton` asserted.

- Include `50` in the Quick Settings menu.
- Keep `400` (battery-saver doubling of 200).
- If the current value is not in the preset list (for example 100 after
  doubling 50), still add it as an item so the dropdown never asserts.

Helper: `lib/utils/ping_distance_options.dart`.

## Testing

- `SessionMapView`: all / session / empty filtering; short-press start clears
  to `all`; fresh start uses the new session; empty discard → latest or empty;
  delete of the active session → latest or empty; delete of another session is
  a no-op.
- Ping distance helper: `50.0` is a listed value; unknown values are appended;
  a `DropdownButton` with value `50.0` builds without asserting.
- Widget tests for MapScreen / SessionHistory GPS flows are out of scope;
  those screens construct platform services.

## User-visible copy (English, matching the app)

- Snackbar after long-press start: `New session — showing this trip only`
- Empty dialog title: `Session is empty`
- Empty dialog body: `No GPS points were recorded. Save this session anyway?`
- Save / Don't save
- Snackbar after discard when another session remains:
  `Session discarded — showing last saved session`
- Snackbar after discard with none remaining:
  `Session discarded`
- Existing Session History “Filtering by session” / clear filter still apply
  whenever scope is not `all` (including `empty`).
