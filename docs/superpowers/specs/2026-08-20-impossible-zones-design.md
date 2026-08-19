# Impossible Zones

Date: 2026-08-20

## Problem

GPS (and Wi-Fi positioning) sometimes jumps into places the user cannot
physically be: airports, water, restricted land. Those fixes should not move
the map marker, must not be stored, and must not trigger a LoRa ping.

This is separate from:

- **Dead zone alerts**: coverage cells where *this device* previously pinged
  and every ping failed.
- **Privacy zones**: valid positions whose samples are stripped from uploads
  and exports.

## Goals

- The user can define circular **Impossible Zones** by hand (center, radius,
  optional label). There is no built-in airport list.
- A fused or Wi-Fi fix inside any such zone is discarded entirely.
- The last accepted position is kept: marker, trip distance, and ping logic
  continue to use it until a later fix is outside every zone.
- Zones are managed only in Settings. They are not drawn on the map.
- Dead zone alerts and privacy-zone upload filtering are unchanged.

## Non-goals

- A default / crowd-sourced list of airports or no-go areas.
- Map overlay, long-press-to-add, or editing radius of an existing zone.
- Skipping pings while still saving the jumped GPS point.
- Changing privacy zones or dead-zone detection.

## Architecture

New SQLite table `impossible_zones`, same columns as `privacy_zones`
(`id`, `lat`, `lon`, `radius_meters`, `label`). Database version 12 → 13.

Typed model `ImpossibleZone` owns the point-in-circle test (the same
equirectangular approximation already used for privacy zones).
`DatabaseService` stores rows and asks the model whether a coordinate is
inside any zone.

`LocationService._handleNewPosition` checks impossible zones immediately after
the existing location-quality filters and before updating `_lastPosition`,
broadcasting `currentPositionStream`, accumulating distance, pinging, or
inserting a sample. An inside hit logs a diagnostic reason and returns.

## Data flow

1. User adds a zone in Settings → Location Quality Filters. Center is the
   current accepted position, or the map camera center if there is no fix.
2. Row is inserted; the settings list reloads.
3. Each location update: quality filters → valid lat/lon →
   `isInImpossibleZone`. On hit: log, return. On miss: existing pipeline.
4. If the first fix of a session is already inside a zone, there is no last
   valid position yet. The marker appears when GPS leaves the zone (same as
   quality-filter rejection before any fix).

Time-based and Carpeater pings already use `_lastPosition`, so they keep
pinging from the last valid coordinate rather than the discarded jump.

## UI

English UI, matching the rest of Settings.

Location Quality Filters gains a second section **Impossible Zones**:

- Short explanation: GPS inside these areas is discarded; the last valid
  position is kept.
- **Add Impossible Zone**: dialog copied from privacy zones (coordinates,
  optional label, radius 500 m / 1 km / 2 km / 5 km).
- One list tile per zone (label or “Unnamed zone”, coordinates and radius,
  delete).
- **Clear Impossible Zones** when the list is not empty.

The parent Location tile subtitle mentions impossible locations. Restore
Defaults on the quality thresholds does not delete zones.

No map polygons. No snackbar on every rejected fix (GPS can sit in a bad
area); the debug location log is enough.

## Error handling

- Database failures while checking a fix must not crash tracking: treat as
  “not inside” only if the query itself throws; log the error (same spirit as
  the non-critical dead-zone check). Prefer: log and skip the update if the
  check cannot be completed, so a failed lookup cannot leak a junk coordinate.
  Chosen behavior: **on check failure, ignore the fix** (fail closed for
  writes) and log the error.
- Deleting a missing id is a no-op.
- Overlap with a privacy zone is allowed; impossible-zone rejection runs
  first, so the point never becomes a sample.

## Testing

- Unit tests for `ImpossibleZone.contains` and “first matching zone in a
  list”: center, inside radius, outside radius, second zone matches, empty
  list.
- No SQLite integration tests (the project does not host `DatabaseService`
  tests). CRUD stays a thin wrapper around the model.
- LocationService wiring is not unit-tested (heavy device dependencies);
  the check is a short branch next to the existing quality-filter return.

## Docs

- `CHANGELOG.md` Unreleased.
- `docs/getting-started.md` Location Quality Filters bullet and troubleshooting.
- Link this spec from `docs/README.md`.
