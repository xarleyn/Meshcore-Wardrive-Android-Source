/// Endpoints and helpers for the in-app update check and releases link.
///
/// Everything points at this fork's repository, where release APKs are
/// published. The API uses the releases list endpoint instead of
/// `/releases/latest` because the latter ignores prereleases and would
/// report "no releases" while only a prerelease exists.
library;

const String updateCheckApiUrl =
    'https://api.github.com/repos/xarleyn/Meshcore-Wardrive-Android-Source/releases?per_page=10';

const String updateCheckReleasesUrl =
    'https://github.com/xarleyn/Meshcore-Wardrive-Android-Source/releases';

final RegExp _releaseVersionPattern = RegExp(r'(\d+)\.(\d+)\.(\d+)(-x)?$');

class ReleaseVersion implements Comparable<ReleaseVersion> {
  const ReleaseVersion({
    required this.name,
    required this.major,
    required this.minor,
    required this.patch,
    required this.forkSuffix,
  });

  final String name;
  final int major;
  final int minor;
  final int patch;

  /// Legacy release tags without the `-x` fork suffix rank below fork builds
  /// of the same base version.
  final bool forkSuffix;

  static ReleaseVersion? fromTag(String tagName) {
    final match = _releaseVersionPattern.firstMatch(tagName);
    if (match == null) return null;
    return ReleaseVersion(
      name: match.group(0)!,
      major: int.parse(match.group(1)!),
      minor: int.parse(match.group(2)!),
      patch: int.parse(match.group(3)!),
      forkSuffix: match.group(4) != null,
    );
  }

  @override
  int compareTo(ReleaseVersion other) {
    for (final comparison in [
      major.compareTo(other.major),
      minor.compareTo(other.minor),
      patch.compareTo(other.patch),
      (forkSuffix ? 1 : 0).compareTo(other.forkSuffix ? 1 : 0),
    ]) {
      if (comparison != 0) return comparison;
    }
    return 0;
  }
}

/// Extracts the complete supported version from a fork or legacy release tag.
String? versionFromReleaseTag(String tagName) {
  return ReleaseVersion.fromTag(tagName)?.name;
}

/// Selects the greatest supported version regardless of API response order.
String? latestVersionFromReleaseTags(Iterable<String> tagNames) {
  ReleaseVersion? latest;
  for (final tagName in tagNames) {
    final candidate = ReleaseVersion.fromTag(tagName);
    if (candidate != null &&
        (latest == null || candidate.compareTo(latest) > 0)) {
      latest = candidate;
    }
  }
  return latest?.name;
}

/// Returns false for equal, older, or malformed versions.
bool isNewerAppVersion(String candidate, String current) {
  final candidateVersion = ReleaseVersion.fromTag(candidate);
  final currentVersion = ReleaseVersion.fromTag(current);
  if (candidateVersion == null || currentVersion == null) return false;
  return candidateVersion.compareTo(currentVersion) > 0;
}
