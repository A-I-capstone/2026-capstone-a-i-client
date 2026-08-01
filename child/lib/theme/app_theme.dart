import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';

/// Design system theme setup for Capstone AI Client
abstract class AppTheme {
  /// Builds a [ThemeData] with the user's current font/weight settings applied.
  ///
  /// [fontFamily] – null means the system default font.
  /// [isBold]     – when true, body weights are bumped to w700; false uses w500.
  static ThemeData buildTheme({
    String? fontFamily,
    bool isBold = false,
  }) {
    final bodyWeight = isBold ? FontWeight.w700 : FontWeight.w500;
    final headlineWeight = isBold ? FontWeight.w800 : FontWeight.w700;

    return ThemeData(
      useMaterial3: true,
      fontFamily: fontFamily,
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.sunriseYellow,
        primary: AppColors.ink,
        surface: AppColors.surface,
        onPrimary: AppColors.surface,
        onSurface: AppColors.ink,
      ),
      textTheme: TextTheme(
        headlineLarge: AppTypography.headlineLarge.copyWith(
          fontFamily: fontFamily,
          fontWeight: headlineWeight,
        ),
        headlineMedium: AppTypography.headlineMedium.copyWith(
          fontFamily: fontFamily,
          fontWeight: headlineWeight,
        ),
        bodyLarge: AppTypography.bodyLarge.copyWith(
          fontFamily: fontFamily,
          fontWeight: bodyWeight,
        ),
        bodyMedium: AppTypography.bodyMedium.copyWith(
          fontFamily: fontFamily,
          fontWeight: bodyWeight,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppColors.ink, width: 2),
        ),
      ),
    );
  }
}
