import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/routes/go_page.dart';
import '../../../../shared/widgets/app_header.dart';
import '../../../../shared/widgets/feedback_boxes.dart';
import '../../../../shared/widgets/info_tile.dart';
import '../../controllers/user_controller.dart';

/// Modern User Profile page using `GetView<UserController>`.
class ProfilePage extends GetView<UserController> {
  final bool showAppBar;

  const ProfilePage({this.showAppBar = false, super.key});

  void _showAvatarSourceBottomSheet(BuildContext context) {
    if (controller.isBusy) return;

    Get.bottomSheet<void>(
      SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: Text('choose_from_gallery'.tr),
                onTap: () {
                  Get.back();
                  controller.pickAndUploadAvatar(source: ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: Text('take_a_photo'.tr),
                onTap: () {
                  Get.back();
                  controller.pickAndUploadAvatar(source: ImageSource.camera);
                },
              ),
            ],
          ),
        ),
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    );
  }

  Future<void> _confirmDeleteAccount(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('delete_account_title'.tr),
          content: Text('delete_account_message'.tr),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text('cancel'.tr),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(dialogContext).colorScheme.error,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text('delete'.tr),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await controller.deleteAccount();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final content = Obx(() {
      final activeUser = controller.user.value;

      if (activeUser == null) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Icon(
                Icons.person_off_outlined,
                size: 54,
                color: Colors.grey,
              ),
              const SizedBox(height: 12),
              Text('no_active_session'.tr),
              const SizedBox(height: 16),
              FilledButton(onPressed: GoPage.login, child: Text('sign_in'.tr)),
            ],
          ),
        );
      }

      final isVerified = activeUser.isEmailVerified;
      final photoUrl = activeUser.photoUrl;

      return LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final isDesktop = width >= 960;
          final isTablet = width >= 640 && width < 960;
          final horizontalPadding = isDesktop ? 32.0 : (isTablet ? 20.0 : 12.0);

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: 16,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1240),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    // Avatar & Name Header
                    Center(
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: <Widget>[
                          CircleAvatar(
                            radius: 46,
                            backgroundColor: theme.colorScheme.primary
                                .withValues(alpha: 0.15),
                            backgroundImage:
                                photoUrl != null && photoUrl.isNotEmpty
                                ? NetworkImage(photoUrl)
                                : null,
                            child: photoUrl == null || photoUrl.isEmpty
                                ? Text(
                                    (activeUser.displayName?.isNotEmpty == true
                                            ? activeUser.displayName![0]
                                            : (activeUser.email?.isNotEmpty ==
                                                      true
                                                  ? activeUser.email![0]
                                                  : 'U'))
                                        .toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.primary,
                                    ),
                                  )
                                : null,
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              iconSize: 18,
                              visualDensity: VisualDensity.compact,
                              color: Colors.white,
                              tooltip: 'change_avatar'.tr,
                              icon: controller.isUploadingAvatar.value
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                  : const Icon(Icons.camera_alt_outlined),
                              onPressed: () =>
                                  _showAvatarSourceBottomSheet(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    AppHeader(
                      title: activeUser.displayName?.isNotEmpty == true
                          ? activeUser.displayName!
                          : 'starter_title'.tr,
                      subtitle: activeUser.email ?? '',
                    ),
                    const SizedBox(height: 18),

                    // Unverified Email Notice Banner
                    if (!isVerified) ...<Widget>[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.amber.withValues(alpha: 0.45),
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.amber.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.mark_email_unread_rounded,
                                color: Colors.amber,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    'email_unverified_long_title'.tr,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                      height: 1.3,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'email_unverified_long_desc'.trParams({
                                      'email': activeUser.email ?? '',
                                    }),
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.8),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: <Widget>[
                                      FilledButton.icon(
                                        style: FilledButton.styleFrom(
                                          visualDensity: VisualDensity.compact,
                                        ),
                                        onPressed:
                                            GoPage.verificationNotification,
                                        icon: const Icon(
                                          Icons.verified_outlined,
                                          size: 16,
                                        ),
                                        label: Text('verify_page_button'.tr),
                                      ),
                                      OutlinedButton.icon(
                                        style: OutlinedButton.styleFrom(
                                          visualDensity: VisualDensity.compact,
                                        ),
                                        onPressed: controller.isBusy
                                            ? null
                                            : controller
                                                  .sendVerificationNotification,
                                        icon: const Icon(
                                          Icons.send_rounded,
                                          size: 14,
                                        ),
                                        label: Text(
                                          'send_verification_link_short'.tr,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                    ],

                    // User Information Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'account_info_title'.tr,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            InfoTile(
                              label: 'user_id_label'.tr,
                              value: activeUser.id,
                            ),
                            const Divider(height: 16),
                            InfoTile(
                              label: 'user_email_label'.tr,
                              value: activeUser.email ?? 'unknown'.tr,
                            ),
                            const Divider(height: 16),
                            InfoTile(
                              label: 'user_display_name_label'.tr,
                              value: activeUser.displayName ?? 'unknown'.tr,
                            ),
                            const Divider(height: 16),
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text('email_verification_status'.tr),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Row(
                                  children: <Widget>[
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            (isVerified
                                                    ? const Color(0xFF10B981)
                                                    : Colors.amber)
                                                .withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: isVerified
                                              ? const Color(0xFF10B981)
                                              : Colors.amber,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: <Widget>[
                                          Icon(
                                            isVerified
                                                ? Icons.check_circle_rounded
                                                : Icons.warning_amber_rounded,
                                            size: 14,
                                            color: isVerified
                                                ? const Color(0xFF10B981)
                                                : Colors.amber,
                                          ),
                                          const SizedBox(width: 5),
                                          Text(
                                            isVerified
                                                ? 'email_verified_status'.tr
                                                : 'email_unverified_status'.tr,
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: isVerified
                                                  ? const Color(0xFF10B981)
                                                  : Colors.amber,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (!isVerified) ...<Widget>[
                                      const SizedBox(width: 8),
                                      TextButton(
                                        style: TextButton.styleFrom(
                                          visualDensity: VisualDensity.compact,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                          ),
                                        ),
                                        onPressed:
                                            GoPage.verificationNotification,
                                        child: Text(
                                          'verify_now'.tr,
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Quick Navigation Cards (Password Reset & Verification)
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Card(
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: GoPage.passwordResetEmail,
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    const Icon(
                                      Icons.lock_reset_rounded,
                                      color: Color(0xFF60A5FA),
                                      size: 26,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'password_reset_email_app_bar_title'.tr,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Card(
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: GoPage.verificationNotification,
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Icon(
                                      Icons.mark_email_read_outlined,
                                      color: isVerified
                                          ? const Color(0xFF10B981)
                                          : Colors.amber,
                                      size: 26,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'verification_notification_app_bar_title'
                                          .tr,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Edit Display Name Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'update_profile_title'.tr,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 14),
                            TextField(
                              controller: controller.displayNameController,
                              enabled: !controller.isBusy,
                              textInputAction: TextInputAction.done,
                              decoration: InputDecoration(
                                labelText: 'user_display_name_label'.tr,
                                prefixIcon: const Icon(Icons.person_outline),
                              ),
                              onSubmitted: (_) => controller.updateProfile(),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Feedback Messages
                    if (controller.message.value.isNotEmpty) ...<Widget>[
                      SuccessBox(message: controller.message.value),
                      const SizedBox(height: 12),
                    ],
                    if (controller.errorMessage.value.isNotEmpty) ...<Widget>[
                      ErrorBox(message: controller.errorMessage.value),
                      const SizedBox(height: 12),
                    ],

                    // Action Buttons
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: <Widget>[
                        FilledButton.icon(
                          onPressed: controller.isBusy
                              ? null
                              : controller.updateProfile,
                          icon: controller.isLoading.value
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Icon(Icons.save_outlined, size: 18),
                          label: Text('save_changes'.tr),
                        ),
                        OutlinedButton.icon(
                          onPressed: controller.isBusy
                              ? null
                              : controller.reloadUser,
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          label: Text('reload_data'.tr),
                        ),
                        OutlinedButton.icon(
                          onPressed: GoPage.settings,
                          icon: const Icon(Icons.settings_outlined, size: 18),
                          label: Text('nav_settings'.tr),
                        ),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: theme.colorScheme.error,
                            side: BorderSide(color: theme.colorScheme.error),
                          ),
                          onPressed: controller.isBusy
                              ? null
                              : () => _confirmDeleteAccount(context),
                          icon: controller.isDeletingAccount.value
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(
                                  Icons.delete_forever_outlined,
                                  size: 18,
                                ),
                          label: Text(
                            controller.isDeletingAccount.value
                                ? 'deleting_account'.tr
                                : 'delete_account_action'.tr,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    });

    if (showAppBar) {
      return Scaffold(
        appBar: AppBar(title: Text('profile_app_bar_title'.tr)),
        body: content,
      );
    }

    return content;
  }
}
