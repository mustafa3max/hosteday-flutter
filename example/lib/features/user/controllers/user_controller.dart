import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hosteday_flutter/hosteday_flutter.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/errors/error_presenter.dart';
import '../../../core/routes/go_page.dart';

/// GetX controller managing user profile, password reset emails, and email verification notifications.
class UserController extends GetxController {
  final Rx<HostedayUser?> user = Rx<HostedayUser?>(null);

  final RxBool isLoading = false.obs;
  final RxBool isUploadingAvatar = false.obs;
  final RxBool isDeletingAccount = false.obs;
  final RxBool isSendingVerification = false.obs;

  final RxString message = ''.obs;
  final RxString errorMessage = ''.obs;

  StreamSubscription<HostedayUser?>? _userSubscription;

  // ---------------------------------------------------------------------------
  // Profile Information State
  // ---------------------------------------------------------------------------
  final TextEditingController displayNameController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  bool get isBusy =>
      isLoading.value ||
      isUploadingAvatar.value ||
      isDeletingAccount.value ||
      isSendingVerification.value;

  // ---------------------------------------------------------------------------
  // Password Reset Email State
  // ---------------------------------------------------------------------------
  final GlobalKey<FormState> passwordResetFormKey = GlobalKey<FormState>();
  final TextEditingController passwordResetEmailController =
      TextEditingController();
  final RxBool passwordResetSent = false.obs;

  // ---------------------------------------------------------------------------
  // Verification Notification State
  // ---------------------------------------------------------------------------
  final RxBool verificationNotificationSent = false.obs;

  @override
  void onInit() {
    super.onInit();
    _bindUserSession();
  }

  void _bindUserSession() {
    if (Hosteday.isInitialized) {
      user.value = Hosteday.auth.currentUser;
      displayNameController.text = user.value?.displayName ?? '';
      passwordResetEmailController.text = user.value?.email ?? '';

      _userSubscription = Hosteday.auth.authStateChanges().listen((updatedUser) {
        user.value = updatedUser;
        if (updatedUser != null) {
          if (displayNameController.text.isEmpty &&
              updatedUser.displayName != null) {
            displayNameController.text = updatedUser.displayName!;
          }
          if (passwordResetEmailController.text.isEmpty &&
              updatedUser.email != null) {
            passwordResetEmailController.text = updatedUser.email!;
          }
        }
      });
    }
  }

  @override
  void onClose() {
    _userSubscription?.cancel();
    displayNameController.dispose();
    passwordResetEmailController.dispose();
    super.onClose();
  }

  void clearFeedback() {
    message.value = '';
    errorMessage.value = '';
  }

  // ---------------------------------------------------------------------------
  // Profile Actions
  // ---------------------------------------------------------------------------

  /// Reload user profile data from backend.
  Future<void> reloadUser() async {
    if (isBusy) return;

    isLoading.value = true;
    clearFeedback();

    try {
      final updated = await Hosteday.auth.reload();
      user.value = updated;
      displayNameController.text = updated.displayName ?? '';
      message.value = 'profile_reloaded'.tr;
    } catch (error) {
      errorMessage.value = ErrorPresenter.messageFrom(error);
    } finally {
      isLoading.value = false;
    }
  }

