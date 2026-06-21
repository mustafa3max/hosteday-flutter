/// Defines the storage contract used to persist a HosteDay auth session.
///
/// The SDK does not impose a specific storage package. Applications should
/// provide a secure implementation, such as one backed by flutter_secure_storage.
abstract interface class HosteDayAuthStorage {
  /// Reads a value stored under [key].
  Future<String?> read(String key);

  /// Stores [value] under [key].
  Future<void> write(String key, String value);

  /// Deletes the value stored under [key].
  Future<void> delete(String key);
}

/// Internal storage keys used by HosteDay authentication.
abstract final class HosteDayAuthStorageKeys {
  /// Stores the serialized [HosteDaySession].
  static const String session = 'hosteday.auth.session';

  /// Stores the current access token for fast token retrieval.
  static const String accessToken = 'hosteday.auth.access_token';
}

/// In-memory storage intended for tests, demos, and temporary sessions.
///
/// This storage is cleared when the application process restarts.
/// Use a secure persistent implementation in production applications.
class MemoryHosteDayAuthStorage implements HosteDayAuthStorage {
  final Map<String, String> _values = <String, String>{};

  @override
  Future<String?> read(String key) async {
    return _values[key];
  }

  @override
  Future<void> write(String key, String value) async {
    _values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    _values.remove(key);
  }
}
