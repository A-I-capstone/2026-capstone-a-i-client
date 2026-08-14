import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared/shared.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../viewmodels/settings_viewmodel.dart';
import '../viewmodels/user_viewmodel.dart';
import 'child_pairing_view.dart';
import 'nickname_setup_view.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.bg,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        title: const Text('설정', style: AppTypography.headlineMedium),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: AppColors.ink,
              size: 32,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          children: const [
            _AccountSection(),
            SizedBox(height: 32),
            _PairingSection(),
            SizedBox(height: 32),
            _TextSettingsSection(),
            SizedBox(height: 32),
            _HelpSection(),
            SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}

// ── Shared card shell ──────────────────────────────────────────────────────


class _SettingsCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SettingsCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTypography.eyebrow),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.ink, width: 2),
          ),
          child: child,
        ),
      ],
    );
  }
}

// ── Account section ────────────────────────────────────────────────────────

class _AccountSection extends StatelessWidget {
  const _AccountSection();

  @override
  Widget build(BuildContext context) {
    final name = context.watch<UserViewModel>().name;

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => NicknameSetupView(
              isEditing: true,
              onCompleted: () => Navigator.of(context).pop(),
            ),
          ),
        );
      },
      child: _SettingsCard(
        title: '계정 및 닉네임',
        child: Row(
          children: [
            const CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.saffron,
              child: Icon(Icons.person_rounded, size: 32, color: AppColors.ink),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: AppTypography.headlineMedium),
                  Text(
                    '닉네임 변경하기',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.slate,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.ink,
              size: 32,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Pairing section ────────────────────────────────────────────────────────

class _PairingSection extends StatelessWidget {
  const _PairingSection();

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<BaseAuthProvider>();
    final childUid = authProvider.currentUid ?? '';

    return _SettingsCard(
      title: '부모님 앱 연동',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ChildPairingView(
                childUid: childUid,
                onPaired: (familyId) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('부모님 앱과 성공적으로 연동되었어요!'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ),
          );
        },
        child: Row(
          children: [
            const CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.peach,
              child: Icon(Icons.link_rounded, size: 28, color: AppColors.ink),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('부모님 앱 연동하기', style: AppTypography.headlineMedium),
                  Text(
                    '수동으로 연동을 진행해요',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.slate,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.ink,
              size: 32,
            ),
          ],
        ),
      ),
    );
  }
}


// ── Text / font section ────────────────────────────────────────────────────

class _TextSettingsSection extends StatelessWidget {
  const _TextSettingsSection();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<SettingsViewModel>();

    return _SettingsCard(
      title: '글자 설정',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('글자 크기', style: AppTypography.bodyLarge),
          Slider(
            value: viewModel.textSize,
            min: 16.0,
            max: 32.0,
            divisions: 8,
            activeColor: AppColors.ocean,
            inactiveColor: AppColors.oceanSoft.withValues(alpha: 0.3),
            onChanged: (val) =>
                context.read<SettingsViewModel>().setTextSize(val),
          ),
          const SizedBox(height: 16),
          const Text('폰트', style: AppTypography.bodyLarge),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: SettingsViewModel.availableFonts.map((font) {
              final isSelected =
                  viewModel.selectedFontDisplayName == font.displayName;
              return _FontChip(
                displayName: font.displayName,
                fontFamily: font.fontFamily,
                isSelected: isSelected,
                onTap: () => context
                    .read<SettingsViewModel>()
                    .setFontFamily(font.displayName),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('글자 굵게 보기', style: AppTypography.bodyLarge),
              Switch(
                value: viewModel.isBold,
                activeThumbColor: AppColors.surface,
                activeTrackColor: AppColors.ocean,
                inactiveThumbColor: AppColors.border,
                onChanged: (_) =>
                    context.read<SettingsViewModel>().toggleBold(),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _FontPreview(viewModel: viewModel),
        ],
      ),
    );
  }
}

class _FontChip extends StatelessWidget {
  final String displayName;
  final String? fontFamily;
  final bool isSelected;
  final VoidCallback onTap;

  const _FontChip({
    required this.displayName,
    required this.fontFamily,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.mint : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.ink, width: 2),
        ),
        child: Text(
          displayName,
          style: TextStyle(
            fontSize: 18,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
            color: AppColors.ink,
            fontFamily: fontFamily,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}

class _FontPreview extends StatelessWidget {
  final SettingsViewModel viewModel;

  const _FontPreview({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.sunriseYellow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.ink, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '미리보기',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.ink.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.noScaling,
            ),
            child: Text(
              '안녕! 나는 너의 AI 친구야.\n이 글자가 어떻게 보여?',
              style: TextStyle(
                fontSize: viewModel.textSize,
                fontWeight:
                    viewModel.isBold ? FontWeight.w700 : FontWeight.w500,
                color: AppColors.ink,
                fontFamily: viewModel.fontFamily,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Help section ───────────────────────────────────────────────────────────

class _HelpSection extends StatelessWidget {
  const _HelpSection();

  @override
  Widget build(BuildContext context) {
    return _SettingsCard(
      title: '도움말',
      child: Row(
        children: [
          const Icon(
            Icons.help_outline_rounded,
            color: AppColors.ink,
            size: 32,
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Text('궁금한 점이 있나요?', style: AppTypography.bodyLarge),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.ink,
            size: 32,
          ),
        ],
      ),
    );
  }
}
