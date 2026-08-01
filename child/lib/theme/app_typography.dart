import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Design system typography tokens defined in ui-design-guide.md
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

  /// Default body font size must be at least 18sp for children's UI
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

  /// Section eyebrows: uppercase, 600 weight, tracked-out small label
  static const TextStyle eyebrow = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.slate,
    letterSpacing: 1.28, // ~0.08em at 16sp
  );

  static const TextStyle buttonLabel = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.surface,
  );
}
