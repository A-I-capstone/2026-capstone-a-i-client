import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared/shared.dart';

import '../models/child_info.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../viewmodels/onboarding_viewmodel.dart';
import '../viewmodels/parent_settings_viewmodel.dart';
import '../widgets/bouncy_button.dart';
import 'pairing_view.dart';

/// Settings screen for Parent App.
/// Includes child pairing, child unlinking, data deletion, and app info.
class ParentSettingsView extends StatelessWidget {
  final String parentUid;

  const ParentSettingsView({super.key, required this.parentUid});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ParentSettingsViewModel(parentUid: parentUid),
      child: _ParentSettingsContent(parentUid: parentUid),
    );
  }
}

class _ParentSettingsContent extends StatelessWidget {
  final String parentUid;

  const _ParentSettingsContent({required this.parentUid});

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
            _ChildManagementSection(parentUid: parentUid),
            const SizedBox(height: 28),
            _DataManagementSection(parentUid: parentUid),
            const SizedBox(height: 28),
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
            boxShadow: const [
              BoxShadow(
                color: Color(0x10000000),
                blurRadius: 0,
                offset: Offset(2, 2),
              ),
            ],
          ),
          child: child,
        ),
      ],
    );
  }
}

class _SettingsActionTile extends StatelessWidget {
  final Widget iconWidget;
  final String title;
  final String description;
  final VoidCallback onTap;
  final Color? titleColor;

  const _SettingsActionTile({
    required this.iconWidget,
    required this.title,
    required this.description,
    required this.onTap,
    this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Row(
        children: [
          iconWidget,
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.headlineMedium.copyWith(
                    fontSize: 18,
                    color: titleColor ?? AppColors.ink,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
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
            size: 26,
          ),
        ],
      ),
    );
  }
}

class _ChildManagementSection extends StatelessWidget {
  final String parentUid;

  const _ChildManagementSection({required this.parentUid});

  void _onUnlinkChildTap(BuildContext context) {
    final viewModel = context.read<ParentSettingsViewModel>();
    final children = viewModel.children;

    if (children.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('연동된 자녀가 없습니다.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (children.length == 1) {
      _showUnlinkConfirmDialog(context, children.first);
    } else {
      _showChildSelectionModal(context, children);
    }
  }

  void _showChildSelectionModal(BuildContext context, List<ChildInfo> children) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (bottomSheetContext) {
        return _ChildSelectSheet(
          children: children,
          onChildSelected: (selectedChild) {
            Navigator.of(bottomSheetContext).pop();
            _showUnlinkConfirmDialog(context, selectedChild);
          },
        );
      },
    );
  }

  void _showUnlinkConfirmDialog(BuildContext context, ChildInfo child) {
    final viewModel = context.read<ParentSettingsViewModel>();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return _TimedCountdownDialog(
          icon: Icons.link_off_rounded,
          iconColor: AppColors.tangerine,
          iconBgColor: AppColors.peach,
          title: '연동을 해제할까요?',
          confirmLabel: '연동 해제',
          confirmButtonColor: AppColors.tangerine,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.bg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border, width: 1.5),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.face_rounded,
                      color: AppColors.ink,
                      size: 28,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        child.name,
                        style: AppTypography.headlineMedium.copyWith(fontSize: 18),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Text(
                '• 선택한 자녀와의 연동이 해제됩니다.\n• 아이 기기의 데이터는 유지되지만, 부모 앱에서 다시 확인하려면 새로 연동해야 합니다.',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.ink,
                  fontSize: 14,
                  height: 1.45,
                ),
              ),
            ],
          ),
          onConfirm: () async {
            final success = await viewModel.unlinkChild(child.familyId);
            if (!context.mounted) return;
            if (success) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${child.name} 자녀와의 연동이 해제되었습니다.'),
                  duration: const Duration(seconds: 2),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    viewModel.errorMessage ?? '연동 해제에 실패했습니다.',
                  ),
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return _SettingsCard(
      title: '자녀 관리',
      child: Column(
        children: [
          _SettingsActionTile(
            iconWidget: Container(
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
            title: '자녀 추가 연동하기',
            description: '새로운 자녀 기기를 추가로 연동합니다.',
            onTap: () {
              final onboarding = context.read<ParentOnboardingViewModel>();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ParentPairingView(
                    parentUid: parentUid,
                    isFirstSetup: false,
                    onPairingComplete: () {
                      onboarding.completePairing();
                      Navigator.of(context).pop();
                    },
                  ),
                ),
              );
            },
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(color: AppColors.border, height: 1, thickness: 1),
          ),
          _SettingsActionTile(
            iconWidget: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: AppColors.peach,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.link_off_rounded,
                color: AppColors.ink,
                size: 24,
              ),
            ),
            title: '연동된 자녀 삭제',
            description: '선택한 자녀와의 기기 연동을 해제합니다.',
            onTap: () => _onUnlinkChildTap(context),
          ),
        ],
      ),
    );
  }
}

class _ChildSelectSheet extends StatelessWidget {
  final List<ChildInfo> children;
  final ValueChanged<ChildInfo> onChildSelected;

