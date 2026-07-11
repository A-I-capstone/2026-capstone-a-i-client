abstract class KeyValueStore {
  /// Writes a value to the storage for the given key.
  Future<void> write({required String key, required String value});

  /// Reads a value from the storage for the given key.
  /// Returns null if the key does not exist.
  Future<String?> read({required String key});

  /// Deletes the value associated with the given key.
  Future<void> delete({required String key});
}
