import 'package:flame/cache.dart';
import 'package:flame/widgets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../../viewmodels/village_viewmodel.dart';
import '../../../widgets/bouncy_button.dart';

/// Bottom bar containing Shop, Edit, and Sell action buttons.
class BottomActionButtons extends StatelessWidget {
  const BottomActionButtons({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<VillageViewModel>();

    if (viewModel.isPlacingMode) {
      return const SizedBox.shrink();
    }

    return SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ActionButton(
                icon: Icons.store_rounded,
                label: '상점',
                color: AppColors.marigold,
                isActive: viewModel.isShopOpen,
                onTap: viewModel.toggleShop,
              ),
              const SizedBox(width: 12),
              _ActionButton(
                icon: Icons.edit_rounded,
                label: '편집',
                color: AppColors.mint,
                isActive: viewModel.isEditOpen,
                onTap: viewModel.toggleEdit,
              ),
              const SizedBox(width: 12),
              _ActionButton(
                icon: Icons.sell_rounded,
                label: '팔기',
                color: const Color(0xFFFF9849), // Tangerine
                isActive: viewModel.isSellOpen,
                onTap: viewModel.toggleSell,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isActive;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final contentColor = isActive ? AppColors.marigold : AppColors.ink;

    return BouncyButton(
      onTap: onTap,
      child: NineTileBoxWidget.asset(
        path: 'assets/game/image/icons/Button.png',
        images: Images(prefix: ''),
        tileSize: 10,
        destTileSize: 10,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: contentColor,
              size: 22,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTypography.headlineMedium.copyWith(
                fontSize: 15,
                color: contentColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
