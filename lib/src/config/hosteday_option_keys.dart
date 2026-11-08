/// Defines the official option keys accepted when initializing Hosteday.
///
/// These keys are only for values that the app developer is allowed to provide
/// during SDK initialization.
///
/// Authentication and user API paths are owned by Hosteday and are not
/// configurable from initialization options.
abstract final class HostedayOptionKeys {
  /// The Hosteday project domain.
  ///
  /// Example:
  /// `enterprise.hosteday.com`
  static const String projectDomain = 'project_domain';

  /// Optional custom API base URL.
  ///
  /// In most cases, users should only provide [projectDomain], and the SDK will
  /// build the API base URL automatically.
  ///
  /// Example:
  /// `https://enterprise.hosteday.com`
  static const String apiBaseUrl = 'api_base_url';

  /// Alias for [apiBaseUrl].
  static const String baseUrl = 'base_url';

  /// The project API token sent through the X-Api-Token header.
  ///
  /// The option value may be null. When null or empty, the header is not sent.
  static const String projectApiKey = 'project_api_key';

  /// Optional custom header name for the project API token.
  ///
  /// Default:
  /// `X-Api-Token`
  static const String apiTokenHeader = 'api_token_header';

  /// Legacy option key kept for backward compatibility.
  ///
  /// Older examples used the actual header name as the option key.
  static const String legacyApiToken = 'X-Api-Token';

  /// The Pusher-compatible application key.
  ///
  /// This is the key after `/app/` in the WebSocket URL.
  static const String realtimeAppKey = 'realtime_app_key';

  /// The realtime WebSocket host.
  ///
  /// Example:
  /// `ws3.hosteday.com`
  static const String realtimeHost = 'realtime_host';

  /// The realtime WebSocket scheme.
  ///
  /// Supported values:
  /// `ws`, `wss`
  static const String realtimeScheme = 'realtime_scheme';

  /// The realtime WebSocket port.
  ///
  /// Example:
  /// `443`
  static const String realtimePort = 'realtime_port';

  /// The endpoint used to authorize private and presence channels.
  ///
  /// Keep this configurable only if Hosteday may give different projects
  /// different broadcasting auth endpoints.
  static const String broadcastingAuthPath = 'broadcasting_auth_path';

  /// The endpoint used to publish public realtime events.
  static const String publicEventsPath = 'public_events_path';

  /// The endpoint used to publish private realtime events.
  static const String privateEventsPath = 'private_events_path';

  /// The endpoint used to publish presence realtime events.
  static const String presenceEventsPath = 'presence_events_path';

  /// Whether push notifications and device registration are enabled.
  ///
  /// Default: `true`.
  static const String notificationsEnabled = 'notifications_enabled';

  /// Custom endpoint path to send notifications.
  static const String sendNotificationPath = 'send_notification_path';

  /// Custom endpoint path to register device tokens.
  static const String registerDeviceTokenPath = 'register_device_token_path';

  /// Custom endpoint path to unregister device tokens.
  static const String unregisterDeviceTokenPath = 'unregister_device_token_path';

  /// Custom endpoint path to list registered devices.
  static const String registeredDevicesPath = 'registered_devices_path';

  /// The default push notification topic for the project/app.
  ///
  /// Example:
  /// `global_announcements`
  static const String defaultNotificationTopic = 'default_notification_topic';

  /// Firebase API key for native push notifications (Web/Mobile).
  static const String firebaseApiKey = 'firebase_api_key';
  static const String fcmApiKey = 'fcm_api_key';

  /// Firebase App ID for push notifications.
  static const String firebaseAppId = 'firebase_app_id';
  static const String fcmAppId = 'fcm_app_id';

  /// Firebase Messaging Sender ID.
  static const String firebaseMessagingSenderId = 'firebase_messaging_sender_id';
  static const String fcmSenderId = 'fcm_sender_id';

  /// Firebase Project ID.
  static const String firebaseProjectId = 'firebase_project_id';
  static const String fcmProjectId = 'fcm_project_id';

  /// Web Push Public Certificate (VAPID key) for Web browsers.
  static const String firebaseVapidKey = 'firebase_vapid_key';
  static const String fcmVapidKey = 'fcm_vapid_key';
  static const String webPushVapidKey = 'web_push_vapid_key';

  /// Firebase Auth Domain.
  static const String firebaseAuthDomain = 'firebase_auth_domain';

  /// Firebase Storage Bucket.
  static const String firebaseStorageBucket = 'firebase_storage_bucket';

  /// Firebase Measurement ID.
  static const String firebaseMeasurementId = 'firebase_measurement_id';

  /// Whether smart background jobs and scheduled tasks are enabled.
  static const String jobsEnabled = 'jobs_enabled';
  static const String backgroundJobsEnabled = 'background_jobs_enabled';

  /// The endpoint path for smart background jobs.
  static const String jobsPath = 'jobs_path';

  /// The text used to search and filter the requested resources.
  ///
  /// This value is added to the request URL as the `search` query parameter.
  ///
  /// Example:
  /// `?search=sewing`
  static const String search = 'search';

  /// The relation field used to filter the requested resources.
  ///
  /// This value is added to the request URL as the `relation_field`
  /// query parameter.
  ///
  /// Example:
  /// `?relation_field=category_id`
  static const String relationField = 'relation_field';

  /// The value of the relation field used for filtering.
  ///
  /// This value is added to the request URL as the `relation_value`
  /// query parameter and should be used together with [relationField].
  ///
  /// Example:
  /// `?relation_field=category_id&relation_value=5`
  static const String relationValue = 'relation_value';
}

/// Legacy spelling of the option key constants.
@Deprecated('Use HostedayOptionKeys instead.')
abstract final class HosteDayOptionKeys {
  static const String projectDomain = HostedayOptionKeys.projectDomain;
  static const String apiBaseUrl = HostedayOptionKeys.apiBaseUrl;
  static const String baseUrl = HostedayOptionKeys.baseUrl;
  static const String projectApiKey = HostedayOptionKeys.projectApiKey;
  static const String apiTokenHeader = HostedayOptionKeys.apiTokenHeader;
  static const String legacyApiToken = HostedayOptionKeys.legacyApiToken;
  static const String realtimeAppKey = HostedayOptionKeys.realtimeAppKey;
  static const String realtimeHost = HostedayOptionKeys.realtimeHost;
  static const String realtimeScheme = HostedayOptionKeys.realtimeScheme;
  static const String realtimePort = HostedayOptionKeys.realtimePort;
  static const String broadcastingAuthPath =
      HostedayOptionKeys.broadcastingAuthPath;
  static const String publicEventsPath = HostedayOptionKeys.publicEventsPath;
  static const String privateEventsPath = HostedayOptionKeys.privateEventsPath;
  static const String presenceEventsPath =
      HostedayOptionKeys.presenceEventsPath;
  static const String notificationsEnabled =
      HostedayOptionKeys.notificationsEnabled;
  static const String defaultNotificationTopic =
      HostedayOptionKeys.defaultNotificationTopic;
  static const String search = HostedayOptionKeys.search;
  static const String relationField = HostedayOptionKeys.relationField;
  static const String relationValue = HostedayOptionKeys.relationValue;
}
