import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Reusable bouncy button — same design language as child app.
/// Guarantees a minimum 48x48 dp touch target and tactile press animation.
class BouncyButton extends StatefulWidget {
  final String? label;
  final Widget? icon;
  final Widget? child;
  final VoidCallback? onTap;
  final Color backgroundColor;
  final Color foregroundColor;
  final bool isCircle;
  final EdgeInsetsGeometry? padding;

  const BouncyButton({
    super.key,
    this.label,
    this.icon,
    this.child,
    this.onTap,
    this.backgroundColor = AppColors.ink,
    this.foregroundColor = AppColors.surface,
    this.isCircle = false,
    this.padding,
  });


  @override
  State<BouncyButton> createState() => _BouncyButtonState();
}

class _BouncyButtonState extends State<BouncyButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) => _controller.forward();

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onTap?.call();
  }

  void _onTapCancel() => _controller.reverse();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onTap != null ? _onTapDown : null,
      onTapUp: widget.onTap != null ? _onTapUp : null,
      onTapCancel: widget.onTap != null ? _onTapCancel : null,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child ??
            _ButtonContainer(
              label: widget.label,
              icon: widget.icon,
              backgroundColor: widget.backgroundColor,
              foregroundColor: widget.foregroundColor,
              isCircle: widget.isCircle,
              padding: widget.padding,
            ),
      ),
    );
  }
}

class _ButtonContainer extends StatelessWidget {
  final String? label;
  final Widget? icon;
  final Color backgroundColor;
  final Color foregroundColor;
  final bool isCircle;
  final EdgeInsetsGeometry? padding;

  const _ButtonContainer({
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.isCircle,
    required this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final ShapeBorder shape =
        isCircle ? const CircleBorder() : const StadiumBorder();

    final defaultPadding = isCircle
        ? const EdgeInsets.all(12)
        : const EdgeInsets.symmetric(horizontal: 20, vertical: 14);

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
      child: Material(
        color: backgroundColor,
        shape: shape,
        elevation: 0,
        child: Padding(
          padding: padding ?? defaultPadding,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon case final iconWidget?) ...[
                iconWidget,
                if (label != null) const SizedBox(width: 8),
              ],
              if (label case final labelText?)
                Text(
                  labelText,
                  style: AppTypography.buttonLabel.copyWith(
                    color: foregroundColor,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

