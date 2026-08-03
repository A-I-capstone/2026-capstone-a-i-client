import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/village_item.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../../viewmodels/village_viewmodel.dart';
import '../../../widgets/bouncy_button.dart';

/// Shop drawer sliding up from the bottom covering ~45% of screen height.
class ShopDrawer extends StatelessWidget {
  const ShopDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final isOpen = context.select<VillageViewModel, bool>((vm) => vm.isShopOpen);
    final mediaQuery = MediaQuery.of(context);
    final drawerHeight = mediaQuery.size.height * 0.45;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      left: 0,
      right: 0,
      bottom: isOpen ? 0 : -drawerHeight,
      height: drawerHeight,
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(
            top: BorderSide(color: AppColors.ink, width: 3),
            left: BorderSide(color: AppColors.ink, width: 3),
            right: BorderSide(color: AppColors.ink, width: 3),
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 16,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          children: const [
            _DrawerHandle(),
            _CategoryTabBar(),
            Expanded(child: _ShopItemListHorizontal()),
          ],
        ),
      ),
    );
  }
}

class _DrawerHandle extends StatelessWidget {
  const _DrawerHandle();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 8),
      child: Container(
        width: 48,
        height: 6,
        decoration: BoxDecoration(
          color: AppColors.border,
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    );
  }
}

class _CategoryTabBar extends StatelessWidget {
  const _CategoryTabBar();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<VillageViewModel>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _CategoryTabChip(
              category: VillageItemCategory.building,
              label: '건물',
              isSelected: viewModel.selectedShopCategory == VillageItemCategory.building,
              onTap: () => viewModel.selectShopCategory(VillageItemCategory.building),
            ),
            _CategoryTabChip(
              category: VillageItemCategory.nature,
              label: '자연물',
              isSelected: viewModel.selectedShopCategory == VillageItemCategory.nature,
              onTap: () => viewModel.selectShopCategory(VillageItemCategory.nature),
            ),
            _CategoryTabChip(
              category: VillageItemCategory.facility,
              label: '편의설비',
              isSelected: viewModel.selectedShopCategory == VillageItemCategory.facility,
              onTap: () => viewModel.selectShopCategory(VillageItemCategory.facility),
            ),
            _CategoryTabChip(
              category: VillageItemCategory.fence,
              label: '울타리',
              isSelected: viewModel.selectedShopCategory == VillageItemCategory.fence,
              onTap: () => viewModel.selectShopCategory(VillageItemCategory.fence),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryTabChip extends StatelessWidget {
  final VillageItemCategory category;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryTabChip({
    required this.category,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.marigold : AppColors.bg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected ? AppColors.ink : AppColors.border,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Text(
            label,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.ink,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}

class _ShopItemListHorizontal extends StatelessWidget {
  const _ShopItemListHorizontal();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<VillageViewModel>();
    final filteredItems = viewModel.shopItems
        .where((e) => e.category == viewModel.selectedShopCategory)
        .toList();

    if (filteredItems.isEmpty) {
      return Center(
        child: Text(
          '등록된 아이템이 없어요',
          style: AppTypography.bodyMedium.copyWith(color: AppColors.slate),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      scrollDirection: Axis.horizontal,
      itemCount: filteredItems.length,
      itemBuilder: (context, index) {
        return _ShopItemCard(item: filteredItems[index]);
      },
    );
  }
}

class _ShopItemCard extends StatelessWidget {
  final VillageItem item;

  const _ShopItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<VillageViewModel>();
    final canAfford = viewModel.coins >= item.price;

    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Image placeholder
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.bg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
              ),
              child: const Icon(
                Icons.image_not_supported_rounded,
                color: AppColors.border,
                size: 36,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            item.name,
            style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            '${item.price} 코인',
            style: AppTypography.bodyMedium.copyWith(
              fontSize: 13,
              color: canAfford ? AppColors.sand : AppColors.slate,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            child: BouncyButton(
              backgroundColor: canAfford ? AppColors.tealCta : AppColors.border,
              padding: const EdgeInsets.symmetric(vertical: 6),
              icon: Center(
                child: Text(
                  '구매',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.surface,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              onTap: canAfford ? () => viewModel.buyItem(item) : null,
            ),
          ),
        ],
      ),
    );
  }
}
