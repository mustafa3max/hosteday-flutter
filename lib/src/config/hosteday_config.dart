import 'hosteday_option_keys.dart';

/// Defines the base URL, API paths, project credentials, and real-time
/// connection settings used by HosteDay clients.
class HosteDayConfig {
  /// The project domain supplied during SDK initialization.
  ///
  /// Example: `example.hosteday.com`
  final String projectDomain;

  /// The base URL of the HosteDay API.
  ///
  /// Example: `https://example.hosteday.com`
  final String baseUrl;

  /// Optional project-level API token.
  ///
  /// This token is sent automatically with every HTTP request using
  /// [apiTokenHeader].
  final String? apiToken;

  /// The header name used for the project API token.
  final String apiTokenHeader;

  /// The application key used by the Pusher-compatible real-time service.
  final String pusherKey;

  /// The host name used for real-time connections.
  final String realtimeHost;

  final String loginPathPost;
  final String registerPathPost;
  final String forgotPasswordPathPost;
  final String resetPasswordPathPost;
  final String userShowPathGet;
  final String userUpdatePathPut;
  final String userUpdateAvatarPathPost;
  final String userDeletePathDelete;
  final String logoutPathPost;
  final String emailVerifyPathPost;
  final String publicEventsPath;
  final String privateEventsPath;
  final String presenceEventsPath;
  final String broadcastingAuthPath;

  const HosteDayConfig({
    required this.baseUrl,
    this.projectDomain = '',
    this.apiToken,
    this.apiTokenHeader = 'X-Api-Token',
    this.pusherKey = '',
    this.realtimeHost = '',
    //
    this.loginPathPost = '/api/auth/login',
    this.registerPathPost = '/api/auth/register',
    this.forgotPasswordPathPost = '/api/auth/forgot-password',
    this.resetPasswordPathPost = '/api/auth/reset-password',
    //
    this.userShowPathGet = '/api/user',
    this.userUpdatePathPut = '/api/user',
    this.userUpdateAvatarPathPost = '/api/user/avatar',
    this.userDeletePathDelete = '/api/user',
    this.logoutPathPost = '/api/logout',
    this.emailVerifyPathPost = '/api/email/verify',
    //
    this.publicEventsPath = '/api/realtime/events/public',
    this.privateEventsPath = '/api/realtime/events/private',
    this.presenceEventsPath = '/api/realtime/events/presence',
    this.broadcastingAuthPath = '/api/broadcasting/auth-manual',
  });

  /// Creates a typed configuration from Firebase-style initialization options.
  factory HosteDayConfig.fromOptions(Map<String, Object?> options) {
    final projectDomain = _requiredOption(options, 'project_domain');

    final baseUrl = _stringOption(
          options,
          const ['api_base_url', 'base_url'],
        ) ??
        _baseUrlFromProjectDomain(projectDomain);

    final baseUri = Uri.tryParse(baseUrl);

    if (baseUri == null || baseUri.scheme.isEmpty || baseUri.host.isEmpty) {
      throw ArgumentError.value(
        baseUrl,
        'api_base_url',
        'A valid HTTP or HTTPS URL is required.',
      );
    }

    final realtimeScheme = (_stringOption(
              options,
              const ['realtime_scheme'],
            ) ??
            'wss')
        .toLowerCase();

    if (realtimeScheme != 'ws' && realtimeScheme != 'wss') {
      throw ArgumentError.value(
        realtimeScheme,
        'realtime_scheme',
        'Only ws or wss are supported.',
      );
    }

    return HosteDayConfig(
      projectDomain: projectDomain,
      baseUrl: baseUrl,
      apiToken: _stringOption(
        options,
        const [HosteDayOptionKeys.apiToken],
      ),
      apiTokenHeader: 'X-Api-Token',
      pusherKey: _stringOption(
            options,
            const [HosteDayOptionKeys.pusherKey],
          ) ??
          '',
      realtimeHost: _stringOption(
            options,
            const [HosteDayOptionKeys.realtimeHost],
          ) ??
          baseUri.host,
      loginPathPost: _stringOption(
            options,
            const ['login_path_post'],
          ) ??
          '/api/auth/login',
      registerPathPost: _stringOption(
            options,
            const ['register_path_post'],
          ) ??
          '/api/auth/register',
      forgotPasswordPathPost: _stringOption(
            options,
            const ['forgot_password_path_post'],
          ) ??
          '/api/auth/forgot-password',
      resetPasswordPathPost: _stringOption(
            options,
            const ['reset_password_path_post'],
          ) ??
          '/api/auth/reset-password',
      userShowPathGet: _stringOption(
            options,
            const ['user_show_path_get'],
          ) ??
          '/api/user',
      userUpdatePathPut: _stringOption(
            options,
            const ['user_update_path_put'],
          ) ??
          '/api/user',
      userUpdateAvatarPathPost: _stringOption(
            options,
            const ['user_update_avatar_path_post'],
          ) ??
          '/api/user/avatar',
      userDeletePathDelete: _stringOption(
            options,
            const ['user_delete_path_delete'],
          ) ??
          '/api/user',
      logoutPathPost: _stringOption(
            options,
            const ['logout_path_post'],
          ) ??
          '/api/logout',
      emailVerifyPathPost: _stringOption(
            options,
            const ['email_verify_path_post'],
          ) ??
          '/api/email/verify',
      publicEventsPath: _stringOption(
            options,
            const [HosteDayOptionKeys.publicEventsPath],
          ) ??
          '/api/realtime/events/public',
      privateEventsPath: _stringOption(
            options,
            const [HosteDayOptionKeys.privateEventsPath],
          ) ??
          '/api/realtime/events/private',
      presenceEventsPath: _stringOption(
            options,
            const [HosteDayOptionKeys.presenceEventsPath],
          ) ??
          '/api/realtime/events/presence',
      broadcastingAuthPath: _stringOption(
            options,
            const [HosteDayOptionKeys.broadcastingAuthPath],
          ) ??
          '/api/broadcasting/auth-manual',
    );
  }

  /// The complete Pusher-compatible WebSocket application URL.
  ///
  /// Example:
  /// wss://ws3.hosteday.com:443/app/YOUR_PUSHER_KEY
  String get realtimeUrl {
    return 'wss://$realtimeHost:443/app/$pusherKey';
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

  static String _baseUrlFromProjectDomain(String projectDomain) {
    final normalized = projectDomain
        .trim()
        .replaceFirst(RegExp(r'^https?://'), '')
        .replaceFirst(RegExp(r'/$'), '');

    return 'https://$normalized';
  }
}
