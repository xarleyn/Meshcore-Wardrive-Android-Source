## MeshCore Wardrive - LoRa Companion Guide

> **Fork note:** the upstream app used an MQTT broker to listen for observer
> responses. **MQTT was removed in this fork.** The app now talks only to the
> companion radio over USB/Bluetooth, and repeater responses arrive as frames
> on the same link: `LoRaCompanionService` dispatches them, and
> `lib/services/meshcore_protocol.dart` encodes and parses the frames.
>
> Sections that describe upstream-only MQTT functionality and do **not** apply
> to this fork: **Connect to MQTT** (Setup step 2), **MQTT Configuration**,
> **MQTT Won't Connect** and the MQTT items of **No Responses**
> (Troubleshooting), and **Test MQTT Connection** / **Simulate Observer
> Response** (Testing Without Real Network).

This app works like the mesh-map.pages.dev website - using your LoRa companion
device to send actual radio pings and collect repeater responses over the same
radio link.

## How It Works

```
1. Phone (GPS) → USB/Bluetooth → LoRa Companion
2. LoRa Companion → LoRa Radio → MeshCore mesh
3. Repeaters respond over the LoRa mesh; the companion radio relays the responses back
4. Green square = A repeater heard you
5. Red square = Dead zone (no response)
```

### Key Points

- **LoRa device transmits** the actual radio ping (zero-hop advert + discovery request)
- **Responses arrive over the radio link** - no MQTT broker is involved
- Tests **real mesh coverage**, not just internet connectivity
- Auto-ping by time interval (default 30 s), by distance (default ~0.5 miles), or both
- Can ignore your mobile repeater to avoid false positives

## Setup Steps

### 1. Connect LoRa Companion

**Option A: USB** (Recommended)
1. Plug LoRa device into phone via USB-C/OTG
2. Grant USB permissions when prompted
3. In app: Tap "Scan USB Devices"
4. Select your device from list
5. Wait for "Connected via USB"

**Option B: Bluetooth**
1. Pair LoRa device in Android Bluetooth settings
2. In app: Tap "Scan Bluetooth Devices"
3. Select your device from the live list. Previously used devices appear
   immediately.
4. Wait for "Connected via Bluetooth"

### 2. Connect to MQTT *(upstream only - removed in this fork)*

1. Tap "Connect to MQTT"
2. Enter broker details (default: `mqtt.meshcore.io`)
3. Enter credentials if required
4. Wait for "MQTT Connected"

### 3. Configure Settings (Optional)

Ping and discovery options live in Settings → Discovery and in the quick
settings panel on the map screen:

**Ping Mode:**
- **Distance** - ping after moving a set distance (default ~0.5 miles)
- **Time** - ping on a fixed interval (default 30 s)
- **Both** - ping when either trigger fires first

**Ping Interval:**
- Distance presets: 50 m, 200 m, 400 m, 0.5 mi (805 m), 1 mi (1609 m)
- Time presets: 5 s to 5 minutes

**Discovery Timeout:**
- How long the app waits for repeater responses after each ping
- Adjustable from 5 to 30 seconds (default 10 s)

**Ignore Mobile Repeater:**
- If you carry a portable repeater, set its prefix
- Example: If your repeater ID is `MOB-123`, enter `MOB-`
- This prevents false positive pings

### 4. Start Wardriving

1. Enable "Auto-Ping" toggle
2. Tap green play button to start GPS tracking
3. As you move:
   - A ping fires when the distance or time trigger is reached
   - The app waits up to the discovery timeout for repeater responses
   - Green = heard by a repeater
   - Red = no response (dead zone)

## Supported LoRa Devices

This fork works with radios running the **MeshCore companion firmware**,
connected over USB serial or Bluetooth LE (boards such as T-Beam, Heltec,
LILYGO, and other LoRa boards supported by that firmware).

### Protocol

The app speaks the MeshCore companion radio binary protocol. Frame layout,
command codes (`CMD_*`), and response codes (`RESP_CODE_*`) are defined in
`lib/services/meshcore_protocol.dart` and must stay in sync with the
companion firmware (see `companion_protocol.md` in the MeshCore repository).

## MQTT Configuration *(upstream only - removed in this fork)*

### Default Settings

```
Broker: mqtt.meshcore.io
Port: 1883
Subscribe Topic: meshcore/observer/+/pong
```

### Expected Observer Response Format

When an observer hears your ping, it should publish to MQTT:

**Topic:** `meshcore/observer/{observer_id}/pong`

**Payload:**
```json
{
  "ping_id": "abc12345",
  "observer_id": "OBS-001",
  "rssi": -85,
  "snr": 7,
  "lat": 47.7776,
  "lon": -122.4247,
  "timestamp": "2024-01-01T12:00:00Z"
}
```

## Customization

Customization happens through app settings - no code edits required:

### Ping Trigger and Interval

