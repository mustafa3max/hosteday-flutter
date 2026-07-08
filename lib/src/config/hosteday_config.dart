import 'hosteday_option_keys.dart';

/// Defines API URLs, project credentials, and realtime connection settings
/// used by HosteDay clients.
///
/// Authentication and user paths are fixed by HosteDay and cannot be overridden
/// from initialization options.
class HosteDayConfig {
  // ---------------------------------------------------------------------------
  // Default HosteDay API paths.
  //
  // These paths are owned by HosteDay.
  // They are intentionally not configurable from HosteDayOptionKeys.
  // ---------------------------------------------------------------------------

  static const String _signInPath = '/api/auth/login';
  static const String _signUpPath = '/api/auth/register';

  /// Sends a password reset email.
  ///
  /// The password reset itself is completed through the web link in the email.
  static const String _sendPasswordResetEmailPath = '/api/auth/forgot-password';

  /// Returns the currently authenticated user.
  static const String _currentUserPath = '/api/user';

  /// Updates the currently authenticated user.
  static const String _updateUserPath = '/api/user';

  /// Updates the currently authenticated user's avatar.
  static const String _updateUserAvatarPath = '/api/user/avatar';

  /// Deletes the currently authenticated user.
  static const String _deleteUserPath = '/api/user';

  /// Signs the current user out on the server.
  static const String _signOutPath = '/api/logout';

  /// Sends or resends the email verification notification.
  ///
  /// The email verification itself is completed through the web link
  /// in the email.
  static const String _sendEmailVerificationNotificationPath =
      '/api/email/verification-notification';

  static const String _publicEventsPath = '/api/realtime/events/public';
  static const String _privateEventsPath = '/api/realtime/events/private';
  static const String _presenceEventsPath = '/api/realtime/events/presence';
  static const String _broadcastingAuthPath = '/api/broadcasting/auth-manual';

  /// The project domain supplied during SDK initialization.
  ///
  /// Example:
  /// `my-project.hosteday.com`
  final String projectDomain;

  /// The base URL of the HosteDay API.
  ///
  /// Example:
  /// `https://my-project.hosteday.com`
  final String baseUrl;

  /// Optional project-level API token.
  ///
  /// This token is sent automatically with every HTTP request using
  /// [apiTokenHeader].
  final String? apiToken;

  /// The header name used for the project-level API token.
  ///
  /// Default:
  /// `X-Api-Token`
  final String apiTokenHeader;

  /// The application key used by the Pusher-compatible realtime service.
  final String pusherKey;

  /// The host name used for realtime WebSocket connections.
  final String realtimeHost;

  /// The WebSocket scheme used for realtime connections.
  ///
  /// Supported values:
  /// `ws`, `wss`
  final String realtimeScheme;

  /// The WebSocket port used for realtime connections.
  final int realtimePort;

  const HosteDayConfig({
    required this.baseUrl,
    this.projectDomain = '',
    this.apiToken,
    this.apiTokenHeader = 'X-Api-Token',
    this.pusherKey = '',
    this.realtimeHost = '',
    this.realtimeScheme = 'wss',
    this.realtimePort = 443,
  });

  /// Creates a typed configuration from Firebase-style initialization options.
  ///
  /// Only project, token, API base URL, and realtime settings can be provided.
  /// Auth and user paths are fixed by HosteDay.
  factory HosteDayConfig.fromOptions(Map<String, Object?> options) {
    final projectDomain = _requiredOption(
      options,
      HosteDayOptionKeys.projectDomain,
    );

    final baseUrl = _stringOption(
          options,
          const [
            HosteDayOptionKeys.apiBaseUrl,
            HosteDayOptionKeys.baseUrl,
          ],
        ) ??
        _baseUrlFromProjectDomain(projectDomain);

    final baseUri = Uri.tryParse(baseUrl);

    if (baseUri == null ||
        baseUri.scheme.isEmpty ||
        baseUri.host.isEmpty ||
        (baseUri.scheme != 'http' && baseUri.scheme != 'https')) {
      throw ArgumentError.value(
        baseUrl,
        HosteDayOptionKeys.apiBaseUrl,
        'A valid HTTP or HTTPS URL is required.',
      );
    }

    final realtimeScheme = (_stringOption(
              options,
              const [HosteDayOptionKeys.realtimeScheme],
            ) ??
            'wss')
        .toLowerCase();

    if (realtimeScheme != 'ws' && realtimeScheme != 'wss') {
      throw ArgumentError.value(
        realtimeScheme,
        HosteDayOptionKeys.realtimeScheme,
        'Only ws or wss are supported.',
      );
    }

    final realtimePort = _intOption(
          options,
          const [HosteDayOptionKeys.realtimePort],
        ) ??
        (realtimeScheme == 'wss' ? 443 : 80);

    if (realtimePort <= 0 || realtimePort > 65535) {
      throw ArgumentError.value(
        realtimePort,
        HosteDayOptionKeys.realtimePort,
        'A valid TCP port between 1 and 65535 is required.',
      );
    }

    return HosteDayConfig(
      projectDomain: projectDomain,
      baseUrl: baseUrl,
      apiToken: _stringOption(
        options,
        const [
          HosteDayOptionKeys.projectApiKey,
          HosteDayOptionKeys.legacyApiToken,
        ],
      ),
      apiTokenHeader: _stringOption(
            options,
            const [HosteDayOptionKeys.apiTokenHeader],
          ) ??
          'X-Api-Token',
      pusherKey: _stringOption(
            options,
            const [HosteDayOptionKeys.realtimeAppKey],
          ) ??
          '',
      realtimeHost: _stringOption(
            options,
            const [HosteDayOptionKeys.realtimeHost],
          ) ??
          baseUri.host,
      realtimeScheme: realtimeScheme,
      realtimePort: realtimePort,
    );
  }

