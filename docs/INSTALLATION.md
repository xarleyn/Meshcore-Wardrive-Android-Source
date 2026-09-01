# Installation Guide

## Android Installation

### Step 1: Enable Unknown Sources
1. Open **Settings** on your Android device
2. Go to **Security** or **Privacy**
3. Enable **Install from Unknown Sources** or **Allow from this source** (for Android 8+)

### Step 2: Download the APK
1. Download the latest APK from the [GitHub Releases page](https://github.com/xarleyn/Meshcore-Wardrive-Android-Source/releases)
2. Transfer to your Android device if downloaded on computer

### Step 3: Install
1. Open the APK file on your device
2. Tap **Install**
3. Wait for installation to complete
4. Tap **Open** or find the app in your app drawer

### Important: fresh fork identity

Starting with `v1.0.44-xarleyn.1`, this fork uses the Android package ID
`io.github.xarleyn.meshcore.wardrive`. The original application and older fork
builds used `mintylinux.meshcore.wardrive`, so Android treats this release as a
different application. Both applications can be installed at the same time.

There is no automatic data migration. The new fork starts with an empty
database and default settings; data in the old package is not available to it.
Treat old measurements and settings as lost for this transition. Uninstalling
the old package permanently deletes its private data.

### Step 4: Grant Permissions
On first launch, grant these permissions:
- **Location** (Always) - Required for GPS tracking
- **Bluetooth** - For Bluetooth LoRa device connection
- **Storage** - For exporting data
- **USB** - For USB LoRa device connection (when connected)

## First Time Setup

### Join #meshwar Channel
1. Open the **MeshCore app** on your device
2. Get the **#meshwar QR code** from another user
3. Scan the QR code to join the channel
4. The channel will now appear in your channels list

### Connect LoRa Device

#### USB Connection
1. Connect your MeshCore companion radio via USB cable
2. Open MeshCore Wardrive app
3. Tap **Connect** → **Scan USB Devices**
4. Select your device from the list
5. Grant USB permissions when prompted

#### Bluetooth Connection
1. Pair your device in Android Settings → Bluetooth first
2. Open MeshCore Wardrive app
3. Tap **Connect** → **Scan Bluetooth**
4. Select your device from the live list. Previously used radios appear
   immediately; newly found devices are added while scanning continues.
5. Wait for connection (green indicator)

### Start Wardriving
1. Press the **green play button** to start GPS tracking
2. Toggle **Auto-Ping switch** to enable automatic pinging
3. Drive/walk through your area
4. Watch the map fill with coverage data!

## Troubleshooting

### "Failed to install" error
- Make sure you have enough storage space (need ~100MB free)
- For an update, make sure the APK has the same application ID and signing
  certificate as the installed app, and a higher build number
- `v1.0.44-xarleyn.1` is a fresh install and does not replace a build using
  `mintylinux.meshcore.wardrive`
- Restart your device and try again

### Permissions denied
- Go to Settings → Apps → MeshCore Wardrive → Permissions
- Enable all required permissions manually

### App crashes on startup
- Clear app data: Settings → Apps → MeshCore Wardrive → Storage → Clear Data
- Reinstall the app
- Make sure your Android version is 7.0 or higher

## Updating

For updates between releases that already use
`io.github.xarleyn.meshcore.wardrive`:

1. Download the new APK
2. Install over the existing app (data will be preserved)

Do not uninstall first unless you intentionally want a clean installation.
Uninstalling deletes the app's settings and collected wardrive data. If Android
rejects the update because its signing certificate differs, export or back up
important data before uninstalling the old app.

The one-time change from `mintylinux.meshcore.wardrive` to
`io.github.xarleyn.meshcore.wardrive` is not an update. After installing the
new fork, grant permissions again and reconfigure background location, battery
optimization/MIUI autostart, Bluetooth or USB access, widgets, offline maps,
and any stored credentials. No migration from the old package is provided.

## Uninstalling

1. Go to Settings → Apps → MeshCore Wardrive
2. Tap **Uninstall**
3. Or long-press the app icon → App info → Uninstall

Note: Uninstalling will delete all your collected wardrive data.
