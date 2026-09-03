import 'dart:io';

import 'package:meshcore_wardrive/services/database_service.dart';

import 'fake_path_provider.dart';

/// Fresh temporary SQLite database per test.
///
/// [setUp] redirects path_provider into a new system-temp directory and
/// creates the service; [tearDown] closes the database so the directory can
/// be deleted on Windows. The harness relies on `useSqfliteFfi()` having been
/// called once in the test file's `main`.
class DatabaseHarness {
  late Directory tempDir;
  late DatabaseService databaseService;

  Future<void> setUp() async {
    tempDir = await Directory.systemTemp.createTemp('db_service_test');
    installFakePathProvider(tempDir);
    databaseService = DatabaseService();
  }

  Future<void> tearDown() async {
    try {
      await databaseService.close();
    } catch (_) {
      // Already closed or never opened; directory deletion is best-effort.
    }
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  }
}
