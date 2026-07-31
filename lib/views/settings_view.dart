import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../viewmodels/profile_viewmodel.dart';
import '../viewmodels/settings_viewmodel.dart';
import 'profile_select_view.dart';


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
            _VoiceSection(),
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
            border: Border.all(
              color: AppColors.ink,
              width: 2,
            ), // thick ink outline for kid-friendly design
          ),
          child: child,
        ),
      ],
    );
  }
}

class _AccountSection extends StatelessWidget {
  const _AccountSection();
  @override
  Widget build(BuildContext context) {
    final activeProfile = context.watch<ProfileViewModel>().activeProfile;
    final profileName = activeProfile?.name ?? '내 친구';

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ProfileSelectView()),
      ),
      child: _SettingsCard(
        title: '계정 관리',
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
                  Text(profileName, style: AppTypography.headlineMedium),
                  Text(
                    '프로필 변경하기',
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

class _VoiceSection extends StatelessWidget {
  const _VoiceSection();
  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<SettingsViewModel>();
    return _SettingsCard(
      title: '음성',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('어떤 목소리로 이야기할까요?', style: AppTypography.bodyLarge),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: viewModel.availableVoices.map((voice) {
              final isSelected = viewModel.ttsVoice == voice;
              return GestureDetector(
                onTap: () =>
                    context.read<SettingsViewModel>().setTtsVoice(voice),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.tangerine : AppColors.surface,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppColors.ink, width: 2),
                  ),
                  child: Text(
                    voice,
                    style: AppTypography.bodyLarge.copyWith(
                      fontWeight: isSelected
                          ? FontWeight.w800
                          : FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

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
            inactiveColor: AppColors.oceanSoft.withOpacity(0.3),
            onChanged: (val) =>
                context.read<SettingsViewModel>().setTextSize(val),
          ),
          const SizedBox(height: 16),
          const Text('폰트', style: AppTypography.bodyLarge),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: viewModel.availableFonts.map((font) {
              final isSelected = viewModel.fontFamily == font;
              return GestureDetector(
                onTap: () =>
                    context.read<SettingsViewModel>().setFontFamily(font),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.mint : AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.ink, width: 2),
                  ),
                  child: Text(
                    font,
                    style: AppTypography.bodyLarge.copyWith(
                      fontWeight: isSelected
                          ? FontWeight.w800
                          : FontWeight.w500,
                    ),
                  ),
                ),
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
                activeColor: AppColors.surface,
                activeTrackColor: AppColors.ocean,
                inactiveThumbColor: AppColors.surface,
                inactiveTrackColor: AppColors.border,
                onChanged: (_) =>
                    context.read<SettingsViewModel>().toggleBold(),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Preview Area
          Container(
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
                    color: AppColors.ink.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '안녕! 나는 너의 AI 친구야.\n이 글자가 어떻게 보여?',
                  style: TextStyle(
                    fontSize: viewModel.textSize,
                    fontWeight: viewModel.isBold
                        ? FontWeight.w800
                        : FontWeight.w500,
                    color: AppColors.ink,
                    fontFamily: _getFontFamily(viewModel.fontFamily),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String? _getFontFamily(String font) {
    if (font == '둥근 폰트') return 'Nunito';
    if (font == '반듯한 폰트') return 'General Sans';
    return null;
  }
}

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
