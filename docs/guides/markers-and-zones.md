# Markers and zones

Long-pressing the map opens a menu with three things you can place at that
point: a **planned repeater**, a **privacy zone**, or a **GPS exclusion zone**
(also called an Impossible Zone). The same objects are managed from Settings.

## Planned repeater markers

A planned repeater is a note-to-yourself marker for a spot where a repeater
could be installed in the future.

- Add it from the long-press menu; an optional label can be entered in the
  dialog.
- Markers survive restarts and are stored in the database (and in database
  backups).
- The planned-markers tile in Settings shows the current count and offers to
  remove all markers (with confirmation).

## Privacy zones

A privacy zone is a circle whose data is excluded from uploads and exports.
Use it, for example, around your home so the published map never shows your
exact location.

- Add it from the long-press menu or Settings.
- The radius can be set freely between 50 m and 10 km with a slider; an
  editable meters field stays in sync with the slider and clamps typed values
  into the range.
- **Preview on map** collapses the dialog into a small bar at the bottom of
  the screen and draws the zone circle; the map stays interactive, and the
  bar offers Edit, Add, and Close.
- Samples inside a privacy zone are excluded from **web map uploads**, so
  published maps never show them. Sample exports (JSON/CSV/GPX/KML) currently
  include all samples; keep privacy-zone data out of shared files by deleting
  it first or sharing only uploads.

## GPS exclusion zones (Impossible Zones)

A GPS exclusion zone is a circle where you cannot physically be - typically
an airport or approach corridor. Fixes inside a zone are discarded entirely:
no sample, no ping, and the map keeps the last valid position instead of
jumping.

- Add zones from the long-press menu or from Settings → Location Quality
  Filters, which is also where the full list lives.
- The same radius slider and map preview are used.
- Zones are not drawn on the map by default; both zone layers can be shown
  with their own Map Display toggles, which draw the zone center and its
  configured radius.
- **Restore Defaults** in the quality-filter settings resets the thresholds,
  not the zones.

## Map display toggles

Settings → Map Display provides independent toggles for the privacy-zone and
GPS-exclusion-zone overlays. Both choices participate in settings
export/import.
