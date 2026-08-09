import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/child_info.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../viewmodels/child_list_viewmodel.dart';
import '../viewmodels/onboarding_viewmodel.dart';
import '../widgets/bouncy_button.dart';
import 'home_view.dart';
import 'pairing_view.dart';
import 'parent_settings_view.dart';

/// Screen displaying the list of paired children for the parent to select.
class ChildListView extends StatelessWidget {
  final String parentUid;

  const ChildListView({super.key, required this.parentUid});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ChildListViewModel(parentUid: parentUid),
      child: _ChildListContent(parentUid: parentUid),
    );
  }
}

class _ChildListContent extends StatefulWidget {
  final String parentUid;

  const _ChildListContent({required this.parentUid});

  @override
  State<_ChildListContent> createState() => _ChildListContentState();
}

class _ChildListContentState extends State<_ChildListContent> {
  bool _hasRedirectedToPairing = false;

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ChildListViewModel>();

    // If loaded and empty (e.g. error or no active child), auto fallback to pairing view
    if (!viewModel.isLoading && viewModel.isEmpty && !_hasRedirectedToPairing) {
      _hasRedirectedToPairing = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final onboarding = context.read<ParentOnboardingViewModel>();
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ParentPairingView(
              parentUid: widget.parentUid,
              onPairingComplete: () {
                onboarding.completePairing();
                Navigator.of(context).pop();
              },
            ),
          ),
        );
      });
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            _ChildListHeader(parentUid: widget.parentUid),
            Expanded(
              child: viewModel.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.ink,
                        strokeWidth: 3,
                      ),
                    )
                  : viewModel.children.isEmpty
                      ? const _EmptyChildView()
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          itemCount: viewModel.children.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            final child = viewModel.children[index];
                            return _ChildCardTile(
                              childInfo: child,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => HomeView(
                                      childUid: child.childUid,
                                      childName: child.nickname,
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
            ),
            _AddChildButton(parentUid: widget.parentUid),
          ],
        ),
      ),
    );
  }
}

class _ChildListHeader extends StatelessWidget {
  final String parentUid;

  const _ChildListHeader({required this.parentUid});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '자녀 선택',
                style: AppTypography.headlineMedium.copyWith(fontSize: 26),
              ),
              const SizedBox(height: 2),
              Text(
                '과제를 관리할 자녀를 선택해 주세요.',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.slate,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          BouncyButton(
            isCircle: true,
            backgroundColor: AppColors.surface,
            padding: const EdgeInsets.all(10),
            icon: const Icon(
              Icons.settings_rounded,
              color: AppColors.ink,
              size: 26,
            ),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ParentSettingsView(parentUid: parentUid),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _EmptyChildView extends StatelessWidget {
  const _EmptyChildView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: AppColors.peach,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.family_restroom_rounded,
              size: 36,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '연동된 자녀가 없습니다.',
            style: AppTypography.headlineMedium.copyWith(fontSize: 20),
          ),
          const SizedBox(height: 4),
          Text(
            '아래 버튼을 눌러 자녀 기기를 연동해 보세요!',
            style: AppTypography.bodyMedium.copyWith(color: AppColors.slate),
          ),
        ],
      ),
    );
  }
}

class _ChildCardTile extends StatelessWidget {
  final ChildInfo childInfo;
  final VoidCallback onTap;

  const _ChildCardTile({
    required this.childInfo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BouncyButton(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.ink, width: 2.5),
          boxShadow: const [
            BoxShadow(
              color: Color(0x15000000),
              blurRadius: 0,
              offset: Offset(3, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: const BoxDecoration(
                color: AppColors.saffron,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.face_rounded,
                color: AppColors.ink,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    childInfo.nickname,
                    style: AppTypography.headlineMedium.copyWith(fontSize: 22),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '연동일: ${childInfo.pairedAt.year}.${childInfo.pairedAt.month.toString().padLeft(2, '0')}.${childInfo.pairedAt.day.toString().padLeft(2, '0')}',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.slate,
                      fontSize: 13,
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

class _AddChildButton extends StatelessWidget {
  final String parentUid;

  const _AddChildButton({required this.parentUid});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: BouncyButton(
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
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: AppColors.sunriseYellow,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppColors.ink, width: 2.5),
            boxShadow: const [
              BoxShadow(
                color: Color(0x15000000),
                blurRadius: 0,
                offset: Offset(3, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.person_add_rounded,
                color: AppColors.ink,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                '자녀 추가 연동하기',
                style: AppTypography.headlineMedium.copyWith(fontSize: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
