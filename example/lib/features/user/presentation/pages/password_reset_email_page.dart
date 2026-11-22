import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/routes/go_page.dart';
import '../../../../shared/widgets/feedback_boxes.dart';
import '../../../../shared/widgets/form_fields.dart';
import '../../controllers/user_controller.dart';

/// User Password Reset Email page using `GetView<UserController>`.
class PasswordResetEmailPage extends GetView<UserController> {
  const PasswordResetEmailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Title(
      title: '${'password_reset_email_app_bar_title'.tr} | Hosteday',
      color: theme.colorScheme.primary,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 900;
          final isTablet = constraints.maxWidth >= 600 && !isDesktop;
          final horizontalPadding = isDesktop ? 32.0 : (isTablet ? 20.0 : 16.0);

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1240),
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: 24,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    // Header Icon
                    Center(
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF60A5FA,
                          ).withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(
                              0xFF60A5FA,
                            ).withValues(alpha: 0.35),
                          ),
                        ),
                        child: const Icon(
                          Icons.lock_reset_rounded,
                          size: 38,
                          color: Color(0xFF60A5FA),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    Text(
                      'password_reset_email_header_title'.tr,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'password_reset_email_header_subtitle'.tr,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.75,
                        ),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Form or Sent Status
                    Obx(() {
                      final isSent = controller.passwordResetSent.value;

                      if (isSent) {
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              children: <Widget>[
                                const Icon(
                                  Icons.mark_email_read_rounded,
                                  size: 52,
                                  color: Color(0xFF10B981),
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  'password_reset_email_sent_title'.tr,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16.5,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'password_reset_email_sent_desc'.trParams({
                                    'email': controller
                                        .passwordResetEmailController
                                        .text,
                                  }),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.8),
                                    fontSize: 13,
                                    height: 1.45,
                                  ),
                                ),
                                const SizedBox(height: 22),
                                Wrap(
                                  spacing: 10,
                                  runSpacing: 10,
                                  alignment: WrapAlignment.center,
                                  children: <Widget>[
                                    FilledButton.tonal(
                                      onPressed: GoPage.back,
                                      child: Text('back'.tr),
                                    ),
                                    OutlinedButton.icon(
                                      onPressed: controller.isLoading.value
                                          ? null
                                          : () => controller
                                                .sendPasswordResetEmail(),
                                      icon: const Icon(
                                        Icons.refresh_rounded,
                                        size: 16,
                                      ),
                                      label: Text('resend_button'.tr),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(22),
                          child: Form(
                            key: controller.passwordResetFormKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: <Widget>[
                                EmailField(
                                  controller:
                                      controller.passwordResetEmailController,
                                  textInputAction: TextInputAction.done,
                                ),
                                const SizedBox(height: 18),

                                // Feedback Error Display
                                if (controller.errorMessage.value.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 14),
                                    child: ErrorBox(
                                      message: controller.errorMessage.value,
                                    ),
                                  ),

                                // Submit Button
                                FilledButton.icon(
                                  onPressed: controller.isLoading.value
                                      ? null
                                      : () =>
                                            controller.sendPasswordResetEmail(),
                                  icon: controller.isLoading.value
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
                                      : const Icon(
                                          Icons.send_rounded,
                                          size: 18,
                                        ),
                                  label: Text(
                                    'send_reset_email_button'.tr,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 20),

                    TextButton.icon(
                      onPressed: GoPage.back,
                      icon: const Icon(Icons.arrow_back_rounded, size: 16),
                      label: Text('back_to_profile'.tr),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
