import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../viewmodels/village_viewmodel.dart';

/// Temporary Debug Toolbar for testing Village state and coins.
/// TODO: Must be completely deleted along with its reference in VillageView before release.
class DebugVillageToolbar extends StatelessWidget {
  const DebugVillageToolbar({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.read<VillageViewModel>();

    return SafeArea(
      child: Align(
        alignment: Alignment.topRight,
        child: Padding(
          padding: const EdgeInsets.only(top: 60, right: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _DebugChipButton(
                icon: Icons.add_circle_outline_rounded,
                label: '+100 코인',
                color: const Color(0xFFFF0055), // High-contrast neon pink
                onTap: () => viewModel.debugAddCoins(100),
              ),
              const SizedBox(height: 6),
              _DebugChipButton(
                icon: Icons.refresh_rounded,
                label: '마을 초기화',
                color: const Color(0xFFFF6B00), // High-contrast orange
                onTap: () => viewModel.debugResetVillage(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DebugChipButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _DebugChipButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.yellowAccent, width: 1.5),
          boxShadow: const [
            BoxShadow(
              color: Color(0x3D000000),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: Colors.yellowAccent,
              size: 14,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