  /// Update user display name.
  Future<void> updateProfile() async {
    if (isBusy) return;

    final name = displayNameController.text.trim();
    if (name.isEmpty) {
      errorMessage.value = 'name_required'.tr;
      return;
    }

    isLoading.value = true;
    clearFeedback();

    try {
      await Hosteday.auth.updateProfile(name: name);
      final updated = await Hosteday.auth.reload();
      user.value = updated;
      message.value = 'profile_updated_success'.tr;

      Get.snackbar(
        'name_updated_title'.tr,
        'name_updated_desc'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF10B981).withValues(alpha: 0.9),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
      );
    } catch (error) {
      errorMessage.value = ErrorPresenter.messageFrom(error);
    } finally {
      isLoading.value = false;
    }
  }

  /// Pick and upload a new avatar image.
  Future<void> pickAndUploadAvatar({required ImageSource source}) async {
    if (isBusy) return;

    try {
      final image = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1600,
        maxHeight: 1600,
      );

      if (image == null) return;

      isUploadingAvatar.value = true;
      clearFeedback();

      final bytes = await image.readAsBytes();
      if (bytes.isEmpty) {
        throw StateError('empty_image_error'.tr);
      }

      final extension = _extractImageExtension(image.name);
      await Hosteday.auth.updateAvatar(bytes: bytes, extension: extension);

      final updated = await Hosteday.auth.reload();
      user.value = updated;
      message.value = 'avatar_uploaded_success'.tr;

      Get.snackbar(
        'avatar_updated_title'.tr,
        'avatar_updated_desc'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF10B981).withValues(alpha: 0.9),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
      );
    } catch (error) {
      errorMessage.value = ErrorPresenter.messageFrom(error);
    } finally {
      isUploadingAvatar.value = false;
    }
  }

  String _extractImageExtension(String fileName) {
    final normalized = fileName.trim().toLowerCase();
    final dotIndex = normalized.lastIndexOf('.');
    if (dotIndex == -1 || dotIndex == normalized.length - 1) {
      throw FormatException('invalid_image_ext'.tr);
    }
    final extension = normalized.substring(dotIndex + 1);
    const supported = <String>{'jpg', 'jpeg', 'png', 'webp'};
    if (!supported.contains(extension)) {
      throw FormatException(
        'unsupported_image_ext'.trParams({'ext': extension}),
      );
    }
    return extension;
  }

  /// Delete current account permanently.
  Future<bool> deleteAccount() async {
    if (isBusy) return false;

    isDeletingAccount.value = true;
    clearFeedback();

    try {
      await Hosteday.auth.deleteUser();
      user.value = null;
      GoPage.offHome();
      Get.snackbar(
        'account_deleted_title'.tr,
        'account_deleted_desc'.tr,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
      return true;
    } catch (error) {
      errorMessage.value = ErrorPresenter.messageFrom(error);
      return false;
    } finally {
      isDeletingAccount.value = false;
    }
  }

  // ---------------------------------------------------------------------------
  // Password Reset Email Actions
  // ---------------------------------------------------------------------------

  /// Send password reset link to specified or current email.
  Future<bool> sendPasswordResetEmail({String? targetEmail}) async {
    final email = (targetEmail ?? passwordResetEmailController.text).trim();
    if (email.isEmpty) {
      errorMessage.value = 'email_required'.tr;
      return false;
    }

    isLoading.value = true;
    clearFeedback();

    try {
      await Hosteday.auth.sendPasswordResetEmail(email: email);
      passwordResetSent.value = true;
      message.value = 'reset_email_sent_to'.trParams({'email': email});

      Get.snackbar(
        'reset_link_sent_title'.tr,
        'check_inbox_reset_email'.trParams({'email': email}),
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

  // ---------------------------------------------------------------------------
  // Verification Notification Actions
  // ---------------------------------------------------------------------------

  /// Send email verification notification to current user.
  Future<bool> sendVerificationNotification() async {
    if (isBusy) return false;

    isSendingVerification.value = true;
    clearFeedback();

    try {
      await Hosteday.auth.sendEmailVerification();
      verificationNotificationSent.value = true;
      message.value = 'verification_sent_desc'.tr;

      Get.snackbar(
        'verification_sent_title'.tr,
        'verification_sent_desc'.tr,
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
      isSendingVerification.value = false;
    }
  }

  /// Check whether the email has been verified after clicking link.
  Future<void> checkVerificationStatus() async {
    await reloadUser();
    if (user.value?.isEmailVerified == true) {
      Get.snackbar(
        'verification_congrats_title'.tr,
        'verification_congrats_desc'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF10B981).withValues(alpha: 0.9),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
      );
    } else {
      Get.snackbar(
        'verification_pending_title'.tr,
        'verification_pending_desc'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.amber.shade800,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
      );
    }
  }
}

