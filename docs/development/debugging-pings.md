# Debugging MeshCore Wardrive Ping Responses

## Expected flow

After connecting, the app sends a valid `CMD_APP_START`, negotiates companion
protocol version 13 with `CMD_DEVICE_QUERY`, and loads the contact list. A ping
then produces logs similar to:

```text
📍 Updated device position: lat, lon
📡 Sending zero-hop advertisement
📡 Sending DISCOVER_REQ with tag=0xXXXXXXXX
🔍 DISCOVER_RESP: tag=0xXXXXXXXX, node=[ID], type=2, SNR=X, RSSI=Y
📞 Requesting position for [ID]
Contact: [NAME] (type: 2)
✅ Added to map: [NAME] at (lat, lon)
```

The first matching discovery response completes the ping. Further responses
with the same tag are collected briefly for radio-position estimation.

Key incoming frame codes are:

- `0x03`: contact details response.
- `0x05`: self information returned by `CMD_APP_START`.
- `0x0D`: device and negotiated-protocol information.
- `0x80`: advertisement containing a 32-byte public key; the app follows it
  with `CMD_GET_CONTACT_BY_KEY` (`0x1E`).
- `0x84`: arbitrary `PUSH_CODE_RAW_DATA`. This is not a delivery ACK and does
  not count as a wardrive ping response.
- `0x8A`: newly auto-added contact in the same full layout as `0x03`.
- `0x8E`: control data, including tagged discovery responses.

## Common issues

### No raw data after sending a ping

Check that the device is still connected, has enough battery, is running
companion firmware, and is in radio range. For BLE, MeshCore must expose service
`6E400001-B5A3-F393-E0A9-E50E24DCCA9E` with RX `...0002` and TX `...0003`.

### Raw data arrives but no frames are parsed

USB radio-to-app frames start with `3E`, followed by a two-byte little-endian
length. BLE notifications are unwrapped and begin directly with the packet
code. A USB/BLE mode mismatch or truncated serial data will prevent parsing.

### Only command responses arrive

`0x00` means success, `0x01` means error, and `0x06` means a packet was queued
for transmission. These confirm local command processing; they do not mean a
repeater answered the tagged discovery request. Look for `0x8E` and a matching
tag.

### Discovery response has an unknown tag

The response probably arrived after its ping window ended. Increase the ping
timeout and confirm the received tag matches the transmitted tag. The app
allows only one discovery cycle at a time.

### A repeater answers but has no map position

Look for `Requesting position`, followed by a `0x03` contact response. The
contact must be a repeater or room server and include latitude and longitude.
Also check the ignored-repeater-prefix setting.

## Current frame layouts

`PUSH_CODE_RAW_DATA` (`0x84`) payload, excluding the packet code:

```text
Byte 0:   SNR * 4 (signed int8)
Byte 1:   RSSI (signed int8)
Byte 2:   Reserved
Byte 3+:  Arbitrary radio payload
```

`PUSH_CODE_CONTROL_DATA` (`0x8E`) payload, excluding the packet code:

```text
Byte 0:   SNR * 4 (signed int8)
Byte 1:   RSSI (signed int8)
Byte 2:   Reported path length
Byte 3+:  Control payload
```

The firmware reports the path length as metadata but does not copy path bytes
into this companion frame. The control payload always starts at byte 3.

A discovery response control payload is:

```text
Byte 0:   Upper nibble 0x9 (DISCOVER_RESP), lower nibble node type
Byte 1:   SNR * 4 (signed int8)
Byte 2-5: Request tag (uint32 little-endian)
Byte 6+:  Public key (8-byte prefix or full 32 bytes)
```

Wardrive requests full 32-byte keys so it can immediately issue
`CMD_GET_CONTACT_BY_KEY` and cache a contact for map and Carpeater use.

## Manual device checks

1. Connect over USB and verify logs show self info, device info, and a complete
   contact-list transfer.
2. Repeat over BLE and verify the negotiated MTU and notifications remain
   stable while loading contacts.
3. Send a ping in a known-covered area and confirm one or more tagged `0x8E`
   responses complete it.
4. Confirm `0x80` causes a command-30 contact lookup and `0x8A` updates a contact
   directly.
5. Capture a full debug log if the firmware returns `0x01`; the following byte
   is the MeshCore error code.
