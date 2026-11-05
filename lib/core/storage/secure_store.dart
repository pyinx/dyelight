import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Only owner of the API key (Keychain / Keystore).
class SecureStore {
  SecureStore([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  static const _keyName = 'api_key';
  final FlutterSecureStorage _storage;

  /// An unreadable key (e.g. Keystore reset after a device restore) counts as
  /// "no key" so the app starts and the user can simply enter it again.
  Future<String> readApiKey() async {
    try {
      return await _storage.read(key: _keyName) ?? '';
    } on PlatformException {
      return '';
    }
  }

  Future<void> writeApiKey(String key) => key.isEmpty
      ? _storage.delete(key: _keyName)
      : _storage.write(key: _keyName, value: key);
}