  // ---------------------------------------------------------------------------
  // Fixed HosteDay auth paths.
  // ---------------------------------------------------------------------------

  /// Signs the user in.
  String get signInPath => _signInPath;

  /// Creates a new user account.
  ///
  /// If HosteDay sends an email verification message after registration,
  /// the verification itself is completed through the web link in the email.
  String get signUpPath => _signUpPath;

  /// Requests a password reset email.
  ///
  /// The password reset itself is completed through the web link in the email.
  String get sendPasswordResetEmailPath => _sendPasswordResetEmailPath;

  /// Signs the current user out on the server.
  String get signOutPath => _signOutPath;

  /// Sends or resends the email verification notification.
  ///
  /// The email verification itself is completed through the web link
  /// in the email.
  String get sendEmailVerificationNotificationPath {
    return _sendEmailVerificationNotificationPath;
  }

  // ---------------------------------------------------------------------------
  // Fixed HosteDay user paths.
  // ---------------------------------------------------------------------------

  /// Returns the currently authenticated user.
  String get currentUserPath => _currentUserPath;

  /// Updates the currently authenticated user.
  String get updateUserPath => _updateUserPath;

  /// Updates the currently authenticated user's avatar.
  String get updateUserAvatarPath => _updateUserAvatarPath;

  /// Deletes the currently authenticated user.
  String get deleteUserPath => _deleteUserPath;

  // ---------------------------------------------------------------------------
  // Fixed HosteDay realtime API paths.
  // ---------------------------------------------------------------------------

  /// Publishes public realtime events.
  String get publicEventsPath => _publicEventsPath;

  /// Publishes private realtime events.
  String get privateEventsPath => _privateEventsPath;

  /// Publishes presence realtime events.
  String get presenceEventsPath => _presenceEventsPath;

  /// Authorizes private and presence realtime channels.
  String get broadcastingAuthPath => _broadcastingAuthPath;

  /// The complete Pusher-compatible WebSocket application URL.
  ///
  /// Example:
  /// `wss://ws3.hosteday.com:443/app/YOUR_PUSHER_KEY`
  String get realtimeUrl {
    return '$realtimeScheme://$realtimeHost:$realtimePort/app/$pusherKey';
  }

  /// Headers sent automatically with all HosteDay HTTP requests.
  Map<String, String> get defaultHeaders {
    final token = apiToken?.trim();

    if (token == null || token.isEmpty) {
      return const <String, String>{};
    }

    return <String, String>{
      apiTokenHeader: token,
    };
  }

  /// Builds a complete URI by combining [baseUrl] with [path].
  Uri uri(String path) {
    final cleanBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;

    final cleanPath = path.startsWith('/') ? path : '/$path';

    return Uri.parse('$cleanBase$cleanPath');
  }

  // ---------------------------------------------------------------------------
  // Legacy getters.
  //
  // These getters keep old internal code working while you migrate the SDK
  // to the new names.
  // ---------------------------------------------------------------------------

  @Deprecated('Use signInPath instead.')
  String get loginPathPost => signInPath;

  @Deprecated('Use signUpPath instead.')
  String get registerPathPost => signUpPath;

  @Deprecated('Use sendPasswordResetEmailPath instead.')
  String get forgotPasswordPathPost => sendPasswordResetEmailPath;

  @Deprecated('Use currentUserPath instead.')
  String get userShowPathGet => currentUserPath;

  @Deprecated('Use updateUserPath instead.')
  String get userUpdatePathPut => updateUserPath;

  @Deprecated('Use updateUserAvatarPath instead.')
  String get userUpdateAvatarPathPost => updateUserAvatarPath;

  @Deprecated('Use deleteUserPath instead.')
  String get userDeletePathDelete => deleteUserPath;

  @Deprecated('Use signOutPath instead.')
  String get logoutPathPost => signOutPath;

  @Deprecated('Use sendEmailVerificationNotificationPath instead.')
  String get resendEmailVerificationPathPost {
    return sendEmailVerificationNotificationPath;
  }

  static String _requiredOption(
    Map<String, Object?> options,
    String key,
  ) {
    final value = _stringOption(options, <String>[key]);

    if (value == null) {
      throw ArgumentError.value(
        options,
        key,
        'The "$key" option is required.',
      );
    }

    return value;
  }

  static String? _stringOption(
    Map<String, Object?> options,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = options[key];

      if (value == null) {
        continue;
      }

      final text = value.toString().trim();

      if (text.isNotEmpty) {
        return text;
      }
    }

    return null;
  }

  static int? _intOption(
    Map<String, Object?> options,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = options[key];

      if (value == null) {
        continue;
      }

      if (value is int) {
        return value;
      }

      final parsed = int.tryParse(value.toString().trim());

      if (parsed != null) {
        return parsed;
      }
    }

    return null;
  }

  static String _baseUrlFromProjectDomain(String projectDomain) {
    final normalized = projectDomain
        .trim()
        .replaceFirst(RegExp(r'^https?://'), '')
        .replaceFirst(RegExp(r'/+$'), '');

    return 'https://$normalized';
  }
}
