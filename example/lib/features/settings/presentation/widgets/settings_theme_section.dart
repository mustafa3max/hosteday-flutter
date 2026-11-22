import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/theme/app_theme_preset.dart';
import '../../controllers/settings_controller.dart';
import 'settings_section_title.dart';

/// Theme and appearance selection section.
class SettingsThemeSection extends StatelessWidget {
  final SettingsController controller;

  const SettingsThemeSection({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SettingsSectionTitle(
          icon: Icons.palette_outlined,
          title: 'settings_section_theme'.tr,
        ),
        const SizedBox(height: 4),
        Text(
          'settings_theme_desc'.tr,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 12),

        // Light Themes Header & Presets
        Padding(
          padding: const EdgeInsets.only(left: 4, right: 4, bottom: 8),
          child: Row(
            children: <Widget>[
              const Icon(
                Icons.light_mode_rounded,
                size: 16,
                color: Colors.amber,
              ),
              const SizedBox(width: 6),
              Text(
                'light_themes_section'.tr,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                  color: Colors.amber,
                ),
              ),
            ],
          ),
        ),
        Obx(() {
          final currentPreset = controller.themeController.currentPreset.value;
          return LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 600;
              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: isWide ? 3 : 1,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: isWide ? 2.6 : 4.6,
                children: AppThemePreset.lightPresets
                    .map(
                      (preset) => _buildThemeCard(
                        context,
                        theme: Theme.of(context),
                        preset: preset,
                        isSelected: currentPreset == preset,
                        onTap: () => controller.changeTheme(preset),
                      ),
                    )
                    .toList(),
              );
            },
          );
        }),

        const SizedBox(height: 16),

        // Dark Themes Header & Presets
        Padding(
          padding: const EdgeInsets.only(left: 4, right: 4, bottom: 8),
          child: Row(
            children: <Widget>[
              const Icon(
                Icons.dark_mode_rounded,
                size: 16,
                color: Colors.indigo,
              ),
              const SizedBox(width: 6),
              Text(
                'dark_themes_section'.tr,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                  color: Colors.indigo,
                ),
              ),
            ],
          ),
        ),
        Obx(() {
          final currentPreset = controller.themeController.currentPreset.value;
          return LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 600;
              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: isWide ? 3 : 1,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: isWide ? 2.6 : 4.6,
                children: AppThemePreset.darkPresets
                    .map(
                      (preset) => _buildThemeCard(
                        context,
                        theme: Theme.of(context),
                        preset: preset,
                        isSelected: currentPreset == preset,
                        onTap: () => controller.changeTheme(preset),
                      ),
                    )
                    .toList(),
              );
            },
          );
        }),
      ],
    );
  }

  Widget _buildThemeCard(
    BuildContext context, {
    required ThemeData theme,
    required AppThemePreset preset,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? preset.primaryColor.withValues(alpha: 0.12)
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? preset.primaryColor
                : theme.colorScheme.outlineVariant.withValues(alpha: 0.45),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? <BoxShadow>[
                  BoxShadow(
                    color: preset.primaryColor.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: preset.primaryColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: preset.primaryColor.withValues(alpha: 0.4),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                preset.localizedName,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  fontSize: 13,
                  color: isSelected ? preset.primaryColor : null,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isSelected)
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: preset.primaryColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_rounded,
                  size: 14,
                  color: preset.isDark ? Colors.black : Colors.white,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
