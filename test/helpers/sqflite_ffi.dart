import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Redirects the sqflite plugin to the FFI implementation so tests on the
/// host VM run against a real SQLite engine instead of the missing platform
/// channel. Call once per test file before any database access.
void useSqfliteFfi() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
}
