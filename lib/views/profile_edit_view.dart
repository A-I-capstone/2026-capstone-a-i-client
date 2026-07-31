import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../viewmodels/profile_viewmodel.dart';
import '../widgets/bouncy_button.dart';

/// Screen for creating a new profile or editing an existing profile's name.
///
/// Pass [profileId] and [initialName] to edit an existing profile.
/// Leave both null to create a new profile.
class ProfileEditView extends StatefulWidget {
  final String? profileId;
  final String? initialName;

  const ProfileEditView({super.key, this.profileId, this.initialName});

  @override
  State<ProfileEditView> createState() => _ProfileEditViewState();
}

class _ProfileEditViewState extends State<ProfileEditView> {
  late final TextEditingController _nameController;
  bool get _isEditing => widget.profileId != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final viewModel = context.read<ProfileViewModel>();

    if (_isEditing) {
      await viewModel.updateProfile(widget.profileId!, name);
    } else {
      await viewModel.createProfile(name);
    }

    if (mounted) Navigator.of(context).pop();
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
        title: Text(
          _isEditing ? '프로필 수정' : '새 프로필',
          style: AppTypography.headlineMedium,
        ),
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
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _AvatarPlaceholder(),
              const SizedBox(height: 40),
              const _NameFieldLabel(),
              const SizedBox(height: 12),
              _NameTextField(controller: _nameController),
              const Spacer(),
              _SaveButton(onSave: _save),
            ],
          ),
        ),
      ),
    );
  }
}

class _AvatarPlaceholder extends StatelessWidget {
  const _AvatarPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 96,
        height: 96,
        decoration: BoxDecoration(
          color: AppColors.sunriseYellow,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.ink, width: 3),
        ),
        child: const Icon(
          Icons.person_rounded,
          size: 52,
          color: AppColors.ink,
        ),
      ),
    );
  }
}

class _NameFieldLabel extends StatelessWidget {
  const _NameFieldLabel();

  @override
  Widget build(BuildContext context) {
    return Text('이름', style: AppTypography.eyebrow);
  }
}

class _NameTextField extends StatelessWidget {
  final TextEditingController controller;

  const _NameTextField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: true,
      maxLength: 20,
      style: AppTypography.bodyLarge,
      decoration: InputDecoration(
        hintText: '이름을 입력해 줘',
        hintStyle: AppTypography.bodyLarge.copyWith(color: AppColors.border),
        filled: true,
        fillColor: AppColors.surface,
        counterText: '',
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: AppColors.ink, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: AppColors.ocean, width: 2.5),
        ),
      ),
    );
  }
}

class _SaveButton extends StatelessWidget {
  final VoidCallback onSave;

  const _SaveButton({required this.onSave});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: BouncyButton(
        label: '저장',
        onTap: onSave,
        backgroundColor: AppColors.ink,
        foregroundColor: AppColors.surface,
        padding: const EdgeInsets.symmetric(vertical: 18),
      ),
    );
  }
}
