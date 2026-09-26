import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../viewmodels/safety_settings_viewmodel.dart';
import '../widgets/bouncy_button.dart';

/// Full-screen view for a parent to configure a child's AI safety thresholds.
///
/// Each of the four adjustable harm categories is shown as a 3-step slider
/// (0 = strictest, 2 = most permissive). Jailbreak is displayed as a locked
/// row to inform the parent that it cannot be changed.
class SafetySettingsView extends StatelessWidget {
  final String familyId;
  final String childName;

  const SafetySettingsView({
    super.key,
    required this.familyId,
    required this.childName,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SafetySettingsViewModel(familyId: familyId),
      child: _SafetySettingsContent(childName: childName),
    );
  }
}

// ---------------------------------------------------------------------------
// Content
// ---------------------------------------------------------------------------

class _SafetySettingsContent extends StatelessWidget {
  final String childName;

  const _SafetySettingsContent({required this.childName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.bg,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        title: const Text('AI 안전 설정', style: AppTypography.headlineMedium),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: AppColors.ink,
            size: 28,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Consumer<SafetySettingsViewModel>(
        builder: (context, vm, _) {
          if (vm.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.ink),
            );
          }

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            children: [
              _ChildNameBadge(childName: childName),
              const SizedBox(height: 20),
              _InfoBanner(),
              const SizedBox(height: 24),
              _SectionLabel(label: '차단 강도 조절'),
              const SizedBox(height: 12),
              _SliderCard(
                icon: Icons.sports_kabaddi_rounded,
                iconBgColor: AppColors.peach,
                label: '괴롭힘 (Harassment)',
                description: '위협·모욕·혐오적 언어를 포함한 공격적 메시지',
                value: vm.harassment,
                onChanged: vm.setHarassment,
              ),
              const SizedBox(height: 12),
              _SliderCard(
                icon: Icons.record_voice_over_rounded,
                iconBgColor: AppColors.peach,
                label: '증오 발언 (Hate Speech)',
                description: '인종·성별·종교 등을 대상으로 한 혐오·차별 표현',
                value: vm.hateSpeech,
                onChanged: vm.setHateSpeech,
              ),
              const SizedBox(height: 12),
              _SliderCard(
                icon: Icons.visibility_off_rounded,
                iconBgColor: AppColors.peach,
                label: '음란물 (Sexually Explicit)',
                description: '성적으로 노골적이거나 부적절한 콘텐츠',
                value: vm.sexuallyExplicit,
                onChanged: vm.setSexuallyExplicit,
              ),
              const SizedBox(height: 12),
              _SliderCard(
                icon: Icons.warning_amber_rounded,
                iconBgColor: AppColors.peach,
                label: '위험 콘텐츠 (Dangerous)',
                description: '자해·위험 행동·무기 제조 등 해로운 정보',
                value: vm.dangerousContent,
                onChanged: vm.setDangerousContent,
              ),
              const SizedBox(height: 12),
              const _LockedJailbreakCard(),
              const SizedBox(height: 28),
              if (vm.errorMessage != null) ...[
                _ErrorMessage(message: vm.errorMessage ?? ''),
                const SizedBox(height: 12),
              ],
              _SaveButton(vm: vm),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Child name badge
// ---------------------------------------------------------------------------

class _ChildNameBadge extends StatelessWidget {
  final String childName;

  const _ChildNameBadge({required this.childName});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.sunriseYellow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.ink, width: 2),
      ),
      child: Row(
        children: [
          const Icon(Icons.face_rounded, color: AppColors.ink, size: 26),
          const SizedBox(width: 10),
          Text(
            '$childName 의 AI 안전 설정',
            style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Info banner
// ---------------------------------------------------------------------------

class _InfoBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: AppColors.slate,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '슬라이더를 왼쪽으로 이동할수록 더 엄격하게 차단됩니다. '
              '변경 사항은 저장 버튼을 누른 후 자녀 앱에 즉시 반영됩니다.',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.slate,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section label
// ---------------------------------------------------------------------------

class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(label.toUpperCase(), style: AppTypography.eyebrow);
  }
}

// ---------------------------------------------------------------------------
// Slider card (one per category)
// ---------------------------------------------------------------------------

class _SliderCard extends StatelessWidget {
  final IconData icon;
  final Color iconBgColor;
  final String label;
  final String description;
  final int value;
  final ValueChanged<int> onChanged;

  const _SliderCard({
    required this.icon,
    required this.iconBgColor,
    required this.label,
    required this.description,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.ink, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppColors.ink, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: AppTypography.bodyLarge.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
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
            ],
          ),
          const SizedBox(height: 8),
          _ThresholdSlider(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 3-step threshold slider
// ---------------------------------------------------------------------------

class _ThresholdSlider extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const _ThresholdSlider({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppColors.ink,
            inactiveTrackColor: AppColors.border,
            thumbColor: AppColors.ink,
            overlayColor: AppColors.ink.withValues(alpha: 0.12),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
            trackHeight: 4,
            tickMarkShape: const RoundSliderTickMarkShape(tickMarkRadius: 3),
            activeTickMarkColor: AppColors.surface,
            inactiveTickMarkColor: AppColors.ink.withValues(alpha: 0.3),
          ),
          child: Slider(
            min: 0,
            max: 2,
            divisions: 2,
            value: value.toDouble(),
            onChanged: (v) => onChanged(v.round()),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _SliderLabel(
                text: '엄격',
                isActive: value == 0,
                color: AppColors.tangerine,
              ),
              _SliderLabel(
                text: '중간',
                isActive: value == 1,
                color: AppColors.marigold,
              ),
              _SliderLabel(
                text: '느슨',
                isActive: value == 2,
                color: AppColors.slate,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SliderLabel extends StatelessWidget {
  final String text;
  final bool isActive;
  final Color color;

  const _SliderLabel({
    required this.text,
    required this.isActive,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTypography.bodyMedium.copyWith(
        fontSize: 12,
        fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
        color: isActive ? color : AppColors.border,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Locked jailbreak card (always block low and above)
// ---------------------------------------------------------------------------

class _LockedJailbreakCard extends StatelessWidget {
  const _LockedJailbreakCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.ink.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lock_rounded,
              color: AppColors.ink,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '탈옥 방지 (Jailbreak)',
                  style: AppTypography.bodyLarge.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: AppColors.slate,
                  ),
                ),
                Text(
                  'AI 규칙 우회 시도를 차단합니다. 항상 최고 강도로 고정됩니다.',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.slate,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.ink.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              '잠금',
              style: AppTypography.bodyMedium.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.slate,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Error message
// ---------------------------------------------------------------------------

class _ErrorMessage extends StatelessWidget {
  final String message;

  const _ErrorMessage({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.dangerRedBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.dangerRed, width: 1.5),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.dangerRed,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.dangerRed,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Save button
// ---------------------------------------------------------------------------

class _SaveButton extends StatelessWidget {
  final SafetySettingsViewModel vm;

  const _SaveButton({required this.vm});

  @override
  Widget build(BuildContext context) {
    final canSave = !vm.isSaving;

    return BouncyButton(
      onTap: canSave ? () => _onSave(context) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: vm.saveSuccess ? AppColors.mint : AppColors.ink,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.ink, width: 2),
          boxShadow: const [
            BoxShadow(
              color: Color(0x30000000),
              blurRadius: 0,
              offset: Offset(2, 2),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: vm.isSaving
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: AppColors.surface,
                  strokeWidth: 2.5,
                ),
              )
            : Text(
                vm.saveSuccess ? '저장 완료 ✓' : '저장하기',
                style: AppTypography.buttonLabel,
              ),
      ),
    );
  }

  Future<void> _onSave(BuildContext context) async {
    await vm.saveSettings();
    if (!context.mounted) return;
    if (vm.saveSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('안전 설정이 저장되었습니다. 자녀 앱에 즉시 반영됩니다.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}
