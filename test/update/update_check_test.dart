import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_wardrive/utils/update_check.dart';

void main() {
  group('versionFromReleaseTag', () {
    test('parses a plain version tag', () {
      expect(versionFromReleaseTag('1.0.43'), '1.0.43');
    });

    test('parses a v-prefixed tag', () {
      expect(versionFromReleaseTag('v1.0.43'), '1.0.43');
    });

    test('preserves the fork revision', () {
      expect(versionFromReleaseTag('v1.0.44-xarleyn.1'), '1.0.44-xarleyn.1');
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
      expect(versionFromReleaseTag('v1.0.44-xarleyn.0'), isNull);
    });
  });

  group('fork version ordering', () {
    test('selects the highest version from unordered release tags', () {
      expect(
        latestVersionFromReleaseTags([
          'v1.0.44-xarleyn.1',
          'nightly',
          'v1.0.43',
          'v1.0.45-xarleyn.1',
          'v1.0.44-xarleyn.2',
        ]),
        '1.0.45-xarleyn.1',
      );
    });

    test('recognizes a newer fork revision', () {
      expect(isNewerAppVersion('1.0.44-xarleyn.2', '1.0.44-xarleyn.1'), isTrue);
    });

    test('recognizes a newer upstream base version', () {
      expect(isNewerAppVersion('1.0.45-xarleyn.1', '1.0.44-xarleyn.9'), isTrue);
    });

    test('does not report an equal or older release as an update', () {
      expect(
        isNewerAppVersion('1.0.44-xarleyn.1', '1.0.44-xarleyn.1'),
        isFalse,
      );
      expect(
        isNewerAppVersion('1.0.44-xarleyn.1', '1.0.45-xarleyn.1'),
        isFalse,
      );
    });

    test('supports legacy tags as fork revision zero', () {
      expect(isNewerAppVersion('1.0.44-xarleyn.1', '1.0.44'), isTrue);
      expect(isNewerAppVersion('1.0.43', '1.0.44-xarleyn.1'), isFalse);
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