  const _ChildSelectSheet({
    required this.children,
    required this.onChildSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('연동 해제할 자녀 선택', style: AppTypography.headlineMedium),
            const SizedBox(height: 6),
            Text(
              '연동을 해제할 자녀를 목록에서 선택해 주세요.',
              style: AppTypography.bodyMedium.copyWith(color: AppColors.slate),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: children.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final child = children[index];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: AppColors.ink, width: 1.5),
                    ),
                    tileColor: AppColors.bg,
                    leading: const CircleAvatar(
                      backgroundColor: AppColors.saffron,
                      child: Icon(Icons.face_rounded, color: AppColors.ink),
                    ),
                    title: Text(
                      child.name,
                      style: AppTypography.headlineMedium.copyWith(fontSize: 17),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.ink,
                    ),
                    onTap: () => onChildSelected(child),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _DataManagementSection extends StatelessWidget {
  final String parentUid;

  const _DataManagementSection({required this.parentUid});

  void _showDeleteAllDataDialog(BuildContext context) {
    final viewModel = context.read<ParentSettingsViewModel>();
    final authProvider = context.read<BaseAuthProvider>();
    final onboardingViewModel = context.read<ParentOnboardingViewModel>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return _TimedCountdownDialog(
          icon: Icons.delete_forever_rounded,
          iconColor: AppColors.dangerRed,
          iconBgColor: AppColors.dangerRedBg,
          title: '모든 데이터를 삭제할까요?',
          confirmLabel: '데이터 영구 삭제',
          confirmButtonColor: AppColors.dangerRed,
          content: _DeleteAllDataContent(children: viewModel.children),
          onConfirm: () async {
            final success = await viewModel.deleteAllData(
              authProvider: authProvider,
              onboardingViewModel: onboardingViewModel,
            );
            if (!context.mounted) return;
            if (success) {
              await authProvider.signInAnonymously();
              if (!context.mounted) return;
              Navigator.of(context).popUntil((route) => route.isFirst);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    viewModel.errorMessage ?? '데이터 삭제 중 문제가 발생했습니다.',
                  ),
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return _SettingsCard(
      title: '계정 및 데이터 관리',
      child: _SettingsActionTile(
        iconWidget: Container(
          width: 44,
          height: 44,
          decoration: const BoxDecoration(
            color: AppColors.dangerRedBg,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.delete_forever_rounded,
            color: AppColors.dangerRed,
            size: 24,
          ),
        ),
        title: '데이터 삭제 요청',
        description: '부모 및 연동된 모든 자녀의 데이터를 영구 삭제합니다.',
        titleColor: AppColors.dangerRed,
        onTap: () => _showDeleteAllDataDialog(context),
      ),
    );
  }
}

class _DeleteAllDataContent extends StatelessWidget {
  final List<ChildInfo> children;

  const _DeleteAllDataContent({required this.children});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.dangerRedBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.dangerRed, width: 2),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: AppColors.dangerRed,
                  size: 24,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '경고: 이 작업은 절대 복구할 수 없습니다!',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.dangerRed,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.bg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.ink, width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '삭제 대상 자녀 계정 목록:',
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                if (children.isEmpty)
                  Text(
                    '• 연동된 자녀 계정 없음',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.slate,
                      fontSize: 14,
                    ),
                  )
                else
                  ...children.map(
                    (child) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.circle,
                            size: 6,
                            color: AppColors.dangerRed,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              child.name,
                              style: AppTypography.bodyLarge.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: AppColors.ink,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            '• Firebase에서 부모 계정과 위 자녀들의 모든 데이터가 즉시 삭제됩니다.\n• 과제, 대화 기록, 과목 등 모든 활동 내역이 완전히 삭제됩니다.\n• 삭제된 계정과 데이터는 다시 복원할 수 없습니다.',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.ink,
              fontSize: 13,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _TimedCountdownDialog extends StatefulWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final String title;
  final Widget content;
  final String confirmLabel;
  final Color confirmButtonColor;
  final Future<void> Function() onConfirm;

  const _TimedCountdownDialog({
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.title,
    required this.content,
    required this.confirmLabel,
    required this.confirmButtonColor,
    required this.onConfirm,
  });

  @override
  State<_TimedCountdownDialog> createState() => _TimedCountdownDialogState();
}

class _TimedCountdownDialogState extends State<_TimedCountdownDialog> {
  int _secondsRemaining = 3;
  Timer? _timer;
  bool _isActionRunning = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_secondsRemaining > 1) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        setState(() {
          _secondsRemaining = 0;
        });
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canProceed = _secondsRemaining == 0 && !_isActionRunning;

    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: AppColors.ink, width: 2),
      ),
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      title: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: widget.iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(widget.icon, color: widget.iconColor, size: 26),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.title,
              style: AppTypography.headlineMedium.copyWith(fontSize: 19),
            ),
          ),
        ],
      ),
      content: widget.content,
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      actions: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              child: BouncyButton(
                onTap: canProceed
                    ? () async {
                        setState(() {
                          _isActionRunning = true;
                        });
                        Navigator.of(context).pop();
                        await widget.onConfirm();
                      }
                    : null,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: canProceed
                        ? widget.confirmButtonColor
                        : AppColors.border.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: canProceed ? AppColors.ink : AppColors.border,
                      width: 2,
                    ),
                    boxShadow: canProceed
                        ? const [
                            BoxShadow(
                              color: Color(0x20000000),
                              blurRadius: 0,
                              offset: Offset(2, 2),
                            ),
                          ]
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _secondsRemaining > 0
                        ? '${widget.confirmLabel} ($_secondsRemaining초)'
                        : widget.confirmLabel,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: canProceed ? AppColors.surface : AppColors.slate,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: BouncyButton(
                onTap: _isActionRunning
                    ? null
                    : () => Navigator.of(context).pop(),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: AppColors.bg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.ink, width: 2),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '취소',
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: AppColors.ink,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
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

