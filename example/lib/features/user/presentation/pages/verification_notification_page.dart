import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/routes/go_page.dart';
import '../../../../shared/widgets/feedback_boxes.dart';
import '../../controllers/user_controller.dart';

/// User Email Verification Notification page using `GetView<UserController>`.
class VerificationNotificationPage extends GetView<UserController> {
  const VerificationNotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('verification_notification_app_bar_title'.tr),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Obx(() {
              final activeUser = controller.user.value;
              final email = activeUser?.email ?? 'user@example.com';
              final isVerified = activeUser?.isEmailVerified ?? false;
              final loading = controller.isLoading.value ||
                  controller.isSendingVerification.value;

              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  // Header Icon
                  Center(
                    child: Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        color: (isVerified
                                ? const Color(0xFF10B981)
                                : Colors.amber)
                            .withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: (isVerified
                                  ? const Color(0xFF10B981)
                                  : Colors.amber)
                              .withValues(alpha: 0.35),
                        ),
                      ),
                      child: Icon(
                        isVerified
                            ? Icons.verified_user_rounded
                            : Icons.mark_email_unread_rounded,
                        size: 40,
                        color: isVerified
                            ? const Color(0xFF10B981)
                            : Colors.amber,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Text(
                    isVerified
                        ? 'verification_verified_title'.tr
                        : 'verification_unverified_title'.tr,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isVerified
                        ? 'verification_verified_desc'.tr
                        : 'verification_unverified_desc'.trParams({'email': email}),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.75),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Status & Action Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          // Verification Status Indicator
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: (isVerified
                                      ? const Color(0xFF10B981)
                                      : Colors.amber)
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: (isVerified
                                        ? const Color(0xFF10B981)
                                        : Colors.amber)
                                    .withValues(alpha: 0.4),
                              ),
                            ),
                            child: Row(
                              children: <Widget>[
                                Icon(
                                  isVerified
                                      ? Icons.check_circle_rounded
                                      : Icons.warning_amber_rounded,
                                  size: 20,
                                  color: isVerified
                                      ? const Color(0xFF10B981)
                                      : Colors.amber,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    isVerified
                                        ? 'status_verified_long'.tr
                                        : 'status_unverified_long'.tr,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: isVerified
                                          ? const Color(0xFF10B981)
                                          : Colors.amber.shade800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),

                          // Feedback messages
                          if (controller.message.value.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: SuccessBox(
                                message: controller.message.value,
                              ),
                            ),
                          if (controller.errorMessage.value.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: ErrorBox(
                                message: controller.errorMessage.value,
                              ),
                            ),

                          // Action Buttons
                          if (!isVerified) ...<Widget>[
                            FilledButton.icon(
                              onPressed: loading
                                  ? null
                                  : controller.sendVerificationNotification,
                              icon: loading
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                          Colors.white,
                                        ),
                                      ),
                                    )
                                  : const Icon(Icons.send_rounded, size: 18),
                              label: Text(
                                'send_verification_email_button'.tr,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            OutlinedButton.icon(
                              onPressed: loading
                                  ? null
                                  : controller.checkVerificationStatus,
                              icon: const Icon(
                                Icons.refresh_rounded,
                                size: 18,
                              ),
                              label: Text('check_status_now'.tr),
                            ),
                          ] else ...<Widget>[
                            FilledButton.tonalIcon(
                              onPressed: GoPage.back,
                              icon: const Icon(
                                Icons.arrow_back_rounded,
                                size: 18,
                              ),
                              label: Text('back_to_profile'.tr),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  if (!isVerified)
                    TextButton.icon(
                      onPressed: GoPage.back,
                      icon: const Icon(Icons.arrow_back_rounded, size: 16),
                      label: Text('back'.tr),
                    ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }
}
