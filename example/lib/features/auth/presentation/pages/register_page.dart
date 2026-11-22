import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/routes/go_page.dart';
import '../../../../shared/widgets/feedback_boxes.dart';
import '../../../../shared/widgets/form_fields.dart';
import '../../controllers/auth_controller.dart';

/// Full-width, modern registration page aligned with the main layout.
class RegisterPage extends GetView<AuthController> {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Title(
      title: '${'register_app_bar_title'.tr} | Hosteday',
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
                child: isDesktop
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          // Left Column: Welcome Banner & Value Props
                          Expanded(
                            flex: 5,
                            child: _buildWelcomeBanner(context, theme),
                          ),
                          const SizedBox(width: 32),
                          // Right Column: Form Card
                          Expanded(
                            flex: 6,
                            child: _buildFormCard(context, theme),
                          ),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          _buildWelcomeBanner(context, theme),
                          const SizedBox(height: 20),
                          _buildFormCard(context, theme),
                        ],
                      ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ===========================================================================
  // Welcome Banner
  // ===========================================================================
  Widget _buildWelcomeBanner(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              shape: BoxShape.circle,
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: theme.colorScheme.primary.withValues(alpha: 0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.person_add_outlined,
              size: 30,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'register_header_title'.tr,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'register_header_subtitle'.tr,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          const Divider(height: 1),
          const SizedBox(height: 20),
          _buildFeatureHighlight(
            icon: Icons.account_circle_outlined,
            title: 'إدارة متكاملة للحساب',
            subtitle: 'تخصيص الاسم، الصورة الشخصية، وإعدادات الأمان الخاصة بك.',
            color: Colors.blue,
            theme: theme,
          ),
          const SizedBox(height: 14),
          _buildFeatureHighlight(
            icon: Icons.notifications_active_outlined,
            title: 'تنبيهات فورية ومباشرة',
            subtitle: 'متابعة حية للمزادات وتنبيهات كسر العروض لحظياً.',
            color: Colors.amber,
            theme: theme,
          ),
          const SizedBox(height: 14),
          _buildFeatureHighlight(
            icon: Icons.verified_user_outlined,
            title: 'حماية وتوثيق مشفر',
            subtitle: 'تأكيد الحساب عبر البريد الإلكتروني لحماية كاملة.',
            color: Colors.green,
            theme: theme,
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureHighlight({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required ThemeData theme,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11.5,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // Form Card
  // ===========================================================================
  Widget _buildFormCard(BuildContext context, ThemeData theme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Form(
          key: controller.registerFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'register_app_bar_title'.tr,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 20),

              NameField(
                controller: controller.registerNameController,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),

              EmailField(
                controller: controller.registerEmailController,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),

              PasswordField(
                controller: controller.registerPasswordController,
                label: 'password_label'.tr,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),

              PasswordField(
                controller: controller.registerConfirmPasswordController,
                label: 'confirm_password_label'.tr,
                hint: 'confirm_password_hint'.tr,
                textInputAction: TextInputAction.done,
                customValidator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'confirm_password_required'.tr;
                  }
                  if (val != controller.registerPasswordController.text) {
                    return 'passwords_dont_match'.tr;
                  }
                  return null;
                },
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
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: loading ? null : controller.submitRegister,
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
                          'register_button'.tr,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                );
              }),
              const SizedBox(height: 20),

              // Sign In Link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    'have_account_text'.tr,
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.75,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  TextButton(
                    onPressed: GoPage.login,
                    child: Text(
                      'login_link'.tr,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
