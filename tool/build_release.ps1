param(
    [ValidatePattern('^\d+\.\d+\.\d+-x$')]
    [string]$VersionName,

    [switch]$SplitPerAbi
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
$pubspecPath = Join-Path $repoRoot 'pubspec.yaml'
$appVersionPath = Join-Path $repoRoot 'lib\constants\app_version.dart'
$keyPropertiesPath = Join-Path $repoRoot 'android\key.properties'
$environmentScript = Join-Path $repoRoot '.toolchain\env.ps1'

if (-not (Test-Path -LiteralPath $environmentScript)) {
    throw "Repository toolchain environment not found: $environmentScript"
}

if (-not (Test-Path -LiteralPath $keyPropertiesPath)) {
    throw 'Release signing is not configured. Create android\key.properties first; see docs/development/releasing.md.'
}

$originalPubspec = [System.IO.File]::ReadAllText($pubspecPath)
$originalAppVersion = [System.IO.File]::ReadAllText($appVersionPath)
$buildSucceeded = $false

Push-Location $repoRoot
try {
    . $environmentScript

    $versionArguments = @('run', 'tool/version.dart', 'bump')
    if ($VersionName) {
        $versionArguments += $VersionName
    }
    & dart @versionArguments
    if ($LASTEXITCODE -ne 0) {
        throw "Version update failed with exit code $LASTEXITCODE."
    }

    & dart run tool/version.dart check
    if ($LASTEXITCODE -ne 0) {
        throw "Version consistency check failed with exit code $LASTEXITCODE."
    }

    & flutter pub get
    if ($LASTEXITCODE -ne 0) {
        throw "flutter pub get failed with exit code $LASTEXITCODE."
    }

    $flutterArguments = @('build', 'apk', '--release')
    if ($SplitPerAbi) {
        $flutterArguments += '--split-per-abi'
    }
    & flutter @flutterArguments
    if ($LASTEXITCODE -ne 0) {
        throw "Release build failed with exit code $LASTEXITCODE."
    }

    $buildSucceeded = $true
} finally {
    if (-not $buildSucceeded) {
        [System.IO.File]::WriteAllText($pubspecPath, $originalPubspec)
        [System.IO.File]::WriteAllText($appVersionPath, $originalAppVersion)
        Write-Warning 'The release failed; version files were restored.'
    }
    Pop-Location
}
