import 'dart:convert';

import 'hosteday_auth_storage.dart';
import 'hosteday_token_provider.dart';

/// Retrieves the active user access token from HosteDay auth storage.
///
/// This provider is used internally by HTTP and realtime clients so that
/// requests automatically start using the newest authenticated user token.
class HosteDayAuthTokenProvider implements HosteDayTokenProvider {
  /// The storage that contains the persisted HosteDay session.
  final HosteDayAuthStorage storage;

  /// Creates a token provider backed by [storage].
  const HosteDayAuthTokenProvider({
    required this.storage,
  });

  @override
  Future<String?> getToken() async {
    final directToken = await storage.read(
      HosteDayAuthStorageKeys.accessToken,
    );

    final normalizedDirectToken = directToken?.trim();

    if (normalizedDirectToken != null && normalizedDirectToken.isNotEmpty) {
      return normalizedDirectToken;
    }

    final serializedSession = await storage.read(
      HosteDayAuthStorageKeys.session,
    );

    if (serializedSession == null || serializedSession.trim().isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(serializedSession);

      if (decoded is! Map) {
        return null;
      }

      final session = Map<String, dynamic>.from(decoded);

      final token = session['access_token']?.toString().trim();

      return token == null || token.isEmpty ? null : token;
    } catch (_) {
      return null;
    }
  }
}

/// Uses the authenticated session token first, then falls back to another
/// externally supplied token provider when no signed-in user session exists.
class HosteDayCombinedTokenProvider implements HosteDayTokenProvider {
  /// Token provider that reads the current HosteDay auth session.
  final HosteDayTokenProvider primary;

  /// Optional fallback provider, useful for existing API-token workflows.
  final HosteDayTokenProvider? fallback;

  /// Creates a combined provider.
  const HosteDayCombinedTokenProvider({
    required this.primary,
    this.fallback,
  });

  @override
  Future<String?> getToken() async {
    final primaryToken = await primary.getToken();

    if (primaryToken != null && primaryToken.trim().isNotEmpty) {
      return primaryToken.trim();
    }

    final fallbackToken = await fallback?.getToken();

    if (fallbackToken == null || fallbackToken.trim().isEmpty) {
      return null;
    }

    return fallbackToken.trim();
  }
}
