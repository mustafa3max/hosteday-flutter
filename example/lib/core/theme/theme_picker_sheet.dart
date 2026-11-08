import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../localization/localization_controller.dart';
import 'app_theme_preset.dart';
import 'theme_controller.dart';

/// Interactive modal sheet to switch between the 6 color themes (3 Light & 3 Dark) and language.
class ThemePickerSheet extends StatelessWidget {
  const ThemePickerSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ThemePickerSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    final localizationController = Get.isRegistered<LocalizationController>()
        ? LocalizationController.to
        : null;
    final theme = Theme.of(context);

    return Container(
      constraints: const BoxConstraints(maxWidth: 620),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // Header
                Row(
                  children: <Widget>[
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.palette_outlined,
                        size: 20,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'theme_sheet_title'.tr,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'theme_sheet_subtitle'.tr,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded, size: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Language Switcher Tile
                if (localizationController != null)
                  Obx(() {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant
                              .withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: <Widget>[
                          Icon(
                            Icons.language_rounded,
                            size: 20,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  'language_label'.tr,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  localizationController.currentLanguageName,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          FilledButton.tonal(
                            style: FilledButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                            ),
                            onPressed: localizationController.toggleLanguage,
                            child: Text(
                              localizationController.targetLanguageName,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                const SizedBox(height: 16),

                // Light Themes Section
                _buildSectionHeader(
                  context,
                  icon: Icons.light_mode_rounded,
                  title: 'light_themes_section'.tr,
                  color: Colors.amber.shade700,
                ),
                const SizedBox(height: 10),
                Obx(() => Column(
                      children: AppThemePreset.lightPresets
                          .map((preset) => _buildThemeTile(
                                context,
                                preset: preset,
                                isSelected:
                                    themeController.currentPreset.value == preset,
                                onTap: () {
                                  themeController.changeTheme(preset);
                                },
                              ))
                          .toList(),
                    )),
                const SizedBox(height: 16),

                // Dark Themes Section
                _buildSectionHeader(
                  context,
                  icon: Icons.dark_mode_rounded,
                  title: 'dark_themes_section'.tr,
                  color: Colors.indigo.shade400,
                ),
                const SizedBox(height: 10),
                Obx(() => Column(
                      children: AppThemePreset.darkPresets
                          .map((preset) => _buildThemeTile(
                                context,
                                preset: preset,
                                isSelected:
                                    themeController.currentPreset.value == preset,
                                onTap: () {
                                  themeController.changeTheme(preset);
                                },
                              ))
                          .toList(),
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
  }) {
    return Row(
      children: <Widget>[
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: color,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildThemeTile(
    BuildContext context, {
    required AppThemePreset preset,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
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
                  : theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
              width: isSelected ? 1.8 : 1,
            ),
          ),
          child: Row(
            children: <Widget>[
              // Color Swatch Indicator
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: preset.primaryColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 2,
                  ),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: preset.primaryColor.withValues(alpha: 0.4),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Preset Names
              Expanded(
                child: Text(
                  preset.localizedName,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                    color: isSelected ? preset.primaryColor : null,
                  ),
                ),
              ),
              // Active Indicator
              if (isSelected)
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: preset.primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_rounded,
                    size: 15,
                    color: preset.isDark ? Colors.black : Colors.white,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
