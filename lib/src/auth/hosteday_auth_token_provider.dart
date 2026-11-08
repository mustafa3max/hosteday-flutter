import 'dart:convert';

import 'hosteday_auth_storage.dart';
import 'hosteday_token_provider.dart';

/// Retrieves the active user access token from Hosteday auth storage.
///
/// This provider is used internally by HTTP and realtime clients so that
/// requests automatically start using the newest authenticated user token.
class HostedayAuthTokenProvider implements HostedayTokenProvider {
  /// The storage that contains the persisted Hosteday session.
  final HostedayAuthStorage storage;

  /// Creates a token provider backed by [storage].
  const HostedayAuthTokenProvider({
    required this.storage,
  });

  @override
  Future<String?> getToken() async {
    final directToken = await storage.read(
      HostedayAuthStorageKeys.accessToken,
    );

    final normalizedDirectToken = directToken?.trim();

    if (normalizedDirectToken != null && normalizedDirectToken.isNotEmpty) {
      return normalizedDirectToken;
    }

    final serializedSession = await storage.read(
      HostedayAuthStorageKeys.session,
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
class HostedayCombinedTokenProvider implements HostedayTokenProvider {
  /// Token provider that reads the current Hosteday auth session.
  final HostedayTokenProvider primary;

  /// Optional fallback provider, useful for existing API-token workflows.
  final HostedayTokenProvider? fallback;

  /// Creates a combined provider.
  const HostedayCombinedTokenProvider({
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

/// Deprecated spelling of [HostedayAuthTokenProvider].
@Deprecated('Use HostedayAuthTokenProvider instead.')
typedef HosteDayAuthTokenProvider = HostedayAuthTokenProvider;

/// Deprecated spelling of [HostedayCombinedTokenProvider].
@Deprecated('Use HostedayCombinedTokenProvider instead.')
typedef HosteDayCombinedTokenProvider = HostedayCombinedTokenProvider;
