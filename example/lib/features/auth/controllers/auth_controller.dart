import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hosteday_flutter/hosteday_flutter.dart';

import '../../../core/controllers/base_hosteday_controller.dart';
import '../../../core/errors/error_presenter.dart';
import '../../../core/notifications/push_notification_service.dart';
import '../../../core/routes/go_page.dart';

/// GetX reactive controller for Hosteday authentication, sessions, and forms.
class AuthController extends BaseHostedayController {
  final Rx<HostedayUser?> currentUser = Rx<HostedayUser?>(null);

  StreamSubscription<HostedayUser?>? _authSubscription;

  bool get isAuthenticated => currentUser.value != null;

  // ---------------------------------------------------------------------------
  // Login Form State
  // ---------------------------------------------------------------------------
  final GlobalKey<FormState> loginFormKey = GlobalKey<FormState>();
  final TextEditingController loginEmailController = TextEditingController();
  final TextEditingController loginPasswordController = TextEditingController();
  final RxBool isLoginPasswordObscured = true.obs;

  void toggleLoginPasswordVisibility() {
    isLoginPasswordObscured.value = !isLoginPasswordObscured.value;
  }

  // ---------------------------------------------------------------------------
  // Register Form State
  // ---------------------------------------------------------------------------
  final GlobalKey<FormState> registerFormKey = GlobalKey<FormState>();
  final TextEditingController registerNameController = TextEditingController();
  final TextEditingController registerEmailController = TextEditingController();
  final TextEditingController registerPasswordController =
      TextEditingController();
  final TextEditingController registerConfirmPasswordController =
      TextEditingController();
  final RxBool isRegisterPasswordObscured = true.obs;
  final RxBool isRegisterConfirmObscured = true.obs;

  void toggleRegisterPasswordVisibility() {
    isRegisterPasswordObscured.value = !isRegisterPasswordObscured.value;
  }

  void toggleRegisterConfirmVisibility() {
    isRegisterConfirmObscured.value = !isRegisterConfirmObscured.value;
  }

  // ---------------------------------------------------------------------------
  // Forgot Password Form State
  // ---------------------------------------------------------------------------
  final GlobalKey<FormState> forgotPasswordFormKey = GlobalKey<FormState>();
  final TextEditingController forgotPasswordEmailController =
      TextEditingController();
  final RxBool forgotPasswordSent = false.obs;

  @override
  void onInit() {
    super.onInit();
    _bindAuthStream();
  }

  void _bindAuthStream() {
    if (Hosteday.isInitialized) {
      currentUser.value = Hosteday.auth.currentUser;
      _authSubscription = Hosteday.auth.authStateChanges().listen((user) {
        currentUser.value = user;
      });
    }
  }

  @override
  void onClose() {
    _authSubscription?.cancel();
    loginEmailController.dispose();
    loginPasswordController.dispose();
    registerNameController.dispose();
    registerEmailController.dispose();
    registerPasswordController.dispose();
    registerConfirmPasswordController.dispose();
    forgotPasswordEmailController.dispose();
    super.onClose();
  }

  @override
  void clearError() {
    errorMessage.value = '';
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  /// Submit login form.
  Future<bool> submitLogin() async {
    if (!(loginFormKey.currentState?.validate() ?? false)) {
      return false;
    }
    return signIn(
      email: loginEmailController.text.trim(),
      password: loginPasswordController.text,
    );
  }

  /// Sign in with email and password.
  Future<bool> signIn({required String email, required String password}) async {
    isLoading.value = true;
    clearError();

    try {
      final credential = await Hosteday.auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      currentUser.value = credential.user;

      // Sync device token immediately with accessToken before navigating home
      final accessToken = credential.session.accessToken;
      if (Get.isRegistered<PushNotificationService>()) {
        try {
          await PushNotificationService.to.syncDeviceToken(
            accessToken: accessToken,
          );
        } catch (e) {
          debugPrint('[AuthController] syncDeviceToken after login notice: $e');
        }
      }

      Get.snackbar(
        'login_success_title'.tr,
        'welcome_back_user'.trParams({
          'name': credential.user.displayName ?? credential.user.email ?? '',
        }),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF10B981).withValues(alpha: 0.9),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
      );

      loginPasswordController.clear();
      GoPage.offHome();
      return true;
    } catch (error) {
      errorMessage.value = ErrorPresenter.messageFrom(error);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Submit registration form.
  Future<bool> submitRegister() async {
    if (!(registerFormKey.currentState?.validate() ?? false)) {
      return false;
    }

    if (registerPasswordController.text !=
        registerConfirmPasswordController.text) {
      errorMessage.value = 'passwords_dont_match'.tr;
      return false;
    }

    return register(
      email: registerEmailController.text.trim(),
      password: registerPasswordController.text,
      name: registerNameController.text.trim(),
    );
  }

  /// Register a new user account.
  Future<bool> register({
    required String email,
    required String password,
    String? name,
  }) async {
    isLoading.value = true;
    clearError();

    try {
      final credential = await Hosteday.auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
        additionalData: name != null && name.trim().isNotEmpty
            ? <String, dynamic>{'name': name.trim()}
            : const <String, dynamic>{},
      );
      currentUser.value = credential.user;

      // Sync device token immediately with accessToken before navigating home
      final accessToken = credential.session.accessToken;
      if (Get.isRegistered<PushNotificationService>()) {
        try {
          await PushNotificationService.to.syncDeviceToken(
            accessToken: accessToken,
          );
        } catch (e) {
          debugPrint(
            '[AuthController] syncDeviceToken after register notice: $e',
          );
        }
      }

      Get.snackbar(
        'register_success_title'.tr,
        'register_success_desc'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF10B981).withValues(alpha: 0.9),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
      );

      registerPasswordController.clear();
      registerConfirmPasswordController.clear();
      GoPage.offHome();
      return true;
    } catch (error) {
      errorMessage.value = ErrorPresenter.messageFrom(error);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Submit forgot password form.
  Future<bool> submitForgotPassword() async {
    if (!(forgotPasswordFormKey.currentState?.validate() ?? false)) {
      return false;
    }
    return sendPasswordResetEmail(forgotPasswordEmailController.text.trim());
  }

  /// Send password reset email.
  Future<bool> sendPasswordResetEmail(String email) async {
    isLoading.value = true;
    clearError();

    try {
      await Hosteday.auth.sendPasswordResetEmail(email: email.trim());
      forgotPasswordSent.value = true;
      Get.snackbar(
        'reset_link_sent_title'.tr,
        'check_inbox_reset_desc'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF10B981).withValues(alpha: 0.9),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
      );
      return true;
    } catch (error) {
      errorMessage.value = ErrorPresenter.messageFrom(error);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Sign out current user.
  Future<void> signOut() async {
    try {
      if (Get.isRegistered<PushNotificationService>()) {
        try {
          await PushNotificationService.to.unregisterDeviceToken();
        } catch (e) {
          debugPrint('[AuthController] unregisterDeviceToken notice: $e');
        }
      }
      await Hosteday.auth.signOut();
      currentUser.value = null;

      Get.snackbar(
        'sign_out_success_title'.tr,
        'sign_out_success_desc'.tr,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
    } catch (error) {
      Get.snackbar(
        'error'.tr,
        ErrorPresenter.messageFrom(error),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.9),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
      );
    }
  }

  /// Reload user profile from server.
  Future<void> reloadUser() async {
    try {
      final user = await Hosteday.auth.reload();
      currentUser.value = user;
    } catch (_) {}
  }
}
