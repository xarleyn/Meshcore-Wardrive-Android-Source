# Android home screen widget

MeshCore Wardrive ships a 4×2 home screen widget that shows live wardrive
statistics without opening the app.

## Add the widget

Long-press an empty spot on the home screen, open **Widgets**, find
**MeshCore Wardrive**, and drag the widget to the home screen.

## What it shows

- **Tracking status** — Tracking or Idle with a color indicator;
- **Sample count** — GPS points recorded in the current session;
- **Connection** — the companion radio link type (USB / Bluetooth);
- **Success rate** — share of successful pings in the session;
- **Session distance** — distance driven while tracking.

Tapping the widget opens the app.

## Behavior

- The widget refreshes in real time as you drive: on tracking start/stop,
  every saved sample, and companion connect/disconnect.
- It follows the in-app language (English or Russian) like the rest of the
  interface.
- The widget belongs to the fork's package
  (`io.github.xarleyn.meshcore.wardrive`); after installing a fork release
  you add it again — it is not carried over from the original app.
