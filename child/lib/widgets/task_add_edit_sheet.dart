import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/subject.dart';
import '../models/task.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../viewmodels/subject_viewmodel.dart';
import '../views/subject_management_view.dart';
import 'bouncy_button.dart';

/// Modal bottom sheet for adding or editing a Task.
class TaskAddEditSheet extends StatefulWidget {
  final Task? task;
  final Function(
    String title,
    DateTime? dueDate,
    List<String> subtasks,
    String subjectId,
  )
  onSave;

  const TaskAddEditSheet({super.key, this.task, required this.onSave});

  static Future<void> show(
    BuildContext context, {
    Task? task,
    required Function(
      String title,
      DateTime? dueDate,
      List<String> subtasks,
      String subjectId,
    )
    onSave,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TaskAddEditSheet(task: task, onSave: onSave),
    );
  }

  @override
  State<TaskAddEditSheet> createState() => _TaskAddEditSheetState();
}

class _TaskAddEditSheetState extends State<TaskAddEditSheet> {
  late final TextEditingController _titleController;
  late final List<TextEditingController> _subtaskControllers;
  DateTime? _selectedDueDate;
  String? _selectedSubjectId;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task?.title ?? '');
    _selectedDueDate = widget.task?.dueDate;
    _selectedSubjectId = widget.task?.subjectId;
    _subtaskControllers = (widget.task?.subtasks ?? [])
        .map((st) => TextEditingController(text: st.title))
        .toList();
    if (_subtaskControllers.isEmpty) {
      _subtaskControllers.add(TextEditingController());
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    for (final controller in _subtaskControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addSubtaskField() {
    setState(() {
      _subtaskControllers.add(TextEditingController());
    });
  }

  void _removeSubtaskField(int index) {
    setState(() {
      _subtaskControllers[index].dispose();
      _subtaskControllers.removeAt(index);
    });
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate ?? now,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365 * 2)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.ink,
              onPrimary: AppColors.surface,
              surface: AppColors.surface,
              onSurface: AppColors.ink,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDueDate = picked;
      });
    }
  }

  void _submit() {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    final subtasks = _subtaskControllers
        .map((c) => c.text.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    widget.onSave(title, _selectedDueDate, subtasks, _selectedSubjectId ?? '');
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final subjectViewModel = context.watch<SubjectViewModel>();
    final subjects = subjectViewModel.subjects;

    // Ensure selectedSubjectId is valid among current subjects
    if (_selectedSubjectId != null &&
        _selectedSubjectId!.isNotEmpty &&
        !subjects.any((s) => s.id == _selectedSubjectId)) {
      _selectedSubjectId = null;
    }

    if (_selectedSubjectId == null && subjects.isNotEmpty) {
      _selectedSubjectId = subjects.first.id;
    }

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
                  widget.task == null ? '새 과제 추가' : '과제 수정',
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
            const SizedBox(height: 16),

            // Subject selection Dropdown + Edit button
            const Text('과목', style: AppTypography.eyebrow),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: AppColors.bg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.ink, width: 2),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedSubjectId,
                        isExpanded: true,
                        icon: const Icon(
                          Icons.arrow_drop_down_rounded,
                          color: AppColors.ink,
                          size: 32,
                        ),
                        items: subjects.map((Subject subject) {
                          return DropdownMenuItem<String>(
                            value: subject.id,
                            child: Row(
                              children: [
                                Container(
                                  width: 18,
                                  height: 18,
                                  decoration: BoxDecoration(
                                    color: Color(subject.colorValue),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppColors.ink,
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  subject.name,
                                  style: AppTypography.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.ink,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedSubjectId = val;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                BouncyButton(
                  backgroundColor: AppColors.peach,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  icon: const Icon(
                    Icons.edit_rounded,
                    color: AppColors.ink,
                    size: 22,
                  ),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ChangeNotifierProvider.value(
                          value: subjectViewModel,
                          child: const SubjectManagementView(),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Task title input
            const Text('과제 이름', style: AppTypography.eyebrow),
            const SizedBox(height: 6),
            TextField(
              controller: _titleController,
              style: AppTypography.bodyLarge,
              decoration: InputDecoration(
                hintText: '예: 과학 탐구 보고서 쓰기',
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
                  borderSide: const BorderSide(
                    color: AppColors.ink,
                    width: 2.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Due date picker row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('마감 기한', style: AppTypography.eyebrow),
                    const SizedBox(height: 4),
                    Text(
                      _selectedDueDate == null
                          ? '설정 안 됨'
                          : '${_selectedDueDate!.year}년 ${_selectedDueDate!.month}월 ${_selectedDueDate!.day}일',
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: _selectedDueDate != null
                            ? AppColors.ink
                            : AppColors.slate,
                      ),
                    ),
                  ],
                ),
                BouncyButton(
                  backgroundColor: AppColors.peach,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  icon: const Icon(
                    Icons.calendar_today_rounded,
                    color: AppColors.ink,
                    size: 20,
                  ),
                  onTap: _pickDueDate,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Subtasks input list
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('세부 과제 (체크리스트)', style: AppTypography.eyebrow),
                GestureDetector(
                  onTap: _addSubtaskField,
                  child: Row(
                    children: [
                      const Icon(
                        Icons.add_circle_outline_rounded,
                        color: AppColors.ink,
                        size: 20,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '추가',
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _subtaskControllers.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                return Row(
                  children: [
                    const Icon(
                      Icons.subdirectory_arrow_right_rounded,
                      color: AppColors.slate,
                      size: 22,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: TextField(
                        controller: _subtaskControllers[index],
                        style: AppTypography.bodyMedium,
                        decoration: InputDecoration(
                          hintText: '예: 자료 조사하기',
                          hintStyle: AppTypography.bodyMedium.copyWith(
                            color: AppColors.border,
                          ),
                          filled: true,
                          fillColor: AppColors.bg,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.border,
                              width: 1.5,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.ink,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (_subtaskControllers.length > 1) ...[
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () => _removeSubtaskField(index),
                        child: const Icon(
                          Icons.remove_circle_outline_rounded,
                          color: AppColors.clay,
                          size: 22,
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
            const SizedBox(height: 24),

            // Save button
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
