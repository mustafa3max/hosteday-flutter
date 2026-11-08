import 'package:flutter/material.dart';

import 'app_theme_factory.dart';
import 'app_theme_preset.dart';

/// Central theme access for the Hosteday application.
abstract final class ExampleTheme {
  const ExampleTheme._();

  /// Default dark theme preset.
  static ThemeData dark() =>
      AppThemeFactory.build(AppThemePreset.cyberMidnightDark);

  /// Default light theme preset.
  static ThemeData light() =>
      AppThemeFactory.build(AppThemePreset.oceanBlueLight);

  /// Builds theme data for a specific preset.
  static ThemeData forPreset(AppThemePreset preset) =>
      AppThemeFactory.build(preset);
}
