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

    test('parses a repository-prefixed tag', () {
      expect(
        versionFromReleaseTag('Meshcore-Wardrive-Android-Source-1.0.43'),
        '1.0.43',
      );
    });

    test('returns only the dotted version part', () {
      expect(versionFromReleaseTag('release-2.10-beta'), '2.10');
    });

    test('returns null for tags without a dotted version', () {
      expect(versionFromReleaseTag('nightly'), isNull);
      expect(versionFromReleaseTag(''), isNull);
      expect(versionFromReleaseTag('build-42'), isNull);
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
      expect(updateCheckApiUrl, contains('?per_page=1'));
      expect(updateCheckApiUrl, isNot(contains('/releases/latest')));
    });
  });
}
