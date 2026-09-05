import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Minimal read/write/delete boundary over platform secure storage.
///
/// Isolates the device storage boundary so tests can substitute an in-memory
/// fake instead of touching the real keychain/keystore (AGENTS.md: "Isolate
/// device and network boundaries so they can be faked").
abstract class SecureCredentialsStore {
  Future<String?> read(String key);

  Future<void> write(String key, String value);

  Future<void> delete(String key);
}

/// Default [SecureCredentialsStore] backed by [FlutterSecureStorage].
///
/// Android keeps the plugin v10 defaults (KeyStore-wrapped AES-GCM with
/// `resetOnError` and automatic cipher migration). The legacy
/// `encryptedSharedPreferences` flag is deprecated and ignored by the plugin
/// since v10, so it is intentionally left unset.
class FlutterSecureCredentialsStore implements SecureCredentialsStore {
  const FlutterSecureCredentialsStore();

  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(),
  );

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}
