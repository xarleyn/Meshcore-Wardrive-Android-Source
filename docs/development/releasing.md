# Android release builds

Android accepts an APK as an update only when all of the following remain true:

- the `applicationId` is unchanged (`mintylinux.meshcore.wardrive`);
- the new `versionCode` is greater than the installed one;
- the new APK is signed with the same certificate as the installed APK.

Application settings and the SQLite database surviving installation are a
reliable sign that Android performed an in-place update. Uninstalling the app
deletes that private application data.

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

`flutter run` installs a debug-signed APK with the same application ID. It can
update another debug installation, but it cannot replace an APK signed with the
dedicated release key. Use the signed release APK when validating the real
upgrade path; use `flutter run` for development-only device validation.

## Build and increment the version

From PowerShell at the repository root, run:

```powershell
.\tool\build_release.ps1
```

The script increments only the Android build number (`versionCode`), for
example `1.0.42+45` to `1.0.42+46`, synchronizes the in-app version constant,
and builds the release APK. If the build fails, it restores both version files.

For a new public version, pass its semantic version name. The build number is
still incremented automatically:

```powershell
.\tool\build_release.ps1 -VersionName 1.0.43
```

To produce per-architecture APKs, add `-SplitPerAbi`.

The lower-level cross-platform version commands are:

```powershell
. .\.toolchain\env.ps1
dart run tool/version.dart check
dart run tool/version.dart sync
dart run tool/version.dart bump 1.0.43
```

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

On Linux or macOS:

```sh
base64 -w0 /path/to/meshcore-wardrive-upload.jks | pbcopy   # macOS
base64 -w0 /path/to/meshcore-wardrive-upload.jks            # Linux
```

On Windows PowerShell:

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes('C:\secure\meshcore-wardrive-upload.jks')) | Set-Clipboard
```

### Publish

1. Commit the desired `version:` in `pubspec.yaml` (and matching
   `lib/constants/app_version.dart`) on the branch you want to ship.
2. Open **Actions → Release APK → Run workflow**.
3. Optionally mark the GitHub Release as a pre-release.
4. The workflow creates tag `v{versionName}` (for example `v1.0.42` from
   `1.0.42+45`) and attaches
   `meshcore-wardrive-{versionName}-{versionCode}.apk`.

If that tag or release already exists, the workflow fails so you can bump the
version first. Continuous integration on `main` runs format checks, analyzer,
tests, and a debug APK build; it does not publish releases.
