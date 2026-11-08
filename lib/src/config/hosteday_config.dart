import '../features/hosteday_features.dart';
import '../urls/hosteday_url_resolver.dart';
import 'hosteday_option_keys.dart';

/// Defines API URLs, project credentials, and realtime connection settings
/// used by Hosteday clients.
///
/// Authentication and user paths are fixed by Hosteday and cannot be overridden
/// from initialization options.
class HostedayConfig {
  // ---------------------------------------------------------------------------
  // Default Hosteday API paths.
  //
  // These paths are owned by Hosteday.
  // They are intentionally not configurable from HostedayOptionKeys.
  // ---------------------------------------------------------------------------

  static const String _signInPath = '/api/auth/login';
  static const String _signUpPath = '/api/auth/register';

  /// Sends a password reset email.
  ///
  /// The password reset itself is completed through the web link in the email.
  static const String _sendPasswordResetEmailPath = '/api/auth/forgot-password';

  /// Sends a password-reset email to the currently authenticated user.
  ///
  /// The server gets the email address from the authenticated user.
  static const String _sendCurrentUserPasswordResetEmailPath =
      '/api/user/password-reset-email';

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

  static const String _registerDeviceTokenPath =
      '/api/notifications/devices/register';
  static const String _unregisterDeviceTokenPath =
      '/api/notifications/devices/unregister';
  static const String _sendNotificationPath = '/api/notifications/send';
  static const String _registeredDevicesPath = '/api/notifications/devices';

  /// The project domain supplied during SDK initialization.
  ///
  /// Example:
  /// `my-project.hosteday.com`
  final String projectDomain;

  /// The base URL of the Hosteday API.
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

  /// Whether push notification features are enabled.
  final bool notificationsEnabled;

  /// The default push notification topic for the application.
  final String? defaultNotificationTopic;

  /// Firebase Web / Native API key for push notifications.
  final String? firebaseApiKey;

  /// Firebase App ID for push notifications.
  final String? firebaseAppId;

  /// Firebase Messaging Sender ID.
  final String? firebaseMessagingSenderId;

  /// Firebase Project ID.
  final String? firebaseProjectId;

  /// Web Push Public Certificate (VAPID key) for Web browsers.
  final String? firebaseVapidKey;

  /// Firebase Auth Domain.
  final String? firebaseAuthDomain;

  /// Firebase Storage Bucket.
  final String? firebaseStorageBucket;

  /// Firebase Measurement ID.
  final String? firebaseMeasurementId;

  /// Whether background jobs and task queues are enabled.
  final bool jobsEnabled;

  /// The endpoint path for smart background jobs.
  final String jobsPath;

  /// Registers a device token for push notifications.
  final String registerDeviceTokenPath;

  /// Unregisters a device token.
  final String unregisterDeviceTokenPath;

  /// Sends a push notification through the server gateway.
  final String sendNotificationPath;

  /// Fetches registered devices for the current user.
  final String registeredDevicesPath;

  /// Feature flags and plan entitlements.
  final HostedayFeatures features;

  const HostedayConfig({
    required this.baseUrl,
    this.projectDomain = '',
    this.apiToken,
    this.apiTokenHeader = 'X-Api-Token',
    this.pusherKey = '',
    this.realtimeHost = '',
    this.realtimeScheme = 'wss',
    this.realtimePort = 443,
    this.notificationsEnabled = true,
    this.defaultNotificationTopic,
    this.firebaseApiKey,
    this.firebaseAppId,
    this.firebaseMessagingSenderId,
    this.firebaseProjectId,
    this.firebaseVapidKey,
    this.firebaseAuthDomain,
    this.firebaseStorageBucket,
    this.firebaseMeasurementId,
    this.jobsEnabled = true,
    this.jobsPath = '/api/jobs',
    this.registerDeviceTokenPath = _registerDeviceTokenPath,
    this.unregisterDeviceTokenPath = _unregisterDeviceTokenPath,
    this.sendNotificationPath = _sendNotificationPath,
    this.registeredDevicesPath = _registeredDevicesPath,
    this.features = const HostedayFeatures(),
  });

