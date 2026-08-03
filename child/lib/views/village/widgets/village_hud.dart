import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../../viewmodels/village_viewmodel.dart';
import '../../../widgets/bouncy_button.dart';

/// Top HUD bar displaying coin balance (left) and back button (right).
class VillageHud extends StatelessWidget {
  const VillageHud({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            _CoinBadge(),
            _BackButton(),
          ],
        ),
      ),
    );
  }
}

class _CoinBadge extends StatelessWidget {
  const _CoinBadge();

  @override
  Widget build(BuildContext context) {
    final coins = context.select<VillageViewModel, int>((vm) => vm.coins);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.ink, width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              color: AppColors.marigold,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.monetization_on_rounded,
              color: AppColors.ink,
              size: 20,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$coins 코인',
            style: AppTypography.headlineMedium.copyWith(
              fontSize: 18,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton();

  @override
  Widget build(BuildContext context) {
    return BouncyButton(
      isCircle: true,
      backgroundColor: Colors.transparent,
      padding: EdgeInsets.zero,
      icon: Image.asset(
        'assets/game/image/icons/Back.png',
        width: 44,
        height: 44,
        fit: BoxFit.contain,
      ),
      onTap: () => Navigator.of(context).pop(),
    );
  }
}
