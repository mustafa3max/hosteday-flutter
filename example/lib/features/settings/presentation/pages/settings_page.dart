import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/settings_controller.dart';
import '../widgets/settings_about_section.dart';
import '../widgets/settings_language_section.dart';
import '../widgets/settings_notifications_section.dart';
import '../widgets/settings_theme_section.dart';

/// End-user General Settings Page.
///
/// Consolidates all user-facing preferences into a clean, modern interface:
/// - Push notifications, outbid alerts, sound & haptics.
/// - Full theme selection (3 Light & 3 Dark presets).
/// - Instant language switching (Arabic <-> English).
/// - System & app information.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = Get.isRegistered<SettingsController>()
        ? Get.find<SettingsController>()
        : Get.put(SettingsController(), permanent: true);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 900;
        final isTablet = constraints.maxWidth >= 600 && !isDesktop;
        final horizontalPadding = isDesktop ? 32.0 : (isTablet ? 20.0 : 16.0);

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1240),
            child: ListView(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: 20,
              ),
              children: <Widget>[
                // ---------------------------------------------------------------
                // Hero Header Card
                // ---------------------------------------------------------------
                _buildHeaderCard(context, theme),
                const SizedBox(height: 20),

                // ---------------------------------------------------------------
                // Section 1: Notifications & Alerts
                // ---------------------------------------------------------------
                SettingsNotificationsSection(controller: controller),
                const SizedBox(height: 24),

                // ---------------------------------------------------------------
                // Section 2: Appearance & Theme
                // ---------------------------------------------------------------
                SettingsThemeSection(controller: controller),
                const SizedBox(height: 24),

                // ---------------------------------------------------------------
                // Section 3: Language & Localization
                // ---------------------------------------------------------------
                SettingsLanguageSection(controller: controller),
                const SizedBox(height: 24),

                // ---------------------------------------------------------------
                // Section 4: App Information
                // ---------------------------------------------------------------
                const SettingsAboutSection(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  // ===========================================================================
  // Header Card
  // ===========================================================================
  Widget _buildHeaderCard(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              shape: BoxShape.circle,
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: theme.colorScheme.primary.withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.tune_rounded,
              size: 26,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'settings_title'.tr,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'settings_subtitle'.tr,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