  /// Creates a typed configuration from Firebase-style initialization options.
  ///
  /// Only project, token, API base URL, and realtime settings can be provided.
  /// Auth and user paths are fixed by Hosteday.
  factory HostedayConfig.fromOptions(Map<String, Object?> options) {
    final projectDomain = _requiredOption(
      options,
      HostedayOptionKeys.projectDomain,
    );

    final baseUrl = _stringOption(
          options,
          const [
            HostedayOptionKeys.apiBaseUrl,
            HostedayOptionKeys.baseUrl,
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
        HostedayOptionKeys.apiBaseUrl,
        'A valid HTTP or HTTPS URL is required.',
      );
    }

    HostedayUrlResolver(projectDomain: projectDomain, apiBaseUrl: baseUrl);

    final realtimeScheme = (_stringOption(
              options,
              const [HostedayOptionKeys.realtimeScheme],
            ) ??
            'wss')
        .toLowerCase();

    if (realtimeScheme != 'ws' && realtimeScheme != 'wss') {
      throw ArgumentError.value(
        realtimeScheme,
        HostedayOptionKeys.realtimeScheme,
        'Only ws or wss are supported.',
      );
    }

    final realtimePort = _intOption(
          options,
          const [HostedayOptionKeys.realtimePort],
        ) ??
        (realtimeScheme == 'wss' ? 443 : 80);

    if (realtimePort <= 0 || realtimePort > 65535) {
      throw ArgumentError.value(
        realtimePort,
        HostedayOptionKeys.realtimePort,
        'A valid TCP port between 1 and 65535 is required.',
      );
    }

    return HostedayConfig(
      projectDomain: projectDomain,
      baseUrl: baseUrl,
      apiToken: _stringOption(
        options,
        const [
          HostedayOptionKeys.projectApiKey,
          HostedayOptionKeys.legacyApiToken,
        ],
      ),
      apiTokenHeader: _stringOption(
            options,
            const [HostedayOptionKeys.apiTokenHeader],
          ) ??
          'X-Api-Token',
      pusherKey: _stringOption(
            options,
            const [HostedayOptionKeys.realtimeAppKey],
          ) ??
          '',
      realtimeHost: _stringOption(
            options,
            const [HostedayOptionKeys.realtimeHost],
          ) ??
          '',
      realtimeScheme: realtimeScheme,
      realtimePort: realtimePort,
      notificationsEnabled: _boolOption(
            options,
            const [HostedayOptionKeys.notificationsEnabled],
          ) ??
          true,
      defaultNotificationTopic: _stringOption(
        options,
        const [HostedayOptionKeys.defaultNotificationTopic],
      ),
      firebaseApiKey: _stringOption(
        options,
        const [
          HostedayOptionKeys.firebaseApiKey,
          HostedayOptionKeys.fcmApiKey,
        ],
      ),
      firebaseAppId: _stringOption(
        options,
        const [
          HostedayOptionKeys.firebaseAppId,
          HostedayOptionKeys.fcmAppId,
        ],
      ),
      firebaseMessagingSenderId: _stringOption(
        options,
        const [
          HostedayOptionKeys.firebaseMessagingSenderId,
          HostedayOptionKeys.fcmSenderId,
        ],
      ),
      firebaseProjectId: _stringOption(
        options,
        const [
          HostedayOptionKeys.firebaseProjectId,
          HostedayOptionKeys.fcmProjectId,
        ],
      ),
      firebaseVapidKey: _stringOption(
        options,
        const [
          HostedayOptionKeys.firebaseVapidKey,
          HostedayOptionKeys.fcmVapidKey,
          HostedayOptionKeys.webPushVapidKey,
        ],
      ),
      firebaseAuthDomain: _stringOption(
        options,
        const [HostedayOptionKeys.firebaseAuthDomain],
      ),
      firebaseStorageBucket: _stringOption(
        options,
        const [HostedayOptionKeys.firebaseStorageBucket],
      ),
      firebaseMeasurementId: _stringOption(
        options,
        const [HostedayOptionKeys.firebaseMeasurementId],
      ),
      jobsEnabled: _boolOption(
            options,
            const [
              HostedayOptionKeys.jobsEnabled,
              HostedayOptionKeys.backgroundJobsEnabled,
            ],
          ) ??
          true,
      jobsPath: _stringOption(
            options,
            const [HostedayOptionKeys.jobsPath],
          ) ??
          '/api/jobs',
      registerDeviceTokenPath: _stringOption(
            options,
            const [HostedayOptionKeys.registerDeviceTokenPath],
          ) ??
          _registerDeviceTokenPath,
      unregisterDeviceTokenPath: _stringOption(
            options,
            const [HostedayOptionKeys.unregisterDeviceTokenPath],
          ) ??
          _unregisterDeviceTokenPath,
      sendNotificationPath: _stringOption(
            options,
            const [HostedayOptionKeys.sendNotificationPath],
          ) ??
          _sendNotificationPath,
      registeredDevicesPath: _stringOption(
            options,
            const [HostedayOptionKeys.registeredDevicesPath],
          ) ??
          _registeredDevicesPath,
      features: options['features'] is Map<String, dynamic>
          ? HostedayFeatures.fromMap(
              options['features'] as Map<String, dynamic>)
          : (options['features'] is HostedayFeatures
              ? options['features'] as HostedayFeatures
              : const HostedayFeatures()),
    );
  }

