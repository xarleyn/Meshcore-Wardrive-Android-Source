# Analytics and statistics

The fork ships several screens that analyze recorded data. They all read the
local database; nothing is sent anywhere.

## Coverage analytics

The Analytics screen opens from Settings → Data Management → Analytics and
has five tabs:

- **Score** - an overall coverage score for your recordings with the
  underlying stats, and a shareable summary.
- **Time** - success rates by period of day, so you can see how propagation
  changes between morning, day, evening, and night.
- **Goals** - progress toward coverage goals: pick an area and radius and
  track how much of it you have covered.
- **Compare** - side-by-side comparison of coverage between sessions or time
  periods.
- **Repeaters** - per-repeater reliability statistics with trend information.

## Repeater health

Settings → Diagnostics opens the Repeater Health screen: success rates per
repeater with 7-day vs 30-day trend direction, and a detail screen per
repeater with its response history.

## Signal trends

The Signal Trend screen charts RSSI, SNR, and ping response time over your
recorded samples - useful for spotting when a link is degrading and whether
it correlates with antenna, weather, or route changes.

## Device comparison

If you wardrive with several companion radios (samples are tagged with the
device ID), the Device Comparison screen picks two devices and compares their
success rates and coverage for the same area.

## Achievements

The Achievements screen tracks unlockable badges:

- 📡 first ping, 💯 100, 🔥 1000, 👑 10000 pings;
- 📻 first repeater heard, 🗺️ 10, 🌐 50 repeaters;
- 🚗 10, 🛣️ 100, ✈️ 500 distance units - the thresholds follow the selected
  distance unit, so 100 km and 100 miles unlock the same badge depending on
  the setting;
- 🏘️ 50, 🏰 500 coverage cells;
- 🎬 first session, 🏆 50 sessions;
- 💎 a hidden badge that stays invisible until unlocked (see below).

### Hidden legend badge

The hidden 💎 badge unlocks while the connected companion radio advertises a
node name starting with `Ya_`, `Yakut`, or `Якут` (case-insensitive). The
name is taken from the radio's own MeshCore advert, which is separate from
the Bluetooth/USB transport name.
