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
///
/// Page titles are dynamically managed via reactive `Title` widgets in pages
/// and `HomeShell` so they automatically reflect language changes (Arabic <-> English).
abstract final class AppPages {
  const AppPages._();

  static const String initial = AppRoutes.home;

  static final List<GetPage<dynamic>> pages = <GetPage<dynamic>>[
    // -------------------------------------------------------------------------
    // Shell & Feature Tab Routes (with browser URL reflection)
    // -------------------------------------------------------------------------
    GetPage<dynamic>(
      name: AppRoutes.home,
      page: () => const HomeShell(initialTab: HomeTab.guide),
      binding: HomeBinding(),
    ),
    GetPage<dynamic>(
      name: AppRoutes.realtime,
      page: () => const HomeShell(initialTab: HomeTab.realtime),
      binding: HomeBinding(),
    ),
    GetPage<dynamic>(
      name: AppRoutes.settings,
      page: () => const HomeShell(initialTab: HomeTab.settings),
      binding: HomeBinding(),
    ),
    GetPage<dynamic>(
      name: AppRoutes.notifications,
      page: () => const HomeShell(initialTab: HomeTab.settings),
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
      page: () => const HomeShell(child: LoginPage()),
      binding: AuthBinding(),
    ),
    GetPage<dynamic>(
      name: AppRoutes.register,
      page: () => const HomeShell(child: RegisterPage()),
      binding: AuthBinding(),
    ),
    GetPage<dynamic>(
      name: AppRoutes.forgotPassword,
      page: () => const HomeShell(child: ForgotPasswordPage()),
      binding: AuthBinding(),
    ),

    // -------------------------------------------------------------------------
    // User Pages (password-reset-email, verification-notification)
    // -------------------------------------------------------------------------
    GetPage<dynamic>(
      name: AppRoutes.passwordResetEmail,
      page: () => const HomeShell(child: PasswordResetEmailPage()),
      binding: UserBinding(),
    ),
    GetPage<dynamic>(
      name: AppRoutes.verificationNotification,
      page: () => const HomeShell(child: VerificationNotificationPage()),
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
