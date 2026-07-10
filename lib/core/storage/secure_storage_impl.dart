import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'key_value_store.dart';

class SecureStorageImpl implements KeyValueStore {
  final FlutterSecureStorage _storage;

  const SecureStorageImpl({
    FlutterSecureStorage storage = const FlutterSecureStorage(),
  }) : _storage = storage;

  @override
  Future<void> write({required String key, required String value}) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (e) {
      // Fail silently to prevent crashing, preserving child-friendly UX rules
    }
  }

  @override
  Future<String?> read({required String key}) async {
    try {
      return await _storage.read(key: key);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> delete({required String key}) async {
    try {
      await _storage.delete(key: key);
    } catch (e) {
      // Fail silently
    }
  }
}
