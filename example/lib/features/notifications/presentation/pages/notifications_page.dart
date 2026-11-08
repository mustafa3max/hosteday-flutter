import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/notifications/push_notification_service.dart';
import '../../../../shared/widgets/feedback_boxes.dart';
import '../../controllers/notifications_controller.dart';

/// User-friendly Notifications Center and preferences manager with full GetX localization.
class NotificationsPage extends GetView<NotificationsController> {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final notifyController = Get.isRegistered<NotificationsController>()
        ? Get.find<NotificationsController>()
        : Get.put(NotificationsController());

    final pushService = Get.isRegistered<PushNotificationService>()
        ? PushNotificationService.to
        : null;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1240),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final isDesktop = width >= 960;
            final isTablet = width >= 640 && width < 960;
            final isSmall = width < 450;
            final horizontalPadding = isDesktop ? 32.0 : (isTablet ? 20.0 : 12.0);
            final cardPadding = isSmall ? 12.0 : 18.0;

            return Obx(() {
              final loading = notifyController.isLoading.value;
              final msg = notifyController.message.value;
              final errMsg = notifyController.errorMessage.value;
              final isPermissionGranted =
                  pushService?.isPermissionGranted.value ?? false;
              final history = pushService?.notificationsHistory ?? [];
              final generalAnnounce =
                  notifyController.generalAnnouncements.value;

              final statusBadge = Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isPermissionGranted
                      ? const Color(0xFF10B981).withValues(alpha: 0.15)
                      : Colors.amber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isPermissionGranted
                        ? const Color(0xFF10B981)
                        : Colors.amber,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(
                      isPermissionGranted
                          ? Icons.notifications_active_rounded
                          : Icons.notifications_off_outlined,
                      size: 14,
                      color: isPermissionGranted
                          ? const Color(0xFF10B981)
                          : Colors.amber.shade800,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isPermissionGranted
                          ? 'notifications_status_enabled'.tr
                          : 'notifications_status_disabled'.tr,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        color: isPermissionGranted
                            ? const Color(0xFF10B981)
                            : Colors.amber.shade800,
                      ),
                    ),
                  ],
                ),
              );

              return ListView(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: isSmall ? 16 : 24,
                ),
                children: <Widget>[
                  // 1. Header (Adaptive)
                  if (isSmall)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                'notifications_page_title'.tr,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            statusBadge,
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'notifications_page_subtitle'.tr,
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.75),
                          ),
                        ),
                      ],
                    )
                  else
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                'notifications_page_title'.tr,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  height: 1.25,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'notifications_page_subtitle'.tr,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.75),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        statusBadge,
                      ],
                    ),
                  const SizedBox(height: 16),

                  // 2. Feedback Boxes
                  if (msg.isNotEmpty) ...<Widget>[
                    SuccessBox(message: msg),
                    const SizedBox(height: 12),
                  ],
                  if (errMsg.isNotEmpty) ...<Widget>[
                    ErrorBox(message: errMsg),
                    const SizedBox(height: 12),
                  ],

                  // 3. Notification Preferences Card
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(cardPadding),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Icon(
                                Icons.tune_rounded,
                                color: theme.colorScheme.primary,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'notifications_settings_title'.tr,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Toggle 1: Push Notifications
                          SwitchListTile.adaptive(
                            contentPadding: EdgeInsets.zero,
                            value: isPermissionGranted,
                            onChanged:
                                loading ? null : notifyController.togglePush,
                            title: Text(
                              'push_notifications_toggle_title'.tr,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13.5,
                              ),
                            ),
                            subtitle: Text(
                              'push_notifications_toggle_subtitle'.tr,
                              style: const TextStyle(fontSize: 11.5),
                            ),
                            secondary: Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.notifications_active_outlined,
                                color: theme.colorScheme.primary,
                                size: 18,
                              ),
                            ),
                          ),

                          if (isPermissionGranted) ...<Widget>[
                            const Divider(height: 16),

                            // Toggle 2: General Announcements
                            SwitchListTile.adaptive(
                              contentPadding: EdgeInsets.zero,
                              value: generalAnnounce,
                              onChanged: loading
                                  ? null
                                  : notifyController.toggleGeneralAnnouncements,
                              title: Text(
                                'general_announcements_toggle_title'.tr,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13.5,
                                ),
                              ),
                              subtitle: Text(
                                'general_announcements_toggle_subtitle'.tr,
                                style: const TextStyle(fontSize: 11.5),
                              ),
                              secondary: Container(
                                padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.secondary
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.campaign_outlined,
                                  color: theme.colorScheme.secondary,
                                  size: 18,
                                ),
                              ),
                            ),

                            const Divider(height: 16),

                            // Action Buttons: Test Button & Copy Token Button
                            Column(
                              children: <Widget>[
                                SizedBox(
                                  width: double.infinity,
                                  child: FilledButton.tonalIcon(
                                    style: FilledButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 10,
                                      ),
                                    ),
                                    onPressed: loading
                                        ? null
                                        : notifyController.sendTestPush,
                                    icon: const Icon(
                                      Icons.notifications_outlined,
                                      size: 18,
                                    ),
                                    label: Text(
                                      'send_test_push_button'.tr,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 10,
                                      ),
                                    ),
                                    onPressed: loading
                                        ? null
                                        : notifyController.copyFcmToken,
                                    icon: const Icon(Icons.copy_rounded,
                                        size: 16),
                                    label: Text(
                                      'copy_fcm_token_button'.tr,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontSize: 12),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: theme
                                        .colorScheme.surfaceContainerHighest
                                        .withValues(alpha: 0.5),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: theme.dividerColor
                                          .withValues(alpha: 0.15),
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Icon(
                                        Icons.lightbulb_outline_rounded,
                                        size: 16,
                                        color: theme.colorScheme.primary,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: <Widget>[
                                            Text(
                                              'how_to_send_from_dashboard_title'.tr,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                            const SizedBox(height: 3),
                                            Text(
                                              '${'how_to_send_from_dashboard_step1'.tr}\n'
                                              '${'how_to_send_from_dashboard_step2'.tr}\n'
                                              '${'how_to_send_from_dashboard_step3'.tr}',
                                              style: TextStyle(
                                                fontSize: 11,
                                                height: 1.4,
                                                color: theme.colorScheme
                                                    .onSurface
                                                    .withValues(alpha: 0.8),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 4. Device Registration & HosteDay Server Status Card
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(cardPadding),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Icon(
                                Icons.devices_other_rounded,
                                color: theme.colorScheme.primary,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'device_registration_title'.tr,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              IconButton(
                                icon:
                                    const Icon(Icons.refresh_rounded, size: 18),
                                tooltip: 'refresh_device_list_tooltip'.tr,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed:
                                    notifyController.fetchRegisteredDevices,
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: theme
                                  .colorScheme.surfaceContainerHighest
                                  .withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: <Widget>[
                                Row(
                                  children: <Widget>[
                                    Expanded(
                                      child: Text(
                                        'sync_status_label'.tr,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: (pushService?.fcmToken.value
                                                    .isNotEmpty ??
                                                false)
                                            ? const Color(0xFF10B981)
                                                .withValues(alpha: 0.15)
                                            : Colors.amber
                                                .withValues(alpha: 0.15),
                                        borderRadius:
                                            BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        (pushService?.fcmToken.value
                                                    .isNotEmpty ??
                                                false)
                                            ? 'sync_status_connected'.tr
                                            : 'sync_status_waiting'.tr,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: (pushService?.fcmToken
                                                      .value.isNotEmpty ??
                                                  false)
                                              ? const Color(0xFF10B981)
                                              : Colors.amber.shade800,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(height: 14),
                                Row(
                                  children: <Widget>[
                                    Text(
                                      'device_id_label'.tr,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        notifyController.deviceId.value.isEmpty
                                            ? 'device_id_generating'.tr
                                            : notifyController.deviceId.value,
                                        textAlign: TextAlign.end,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontFamily: 'monospace',
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: <Widget>[
                                    Expanded(
                                      child: Text(
                                        'device_type_label'.tr,
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      notifyController.currentPlatformName,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                if (notifyController
                                    .registeredDevices.isNotEmpty) ...<Widget>[
                                  const Divider(height: 14),
                                  Row(
                                    children: <Widget>[
                                      Expanded(
                                        child: Text(
                                          'registered_devices_count_label'.tr,
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'registered_devices_count_value'.trParams({
                                          'count': notifyController
                                              .registeredDevices.length
                                              .toString(),
                                        }),
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: theme.colorScheme.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 5. Notification Inbox & History Card
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(cardPadding),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Icon(
                                Icons.inbox_rounded,
                                color: theme.colorScheme.primary,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  'notifications_inbox_title'.tr,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${history.length}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ),
                              if (history.isNotEmpty) ...<Widget>[
                                const Spacer(),
                                TextButton.icon(
                                  onPressed: notifyController.clearHistory,
                                  icon: const Icon(Icons.delete_outline,
                                      size: 14),
                                  label: Text(
                                    'clear_notifications_button'.tr,
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 10),

                          // List or Empty State
                          if (history.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 28),
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    Icon(
                                      Icons.notifications_none_rounded,
                                      size: 44,
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.35),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      'no_notifications_title'.tr,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'no_notifications_subtitle'.tr,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: theme.colorScheme.onSurface
                                            .withValues(alpha: 0.65),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: history.length,
                              separatorBuilder: (_, _) =>
                                  const Divider(height: 14),
                              itemBuilder: (context, index) {
                                final item = history[index];
                                final title = item['title']?.toString() ??
                                    'default_notification_title'.tr;
                                final body = item['body']?.toString() ?? '';
                                final time =
                                    notifyController.formatNotificationTime(
                                        item['received_at']?.toString());

                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primary
                                          .withValues(alpha: 0.12),
                                      borderRadius:
                                          BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.notifications_active_rounded,
                                      size: 18,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                  title: Text(
                                    title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Text(
                                      body,
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        color: theme.colorScheme.onSurface
                                            .withValues(alpha: 0.75),
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  trailing: Text(
                                    time,
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.5),
                                    ),
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            });
          },
        ),
      ),
    );
  }
}
