import 'package:flutter/material.dart';

import 'app_theme_preset.dart';

/// Builds consistent Material 3 [ThemeData] for each [AppThemePreset].
///
/// Ensures button sizing, card shapes, input styles, and responsive layout
/// properties stay bullet-proof across all color variations.
abstract final class AppThemeFactory {
  const AppThemeFactory._();

  static ThemeData build(AppThemePreset preset) {
    final brightness = preset.isDark ? Brightness.dark : Brightness.light;

    final colorScheme = ColorScheme.fromSeed(
      seedColor: preset.primaryColor,
      brightness: brightness,
    ).copyWith(
      primary: preset.primaryColor,
      onPrimary: preset.isDark ? Colors.black : Colors.white,
      secondary: preset.accentColor,
      surface: preset.surfaceColor,
      onSurface: preset.textColor,
      error: const Color(0xFFEF4444),
      outlineVariant: preset.borderColor,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: preset.scaffoldColor,
      canvasColor: preset.scaffoldColor,

      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: preset.scaffoldColor,
        foregroundColor: preset.textColor,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: preset.textColor,
          fontSize: 19,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
      ),

      textTheme: TextTheme(
        headlineLarge: TextStyle(
          color: preset.textColor,
          fontSize: 30,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.8,
        ),
        headlineMedium: TextStyle(
          color: preset.textColor,
          fontSize: 26,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.6,
        ),
        headlineSmall: TextStyle(
          color: preset.textColor,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
        ),
        titleLarge: TextStyle(
          color: preset.textColor,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        titleMedium: TextStyle(
          color: preset.textColor,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(
          color: preset.textColor,
          fontSize: 15,
          height: 1.45,
        ),
        bodyMedium: TextStyle(
          color: preset.textMutedColor,
          fontSize: 13.5,
          height: 1.45,
        ),
        bodySmall: TextStyle(
          color: preset.textMutedColor,
          fontSize: 12,
          height: 1.35,
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: preset.surfaceColor,
        hintStyle: TextStyle(color: preset.textMutedColor.withValues(alpha: 0.8)),
        labelStyle: TextStyle(color: preset.textMutedColor),
        floatingLabelStyle: TextStyle(
          color: preset.primaryColor,
          fontWeight: FontWeight.w600,
        ),
        prefixIconColor: preset.textMutedColor,
        suffixIconColor: preset.textMutedColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: preset.borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: preset.borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: preset.primaryColor, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFEF4444)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.6),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: preset.primaryColor,
          foregroundColor: preset.isDark ? Colors.black : Colors.white,
          disabledBackgroundColor: preset.borderColor,
          disabledForegroundColor: preset.textMutedColor,
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          textStyle: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: preset.textColor,
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          side: BorderSide(color: preset.borderColor),
          textStyle: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),

      cardTheme: CardThemeData(
        color: preset.surfaceColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: preset.borderColor),
        ),
      ),

      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: preset.scaffoldColor,
        indicatorColor: preset.primaryColor.withValues(alpha: 0.16),
        selectedIconTheme: IconThemeData(color: preset.primaryColor),
        unselectedIconTheme: IconThemeData(color: preset.textMutedColor),
        selectedLabelTextStyle: TextStyle(
          color: preset.primaryColor,
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
        unselectedLabelTextStyle: TextStyle(
          color: preset.textMutedColor,
          fontWeight: FontWeight.w500,
          fontSize: 13,
        ),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: preset.scaffoldColor,
        surfaceTintColor: Colors.transparent,
        indicatorColor: preset.primaryColor.withValues(alpha: 0.16),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            color: selected ? preset.primaryColor : preset.textMutedColor,
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? preset.primaryColor : preset.textMutedColor,
          );
        }),
      ),

      dividerTheme: DividerThemeData(
        color: preset.borderColor,
        thickness: 1,
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: preset.surfaceColor,
        contentTextStyle: TextStyle(color: preset.textColor),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: preset.borderColor),
        ),
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: preset.primaryColor,
      ),
    );
  }
}

