# MeshCore Wardrive - Quick Start

## Build and Install

Build and install the app on an Android device from the repository root.

### Install on Connected Device

```bash
flutter pub get
flutter install
```

### Or Install APK Manually

Build an APK first:

```bash
flutter build apk --debug
```

The output is written to `build/app/outputs/flutter-apk/app-debug.apk`. Transfer
that file to your Android device and install it.

## First Launch

1. **Grant Permissions**: When you first open the app, grant:
   - Location permissions (choose "Allow all the time" for best results)
   - Storage permissions (for exporting data)

2. **Start Tracking**: Tap the green play button (bottom right)
   - The button will turn red when tracking is active
   - The map searches for and updates your position before tracking starts
   - Recorded samples are added after about 5 meters of movement
   - A short press keeps showing all stored coverage. Long-press the play
     button to start a new session on a blank map without deleting old samples.

3. **View Your Coverage**: As you move:
   - GPS samples are collected automatically
   - Coverage areas appear as colored rectangles
   - Colors indicate signal quality (default) or data age

## Key Features

### Map Controls
- **My Location Button** (small blue button): Centers map on your current position
- **Start/Stop Button** (large green/red): Toggles location tracking. Long-press
  while stopped starts a fresh session that only shows this trip. After you
  stop, the map stays on that session until you short-press Play (show all) or
  pick another session in Settings → Session History. Stopping with no GPS
  points asks whether to save the empty session.
- **Settings Icon** (top right): Access display options

### Settings Options
- **Show Samples**: Toggle individual GPS point visibility
- **Show Edges**: Toggle repeater connection lines
- **Radio position estimate**: After at least three positioned repeaters answer
  the same ping, a temporary grey marker and uncertainty circle show the coarse
  RSSI-weighted estimate. This is not a GPS fix and can be inaccurate because
  terrain, antennas, and radio propagation strongly affect RSSI. Disable
  **Show Approximate Position** to hide it without stopping the calculation.
- **beaconDB Wi-Fi Positioning**: Disabled by default. When enabled, the app
  sends nearby access-point BSSIDs, signal levels, frequencies, and observation
  ages to beaconDB every 30 seconds. SSIDs are used only on the phone to exclude
  hidden and `_nomap` networks and are not sent. A valid Wi-Fi estimate takes
  priority over Android fused/GPS positioning and uses a cyan current-location
  marker. The app returns to fused positioning when no fresh Wi-Fi estimate is
  available. Internet access and at least two mapped access points are required.
- **Location Quality Filters**: Thresholds for maximum horizontal error,
  airborne altitude and speed, and maximum wardrive speed, plus **Impossible
  Zones** — circular areas you cannot physically occupy (for example an
  airport). GPS inside a zone is discarded and the last valid position is
  kept. Zones are managed only in this settings page and are not drawn on
  the map. Speeds are entered in km/h. **Restore Defaults** resets the
  thresholds, not the zones.
- **Color Mode**:
  - Quality: Green (excellent) → Red (poor)
  - Age: Green (fresh) → Red (old)

### Data Management
- **Export**: Saves all collected samples as JSON file
  - Files saved to app's external storage
  - Named with timestamp: `meshcore_export_YYYYMMDD_HHMMSS.json`
  
- **Clear**: Deletes all collected data (with confirmation)

## Tips for Wardriving

1. **Battery Optimization**: Disable battery optimization for this app in Android settings
2. **Location Sources**: Android combines GPS, cellular, and nearby Wi-Fi. A
   clear view of the sky still gives the best outdoor accuracy.
3. **Regular Exports**: Export data periodically to avoid data loss
4. **Background Tracking**: The app can track in the background on Android 10+

## Data Format

Exported JSON contains an array of samples:
```json
[
  {
    "id": "timestamp_geohash",
    "lat": 47.7776,
    "lon": -122.4247,
    "timestamp": "2024-01-01T12:00:00.000Z",
    "path": null,
    "geohash": "c23nb2q2"
  }
]
```

## Troubleshooting

### Compass heading looks wrong
- Switch the current-location marker to **Direction arrow** in Settings
- If a calibration banner appears, tap **Calibrate** and move the phone in a
  figure-8 until the bar fills. **Later** hides the banner for a day
- You can also long-press the compass button or open **Calibrate Compass** in
  Settings at any time

### Location Not Updating
- Check Location Services are enabled
- Grant "Allow all the time" permission
- Leave the map open; the app retries a stalled location stream automatically
- Be aware that Android's fused result can still be wrong during real GNSS
  spoofing. Fixes marked as mock locations, worse than the configured accuracy
  threshold (250m by default), or moving implausibly fast are ignored, but
  software cannot prove every plausible fix is genuine without an independent
  positioning source. If GPS still jumps somewhere you cannot be, add an
  **Impossible Zone** in Location Quality Filters.

### Map Not Loading
- Check internet connection (needed for map tiles)
- Verify INTERNET permission is granted

### Export Fails
- Grant storage permissions
- Check available storage space

## Technical Details

- **Sample Rate**: Every 5 meters of movement
- **Location Accuracy**: High (Android fused GPS/network/Wi-Fi location)
- **Optional Wi-Fi Source**: beaconDB Wi-Fi-only lookup, 30-second interval,
  no IP or cell-position fallback, disabled by default
- **Quality Filtering**: Android-reported mock fixes, fixes worse than 250m,
  and probable aircraft movement are excluded; high-altitude roads are still
  supported. Optional Impossible Zones discard fixes inside user-defined
  circles (airports and other unreachable areas) and keep the last valid
  position.
- **Coverage Precision**: ~0.61km × 1.22km grid
- **Sample Precision**: ~19m × 19m grid
- **Initial Map View**: Centroid of stored samples at city-scale zoom; if there
  are no samples and GPS is not available yet, 47.7776, -122.4247 (Puget Sound)
- **Max Distance**: 60 miles from center

## Development

To make changes:

1. Edit source files in `lib/`
2. Run `flutter pub get` if you add dependencies
3. Test with `flutter run`
4. Build release with `flutter build apk --release`

## Credits

Based on mesh-map.pages.dev by Kyle Reed for MeshCore network coverage mapping.
