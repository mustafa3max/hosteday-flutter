/// Defines a contract for providing an authentication token to HosteDay clients.
///
/// Implement this interface when tokens are retrieved dynamically, such as from
/// secure storage, an authentication service, or a refreshed user session.
abstract class HosteDayTokenProvider {
  /// Retrieves the current authentication token.
  ///
  /// Returns `null` when no token is available.
  Future<String?> getToken();
}

/// A token provider that always returns a predefined token value.
///
/// This implementation is useful when the token is already available at the
/// time the client is created.
class StaticHosteDayTokenProvider implements HosteDayTokenProvider {
  /// The token returned by [getToken].
  final String? token;

  /// Creates a token provider that returns the specified [token].
  const StaticHosteDayTokenProvider(this.token);

  /// Returns the predefined [token].
  @override
  Future<String?> getToken() async => token;
}
