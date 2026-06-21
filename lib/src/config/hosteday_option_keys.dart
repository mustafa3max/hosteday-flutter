/// Defines the official option keys accepted when initializing HosteDay.
abstract final class HosteDayOptionKeys {
  /// Example: enterprise.hosteday.com
  static const String projectDomain = 'project_domain';

  /// The project API token sent through the X-Api-Token header.
  ///
  /// The option value may be null. When null or empty, the header is not sent.
  static const String apiToken = 'X-Api-Token';

  /// The Pusher-compatible application key.
  ///
  /// This is the key after /app/ in the WebSocket URL.
  static const String pusherKey = 'pusher_key';

  /// Example: ws3.hosteday.com
  static const String realtimeHost = 'realtime_host';

  /// Supported values: ws or wss.
  static const String realtimeScheme = 'realtime_scheme';

  /// Example: 443
  static const String realtimePort = 'realtime_port';

  /// The endpoint used to authorize private and presence channels.
  static const String broadcastingAuthPath = 'broadcasting_auth_path';

  static const String publicEventsPath = 'public_events_path';
  static const String privateEventsPath = 'private_events_path';
  static const String presenceEventsPath = 'presence_events_path';
}
