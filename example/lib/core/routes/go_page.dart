import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../features/auth/bindings/auth_binding.dart';
import '../../features/live_bidding/live_bidding_binding.dart';
import '../../features/live_bidding/views/live_bidding_screen.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/home/bindings/home_binding.dart';
import '../../features/home/controllers/home_controller.dart';
import '../../features/home/presentation/home_shell.dart';
import '../../features/user/bindings/user_binding.dart';
import '../../features/user/presentation/pages/password_reset_email_page.dart';
import '../../features/user/presentation/pages/verification_notification_page.dart';
import 'app_routes.dart';

/// Centralized, type-safe navigation manager with smooth transitions and automatic fallback.
///
/// Designed to streamline navigation across the app:
/// - Uses named routing (`toNamed`, `offNamed`, `offAllNamed`) so URLs appear in the browser address bar.
/// - Falls back safely to direct widget transitions if named routing fails in non-shell contexts.
abstract final class GoPage {
  const GoPage._();

  static const Transition defaultTransition = Transition.rightToLeftWithFade;
  static const Duration defaultDuration = Duration(milliseconds: 260);

  // ---------------------------------------------------------------------------
  // Core Navigation Engine (using named routes for browser URL reflection)
  // ---------------------------------------------------------------------------
  static Future<T?> _navigate<T>({
    required String routeName,
    required Widget Function() pageBuilder,
    Bindings? binding,
    dynamic arguments,
    bool offAll = false,
    bool off = false,
    Transition transition = defaultTransition,
    Duration duration = defaultDuration,
  }) async {
    try {
      if (offAll) {
        return await Get.offAllNamed<T>(routeName, arguments: arguments);
      }
      if (off) {
        return await Get.offNamed<T>(routeName, arguments: arguments);
      }
      return await Get.toNamed<T>(routeName, arguments: arguments);
    } catch (_) {
      // Direct fallback to pageBuilder
      if (offAll) {
        return Get.offAll<T>(
          pageBuilder,
          binding: binding,
          arguments: arguments,
          transition: transition,
          duration: duration,
        );
      }
      if (off) {
        return Get.off<T>(
          pageBuilder,
          binding: binding,
          arguments: arguments,
          transition: transition,
          duration: duration,
        );
      }
      return Get.to<T>(
        pageBuilder,
        binding: binding,
        arguments: arguments,
        transition: transition,
        duration: duration,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Generic Navigation Utilities
  // ---------------------------------------------------------------------------

  /// Navigate back to previous page.
  static void back<T>([T? result]) {
    if (Get.isDialogOpen == true || Get.isBottomSheetOpen == true) {
      Get.back<T>(result: result);
      return;
    }

    if (Get.key.currentState?.canPop() == true) {
      Get.back<T>(result: result);
    } else if (Get.context != null) {
      Navigator.of(Get.context!).maybePop<T>(result);
    }
  }

  /// Reset the navigation stack and navigate directly to Home.
  static Future<dynamic> offHome() => home(offAll: true);

  // ---------------------------------------------------------------------------
  // Home Shell Route
  // ---------------------------------------------------------------------------
  static Future<dynamic> home({bool offAll = false}) {
    return _navigate<dynamic>(
      routeName: AppRoutes.home,
      pageBuilder: () => const HomeShell(initialTab: HomeTab.guide),
      binding: HomeBinding(),
      offAll: offAll,
      transition: Transition.fadeIn,
    );
  }

  // ---------------------------------------------------------------------------
  // Auth Feature Routes (login, register, forgot-password)
  // ---------------------------------------------------------------------------

  /// Navigate to Login / Sign In.
  static Future<dynamic> login({bool off = false, bool offAll = false}) {
    return _navigate<dynamic>(
      routeName: AppRoutes.login,
      pageBuilder: () => const HomeShell(child: LoginPage()),
      binding: AuthBinding(),
      off: off,
      offAll: offAll,
    );
  }

  /// Alias for [login].
  static Future<dynamic> signIn({bool off = false, bool offAll = false}) =>
      login(off: off, offAll: offAll);

  /// Navigate to Register account.
  static Future<dynamic> register({bool off = false}) {
    return _navigate<dynamic>(
      routeName: AppRoutes.register,
      pageBuilder: () => const HomeShell(child: RegisterPage()),
      binding: AuthBinding(),
      off: off,
    );
  }

  /// Navigate to Forgot Password.
  static Future<dynamic> forgotPassword() {
    return _navigate<dynamic>(
      routeName: AppRoutes.forgotPassword,
      pageBuilder: () => const HomeShell(child: ForgotPasswordPage()),
      binding: AuthBinding(),
    );
  }

  // ---------------------------------------------------------------------------
  // User Feature Routes (profile, password-reset-email, verification-notification)
  // ---------------------------------------------------------------------------

  /// Navigate to User Profile.
  static Future<dynamic> profile({bool showAppBar = false, bool off = false}) {
    return _navigate<dynamic>(
      routeName: AppRoutes.profile,
      pageBuilder: () => const HomeShell(initialTab: HomeTab.profile),
      binding: HomeBinding(),
      off: off,
    );
  }

  /// Navigate to Password Reset Email instructions page.
  static Future<dynamic> passwordResetEmail() {
    return _navigate<dynamic>(
      routeName: AppRoutes.passwordResetEmail,
      pageBuilder: () => const HomeShell(child: PasswordResetEmailPage()),
      binding: UserBinding(),
    );
  }

  /// Navigate to Verification Notification & status page.
  static Future<dynamic> verificationNotification() {
    return _navigate<dynamic>(
      routeName: AppRoutes.verificationNotification,
      pageBuilder: () => const HomeShell(child: VerificationNotificationPage()),
      binding: UserBinding(),
    );
  }

  /// Alias for [verificationNotification].
  static Future<dynamic> emailVerification() => verificationNotification();

  // ---------------------------------------------------------------------------
  // Additional Features
  // ---------------------------------------------------------------------------

  /// Navigate to Realtime WebSockets page.
  static Future<dynamic> realtime({bool off = false}) {
    return _navigate<dynamic>(
      routeName: AppRoutes.realtime,
      pageBuilder: () => const HomeShell(initialTab: HomeTab.realtime),
      binding: HomeBinding(),
      off: off,
    );
  }

  /// Navigate to General Settings page.
  static Future<dynamic> settings({bool off = false}) {
    return _navigate<dynamic>(
      routeName: AppRoutes.settings,
      pageBuilder: () => const HomeShell(initialTab: HomeTab.settings),
      binding: HomeBinding(),
      off: off,
    );
  }

  /// Backward-compatible alias for [settings].
  static Future<dynamic> notifications({bool off = false}) =>
      settings(off: off);

  /// Navigate to Live Bidding Radar (Pluggable Feature).
  static Future<dynamic> liveBidding() {
    return _navigate<dynamic>(
      routeName: AppRoutes.liveBidding,
      pageBuilder: () => const LiveBiddingScreen(),
      binding: LiveBiddingBinding(),
    );
  }
}
