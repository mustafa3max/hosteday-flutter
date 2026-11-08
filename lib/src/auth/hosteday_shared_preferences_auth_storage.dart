import 'package:shared_preferences/shared_preferences.dart';

import 'hosteday_auth_storage.dart';

/// Persistent Hosteday auth storage backed by shared_preferences.
///
/// This storage uses [SharedPreferencesAsync], which avoids the local cache used
/// by the legacy SharedPreferences API.
class HostedaySharedPreferencesAuthStorage implements HostedayAuthStorage {
  /// Optional key prefix used to avoid collisions with other app values.
  final String keyPrefix;

  final SharedPreferencesAsync _preferences;

  /// Creates a shared_preferences based Hosteday auth storage.
  ///
  /// By default, all keys are prefixed with `hosteday_flutter.`.
  HostedaySharedPreferencesAuthStorage({
    SharedPreferencesAsync? preferences,
    this.keyPrefix = 'hosteday_flutter.',
  }) : _preferences = preferences ?? SharedPreferencesAsync();

  @override
  Future<String?> read(String key) {
    return _preferences.getString(_key(key));
  }

  @override
  Future<void> write(String key, String value) {
    return _preferences.setString(_key(key), value);
  }

  @override
  Future<void> delete(String key) {
    return _preferences.remove(_key(key));
  }

  /// Deletes all Hosteday auth values managed by this storage.
  ///
  /// This does not clear unrelated app preferences.
  Future<void> clear() async {
    await delete(HostedayAuthStorageKeys.session);
    await delete(HostedayAuthStorageKeys.accessToken);
  }

  String _key(String key) {
    final cleanPrefix = keyPrefix.trim();

    if (cleanPrefix.isEmpty) {
      return key;
    }

    return '$cleanPrefix$key';
  }
}

/// Deprecated spelling of [HostedaySharedPreferencesAuthStorage].
@Deprecated('Use HostedaySharedPreferencesAuthStorage instead.')
typedef HosteDaySharedPreferencesAuthStorage
    = HostedaySharedPreferencesAuthStorage;
