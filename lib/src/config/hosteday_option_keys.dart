/// Defines the official option keys accepted when initializing HosteDay.
///
/// These keys are only for values that the app developer is allowed to provide
/// during SDK initialization.
///
/// Authentication and user API paths are owned by HosteDay and are not
/// configurable from initialization options.
abstract final class HosteDayOptionKeys {
  /// The HosteDay project domain.
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
  /// Keep this configurable only if HosteDay may give different projects
  /// different broadcasting auth endpoints.
  static const String broadcastingAuthPath = 'broadcasting_auth_path';

  /// The endpoint used to publish public realtime events.
  static const String publicEventsPath = 'public_events_path';

  /// The endpoint used to publish private realtime events.
  static const String privateEventsPath = 'private_events_path';

  /// The endpoint used to publish presence realtime events.
  static const String presenceEventsPath = 'presence_events_path';

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
