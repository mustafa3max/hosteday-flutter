/// Defines the base URL, API paths, and real-time connection settings used by
/// HosteDay clients.
///
/// Create one configuration instance and pass it to [HosteDayClient],
/// [HosteDayHttpClient], or [HosteDayRealtimeClient] to keep endpoint and
/// connection settings consistent across the package.
class HosteDayConfig {
  /// The base URL of the HosteDay API.
  ///
  /// Example: `https://api.example.com`
  final String baseUrl;

  /// The application key used by the Pusher-compatible real-time service.
  final String pusherKey;

  /// The host name used for real-time connections.
  final String realtimeHost;

  /// The port used for real-time connections.
  final int realtimePort;

  /// The endpoint path used to submit login requests.
  final String loginPathPost;

  /// The endpoint path used to submit user registration requests.
  final String registerPathPost;

  /// The endpoint path used to request a password reset link or code.
  final String forgotPasswordPathPost;

  /// The endpoint path used to submit a new password after reset verification.
  final String resetPasswordPathPost;

  /// The endpoint path used to retrieve the authenticated user's profile.
  final String userShowPathGet;

  /// The endpoint path used to update the authenticated user's profile.
  final String userUpdatePathPut;

  /// The endpoint path used to upload or update the authenticated user's avatar.
  final String userUpdateAvatarPathPost;

  /// The endpoint path used to delete the authenticated user's account.
  final String userDeletePathDelete;

  /// The endpoint path used to end the current authenticated session.
  final String logoutPathPost;

  /// The endpoint path used to verify the authenticated user's email address.
  final String emailVerifyPathPost;

  /// The endpoint path used to publish events to public real-time channels.
  final String publicEventsPath;

  /// The endpoint path used to publish events to private real-time channels.
  final String privateEventsPath;

  /// The endpoint path used to authorize private real-time channel subscriptions.
  final String broadcastingAuthPath;

  /// Creates a configuration instance for HosteDay API and real-time services.
  ///
  /// The [baseUrl] is required and is used as the base for all API paths.
  /// Remaining values provide default endpoint paths and optional real-time
  /// connection settings that can be overridden when needed.
  const HosteDayConfig({
    required this.baseUrl,
    this.pusherKey = '',
    this.realtimeHost = '',
    this.realtimePort = 443,
    this.loginPathPost = '/api/auth/login',
    this.registerPathPost = '/api/auth/register',
    this.forgotPasswordPathPost = '/api/auth/forgot-password',
    this.resetPasswordPathPost = '/api/auth/reset-password',
    this.userShowPathGet = '/api/user',
    this.userUpdatePathPut = '/api/user',
    this.userUpdateAvatarPathPost = '/api/user/avatar',
    this.userDeletePathDelete = '/api/user',
    this.logoutPathPost = '/api/logout',
    this.emailVerifyPathPost = '/api/email/verify',
    this.publicEventsPath = '/api/realtime/events',
    this.privateEventsPath = '/api/realtime/private-events',
    this.broadcastingAuthPath = '/api/broadcasting/auth-manual',
  });

  /// Builds a complete URI by combining [baseUrl] with the provided [path].
  ///
  /// Leading and trailing slashes are normalized to ensure the resulting URI
  /// contains exactly one slash between the base URL and endpoint path.
  Uri uri(String path) {
    final cleanBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;

    final cleanPath = path.startsWith('/') ? path : '/$path';

    return Uri.parse('$cleanBase$cleanPath');
  }
}