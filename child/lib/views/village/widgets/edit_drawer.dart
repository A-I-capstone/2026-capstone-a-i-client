import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/village_item.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../../viewmodels/village_viewmodel.dart';

/// Edit/Inventory drawer sliding up from bottom covering ~45% of screen height.
class EditDrawer extends StatelessWidget {
  const EditDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final isOpen = context.select<VillageViewModel, bool>((vm) => vm.isEditOpen);
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
            _EditCategoryTabBar(),
            Expanded(child: _InventoryItemListHorizontal()),
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

class _EditCategoryTabBar extends StatelessWidget {
  const _EditCategoryTabBar();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<VillageViewModel>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _EditCategoryChip(
              category: VillageItemCategory.building,
              label: '건물',
              isSelected: viewModel.selectedEditCategory == VillageItemCategory.building,
              onTap: () => viewModel.selectEditCategory(VillageItemCategory.building),
            ),
            _EditCategoryChip(
              category: VillageItemCategory.nature,
              label: '자연물',
              isSelected: viewModel.selectedEditCategory == VillageItemCategory.nature,
              onTap: () => viewModel.selectEditCategory(VillageItemCategory.nature),
            ),
            _EditCategoryChip(
              category: VillageItemCategory.facility,
              label: '편의설비',
              isSelected: viewModel.selectedEditCategory == VillageItemCategory.facility,
              onTap: () => viewModel.selectEditCategory(VillageItemCategory.facility),
            ),
            _EditCategoryChip(
              category: VillageItemCategory.fence,
              label: '울타리',
              isSelected: viewModel.selectedEditCategory == VillageItemCategory.fence,
              onTap: () => viewModel.selectEditCategory(VillageItemCategory.fence),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditCategoryChip extends StatelessWidget {
  final VillageItemCategory category;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _EditCategoryChip({
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
            color: isSelected ? AppColors.mint : AppColors.bg,
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

class _InventoryItemListHorizontal extends StatelessWidget {
  const _InventoryItemListHorizontal();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<VillageViewModel>();

    // Count occurrences of items in inventory
    final Map<String, int> counts = {};
    for (final itemId in viewModel.inventory) {
      counts[itemId] = (counts[itemId] ?? 0) + 1;
    }

    final categoryItems = counts.keys
        .map((itemId) => viewModel.getItemById(itemId))
        .whereType<VillageItem>()
        .where((item) => item.category == viewModel.selectedEditCategory)
        .toList();

    if (categoryItems.isEmpty) {
      return Center(
        child: Text(
          '보관함에 보관된 아이템이 없어요',
          style: AppTypography.bodyMedium.copyWith(color: AppColors.slate),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      scrollDirection: Axis.horizontal,
      itemCount: categoryItems.length,
      itemBuilder: (context, index) {
        final item = categoryItems[index];
        final count = counts[item.id] ?? 0;
        return _InventoryCard(item: item, count: count);
      },
    );
  }
}

class _InventoryCard extends StatelessWidget {
  final VillageItem item;
  final int count;

  const _InventoryCard({required this.item, required this.count});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.read<VillageViewModel>();

    return GestureDetector(
      onTap: () => viewModel.startPlacing(item.id),
      child: Container(
        width: 130,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.ink, width: 1.5),
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.bg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.widgets_rounded,
                        color: AppColors.slate,
                        size: 36,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  item.name,
                  style: AppTypography.bodyMedium.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '배치하기',
                  style: AppTypography.bodyMedium.copyWith(
                    fontSize: 12,
                    color: AppColors.oceanSoft,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Positioned(
              right: 2,
              top: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.ink,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'x$count',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.surface,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
