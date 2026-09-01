import 'package:flutter_test/flutter_test.dart';

import '../tool/version.dart';

void main() {
  group('version tool', () {
    test('parses the project version', () {
      final version = parsePubspecVersion('''
name: meshcore_wardrive
version: 1.2.3-xarleyn.4+47
''');

      expect(version.name, '1.2.3-xarleyn.4');
      expect(version.buildNumber, 47);
    });

    test('increments and replaces only the pubspec version', () {
      const contents = '''
name: meshcore_wardrive
version: 1.2.3-xarleyn.4+47
description: version: remains text
''';

      final updated = replacePubspecVersion(
        contents,
        const ProjectVersion('1.2.4-xarleyn.1', 48),
      );

      expect(updated, contains('version: 1.2.4-xarleyn.1+48'));
      expect(updated, contains('description: version: remains text'));
    });

    test('synchronizes the Dart version constant', () {
      const contents = '''
/// Generated from pubspec.yaml.
const String appVersion = '1.2.3';
''';

      expect(
        replaceAppVersion(contents, '1.2.4-xarleyn.1'),
        contains("const String appVersion = '1.2.4-xarleyn.1';"),
      );
    });

    test('increments the fork revision by default', () {
      expect(nextForkVersionName('1.2.4-xarleyn.1'), '1.2.4-xarleyn.2');
    });

    test('rejects versions without a positive fork revision', () {
      expect(
        () => validateVersion('1.2.3', 2),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => validateVersion('1.2.3-xarleyn.0', 2),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects Android version codes outside the supported range', () {
      expect(
        () => validateVersion('1.2.3-xarleyn.1', 2100000001),
        throwsA(isA<RangeError>()),
      );
    });
  });
}
