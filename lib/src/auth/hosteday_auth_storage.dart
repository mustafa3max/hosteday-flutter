/// Defines the storage contract used to persist a Hosteday auth session.
///
/// The SDK does not impose a specific storage package. Applications should
/// provide a secure implementation, such as one backed by flutter_secure_storage.
abstract interface class HostedayAuthStorage {
  /// Reads a value stored under [key].
  Future<String?> read(String key);

  /// Stores [value] under [key].
  Future<void> write(String key, String value);

  /// Deletes the value stored under [key].
  Future<void> delete(String key);
}

/// Internal storage keys used by Hosteday authentication.
abstract final class HostedayAuthStorageKeys {
  /// Stores the serialized `HostedaySession`.
  static const String session = 'hosteday.auth.session';

  /// Stores the current access token for fast token retrieval.
  static const String accessToken = 'hosteday.auth.access_token';
}

/// In-memory storage intended for tests, demos, and temporary sessions.
///
/// This storage is cleared when the application process restarts.
/// Use a secure persistent implementation in production applications.
class MemoryHostedayAuthStorage implements HostedayAuthStorage {
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

/// Deprecated spelling of [HostedayAuthStorage].
@Deprecated('Use HostedayAuthStorage instead.')
typedef HosteDayAuthStorage = HostedayAuthStorage;

/// Deprecated spelling of [HostedayAuthStorageKeys].
@Deprecated('Use HostedayAuthStorageKeys instead.')
typedef HosteDayAuthStorageKeys = HostedayAuthStorageKeys;

/// Deprecated spelling of [MemoryHostedayAuthStorage].
@Deprecated('Use MemoryHostedayAuthStorage instead.')
typedef MemoryHosteDayAuthStorage = MemoryHostedayAuthStorage;
