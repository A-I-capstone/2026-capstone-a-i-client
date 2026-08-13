import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import '../theme/app_colors.dart';

/// Uses loading_animation_widget's inkDrop animation.
class PulseLoader extends StatelessWidget {
  final double size;
  final Color color;

  const PulseLoader({
    super.key,
    this.size = 48.0,
    this.color = AppColors.marigold,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: LoadingAnimationWidget.inkDrop(color: color, size: size),
    );
  }
}
