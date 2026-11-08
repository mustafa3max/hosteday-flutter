import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/routes/go_page.dart';
import '../../../../shared/widgets/feedback_boxes.dart';
import '../../../../shared/widgets/form_fields.dart';
import '../../controllers/auth_controller.dart';

/// Modern, professional registration page for Hosteday apps using `GetView<AuthController>`.
class RegisterPage extends GetView<AuthController> {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('register_app_bar_title'.tr),
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
                      Icons.person_add_outlined,
                      size: 34,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                Text(
                  'register_header_title'.tr,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'register_header_subtitle'.tr,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 28),

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(22),
                    child: Form(
                      key: controller.registerFormKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          NameField(
                            controller: controller.registerNameController,
                            label: 'name_label'.tr,
                            hint: 'name_hint'.tr,
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: 14),

                          EmailField(
                            controller: controller.registerEmailController,
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: 14),

                          PasswordField(
                            controller: controller.registerPasswordController,
                            label: 'password_label'.tr,
                            hint: 'password_hint'.tr,
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: 14),

                          PasswordField(
                            controller: controller.registerConfirmPasswordController,
                            label: 'confirm_password_label'.tr,
                            hint: 'confirm_password_hint'.tr,
                            textInputAction: TextInputAction.done,
                            customValidator: (text) {
                              if (text == null || text.isEmpty) {
                                return 'confirm_password_required'.tr;
                              }
                              if (text != controller.registerPasswordController.text) {
                                return 'passwords_dont_match'.tr;
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 18),

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
                              onPressed: loading ? null : controller.submitRegister,
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
                                      'register_button'.tr,
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

                // Login Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      'have_account_text'.tr,
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
