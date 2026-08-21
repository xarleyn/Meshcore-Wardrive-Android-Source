/// Endpoints and helpers for the in-app update check and releases link.
///
/// Everything points at this fork's repository, where release APKs are
/// published. The API uses the releases list endpoint instead of
/// `/releases/latest` because the latter ignores prereleases and would
/// report "no releases" while only a prerelease exists.
library;

const String updateCheckApiUrl =
    'https://api.github.com/repos/xarleyn/Meshcore-Wardrive-Android-Source/releases?per_page=1';

const String updateCheckReleasesUrl =
    'https://github.com/xarleyn/Meshcore-Wardrive-Android-Source/releases';

/// Extracts a dotted version such as `1.0.42` from a release tag like
/// `v1.0.42`, `1.0.42`, or `Meshcore-Wardrive-Android-Source-1.0.42`.
/// Returns null when the tag carries no dotted version.
String? versionFromReleaseTag(String tagName) {
  return RegExp(r'\d+(?:\.\d+)+').firstMatch(tagName)?.group(0);
}
