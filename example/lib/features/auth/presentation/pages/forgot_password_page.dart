import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/routes/go_page.dart';
import '../../../../shared/widgets/feedback_boxes.dart';
import '../../../../shared/widgets/form_fields.dart';
import '../../controllers/auth_controller.dart';

/// Modern forgot password page for Hosteday apps using `GetView<AuthController>`.
class ForgotPasswordPage extends GetView<AuthController> {
  const ForgotPasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('forgot_password_app_bar_title'.tr),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Center(
                  child: Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Icon(
                      Icons.mail_lock_outlined,
                      size: 34,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                Text(
                  'forgot_password_header_title'.tr,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'forgot_password_header_subtitle'.tr,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 28),

                Obx(() {
                  final isSent = controller.forgotPasswordSent.value;
                  if (isSent) {
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: <Widget>[
                            const Icon(
                              Icons.mark_email_read_rounded,
                              size: 48,
                              color: Color(0xFF10B981),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'reset_link_sent_title'.tr,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'reset_link_sent_desc'.trParams({
                                'email': controller.forgotPasswordEmailController.text,
                              }),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 18),
                            FilledButton.tonal(
                              onPressed: () {
                                controller.forgotPasswordSent.value = false;
                                controller.forgotPasswordEmailController.clear();
                                GoPage.login();
                              },
                              child: Text('back_to_login'.tr),
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
                        key: controller.forgotPasswordFormKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            EmailField(
                              controller: controller.forgotPasswordEmailController,
                              textInputAction: TextInputAction.done,
                            ),
                            const SizedBox(height: 16),

                            // Reactive Error Display
                            Obx(() {
                              final error = controller.errorMessage.value;
                              if (error.isEmpty) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 14),
                                child: ErrorBox(message: error),
                              );
                            }),

                            // Submit Button
                            Obx(() {
                              final loading = controller.isLoading.value;
                              return FilledButton(
                                onPressed: loading
                                    ? null
                                    : controller.submitForgotPassword,
                                child: loading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(
                                            Colors.white,
                                          ),
                                        ),
                                      )
                                    : Text(
                                        'send_reset_link_button'.tr,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14.5,
                                        ),
                                      ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      'remember_password_question'.tr,
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
                      ),
                    ),
                    const SizedBox(width: 4),
                    TextButton(
                      onPressed: GoPage.login,
                      child: Text('login_link'.tr),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
