import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// 6 distinct theme color presets (3 Light, 3 Dark) for the Hosteday starter app.
enum AppThemePreset {
  // ---------------------------------------------------------------------------
  // 3 Light Theme Presets
  // ---------------------------------------------------------------------------
  oceanBlueLight(
    id: 'ocean_blue_light',
    nameAr: 'أزرق المحيط',
    nameEn: 'Ocean Blue',
    isDark: false,
    primaryColor: Color(0xFF2563EB), // Vibrant Royal Blue
    scaffoldColor: Color(0xFFF8FAFC), // Slate 50
    surfaceColor: Color(0xFFFFFFFF), // Pure White
    borderColor: Color(0xFFE2E8F0), // Slate 200
    textColor: Color(0xFF0F172A), // Slate 900
    textMutedColor: Color(0xFF64748B), // Slate 500
    accentColor: Color(0xFF3B82F6),
  ),

  emeraldMintLight(
    id: 'emerald_mint_light',
    nameAr: 'زمرد نعناعي',
    nameEn: 'Emerald Mint',
    isDark: false,
    primaryColor: Color(0xFF059669), // Emerald 600
    scaffoldColor: Color(0xFFF0FDF4), // Mint Green 50
    surfaceColor: Color(0xFFFFFFFF), // Pure White
    borderColor: Color(0xFFDCFCE7), // Mint 200
    textColor: Color(0xFF064E3B), // Emerald 900
    textMutedColor: Color(0xFF4B7A6C), // Muted Forest
    accentColor: Color(0xFF10B981),
  ),

  sunsetAmberLight(
    id: 'sunset_amber_light',
    nameAr: 'كهرمان الغروب',
    nameEn: 'Sunset Amber',
    isDark: false,
    primaryColor: Color(0xFFD97706), // Warm Amber 600
    scaffoldColor: Color(0xFFFFFBEB), // Amber 50
    surfaceColor: Color(0xFFFFFFFF), // Pure White
    borderColor: Color(0xFFFDE68A), // Amber 200
    textColor: Color(0xFF78350F), // Warm Amber 900
    textMutedColor: Color(0xFF92400E), // Muted Amber
    accentColor: Color(0xFFF59E0B),
  ),

  // ---------------------------------------------------------------------------
  // 3 Dark Theme Presets
  // ---------------------------------------------------------------------------
  cyberMidnightDark(
    id: 'cyber_midnight_dark',
    nameAr: 'سايبر منتصف الليل',
    nameEn: 'Cyber Midnight',
    isDark: true,
    primaryColor: Color(0xFF34D399), // Neon Emerald
    scaffoldColor: Color(0xFF18181B), // Zinc 900
    surfaceColor: Color(0xFF27272A), // Zinc 800
    borderColor: Color(0xFF3F3F46), // Zinc 700
    textColor: Color(0xFFF4F4F5), // Zinc 100
    textMutedColor: Color(0xFFA1A1AA), // Zinc 400
    accentColor: Color(0xFF34D399),
  ),

  royalObsidianDark(
    id: 'royal_obsidian_dark',
    nameAr: 'أزرق ملكي داكن',
    nameEn: 'Royal Obsidian',
    isDark: true,
    primaryColor: Color(0xFF60A5FA), // Electric Blue 400
    scaffoldColor: Color(0xFF0B0F19), // Deep Obsidian
    surfaceColor: Color(0xFF1E293B), // Slate 800
    borderColor: Color(0xFF334155), // Slate 700
    textColor: Color(0xFFF8FAFC), // Slate 50
    textMutedColor: Color(0xFF94A3B8), // Slate 400
    accentColor: Color(0xFF38BDF8),
  ),

  amethystVioletDark(
    id: 'amethyst_violet_dark',
    nameAr: 'بنفسجي الجمشت',
    nameEn: 'Amethyst Violet',
    isDark: true,
    primaryColor: Color(0xFFA78BFA), // Lavender Purple 400
    scaffoldColor: Color(0xFF130E20), // Deep Void Violet
    surfaceColor: Color(0xFF241B3B), // Dark Velvet Violet
    borderColor: Color(0xFF3B2D5C), // Purple 800
    textColor: Color(0xFFF5F3FF), // Purple 50
    textMutedColor: Color(0xFFA79FB8), // Muted Purple
    accentColor: Color(0xFFC084FC),
  );

  final String id;
  final String nameAr;
  final String nameEn;
  final bool isDark;
  final Color primaryColor;
  final Color scaffoldColor;
  final Color surfaceColor;
  final Color borderColor;
  final Color textColor;
  final Color textMutedColor;
  final Color accentColor;

  String get localizedName => 'theme_$id'.tr;

  const AppThemePreset({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.isDark,
    required this.primaryColor,
    required this.scaffoldColor,
    required this.surfaceColor,
    required this.borderColor,
    required this.textColor,
    required this.textMutedColor,
    required this.accentColor,
  });

  static AppThemePreset fromId(String? id) {
    return AppThemePreset.values.firstWhere(
      (preset) => preset.id == id,
      orElse: () => AppThemePreset.cyberMidnightDark,
    );
  }

  static List<AppThemePreset> get lightPresets =>
      AppThemePreset.values.where((p) => !p.isDark).toList();

  static List<AppThemePreset> get darkPresets =>
      AppThemePreset.values.where((p) => p.isDark).toList();
}
