import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_wardrive/services/database_backup_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DatabaseBackupService.hasSqliteHeader', () {
    test('accepts the SQLite 3 signature', () {
      final bytes = <int>[...'SQLite format 3\u0000'.codeUnits, 1, 2, 3];
      expect(DatabaseBackupService.hasSqliteHeader(bytes), isTrue);
    });

    test('rejects empty and short content', () {
      expect(DatabaseBackupService.hasSqliteHeader(<int>[]), isFalse);
      expect(DatabaseBackupService.hasSqliteHeader(<int>[0x53, 0x51]), isFalse);
    });

    test('rejects foreign file signatures', () {
      expect(
        DatabaseBackupService.hasSqliteHeader(<int>[
          ...'PK\u0003\u0004'.codeUnits,
        ]),
        isFalse,
      );
      expect(
        DatabaseBackupService.hasSqliteHeader(<int>[
          ...'not a database'.codeUnits,
        ]),
        isFalse,
      );
    });
  });

  group('DatabaseBackupService.validateBackupFile', () {
    late Directory tempDir;
    final service = DatabaseBackupService();

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('db_backup_test');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    Matcher throwsInvalidHeader() => throwsA(
      isA<DatabaseBackupException>().having(
        (e) => e.error,
        'error',
        DatabaseBackupValidationError.invalidHeader,
      ),
    );

    test('rejects a missing file', () {
      expect(
        service.validateBackupFile('${tempDir.path}/missing.db'),
        throwsInvalidHeader(),
      );
    });

    test('rejects a non-SQLite file', () async {
      final file = File('${tempDir.path}/garbage.db');
      await file.writeAsString('not a database at all ' * 10);

      expect(service.validateBackupFile(file.path), throwsInvalidHeader());
    });

    test('rejects a file that only fakes the SQLite signature', () async {
      // Carries the magic header but is not a database a plugin can open.
      final file = File('${tempDir.path}/fake.db');
      await file.writeAsBytes(<int>[
        ...'SQLite format 3\u0000'.codeUnits,
        ...List<int>.filled(200, 0),
      ]);

      expect(service.validateBackupFile(file.path), throwsInvalidHeader());
    });
  });
}