  // ---------------------------------------------------------------------------
  // Fixed Hosteday auth paths.
  // ---------------------------------------------------------------------------

  /// Signs the user in.
  String get signInPath => _signInPath;

  /// Creates a new user account.
  ///
  /// If Hosteday sends an email verification message after registration,
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
  // Fixed Hosteday user paths.
  // ---------------------------------------------------------------------------

  /// Returns the currently authenticated user.
  String get currentUserPath => _currentUserPath;

  /// Updates the currently authenticated user.
  String get updateUserPath => _updateUserPath;

  /// Updates the currently authenticated user's avatar.
  String get updateUserAvatarPath => _updateUserAvatarPath;

  /// Deletes the currently authenticated user.
  String get deleteUserPath => _deleteUserPath;

  /// Sends a password-reset email to the currently authenticated user.
  ///
  /// This endpoint requires authentication and does not accept an email address.
  /// The server gets the email from the authenticated user.
  String get sendCurrentUserPasswordResetEmailPath =>
      _sendCurrentUserPasswordResetEmailPath;

  // ---------------------------------------------------------------------------
  // Fixed Hosteday realtime API paths.
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


  /// Headers sent automatically with all Hosteday HTTP requests.
  Map<String, String> get defaultHeaders {
    final token = apiToken?.trim();

    if (token == null || token.isEmpty) {
      return const <String, String>{};
    }

    return <String, String>{
      apiTokenHeader: token,
    };
  }

  /// Central URL policy shared by HTTP, static pages, and public media.
  HostedayUrlResolver get urls => HostedayUrlResolver(
        projectDomain:
            projectDomain.isEmpty ? Uri.parse(baseUrl).origin : projectDomain,
        apiBaseUrl: baseUrl,
      );

  /// Project origin, without `/api`.
  String get host => urls.host;

  /// Effective API prefix, including `/api` unless a custom path was supplied.
  String get apiBaseUrl => urls.apiBaseUrl;

  /// Whether both optional realtime settings are available.
  bool get hasRealtime =>
      pusherKey.trim().isNotEmpty && realtimeHost.trim().isNotEmpty;

  /// Builds a complete URI by combining [baseUrl] with [path].
  Uri uri(String path) {
    return urls.api(path);
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
        null,
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

  static bool? _boolOption(
    Map<String, Object?> options,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = options[key];

      if (value == null) {
        continue;
      }

      if (value is bool) {
        return value;
      }

      final text = value.toString().trim().toLowerCase();
      if (text == 'true' || text == '1') {
        return true;
      }
      if (text == 'false' || text == '0') {
        return false;
      }
    }

    return null;
  }

  static String _baseUrlFromProjectDomain(String projectDomain) {
    return HostedayUrlResolver.root(projectDomain).toString();
  }
}
