# Carpeater mode (car repeater)

> **Fork feature.** Carpeater mode exists only in this fork; the upstream app
> has no such mode.

Carpeater ("car repeater") mode records coverage from the vantage point of a
MeshCore repeater instead of your companion radio. The app logs into the chosen
repeater and drives neighbor-discovery cycles through it. This is useful when
the repeater has a better antenna or position than your mobile setup - for
example, mapping an area while sitting behind a hilltop repeater.

## How it works

1. While GPS tracking is active, the app logs into the target repeater over
   the companion radio link.
2. Each discovery cycle asks the repeater for its current neighbors. The
   neighbor table is cleared before every cycle, so cached neighbors from the
   repeater's home location cannot create false coverage squares.
3. Cycle results are recorded like ordinary ping results at your current GPS
   position:
   - one green sample per heard neighbor (SNR is stored);
   - one red dead-zone sample when the repeater hears nobody;
   - the target repeater itself and your ignored-prefix list are filtered out.
4. Cycles repeat at the configured cycle interval until you stop tracking.

Regular auto-ping is suspended while Carpeater drives the radio link, and the
tracking notification shows Carpeater status instead of the live ping counter.
Normal MeshCore messaging still works through the repeater while logged in.

## Setup

Settings → Carpeater:

1. **Enable Carpeater mode**.
2. **Target repeater** - pick the repeater to drive from a searchable list of
   previously found repeaters; rows show the advertised name and ID, and the
   current selection is highlighted.
3. **Admin password** - the repeater's admin password. It is stored only in
   platform secure storage on this device and never appears in settings
   export/import or plaintext preferences.
4. **Cycle interval** - pause between discovery cycles: None (back-to-back),
   5 s, 10 s, 15 s, 30 s, 1 m, or 2 m.

Then start GPS tracking as usual. Carpeater sampling runs only while tracking
is active; toggling the mode mid-tracking switches the link between ordinary
auto-ping and Carpeater discovery.

## Behavior and limits

- **Link loss**: if the radio connection drops, Carpeater pauses and resumes
  automatically once the device reconnects.
- **Consecutive failures**: after 3 failed cycles in a row (for example the
  repeater becomes unreachable or login is refused) the mode stops with an
  error state. Use the retry action on the map status chip to log in again.
- **Samples**: Carpeater samples are tagged with the connected companion
  device ID like all other samples. RSSI is not available in this mode; only
  SNR is stored.

## Troubleshooting

- **Login fails**: verify the admin password and that the repeater permits
  CLI login. If the password was changed on the repeater, update it in
  Settings → Carpeater.
- **No coverage while driving**: remember that coverage reflects what the
  *repeater* hears, not what your phone hears. Check that the repeater's
  antenna actually reaches the area you are mapping.
- **Stops after a few cycles**: three consecutive failed cycles stop the
  mode. Check the debug terminal for the underlying radio errors and use the
  retry action once the link is stable.
