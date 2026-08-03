import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';

/// Preloading screen displayed before entering the village game screen.
class VillageLoadingScreen extends StatefulWidget {
  const VillageLoadingScreen({super.key});

  @override
  State<VillageLoadingScreen> createState() => _VillageLoadingScreenState();
}

class _VillageLoadingScreenState extends State<VillageLoadingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _progressAnimation = Tween<double>(begin: 0.15, end: 0.95).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOutSine,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _LoadingTitle(),
              const SizedBox(height: 28),
              _ProgressBar(animation: _progressAnimation),
              const SizedBox(height: 16),
              const _LoadingSubtitle(),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadingTitle extends StatelessWidget {
  const _LoadingTitle();

  @override
  Widget build(BuildContext context) {
    return Text(
      '마을로 떠나는 중이에요!',
      textAlign: TextAlign.center,
      style: AppTypography.headlineLarge.copyWith(
        color: AppColors.ink,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final Animation<double> animation;

  const _ProgressBar({required this.animation});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      width: double.infinity,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.ink, width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          return FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: animation.value,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.marigold,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _LoadingSubtitle extends StatelessWidget {
  const _LoadingSubtitle();

  @override
  Widget build(BuildContext context) {
    return Text(
      '잠시만 기다려줘...',
      style: AppTypography.bodyMedium.copyWith(
        color: AppColors.slate,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
