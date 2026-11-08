/// Defines named routes for the Hosteday Starter Boilerplate.
///
/// Use these routes with GetX navigation:
/// `Get.toNamed(AppRoutes.login);`
abstract final class AppRoutes {
  const AppRoutes._();

  static const String home = '/';

  // ---------------------------------------------------------------------------
  // Auth Feature Routes (login, register, forgot-password)
  // ---------------------------------------------------------------------------
  static const String login = '/login';
  static const String signIn = '/login'; // Backward-compatible alias
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';

  // ---------------------------------------------------------------------------
  // User Feature Routes (profile, password-reset-email, verification-notification)
  // ---------------------------------------------------------------------------
  static const String profile = '/user/profile';
  static const String userProfile = '/user/profile'; // Alias
  static const String passwordResetEmail = '/user/password-reset-email';
  static const String verificationNotification = '/user/verification-notification';
  static const String emailVerification = '/user/verification-notification'; // Backward-compatible alias

  // ---------------------------------------------------------------------------
  // Additional Features
  // ---------------------------------------------------------------------------
  static const String notifications = '/notifications';
  static const String realtime = '/realtime';
  static const String liveBidding = '/live-bidding';
}
