class HosteDayConfig {
  final String baseUrl;

  final String pusherKey;
  final String realtimeHost;
  final int realtimePort;

  // Auth
  final String loginPathPost;
  final String registerPathPost;
  final String forgotPasswordPathPost;
  final String resetPasswordPathPost;
  // User
  final String userShowPathGet;
  final String userUpdatePathPut;
  final String userUpdateAvatarPathPost;
  final String userDeletePathDelete;
  final String logoutPathPost;
  final String emailVerifyPathPost;
  //
  final String publicEventsPath;
  final String privateEventsPath;
  final String broadcastingAuthPath;

  const HosteDayConfig({
    required this.baseUrl,
    this.pusherKey = '',
    this.realtimeHost = '',
    this.realtimePort = 443,
    // User
    this.loginPathPost = '/api/auth/login',
    this.registerPathPost = '/api/auth/register',
    this.forgotPasswordPathPost = '/api/auth/forgot-password',
    this.resetPasswordPathPost = '/api/auth/reset-password',
    // User
    this.userShowPathGet = '/api/user',
    this.userUpdatePathPut = '/api/user',
    this.userUpdateAvatarPathPost = '/api/user/avatar',
    this.userDeletePathDelete = '/api/user',
    this.logoutPathPost = '/api/logout',
    this.emailVerifyPathPost = '/api/email/verify',
    //
    this.publicEventsPath = '/api/realtime/events',
    this.privateEventsPath = '/api/realtime/private-events',
    this.broadcastingAuthPath = '/api/broadcasting/auth-manual',
  });

  Uri uri(String path) {
    final cleanBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;

    final cleanPath = path.startsWith('/') ? path : '/$path';

    return Uri.parse('$cleanBase$cleanPath');
  }
}
