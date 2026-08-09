import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../viewmodels/onboarding_viewmodel.dart';
import 'pairing_view.dart';

/// Settings screen for Parent App.
/// Includes option to initiate child pairing again.
class ParentSettingsView extends StatelessWidget {
  final String parentUid;

  const ParentSettingsView({super.key, required this.parentUid});

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
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: AppColors.ink,
            size: 28,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          children: [
            _PairingSection(parentUid: parentUid),
            const SizedBox(height: 32),
            const _AppInfoSection(),
          ],
        ),
      ),
    );
  }
}

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

class _PairingSection extends StatelessWidget {
  final String parentUid;

  const _PairingSection({required this.parentUid});

  @override
  Widget build(BuildContext context) {
    return _SettingsCard(
      title: '자녀 기기 연동',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          final onboarding = context.read<ParentOnboardingViewModel>();
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ParentPairingView(
                parentUid: parentUid,
                onPairingComplete: () {
                  onboarding.completePairing();
                  Navigator.of(context).pop();
                },
              ),
            ),
          );
        },
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: AppColors.sunriseYellow,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_add_alt_1_rounded,
                color: AppColors.ink,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '자녀 추가 연동하기',
                    style: AppTypography.headlineMedium.copyWith(fontSize: 18),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '새로운 자녀 기기를 추가로 연동합니다.',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.slate,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.ink,
              size: 28,
            ),
          ],
        ),
      ),
    );
  }
}

class _AppInfoSection extends StatelessWidget {
  const _AppInfoSection();

  @override
  Widget build(BuildContext context) {
    return _SettingsCard(
      title: '앱 정보',
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: AppColors.ink,
            size: 28,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              '버전 정보',
              style: AppTypography.bodyLarge.copyWith(fontSize: 18),
            ),
          ),
          Text(
            'v1.0.0',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.slate,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
