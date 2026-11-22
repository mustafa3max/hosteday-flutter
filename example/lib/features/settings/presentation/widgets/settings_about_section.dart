import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hosteday_flutter/hosteday_flutter.dart';

import '../../../../hosteday_config.dart';
import 'settings_section_title.dart';

/// App and environment information section.
class SettingsAboutSection extends StatelessWidget {
  const SettingsAboutSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    String platformName = 'Web';
    if (!kIsWeb) {
      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
          platformName = 'Android';
          break;
        case TargetPlatform.iOS:
          platformName = 'iOS';
          break;
        case TargetPlatform.macOS:
          platformName = 'macOS';
          break;
        case TargetPlatform.windows:
          platformName = 'Windows';
          break;
        case TargetPlatform.linux:
          platformName = 'Linux';
          break;
        default:
          platformName = 'Native';
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SettingsSectionTitle(
          icon: Icons.info_outline_rounded,
          title: 'settings_section_about'.tr,
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
          child: Column(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.verified_outlined),
                title: Text('settings_app_version'.tr),
                trailing: const Text(
                  'v2.3.1',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.cloud_outlined),
                title: Text('settings_environment'.tr),
                trailing: SelectableText(
                  HosteDayConfig.baseUrl,
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.devices_outlined),
                title: Text('status'.tr),
                trailing: Chip(
                  label: Text(platformName),
                  visualDensity: VisualDensity.compact,
                ),
              ),
              const Divider(height: 1),
              StreamBuilder<bool>(
                stream: Hosteday.isInitialized
                    ? Hosteday.connectivity.onStatusChange
                    : null,
                initialData: Hosteday.isInitialized ? Hosteday.isOnline : true,
                builder: (context, snapshot) {
                  final isOnline = snapshot.data ?? true;
                  final isAr = Get.locale?.languageCode == 'ar';
                  return ListTile(
                    leading: Icon(
                      isOnline ? Icons.wifi_rounded : Icons.wifi_off_rounded,
                      color: isOnline ? Colors.green : Colors.red,
                    ),
                    title: Text(isAr ? 'حالة الاتصال' : 'Connectivity'),
                    trailing: Chip(
                      avatar: CircleAvatar(
                        backgroundColor: isOnline ? Colors.green : Colors.red,
                        radius: 4,
                      ),
                      label: Text(
                        isOnline
                            ? (isAr ? 'متصل' : 'Online')
                            : (isAr ? 'غير متصل' : 'Offline'),
                        style: TextStyle(
                          color: isOnline
                              ? Colors.green.shade800
                              : Colors.red.shade800,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      backgroundColor: (isOnline ? Colors.green : Colors.red)
                          .withValues(alpha: 0.12),
                      visualDensity: VisualDensity.compact,
                      side: BorderSide(
                        color: (isOnline ? Colors.green : Colors.red)
                            .withValues(alpha: 0.3),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
