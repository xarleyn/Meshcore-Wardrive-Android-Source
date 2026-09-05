# Recording sessions

Every recording is a session: a time range with its own statistics and notes.
Sessions let you start a clean trip on a blank map without deleting any stored
data.

## Starting a recording

- **Short press Play** (bottom right): starts tracking and shows **all**
  stored coverage, including new samples. The button turns red while
  tracking.
- **Long press Play** (while not tracking): starts a new session on a **blank**
  map that only shows this trip. Stored samples are not deleted. The button
  uses a short vibration to confirm the long press.

Samples are recorded after about 5 meters of movement. While tracking, the
map keeps searching for a position even before the recording starts, so the
session begins from an accurate fix.

## Stopping

- After you stop a long-press session, the map stays on that trip until you
  short-press Play (show all) or pick another session in
  Settings → Data Management → Session History.
- Stopping with no GPS points asks whether to keep the empty session.
- Deleting the session currently on the map falls back to the latest remaining
  saved session, or to a blank map when none remain.

## Session History

Settings → Data Management → Session History lists every session, newest
first. Each card shows:

- start and end time, recording duration, and distance;
- sample (GPS points) count, ping count, heard count, and success rate with a
  color-coded percentage;
- your notes, if any.

From a card you can:

- **View on map** - open the map filtered to that session's time range;
- **Edit notes** - attach a free-form note (for example the route or the
  radio used);
- **Delete** - removes the session record only; the samples themselves stay.

## Design notes

The session scope model (all / session / empty views) and the long-press
behavior are specified in the
[fresh session map view design](../superpowers/specs/2026-08-19-fresh-session-map-design.md).
