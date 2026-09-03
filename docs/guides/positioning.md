# Positioning and location quality

The app records from Android's fused location provider, so GPS, cellular, and
nearby Wi-Fi positioning work together. This guide covers how position quality
is filtered, what happens when quality degrades, and the optional positioning
sources.

## Quality filters

Android-reported mock fixes, fixes worse than the configured accuracy
threshold (250 m by default), and probable aircraft movement are excluded;
high-altitude roads are still supported. All thresholds are configurable in
Settings → Location Quality Filters:

- maximum horizontal error;
- airborne altitude and speed limits;
- maximum wardrive speed, entered in km/h;
- **Restore Defaults** restores the built-in thresholds without touching
  zones.

## Auto-Ping Pause

When several position fixes in a row are rejected by the quality filters, the
app pauses automatic pings instead of pinging a stale position. Pinging
resumes on the next valid fix, and a snackbar announces each pause and
resume.

- Default: pause after 5 consecutive rejected fixes.
- The toggle and the threshold live in Settings → Location Quality Filters →
  Auto-Ping Pause and participate in settings export/import.

## Impossible Zones

GPS or Wi-Fi fixes inside a user-defined Impossible Zone are discarded - no
sample, no ping - and the map holds the last valid position. Zones are
managed in Settings → Location Quality Filters or by long-pressing the map;
see [markers and zones](markers-and-zones.md).

## Watchdog and recovery

The map keeps searching for a fused position whenever it is open, even before
recording starts. A watchdog restarts stalled or closed location streams and
resumes automatically after Location Services are re-enabled. Tracking
startup failures report a specific cause: permission, settings, or service.

## beaconDB Wi-Fi positioning (optional)

When enabled in Settings, the app scans nearby access points every 30 seconds
and, on a valid estimate, prioritizes Wi-Fi positioning over the fused
provider. The active Wi-Fi position is shown with a cyan marker.

- SSIDs are used only on the phone to exclude hidden and `_nomap` networks;
  hidden, randomized, and stale networks are excluded from the lookup.
- IP and cell-position fallbacks are disabled: a valid estimate requires
  internet access and at least two mapped access points.
- On enabling, the app links to Developer options so Wi-Fi scan throttling can
  be disabled, and holds a Wi-Fi lock while tracking in the foreground.

## Radio position estimate

When at least three positioned repeaters answer the same ping, the app shows
a temporary grey marker with an uncertainty circle: a coarse RSSI-weighted
estimate of where you probably are.

- This is not a GPS fix and can be inaccurate - terrain, antennas, and radio
  propagation strongly affect RSSI.
- **Show Approximate Position** in map settings hides the marker without
  stopping the calculation.

## Direction arrow and compass

The current-location marker can be switched between the classic blue circle
and a compass-aware direction arrow. In arrow mode the compass button toggles
heading-up map rotation; rotating the map manually stops heading-up tracking.
When a compass sensor is unavailable, the arrow falls back to GPS course while
moving.

If Android reports the magnetometer as unreliable, a compact banner offers a
figure-8 calibration (Later hides it for a day). Calibration is also always
available from Settings or by long-pressing the compass button.
