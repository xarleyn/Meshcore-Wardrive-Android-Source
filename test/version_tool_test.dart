import 'package:flutter_test/flutter_test.dart';

import '../tool/version.dart';

void main() {
  group('version tool', () {
    test('parses the project version', () {
      final version = parsePubspecVersion('''
name: meshcore_wardrive
version: 1.2.3+47
''');

      expect(version.name, '1.2.3');
      expect(version.buildNumber, 47);
    });

    test('increments and replaces only the pubspec version', () {
      const contents = '''
name: meshcore_wardrive
version: 1.2.3+47
description: version: remains text
''';

      final updated = replacePubspecVersion(
        contents,
        const ProjectVersion('1.2.4-beta.1', 48),
      );

      expect(updated, contains('version: 1.2.4-beta.1+48'));
      expect(updated, contains('description: version: remains text'));
    });

    test('synchronizes the Dart version constant', () {
      const contents = '''
/// Generated from pubspec.yaml.
const String appVersion = '1.2.3';
''';

      expect(
        replaceAppVersion(contents, '1.2.4'),
        contains("const String appVersion = '1.2.4';"),
      );
    });

    test('rejects invalid version names', () {
      expect(
        () => validateVersion('release-1', 2),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects Android version codes outside the supported range', () {
      expect(
        () => validateVersion('1.2.3', 2100000001),
        throwsA(isA<RangeError>()),
      );
    });
  });
}