Settings → Discovery → **Ping mode**:

- **Distance**: ping after moving a set distance. Presets: 50 m, 200 m,
  400 m, 0.5 mi (805 m), 1 mi (1609 m). Default: 805 m (~0.5 miles).
- **Time**: ping on a fixed interval. Presets: 5 s … 5 min. Default: 30 s.
- **Both**: whichever trigger fires first.

The same ping mode, interval, and timeout controls are also available in the
quick settings panel on the map screen.

### Discovery Timeout

Settings → Discovery → **Discovery timeout**: how long the app collects
repeater responses after a ping, from 5 to 30 seconds (default 10 s). The
**Thorough response collection** toggle next to it keeps collecting until the
timeout instead of finishing early.

### Ignore / Include Repeaters

Settings → Discovery:

- **Ignore repeaters**: prefixes of repeaters to exclude from results (for
  example, your own mobile repeater) to avoid false positives.
- **Include only repeaters**: whitelist of prefixes; when set, only matching
  repeaters are shown.

### Protocol Constants

Protocol-level constants (response layout version, maximum frame size, `CMD_*`
command codes, `RESP_CODE_*` response codes) are defined in
`lib/services/meshcore_protocol.dart`. They mirror the MeshCore companion
firmware - change them only together with the firmware side of the link.

## Data Export

Exported samples include all ping data:

```json
{
  "id": "1234567890_c23nb2q2",
  "lat": 47.7776,
  "lon": -122.4247,
  "timestamp": "2024-01-01T12:00:00.000Z",
  "geohash": "c23nb2q2",
  "rssi": -85,
  "snr": 7,
  "pingSuccess": true
}
```

- `pingSuccess: true` = A repeater heard your ping (green)
- `pingSuccess: false` = No response (red)
- `pingSuccess: null` = Auto-ping was disabled

## Troubleshooting

### LoRa Device Won't Connect

**USB:**
- Check USB-C cable supports data (not just charging)
- Enable USB debugging in Android settings
- Try different USB port

**Bluetooth:**
- Pair device in Android settings first
- Ensure device is in discoverable mode
- Check device battery

### MQTT Won't Connect *(upstream only - removed in this fork)*

- Verify broker address and port
- Check internet connection (cellular/WiFi)
- Confirm credentials if required
- Test broker with MQTT client (MQTT Explorer, mosquitto_sub)

### No Responses (Dead Zones)

- Ensure the LoRa device is actually transmitting (check the debug terminal)
- Check that you are in range of any repeaters
- Increase the discovery timeout in Settings → Discovery
- If you carry a repeater, review the ignored-prefix filter

### Ping Timeout Too Long

Lower the **Discovery timeout** in Settings → Discovery (5–30 s presets,
default 10 s). No code changes required.

### False Positives from Mobile Repeater

Set the ignored repeater prefix in Settings → Discovery → Ignore repeaters
(e.g., `MOB-`).

## Testing Without Real Network

### Test LoRa Connection

1. Connect device via USB/Bluetooth
2. Check device response in the debug terminal
3. Send test ping manually

### Test MQTT Connection *(upstream only - removed in this fork)*

Use a public MQTT broker for testing:
```dart
broker: 'test.mosquitto.org'
port: 1883
// No authentication required
```

### Simulate Observer Response *(upstream only - removed in this fork)*

Use MQTT client to publish test response:

```bash
mosquitto_pub -h mqtt.meshcore.io -t meshcore/observer/TEST/pong -m '{
  "ping_id": "testping",
  "observer_id": "TEST-OBS",
  "rssi": -75,
  "snr": 9
}'
```

## Advanced Features

### Custom Ping Logic

Ping/discovery is implemented in `LoRaCompanionService.ping()`
(`lib/services/lora_companion_service.dart`): it sends a zero-hop
advertisement and a discovery request through the companion protocol, then
matches repeater responses by tag until the timeout.

### Custom Response Parsing

Frame dispatch lives in `LoRaCompanionService` (`_handleFrame`); frame
encoding/parsing helpers and all protocol constants live in
`lib/services/meshcore_protocol.dart`.

### Add Manual Ping Button

Access `locationService.loraCompanion.ping()` directly for single pings.

## Performance Tips

1. **Ping Interval**: ~0.5 miles is good balance - closer intervals may slow you down waiting for responses
2. **Timeout**: 10–30 seconds covers most mesh response times
3. **Battery**: USB connection drains less battery than Bluetooth
4. **Range**: Stay within repeater range for best results

## Security & Privacy

- GPS coordinates stay on the device unless you explicitly export or upload data
- Ping/discovery requests are transmitted over the LoRa mesh by your radio
- No personal information transmitted
- All collected data stays local unless exported or uploaded

## Credits

This implementation replicates the workflow from mesh-map.pages.dev for
MeshCore coverage mapping with LoRa companions.
