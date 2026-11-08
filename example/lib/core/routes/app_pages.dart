import 'package:get/get.dart';

import '../../features/auth/bindings/auth_binding.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/home/bindings/home_binding.dart';
import '../../features/home/controllers/home_controller.dart';
import '../../features/home/presentation/home_shell.dart';
import '../../features/live_bidding/live_bidding_binding.dart';
import '../../features/live_bidding/views/live_bidding_screen.dart';
import '../../features/user/bindings/user_binding.dart';
import '../../features/user/presentation/pages/password_reset_email_page.dart';
import '../../features/user/presentation/pages/verification_notification_page.dart';
import 'app_routes.dart';

/// Central page routes configuration for GetX navigation.
abstract final class AppPages {
  const AppPages._();

  static const String initial = AppRoutes.home;

  static final List<GetPage<dynamic>> pages = <GetPage<dynamic>>[
    // -------------------------------------------------------------------------
    // Shell & Feature Tab Routes (with browser URL reflection)
    // -------------------------------------------------------------------------
    GetPage<dynamic>(
      name: AppRoutes.home,
      page: () => const HomeShell(initialTab: HomeTab.example),
      binding: HomeBinding(),
    ),
    GetPage<dynamic>(
      name: AppRoutes.realtime,
      page: () => const HomeShell(initialTab: HomeTab.realtime),
      binding: HomeBinding(),
    ),
    GetPage<dynamic>(
      name: AppRoutes.notifications,
      page: () => const HomeShell(initialTab: HomeTab.notifications),
      binding: HomeBinding(),
    ),
    GetPage<dynamic>(
      name: AppRoutes.profile,
      page: () => const HomeShell(initialTab: HomeTab.profile),
      binding: HomeBinding(),
    ),

    // -------------------------------------------------------------------------
    // Auth Pages (login, register, forgot-password)
    // -------------------------------------------------------------------------
    GetPage<dynamic>(
      name: AppRoutes.login,
      page: () => const LoginPage(),
      binding: AuthBinding(),
    ),
    GetPage<dynamic>(
      name: AppRoutes.register,
      page: () => const RegisterPage(),
      binding: AuthBinding(),
    ),
    GetPage<dynamic>(
      name: AppRoutes.forgotPassword,
      page: () => const ForgotPasswordPage(),
      binding: AuthBinding(),
    ),

    // -------------------------------------------------------------------------
    // User Pages (password-reset-email, verification-notification)
    // -------------------------------------------------------------------------
    GetPage<dynamic>(
      name: AppRoutes.passwordResetEmail,
      page: () => const PasswordResetEmailPage(),
      binding: UserBinding(),
    ),
    GetPage<dynamic>(
      name: AppRoutes.verificationNotification,
      page: () => const VerificationNotificationPage(),
      binding: UserBinding(),
    ),

    // -------------------------------------------------------------------------
    // Live Bidding Radar Feature Route (Pluggable)
    // -------------------------------------------------------------------------
    GetPage<dynamic>(
      name: AppRoutes.liveBidding,
      page: () => const LiveBiddingScreen(),
      binding: LiveBiddingBinding(),
    ),
  ];
}
