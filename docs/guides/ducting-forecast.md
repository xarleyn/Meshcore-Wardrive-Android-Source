# Ducting forecast

Tropospheric ducting bends VHF/UHF signals along atmospheric layers and can
carry them far beyond the normal radio horizon. The app has two related
features: a 6-day **ducting forecast** viewer and an automatic **atmospheric
ducting monitor** that tags your samples.

## Forecast viewer

Open it from **Settings → Location & positioning → Ducting Forecast**. It
shows the forecast maps published at
[dxinfocentre.com](https://www.dxinfocentre.com/tropo_eur.html) — six-day
tropospheric ducting outlooks drawn per region.

- **23 regions** covering the whole world (for example Europe, Eastern
  Europe, Scandinavia, North Atlantic, Caribbean, East Asia, Australia);
  the selected region is remembered between sessions.
- **Timeline from +6 h to +138 h**: 3-hour steps for the first day and a
  half, then 6-hour steps out to nearly six days.
- **Playback controls** animate the frames so you can watch a duct evolve;
  scrub the timeline to jump to a specific time.
- Pinch to zoom into the map.
- The maps load over the internet; nothing is sent from your device.

## Atmospheric ducting monitor

Separate toggle **"Atmospheric Ducting"** in the same settings section
(off by default). While enabled and recording:

- the app fetches pressure-level data from the Open-Meteo API and computes
  the radio refractivity gradient between the surface and 925 hPa;
- the result is classified as None (normal), Possible (super-refraction),
  or Likely (trapping), cached locally and refreshed periodically;
- each recorded sample is tagged with the current ducting risk level, and a
  color-coded badge in the map control panel shows the live status;
- the risk level also appears in the sample info popup.

The monitor answers "are propagation conditions unusual right now?", while
the forecast viewer answers "what does the next week look like?".
