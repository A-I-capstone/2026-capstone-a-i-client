import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Design system typography tokens — mirrors child app's AppTypography.
abstract class AppTypography {
  static const TextStyle headlineLarge = TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.w800,
    color: AppColors.ink,
    height: 1.2,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.ink,
    height: 1.25,
  );

  /// Body font floor: 18sp for legibility.
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    color: AppColors.ink,
    height: 1.4,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.ink,
    height: 1.4,
  );

  /// Section eyebrows: uppercase, tracked-out, muted-grey.
  static const TextStyle eyebrow = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.slate,
    letterSpacing: 1.28,
  );

  static const TextStyle buttonLabel = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.surface,
  );
}
