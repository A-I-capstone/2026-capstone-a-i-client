import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/profile.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../viewmodels/chat_viewmodel.dart';
import '../viewmodels/profile_viewmodel.dart';
import '../widgets/bouncy_button.dart';
import '../widgets/pulse_loader.dart';
import 'profile_edit_view.dart';

/// Screen that shows all registered profiles and allows the user to:
///   • Switch the active profile (tap the profile row)
///   • Edit a profile's name (pencil icon button)
///   • Delete a profile (trash icon button — hidden for the active profile)
///   • Create a new profile (bottom button)
///
/// Parental Gate / password entry is intentionally omitted here and will be
/// inserted before [_onSwitch] and [_onDelete] calls in a future phase.
class ProfileSelectView extends StatelessWidget {
  const ProfileSelectView({super.key});

  void _onSwitch(BuildContext context, Profile profile) {
    // TODO(future): Insert Parental Gate here before switching.
    final profileVm = context.read<ProfileViewModel>();
    final chatVm = context.read<ChatViewModel>();
    profileVm.switchProfile(profile);
    chatVm.switchToProfile(profile);
    Navigator.of(context).pop();
  }

  void _onEdit(BuildContext context, Profile profile) {
    // TODO(future): Insert Parental Gate here before navigating.
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProfileEditView(
          profileId: profile.id,
          initialName: profile.name,
        ),
      ),
    );
  }

  Future<void> _onDelete(BuildContext context, Profile profile) async {
    // TODO(future): Insert Parental Gate here before deleting.
    await context.read<ProfileViewModel>().deleteProfile(profile.id);
  }

  void _onAdd(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ProfileEditView()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.bg,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        title: const Text('프로필 선택', style: AppTypography.headlineMedium),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: AppColors.ink,
            size: 32,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _ProfileList(
                onSwitch: (p) => _onSwitch(context, p),
                onEdit: (p) => _onEdit(context, p),
                onDelete: (p) => _onDelete(context, p),
              ),
            ),
            _AddProfileButton(onTap: () => _onAdd(context)),
          ],
        ),
      ),
    );
  }
}

class _ProfileList extends StatelessWidget {
  final void Function(Profile) onSwitch;
  final void Function(Profile) onEdit;
  final Future<void> Function(Profile) onDelete;

  const _ProfileList({
    required this.onSwitch,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ProfileViewModel>();

    if (viewModel.isLoading) {
      return const Center(child: PulseLoader(size: 40));
    }

    final profiles = viewModel.profiles;
    if (profiles.isEmpty) {
      return const _EmptyProfilePlaceholder();
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      itemCount: profiles.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final profile = profiles[index];
        final isActive = viewModel.activeProfile?.id == profile.id;
        return _ProfileTile(
          profile: profile,
          isActive: isActive,
          onTap: isActive ? null : () => onSwitch(profile),
          onEdit: () => onEdit(profile),
          // Deletion button is hidden for the currently active profile.
          onDelete: isActive ? null : () => onDelete(profile),
        );
      },
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final Profile profile;
  final bool isActive;
  final VoidCallback? onTap;
  final VoidCallback onEdit;

  /// When null the delete button is not rendered at all (active profile).
  final Future<void> Function()? onDelete;

  const _ProfileTile({
    required this.profile,
    required this.isActive,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: isActive ? AppColors.sunriseYellow : AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isActive ? AppColors.ink : AppColors.border,
              width: isActive ? 2.5 : 1.5,
            ),
          ),
          child: Row(
            children: [
              _ProfileAvatar(isActive: isActive),
              const SizedBox(width: 16),
              Expanded(child: _ProfileInfo(profile: profile, isActive: isActive)),
              _EditButton(onEdit: onEdit),
              // Delete button is completely hidden for the active profile.
              if (onDelete != null) ...[
                const SizedBox(width: 4),
                _DeleteButton(onDelete: onDelete!),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  final bool isActive;
  const _ProfileAvatar({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: isActive ? AppColors.marigold : AppColors.peach,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.ink, width: 2),
      ),
      child: const Icon(
        Icons.person_rounded,
        color: AppColors.ink,
        size: 28,
      ),
    );
  }
}

class _ProfileInfo extends StatelessWidget {
  final Profile profile;
  final bool isActive;
  const _ProfileInfo({required this.profile, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          profile.name,
          style: AppTypography.bodyLarge.copyWith(
            fontWeight: FontWeight.w700,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (isActive)
          Text(
            '현재 사용 중',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.ink,
              fontWeight: FontWeight.w500,
            ),
          ),
      ],
    );
  }
}

class _EditButton extends StatelessWidget {
  final VoidCallback onEdit;
  const _EditButton({required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onEdit,
      icon: const Icon(Icons.edit_rounded, color: AppColors.ink, size: 24),
      tooltip: '수정',
      style: IconButton.styleFrom(
        backgroundColor: AppColors.bg,
        minimumSize: const Size(48, 48),
        shape: const CircleBorder(),
      ),
    );
  }
}

class _DeleteButton extends StatelessWidget {
  final Future<void> Function() onDelete;
  const _DeleteButton({required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onDelete,
      icon: const Icon(Icons.delete_rounded, color: AppColors.tangerine, size: 24),
      tooltip: '삭제',
      style: IconButton.styleFrom(
        backgroundColor: AppColors.bg,
        minimumSize: const Size(48, 48),
        shape: const CircleBorder(),
      ),
    );
  }
}

class _EmptyProfilePlaceholder extends StatelessWidget {
  const _EmptyProfilePlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('프로필이 없어요', style: AppTypography.bodyLarge),
    );
  }
}

class _AddProfileButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AddProfileButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      child: SizedBox(
        width: double.infinity,
        child: BouncyButton(
          icon: const Icon(Icons.add_rounded, color: AppColors.surface, size: 24),
          label: '새 프로필 추가',
          onTap: onTap,
          backgroundColor: AppColors.ink,
          foregroundColor: AppColors.surface,
          padding: const EdgeInsets.symmetric(vertical: 18),
        ),
      ),
    );
  }
}
