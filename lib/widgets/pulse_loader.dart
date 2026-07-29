import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Fun pulsing loading indicator designed specifically for children.
/// Replaces standard CircularProgressIndicator.
class PulseLoader extends StatefulWidget {
  final double size;
  final Color color;

  const PulseLoader({
    super.key,
    this.size = 48.0,
    this.color = AppColors.marigold,
  });

  @override
  State<PulseLoader> createState() => _PulseLoaderState();
}

class _PulseLoaderState extends State<PulseLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.25).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: widget.color,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.ink, width: 2.5),
          ),
          child: Center(
            child: Container(
              width: widget.size * 0.4,
              height: widget.size * 0.4,
              decoration: const BoxDecoration(
                color: AppColors.sunriseYellow,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
