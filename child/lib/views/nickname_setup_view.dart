import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../viewmodels/user_viewmodel.dart';
import '../widgets/bouncy_button.dart';

/// Screen presented to set a nickname after child pairing is complete,
/// or accessible from Settings to update nickname.
class NicknameSetupView extends StatefulWidget {
  final VoidCallback onCompleted;
  final bool isEditing;

  const NicknameSetupView({
    super.key,
    required this.onCompleted,
    this.isEditing = false,
  });

  @override
  State<NicknameSetupView> createState() => _NicknameSetupViewState();
}

class _NicknameSetupViewState extends State<NicknameSetupView> {
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    final currentName = context.read<UserViewModel>().name;
    _nameController = TextEditingController(
      text: widget.isEditing || currentName != '내 친구' ? currentName : '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save({bool isSkip = false}) async {
    final userVm = context.read<UserViewModel>();
    final entered = _nameController.text.trim();

    if (isSkip || entered.isEmpty) {
      // Use fallback default name if empty or skipped
      if (userVm.name.isEmpty || userVm.name == '내 친구') {
        await userVm.updateName('내 친구');
      }
    } else {
      await userVm.updateName(entered);
    }

    if (!mounted) return;
    widget.onCompleted();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.bg,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: widget.isEditing,
        leading: widget.isEditing
            ? IconButton(
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  color: AppColors.ink,
                  size: 32,
                ),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: AppColors.sunriseYellow,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.ink, width: 3),
                ),
                child: const Icon(
                  Icons.face_rounded,
                  size: 54,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                widget.isEditing ? '닉네임 변경하기' : '반가워! 뭐라고 불러줄까?',
                style: AppTypography.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'AI 친구와 이야기할 때 사용할 이름을 적어줘!',
                style: AppTypography.bodyMedium.copyWith(color: AppColors.slate),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 36),
              TextField(
                controller: _nameController,
                autofocus: true,
                maxLength: 12,
                style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: '내 친구 (기본 이름)',
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
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: BouncyButton(
                  label: '시작하기',
                  onTap: () => _save(isSkip: false),
                  backgroundColor: AppColors.ink,
                  foregroundColor: AppColors.surface,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                ),
              ),
              if (!widget.isEditing) ...[
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => _save(isSkip: true),
                  child: Text(
                    '나중에 입력할래',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.slate,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
