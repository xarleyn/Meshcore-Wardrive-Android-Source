# Android release builds

Android accepts an APK as an update only when all of the following remain true:

- the `applicationId` is unchanged (`io.github.xarleyn.meshcore.wardrive`);
- the new `versionCode` is greater than the installed one;
- the new APK is signed with the same certificate as the installed APK.

Application settings and the SQLite database surviving installation are a
reliable sign that Android performed an in-place update. Uninstalling the app
deletes that private application data.

The package ID changed once at `v1.0.44-x`. That release is a fresh
installation, not an in-place update of `mintylinux.meshcore.wardrive`; no data
migration is implemented. All later releases must retain the new package ID.

## Configure stable signing once

Release builds intentionally fail when signing is not configured. This avoids
publishing APKs signed by a machine-specific debug key.

Create and back up a dedicated keystore outside the repository:

```powershell
. .\.toolchain\env.ps1
keytool -genkeypair -v -keystore C:\secure\meshcore-wardrive-upload.jks `
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Copy `android/key.properties.example` to `android/key.properties`, then replace
the placeholder values. Use the same keystore for every future release and
keep an encrypted backup. Losing it prevents updates to installations signed
with that key.

Changing from an old debug key to a dedicated release key is itself a signing
change. Existing installations signed by the old key must be uninstalled once,
unless the original signing key is retained for releases.

`flutter run` installs `io.github.xarleyn.meshcore.wardrive.debug`, while signed
releases use `io.github.xarleyn.meshcore.wardrive`. Debug and release builds can
therefore coexist and keep independent data. Use the signed release APK when
validating the real upgrade path.

## Build and increment the version

From PowerShell at the repository root, run:

```powershell
.\tool\build_release.ps1
```

The script bumps the base version and Android build number, for example
`1.0.44-x+47` to `1.0.45-x+48`, synchronizes the in-app version constant, and
builds the release APK. If the build fails, it restores both version files.

To adopt a specific version name, pass it explicitly:

```powershell
.\tool\build_release.ps1 -VersionName 1.0.45-x
```

To produce per-architecture APKs, add `-SplitPerAbi`.

The lower-level cross-platform version commands are:

```powershell
. .\.toolchain\env.ps1
dart run tool/version.dart check
dart run tool/version.dart sync
dart run tool/version.dart bump 1.0.45-x
```

The version tool rejects names without the required `-x` suffix and rejects
zero or invalid Android build numbers. The `bump` command without a version
name increments the base patch version and `versionCode`, for example
`1.0.44-x+47` to `1.0.45-x+48`.

Commit `pubspec.yaml` and `lib/constants/app_version.dart` together after a
successful release build. Never commit `android/key.properties`, a keystore,
or generated APK files.

## GitHub Actions release

The repository includes a manual workflow that builds a signed release APK from
the version already committed in `pubspec.yaml` and publishes it to GitHub
Releases in the same repository. It does not bump versions.

### Repository secrets

Configure these secrets on the fork before the first Actions release:

| Secret | Value |
| --- | --- |
| `ANDROID_KEYSTORE_BASE64` | Base64 encoding of the `.jks` / `.keystore` file |
| `ANDROID_KEYSTORE_PASSWORD` | `storePassword` from `key.properties` |
| `ANDROID_KEY_PASSWORD` | `keyPassword` from `key.properties` |
| `ANDROID_KEY_ALIAS` | `keyAlias` from `key.properties` |
| `ANDROID_CERT_SHA256` | SHA-256 fingerprint of the release certificate (colons optional) |

On Linux or macOS:

```sh
base64 -w0 /path/to/meshcore-wardrive-upload.jks | pbcopy   # macOS
base64 -w0 /path/to/meshcore-wardrive-upload.jks            # Linux
```

On Windows PowerShell:

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes('C:\secure\meshcore-wardrive-upload.jks')) | Set-Clipboard
```

Read the expected certificate fingerprint with:

```powershell
. .\.toolchain\env.ps1
keytool -list -v -keystore C:\secure\meshcore-wardrive-upload.jks -alias upload
```

Copy the value shown as `SHA256` into `ANDROID_CERT_SHA256`.

### Publish

1. Commit the desired `version:` in `pubspec.yaml` (and matching
   `lib/constants/app_version.dart`) on the branch you want to ship.
2. Open **Actions → Release APK → Run workflow**.
3. Optionally mark the GitHub Release as a pre-release.
4. The workflow creates tag `v{versionName}` (for example
   `v1.0.44-x`) and attaches
   `meshcore-wardrive-xarleyn-{versionName}-{versionCode}.apk`.
5. The release description is filled automatically from the matching
   `## v{versionName} - date` section of `CHANGELOG.md`, followed by the APK
   asset name. The workflow fails before building when that section is
   missing, so keep the changelog entry for the released version up to date.

If that tag or release already exists, the workflow fails so you can bump the
version first. It also fails when the version suffix, package ID, version code,
version name, or signing certificate is unexpected, or when `versionCode` is
not greater than codes found in existing release asset names. Continuous
integration on `main` runs format checks, analyzer, tests, and a debug APK
build; it does not publish releases.

## Manual release validation

Before publication, validate on a device that:

- the original app, the fork release, and the fork debug build can coexist;
- upgrading from one fork release (`-x` suffix) to the next preserves fork
  data;
- USB, Bluetooth LE, foreground location, notifications, and the widget work;
- MIUI Security Space and battery/autostart settings are configured for the new
  package independently.

The release workflow performs `aapt dump badging` and `apksigner verify`
equivalents automatically, but physical radio and Android background behavior
still require device testing.
