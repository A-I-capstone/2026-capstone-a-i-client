import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Reusable card component following the illustrated design system rules.
/// Features a warm surface fill, 24px rounded corners, and optional 2px ink outline.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color backgroundColor;
  final bool showOutline;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20.0),
    this.backgroundColor = AppColors.surface,
    this.showOutline = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(24.0),
        border: showOutline
            ? Border.all(color: AppColors.ink, width: 2.0)
            : Border.all(color: Colors.transparent, width: 0),
      ),
      child: child,
    );
  }
}
