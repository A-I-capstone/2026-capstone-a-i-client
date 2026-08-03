import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../../viewmodels/village_viewmodel.dart';
import '../../../widgets/bouncy_button.dart';

/// Top floating hint bar displayed during item placement mode or sell mode.
class PlacingModeOverlay extends StatelessWidget {
  const PlacingModeOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<VillageViewModel>();

    if (viewModel.isPlacingMode) {
      final pendingItem = viewModel.getItemById(viewModel.pendingItemId ?? '');
      final itemName = pendingItem?.name ?? '아이템';

      return _OverlayBanner(
        icon: Icons.touch_app_rounded,
        text: '$itemName 배치할 곳을 탭하세요',
        buttonLabel: '취소',
        onButtonTap: viewModel.cancelPlacing,
      );
    }

    if (viewModel.isSellOpen) {
      final isSelected = viewModel.pendingSellInstanceId != null;
      return _OverlayBanner(
        icon: Icons.delete_forever_rounded,
        text: isSelected
            ? '한 번 더 탭하면 판매(삭제)됩니다'
            : '삭제할 소품을 탭하세요 (2회 탭 시 삭제)',
        buttonLabel: '닫기',
        onButtonTap: viewModel.toggleSell,
      );
    }

    return const SizedBox.shrink();
  }
}

class _OverlayBanner extends StatelessWidget {
  final IconData icon;
  final String text;
  final String buttonLabel;
  final VoidCallback onButtonTap;

  const _OverlayBanner({
    required this.icon,
    required this.text,
    required this.buttonLabel,
    required this.onButtonTap,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: Container(
          margin: const EdgeInsets.only(top: 60, left: 16, right: 16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.ink,
            borderRadius: BorderRadius.circular(30),
            boxShadow: const [
              BoxShadow(
                color: Color(0x3D000000),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: AppColors.sunriseYellow,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                text,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.surface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 12),
              BouncyButton(
                backgroundColor: AppColors.border,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                icon: Text(
                  buttonLabel,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.ink,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: onButtonTap,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
