import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/subject.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../viewmodels/subject_viewmodel.dart';
import '../widgets/bouncy_button.dart';

/// Screen for managing subjects (View, Create, Edit name & color, Delete).
class SubjectManagementView extends StatelessWidget {
  const SubjectManagementView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.bg,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        title: const Text('과목 관리', style: AppTypography.headlineMedium),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: AppColors.ink,
            size: 32,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: const SafeArea(
        child: _SubjectListContent(),
      ),
      bottomNavigationBar: const _AddSubjectBottomBar(),
    );
  }
}

class _SubjectListContent extends StatelessWidget {
  const _SubjectListContent();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<SubjectViewModel>();
    final subjects = viewModel.subjects;

    if (viewModel.isLoading && subjects.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.ink),
      );
    }

    if (subjects.isEmpty) {
      return Center(
        child: Text(
          '과목이 아직 없어요!\n아래 [새 과목 추가] 버튼을 눌러보세요.',
          textAlign: TextAlign.center,
          style: AppTypography.bodyLarge.copyWith(color: AppColors.slate),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      itemCount: subjects.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final subject = subjects[index];
        return _SubjectTile(subject: subject);
      },
    );
  }
}

class _SubjectTile extends StatelessWidget {
  final Subject subject;

  const _SubjectTile({required this.subject});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.read<SubjectViewModel>();
    final color = Color(subject.colorValue);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.ink, width: 2),
      ),
      child: Row(
        children: [
          // Color badge preview
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.ink, width: 2),
            ),
          ),
          const SizedBox(width: 14),

          // Subject Name
          Expanded(
            child: Text(
              subject.name,
              style: AppTypography.bodyLarge.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
          ),

          // Edit button
          IconButton(
            icon: const Icon(
              Icons.edit_rounded,
              color: AppColors.ink,
              size: 24,
            ),
            onPressed: () {
              _SubjectEditSheet.show(context, subject: subject);
            },
          ),

          // Delete button
          IconButton(
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: AppColors.clay,
              size: 24,
            ),
            onPressed: () => viewModel.deleteSubject(subject.id),
          ),
        ],
      ),
    );
  }
}

class _AddSubjectBottomBar extends StatelessWidget {
  const _AddSubjectBottomBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.ink, width: 2)),
      ),
      child: SafeArea(
        child: BouncyButton(
          backgroundColor: AppColors.ink,
          foregroundColor: AppColors.surface,
          padding: const EdgeInsets.symmetric(vertical: 14),
          label: '새 과목 추가',
          icon: const Icon(
            Icons.add_rounded,
            color: AppColors.surface,
            size: 24,
          ),
          onTap: () {
            _SubjectEditSheet.show(context);
          },
        ),
      ),
    );
  }
}

/// Modal Bottom Sheet for adding or editing a Subject.
class _SubjectEditSheet extends StatefulWidget {
  final Subject? subject;

  const _SubjectEditSheet({this.subject});

  static Future<void> show(BuildContext context, {Subject? subject}) {
    final viewModel = context.read<SubjectViewModel>();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: viewModel,
        child: _SubjectEditSheet(subject: subject),
      ),
    );
  }

  @override
  State<_SubjectEditSheet> createState() => _SubjectEditSheetState();
}

class _SubjectEditSheetState extends State<_SubjectEditSheet> {
  late final TextEditingController _nameController;
  late int _selectedColor;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.subject?.name ?? '');

    if (widget.subject != null) {
      _selectedColor = widget.subject!.colorValue;
    } else {
      final viewModel = context.read<SubjectViewModel>();
      _selectedColor = viewModel.getRandomPaletteColor();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final viewModel = context.read<SubjectViewModel>();
    if (widget.subject == null) {
      viewModel.addSubject(name, colorValue: _selectedColor);
    } else {
      viewModel.updateSubject(widget.subject!.id, name, _selectedColor);
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomInset),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: AppColors.ink, width: 3),
          left: BorderSide(color: AppColors.ink, width: 3),
          right: BorderSide(color: AppColors.ink, width: 3),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.subject == null ? '새 과목 추가' : '과목 수정',
                  style: AppTypography.headlineMedium,
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: const Icon(
                    Icons.close_rounded,
                    color: AppColors.ink,
                    size: 28,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Subject name input
            const Text('과목 이름', style: AppTypography.eyebrow),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              style: AppTypography.bodyLarge,
              decoration: InputDecoration(
                hintText: '예: 미술, 음악, 한자',
                hintStyle: AppTypography.bodyLarge.copyWith(
                  color: AppColors.border,
                ),
                filled: true,
                fillColor: AppColors.bg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.ink, width: 2),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.ink, width: 2),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.ink, width: 2.5),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Color picker
            const Text('과목 색상 선택', style: AppTypography.eyebrow),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: SubjectViewModel.paletteColors.map((colorValue) {
                final isSelected = _selectedColor == colorValue;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedColor = colorValue;
                    });
                  },
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Color(colorValue),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.ink,
                        width: isSelected ? 3.5 : 1.5,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(
                            Icons.check_rounded,
                            color: AppColors.ink,
                            size: 24,
                          )
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 28),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: BouncyButton(
                backgroundColor: AppColors.ink,
                foregroundColor: AppColors.surface,
                padding: const EdgeInsets.symmetric(vertical: 14),
                label: '완료',
                onTap: _submit,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
