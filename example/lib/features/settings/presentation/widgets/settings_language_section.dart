import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/localization/localization_controller.dart';
import '../../controllers/settings_controller.dart';
import 'settings_section_title.dart';

/// Language and localization selection section.
class SettingsLanguageSection extends StatelessWidget {
  final SettingsController controller;

  const SettingsLanguageSection({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SettingsSectionTitle(
          icon: Icons.language_rounded,
          title: 'settings_section_language'.tr,
        ),
        const SizedBox(height: 4),
        Text(
          'settings_language_desc'.tr,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 12),
        Obx(() {
          final isArabic = controller.localizationController.isArabic;
          return Row(
            children: <Widget>[
              // Arabic Option
              Expanded(
                child: _buildLanguageOptionCard(
                  context,
                  theme: theme,
                  title: 'العربية (Arabic)',
                  subtitle: 'من اليمين إلى اليسار (RTL)',
                  icon: '🇸🇦',
                  isSelected: isArabic,
                  onTap: () => controller.changeLanguage(
                    LocalizationController.arabicLocale,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // English Option
              Expanded(
                child: _buildLanguageOptionCard(
                  context,
                  theme: theme,
                  title: 'English',
                  subtitle: 'Left to Right (LTR)',
                  icon: '🇺🇸',
                  isSelected: !isArabic,
                  onTap: () => controller.changeLanguage(
                    LocalizationController.englishLocale,
                  ),
                ),
              ),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildLanguageOptionCard(
    BuildContext context, {
    required ThemeData theme,
    required String title,
    required String subtitle,
    required String icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withValues(alpha: 0.1)
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant.withValues(alpha: 0.45),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? <BoxShadow>[
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: <Widget>[
            Text(icon, style: const TextStyle(fontSize: 26)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: isSelected
                          ? FontWeight.w800
                          : FontWeight.w600,
                      fontSize: 14,
                      color: isSelected ? theme.colorScheme.primary : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.65,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 14,
                  color: Colors.white,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
