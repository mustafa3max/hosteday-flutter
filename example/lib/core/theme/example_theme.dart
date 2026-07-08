import 'package:flutter/material.dart';

/// Central place for the visual style of the HosteDay example app.
abstract final class ExampleTheme {
  const ExampleTheme._();

  static const Color primary = Color(0xFF18181B);
  static const Color secondary = Color(0xFF27272A);
  static const Color accent = Color(0xFF34D399);

  static const Color textAccent = Color(0xFF18181B);
  static const Color textMain = Color(0xFFF4F4F5);
  static const Color textMuted = Color(0xFFA1A1AA);

  static const Color border = Color(0xFF3F3F46);
  static const Color danger = Color(0xFFF87171);
  static const Color success = Color(0xFF34D399);

  /// Recommended theme for the HosteDay example.
  static ThemeData dark() {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: accent,
          brightness: Brightness.dark,
        ).copyWith(
          primary: accent,
          onPrimary: textAccent,
          secondary: secondary,
          onSecondary: textMain,
          surface: secondary,
          onSurface: textMain,
          error: danger,
          onError: primary,
        );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: primary,
      canvasColor: primary,

      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: primary,
        foregroundColor: textMain,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: textMain,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
      ),

      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: textMain,
          fontSize: 32,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.8,
        ),
        headlineMedium: TextStyle(
          color: textMain,
          fontSize: 28,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.6,
        ),
        headlineSmall: TextStyle(
          color: textMain,
          fontSize: 24,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
        ),
        titleLarge: TextStyle(
          color: textMain,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        titleMedium: TextStyle(
          color: textMain,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(color: textMain, fontSize: 16, height: 1.45),
        bodyMedium: TextStyle(color: textMuted, fontSize: 14, height: 1.45),
        bodySmall: TextStyle(color: textMuted, fontSize: 12, height: 1.35),
        labelLarge: TextStyle(
          color: textAccent,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: secondary,
        hintStyle: const TextStyle(color: textMuted),
        labelStyle: const TextStyle(color: textMuted),
        floatingLabelStyle: const TextStyle(
          color: accent,
          fontWeight: FontWeight.w600,
        ),
        prefixIconColor: textMuted,
        suffixIconColor: textMuted,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: accent, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: danger, width: 1.6),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: textAccent,
          disabledBackgroundColor: border,
          disabledForegroundColor: textMuted,
          minimumSize: const Size.fromHeight(48),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textMain,
          minimumSize: const Size.fromHeight(48),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          side: const BorderSide(color: border),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accent,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),

      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: textMain,
          disabledForegroundColor: textMuted,
        ),
      ),

      cardTheme: CardThemeData(
        color: secondary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: border),
        ),
      ),

      listTileTheme: const ListTileThemeData(
        iconColor: accent,
        textColor: textMain,
        titleTextStyle: TextStyle(
          color: textMain,
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
        subtitleTextStyle: TextStyle(color: textMuted, fontSize: 13),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: primary,
        surfaceTintColor: Colors.transparent,
        indicatorColor: accent.withValues(alpha: 0.16),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);

          return TextStyle(
            color: selected ? accent : textMuted,
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);

          return IconThemeData(color: selected ? accent : textMuted);
        }),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: secondary,
        contentTextStyle: const TextStyle(color: textMain),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: border),
        ),
      ),

      dividerTheme: const DividerThemeData(color: border, thickness: 1),

      progressIndicatorTheme: const ProgressIndicatorThemeData(color: accent),
    );
  }
}
