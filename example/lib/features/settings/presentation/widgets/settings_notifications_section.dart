import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/settings_controller.dart';
import 'settings_section_title.dart';

/// Notifications and alert preferences section.
class SettingsNotificationsSection extends StatelessWidget {
  final SettingsController controller;

  const SettingsNotificationsSection({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SettingsSectionTitle(
          icon: Icons.notifications_active_outlined,
          title: 'settings_section_notifications'.tr,
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              children: <Widget>[
                // Master Push Toggle
                Obx(
                  () => SwitchListTile(
                    secondary: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color:
                            (controller.pushEnabled.value
                                    ? theme.colorScheme.primary
                                    : Colors.grey)
                                .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.notifications_rounded,
                        color: controller.pushEnabled.value
                            ? theme.colorScheme.primary
                            : Colors.grey,
                        size: 20,
                      ),
                    ),
                    title: Row(
                      children: <Widget>[
                        Text(
                          'settings_push_title'.tr,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: controller.pushEnabled.value
                                ? Colors.green.withValues(alpha: 0.15)
                                : Colors.grey.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            controller.pushEnabled.value
                                ? 'settings_push_enabled'.tr
                                : 'settings_push_disabled'.tr,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: controller.pushEnabled.value
                                  ? Colors.green.shade700
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Text('settings_push_desc'.tr),
                    value: controller.pushEnabled.value,
                    onChanged: controller.togglePush,
                  ),
                ),
                const Divider(height: 1),

                // Outbid Alerts Toggle
                Obx(
                  () => SwitchListTile(
                    secondary: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color:
                            (controller.auctionAlertsEnabled.value
                                    ? const Color(0xFFF59E0B)
                                    : Colors.grey)
                                .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.radar_rounded,
                        color: controller.auctionAlertsEnabled.value
                            ? const Color(0xFFF59E0B)
                            : Colors.grey,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      'settings_auction_alerts_title'.tr,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text('settings_auction_alerts_desc'.tr),
                    value: controller.auctionAlertsEnabled.value,
                    onChanged: controller.toggleAuctionAlerts,
                  ),
                ),
                const Divider(height: 1),

                // Sound & Haptics Toggle
                Obx(
                  () => SwitchListTile(
                    secondary: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color:
                            (controller.soundHapticsEnabled.value
                                    ? Colors.teal
                                    : Colors.grey)
                                .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.volume_up_rounded,
                        color: controller.soundHapticsEnabled.value
                            ? Colors.teal
                            : Colors.grey,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      'settings_sound_title'.tr,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text('settings_sound_desc'.tr),
                    value: controller.soundHapticsEnabled.value,
                    onChanged: controller.toggleSound,
                  ),
                ),
                const Divider(height: 1),

                // General Announcements Toggle
                Obx(
                  () => SwitchListTile(
                    secondary: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color:
                            (controller.announcementsEnabled.value
                                    ? Colors.indigo
                                    : Colors.grey)
                                .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.campaign_outlined,
                        color: controller.announcementsEnabled.value
                            ? Colors.indigo
                            : Colors.grey,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      'settings_announcements_title'.tr,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text('settings_announcements_desc'.tr),
                    value: controller.announcementsEnabled.value,
                    onChanged: controller.toggleAnnouncements,
                  ),
                ),

                // Request System Permission Banner (if not yet granted)
                Obx(() {
                  if (controller.isSystemPermissionGranted) {
                    return const SizedBox.shrink();
                  }
                  return Container(
                    margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.amber.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: <Widget>[
                        const Icon(
                          Icons.notifications_paused_outlined,
                          color: Colors.amber,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'settings_permission_request'.tr,
                            style: const TextStyle(fontSize: 12.5),
                          ),
                        ),
                        FilledButton.tonal(
                          style: FilledButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                          onPressed: controller.isRequestingPermission.value
                              ? null
                              : controller.requestSystemPermission,
                          child: controller.isRequestingPermission.value
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text('verify_now'.tr),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
