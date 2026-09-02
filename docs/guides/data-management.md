# Data management

The app keeps all measurements in a local SQLite database. There are three
ways to get data in and out: sample exports, a full database backup, and
settings export/import.

## Sample exports

Exports go through the system file picker or the Android share sheet; no
storage permission is needed.

| Format | Contents |
| --- | --- |
| JSON | Full sample records, suitable for import back into the app |
| CSV | One row per sample, spreadsheet-friendly |
| GPX | Track points for GPS tools |
| KML | Placemarks colored by ping result for Google Earth |

A JSON export contains an array of samples with position, timestamp, geohash,
and the ping fields (`rssi`, `snr`, `pingSuccess`, `responseTimeMs`) when a
radio response was recorded.

## Sample import

Import accepts both the current unified format
(`{"samples": [...], "sessions": [...]}`) and the legacy plain sample array.
Sessions included in the export are restored with it, so moving to a new
installation keeps your session history.

## Database backup (recommended)

Settings → Backup offers a complete snapshot of the database:

- **Export Database** writes a consistent copy of everything - samples,
  sessions, upload tracking, planned markers, privacy zones, exclusion zones,
  and devices - to a file or the share sheet.
- **Import Database** validates the picked file (SQLite signature, expected
  schema, schema version) before anything is replaced, upgrades backups from
  older app versions automatically, and keeps the previous database until the
  restored copy reopens successfully.
- Tracking must be stopped before an import.

A database backup is more complete than a JSON sample export and is the
recommended way to move devices.

## Settings export/import

Settings export/import moves preferences (map display options, quality
thresholds, discovery settings, upload endpoints, and so on). Both zone-layer
toggles, sample point size, optimistic coverage, Auto-Ping Pause, and the
link-loss alert participate in it.

Credentials are never exported: the Carpeater admin password is stored in
platform secure storage and stays out of export files.
