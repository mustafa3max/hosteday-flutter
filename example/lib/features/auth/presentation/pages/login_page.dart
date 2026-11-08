import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/routes/go_page.dart';
import '../../../../shared/widgets/feedback_boxes.dart';
import '../../../../shared/widgets/form_fields.dart';
import '../../controllers/auth_controller.dart';

/// Backward compatibility alias.
typedef SignInPage = LoginPage;

/// Modern, professional login page for Hosteday apps using `GetView<AuthController>`.
class LoginPage extends GetView<AuthController> {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('login_app_bar_title'.tr),
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
                // Header Logo
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
                      Icons.lock_outline_rounded,
                      size: 34,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                Text(
                  'login_header_title'.tr,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'login_header_subtitle'.tr,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 28),

                // Form Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(22),
                    child: Form(
                      key: controller.loginFormKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          EmailField(
                            controller: controller.loginEmailController,
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: 14),

                          PasswordField(
                            controller: controller.loginPasswordController,
                            label: 'password_label'.tr,
                            textInputAction: TextInputAction.done,
                          ),
                          const SizedBox(height: 10),

                          Align(
                            alignment: AlignmentDirectional.centerEnd,
                            child: TextButton(
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                visualDensity: VisualDensity.compact,
                              ),
                              onPressed: GoPage.forgotPassword,
                              child: Text(
                                'forgot_password_link'.tr,
                                style: const TextStyle(fontSize: 12.5),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),

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
                              onPressed: loading ? null : controller.submitLogin,
                              child: loading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : Text(
                                      'login_button'.tr,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Register Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      'no_account_text'.tr,
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
                      ),
                    ),
                    const SizedBox(width: 4),
                    TextButton(
                      onPressed: GoPage.register,
                      child: Text('register_link'.tr),
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
