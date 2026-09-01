import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_wardrive/utils/update_check.dart';

void main() {
  group('versionFromReleaseTag', () {
    test('parses a fork-suffixed version tag', () {
      expect(versionFromReleaseTag('v1.0.44-x'), '1.0.44-x');
    });

    test('parses a plain legacy version tag', () {
      expect(versionFromReleaseTag('1.0.43'), '1.0.43');
      expect(versionFromReleaseTag('v1.0.43'), '1.0.43');
    });

    test('parses a repository-prefixed tag', () {
      expect(
        versionFromReleaseTag('Meshcore-Wardrive-Android-Source-1.0.43'),
        '1.0.43',
      );
    });

    test('returns null for unsupported tags', () {
      expect(versionFromReleaseTag('nightly'), isNull);
      expect(versionFromReleaseTag(''), isNull);
      expect(versionFromReleaseTag('build-42'), isNull);
      expect(versionFromReleaseTag('release-2.10-beta'), isNull);
      expect(versionFromReleaseTag('v1.0.44-xarleyn.1'), isNull);
    });
  });

  group('fork version ordering', () {
    test('selects the highest version from unordered release tags', () {
      expect(
        latestVersionFromReleaseTags([
          'v1.0.44-x',
          'nightly',
          'v1.0.43',
          'v1.0.45-x',
          'v1.0.46-x',
        ]),
        '1.0.46-x',
      );
    });

    test('prefers a fork suffix over a plain tag with the same base', () {
      expect(
        latestVersionFromReleaseTags(['v1.0.44', 'v1.0.44-x']),
        '1.0.44-x',
      );
    });

    test('recognizes a newer fork base version', () {
      expect(isNewerAppVersion('1.0.45-x', '1.0.44-x'), isTrue);
    });

    test('does not report an equal or older release as an update', () {
      expect(isNewerAppVersion('1.0.44-x', '1.0.44-x'), isFalse);
      expect(isNewerAppVersion('1.0.44-x', '1.0.45-x'), isFalse);
    });

    test('supports legacy tags without the fork suffix', () {
      expect(isNewerAppVersion('1.0.44-x', '1.0.44'), isTrue);
      expect(isNewerAppVersion('1.0.43', '1.0.44-x'), isFalse);
    });
  });

  group('update check endpoints', () {
    test('point at the fork repository', () {
      expect(
        updateCheckApiUrl,
        startsWith(
          'https://api.github.com/repos/xarleyn/'
          'Meshcore-Wardrive-Android-Source/releases',
        ),
      );
      expect(
        updateCheckReleasesUrl,
        'https://github.com/xarleyn/Meshcore-Wardrive-Android-Source/releases',
      );
    });

    test('uses the releases list so prereleases are found', () {
      // /releases/latest ignores prereleases and would 404 while the
      // repository only has a prerelease published.
      expect(updateCheckApiUrl, contains('?per_page=10'));
      expect(updateCheckApiUrl, isNot(contains('/releases/latest')));
    });
  });
}
