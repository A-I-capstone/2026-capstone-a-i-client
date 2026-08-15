import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared/shared.dart';

import '../models/subject.dart';
import '../models/task.dart';
import '../services/subject/firestore_subject_repository.dart';
import '../services/task/firestore_task_repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../viewmodels/subject_viewmodel.dart';
import '../viewmodels/task_management_viewmodel.dart';
import '../widgets/bouncy_button.dart';
import '../widgets/pulse_loader.dart';
import 'settings_view.dart';

/// Screen for managing Tasks (batch complete/incomplete/delete) and Subjects.
class TaskSubjectManagementView extends StatelessWidget {
  const TaskSubjectManagementView({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<BaseAuthProvider>();
    final userId = authProvider.currentUid ?? '';

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => TaskManagementViewModel(
            taskRepository: FirestoreTaskRepository(),
            userId: userId,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => SubjectViewModel(
            repository: FirestoreSubjectRepository(),
            userId: userId,
          ),
        ),
      ],
      child: const _TaskSubjectManagementContent(),
    );
  }
}

class _TaskSubjectManagementContent extends StatefulWidget {
  const _TaskSubjectManagementContent();

  @override
  State<_TaskSubjectManagementContent> createState() =>
      _TaskSubjectManagementContentState();
}

class _TaskSubjectManagementContentState
    extends State<_TaskSubjectManagementContent> {
  late final PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            const _ManagementHeader(),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                children: const [
                  _TaskManagementTab(),
                  _SubjectManagementTab(),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _ManagementBottomBar(
        currentIndex: _currentIndex,
        onTapTab: _onTabTapped,
      ),
    );
  }
}

// =============================================================================
// Top Header
// =============================================================================

class _ManagementHeader extends StatelessWidget {
  const _ManagementHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(
              Icons.settings_rounded,
              color: AppColors.ink,
              size: 34,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsView()),
              );
            },
          ),
          BouncyButton(
            backgroundColor: AppColors.ink,
            foregroundColor: AppColors.surface,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            label: '메인 화면',
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: AppColors.surface,
              size: 22,
            ),
            onTap: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Tab 1: Task Management Tab
// =============================================================================

class _TaskManagementTab extends StatelessWidget {
  const _TaskManagementTab();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<TaskManagementViewModel>();

    if (viewModel.isLoading && viewModel.tasks.isEmpty) {
      return const Center(child: PulseLoader(size: 36));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _BatchActionBar(),
        const _DividerLine(),
        Expanded(
          child: viewModel.tasks.isEmpty
              ? const _EmptyTasksPlaceholder()
              : const _BatchTaskListView(),
        ),
      ],
    );
  }
}

class _BatchActionBar extends StatelessWidget {
  const _BatchActionBar();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<TaskManagementViewModel>();
    final hasSelection = viewModel.selectedCount > 0;
    final hasCompleted = viewModel.hasCompletedTasks;

    const labelStyle = TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w700,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: BouncyButton(
                  backgroundColor: hasSelection ? AppColors.ink : AppColors.border,
                  foregroundColor: AppColors.surface,
                  labelStyle: labelStyle,
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                  label: '일괄 완료 표시',
                  onTap: hasSelection ? () => viewModel.batchMarkCompleted() : null,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: BouncyButton(
                  backgroundColor: hasSelection ? AppColors.ink : AppColors.border,
                  foregroundColor: AppColors.surface,
                  labelStyle: labelStyle,
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                  label: '일괄 미완료 표시',
                  onTap: hasSelection ? () => viewModel.batchMarkIncompleted() : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: BouncyButton(
                  backgroundColor: hasSelection
                      ? AppColors.overdueRed
                      : AppColors.border.withValues(alpha: 0.35),
                  foregroundColor: hasSelection
                      ? AppColors.overdueText
                      : AppColors.border,
                  labelStyle: labelStyle,
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                  label: '일괄 삭제',
                  onTap: hasSelection ? () => viewModel.batchDelete() : null,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: BouncyButton(
                  backgroundColor: hasCompleted
                      ? AppColors.overdueRed
                      : AppColors.border.withValues(alpha: 0.35),
                  foregroundColor: hasCompleted
                      ? AppColors.overdueText
                      : AppColors.border,
                  labelStyle: labelStyle,
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                  label: '완료한 과제 일괄 삭제',
                  onTap: hasCompleted
                      ? () => viewModel.batchDeleteCompletedTasks()
                      : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DividerLine extends StatelessWidget {
  const _DividerLine();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      height: 2,
      color: AppColors.ink,
    );
  }
}

class _BatchTaskListView extends StatelessWidget {
  const _BatchTaskListView();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<TaskManagementViewModel>();
    final tasks = viewModel.tasks;

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 90),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        final isSelected = viewModel.isSelected(task.id);

        return Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: _BatchTaskRow(task: task, isSelected: isSelected),
        );
      },
    );
  }
}

class _BatchTaskRow extends StatelessWidget {
  final Task task;
  final bool isSelected;

  const _BatchTaskRow({
    required this.task,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    final viewModel = context.read<TaskManagementViewModel>();
    final subjectViewModel = context.watch<SubjectViewModel>();
    final subject = subjectViewModel.getSubjectById(task.subjectId);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _SelectionCheckbox(
          isSelected: isSelected,
          onTap: () => viewModel.toggleSelection(task.id),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _TaskTitleAndDueInfo(
            task: task,
            onTap: () => viewModel.toggleSelection(task.id),
          ),
        ),
        const SizedBox(width: 10),
        _SubjectBadge(subject: subject),
      ],
    );
  }
}

class _SelectionCheckbox extends StatelessWidget {
  final bool isSelected;
  final VoidCallback onTap;

  const _SelectionCheckbox({
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Icon(
          isSelected
              ? Icons.check_box_rounded
              : Icons.check_box_outline_blank_rounded,
          color: AppColors.ink,
          size: 30,
        ),
      ),
    );
  }
}

class _TaskTitleAndDueInfo extends StatelessWidget {
  final Task task;
  final VoidCallback onTap;

  const _TaskTitleAndDueInfo({
    required this.task,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dueDate = task.dueDate;
    final isCompleted = task.isCompleted;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            task.title,
            style: AppTypography.bodyLarge.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              decoration: isCompleted ? TextDecoration.lineThrough : null,
              color: isCompleted ? AppColors.slate : AppColors.ink,
            ),
          ),
          if (dueDate != null) ...[
            const SizedBox(height: 2),
            Text(
              task.isOverdue && !isCompleted
                  ? '(마감기한 지남: ${dueDate.month}월 ${dueDate.day}일)'
                  : task.isDueToday && !isCompleted
                      ? '(마감기한: 오늘)'
                      : '(마감기한: ${dueDate.month}월 ${dueDate.day}일)',
              style: AppTypography.bodyMedium.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                decoration: isCompleted ? TextDecoration.lineThrough : null,
                color: isCompleted
                    ? AppColors.slate
                    : task.isOverdue
                        ? AppColors.overdueText
                        : AppColors.slate,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SubjectBadge extends StatelessWidget {
  final Subject? subject;

  const _SubjectBadge({this.subject});

  @override
  Widget build(BuildContext context) {
    final name = subject?.name ?? '과목';
    final color = subject != null
        ? Color(subject!.colorValue)
        : AppColors.surface;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: AppColors.ink, width: 2),
      ),
      child: Text(
        name,
        style: AppTypography.bodyMedium.copyWith(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.ink,
        ),
      ),
    );
  }
}

class _EmptyTasksPlaceholder extends StatelessWidget {
  const _EmptyTasksPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        '등록된 과제가 없어요!',
        textAlign: TextAlign.center,
        style: AppTypography.bodyLarge.copyWith(color: AppColors.slate),
      ),
    );
  }
}

// =============================================================================
// Tab 2: Subject Management Tab
// =============================================================================

class _SubjectManagementTab extends StatelessWidget {
  const _SubjectManagementTab();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<SubjectViewModel>();
    final subjects = viewModel.subjects;

    if (viewModel.isLoading && subjects.isEmpty) {
      return const Center(child: PulseLoader(size: 36));
    }

    return Column(
      children: [
        Expanded(
          child: subjects.isEmpty
              ? const _EmptySubjectsPlaceholder()
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 90),
                  itemCount: subjects.length,
                  separatorBuilder: (_, _) => const Divider(
                    color: AppColors.border,
                    thickness: 1,
                    height: 1,
                  ),
                  itemBuilder: (context, index) {
                    final subject = subjects[index];
                    return _SubjectManagementTile(subject: subject);
                  },
                ),
        ),
        const _AddSubjectBar(),
      ],
    );
  }
}

class _SubjectManagementTile extends StatelessWidget {
  final Subject subject;

  const _SubjectManagementTile({required this.subject});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.read<SubjectViewModel>();
    final color = Color(subject.colorValue);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          // Clickable Color Circle (Opens Free Color Picker)
          GestureDetector(
            onTap: () => _showColorPickerModal(context, subject),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.ink, width: 2),
              ),
              child: const Icon(
                Icons.palette_outlined,
                color: AppColors.ink,
                size: 20,
              ),
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
              _SubjectEditModal.show(context, subject: subject);
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

  void _showColorPickerModal(BuildContext context, Subject subject) {
    final subjectViewModel = context.read<SubjectViewModel>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FreeColorPickerBottomSheet(
        title: '\'${subject.name}\' 색상 변경',
        initialColor: subject.colorValue,
        onColorSelected: (newColor) {
          subjectViewModel.updateSubject(subject.id, subject.name, newColor);
          Navigator.of(context).pop();
        },
      ),
    );
  }
}

class _AddSubjectBar extends StatelessWidget {
  const _AddSubjectBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
      child: SizedBox(
        width: double.infinity,
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
          onTap: () => _SubjectEditModal.show(context),
        ),
      ),
    );
  }
}

class _EmptySubjectsPlaceholder extends StatelessWidget {
  const _EmptySubjectsPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        '등록된 과목이 없어요!\n[새 과목 추가] 버튼을 눌러보세요.',
        textAlign: TextAlign.center,
        style: AppTypography.bodyLarge.copyWith(color: AppColors.slate),
      ),
    );
  }
}

// =============================================================================
// Free Color Picker Bottom Sheet
// =============================================================================

class _FreeColorPickerBottomSheet extends StatefulWidget {
  final String title;
  final int initialColor;
  final ValueChanged<int> onColorSelected;

  const _FreeColorPickerBottomSheet({
    required this.title,
    required this.initialColor,
    required this.onColorSelected,
  });

  @override
  State<_FreeColorPickerBottomSheet> createState() =>
      _FreeColorPickerBottomSheetState();
}

class _FreeColorPickerBottomSheetState
    extends State<_FreeColorPickerBottomSheet> {
  late HSVColor _hsvColor;

  @override
  void initState() {
    super.initState();
    _hsvColor = HSVColor.fromColor(Color(widget.initialColor));
  }

  void _updateHue(double hue) {
    setState(() {
      _hsvColor = _hsvColor.withHue(hue);
    });
  }

  void _updateSaturation(double saturation) {
    setState(() {
      _hsvColor = _hsvColor.withSaturation(saturation);
    });
  }

  void _updateValue(double value) {
    setState(() {
      _hsvColor = _hsvColor.withValue(value);
    });
  }

  void _selectPresetColor(int colorValue) {
    setState(() {
      _hsvColor = HSVColor.fromColor(Color(colorValue));
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentColor = _hsvColor.toColor();

    return Container(
      padding: const EdgeInsets.all(24),
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
                Text(widget.title, style: AppTypography.headlineMedium),
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

            // Live Preview Card
            Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: currentColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.ink, width: 3),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Hue Slider (Color tone)
            const Text('색상 (무지개 바)', style: AppTypography.eyebrow),
            const SizedBox(height: 6),
            _HueSlider(
              hue: _hsvColor.hue,
              onChanged: _updateHue,
            ),
            const SizedBox(height: 14),

            // Saturation Slider (Richness / Vividness)
            const Text('채도 (선명도)', style: AppTypography.eyebrow),
            const SizedBox(height: 6),
            _SaturationSlider(
              hsvColor: _hsvColor,
              onChanged: _updateSaturation,
            ),
            const SizedBox(height: 14),

            // Value Slider (Brightness)
            const Text('밝기', style: AppTypography.eyebrow),
            const SizedBox(height: 6),
            _ValueSlider(
              hsvColor: _hsvColor,
              onChanged: _updateValue,
            ),
            const SizedBox(height: 18),

            // Quick Preset Colors
            const Text('빠른 색상 선택', style: AppTypography.eyebrow),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: SubjectViewModel.paletteColors.map((val) {
                return GestureDetector(
                  onTap: () => _selectPresetColor(val),
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: Color(val),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.ink, width: 1.5),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Apply Button
            SizedBox(
              width: double.infinity,
              child: BouncyButton(
                backgroundColor: AppColors.ink,
                foregroundColor: AppColors.surface,
                padding: const EdgeInsets.symmetric(vertical: 14),
                label: '이 색상으로 선택',
                onTap: () => widget.onColorSelected(currentColor.toARGB32()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HueSlider extends StatelessWidget {
  final double hue;
  final ValueChanged<double> onChanged;

  const _HueSlider({required this.hue, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.ink, width: 2),
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFF0000),
            Color(0xFFFFFF00),
            Color(0xFF00FF00),
            Color(0xFF00FFFF),
            Color(0xFF0000FF),
            Color(0xFFFF00FF),
            Color(0xFFFF0000),
          ],
        ),
      ),
      child: SliderTheme(
        data: SliderTheme.of(context).copyWith(
          trackHeight: 0,
          thumbShape: const RoundSliderThumbShape(
            enabledThumbRadius: 12,
            elevation: 3,
          ),
          thumbColor: AppColors.surface,
          overlayColor: Colors.transparent,
        ),
        child: Slider(
          value: hue,
          min: 0.0,
          max: 360.0,
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _SaturationSlider extends StatelessWidget {
  final HSVColor hsvColor;
  final ValueChanged<double> onChanged;

  const _SaturationSlider({
    required this.hsvColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final startColor = hsvColor.withSaturation(0.0).toColor();
    final endColor = hsvColor.withSaturation(1.0).toColor();

    return Container(
      height: 36,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.ink, width: 2),
        gradient: LinearGradient(colors: [startColor, endColor]),
      ),
      child: SliderTheme(
        data: SliderTheme.of(context).copyWith(
          trackHeight: 0,
          thumbShape: const RoundSliderThumbShape(
            enabledThumbRadius: 12,
            elevation: 3,
          ),
          thumbColor: AppColors.surface,
          overlayColor: Colors.transparent,
        ),
        child: Slider(
          value: hsvColor.saturation,
          min: 0.0,
          max: 1.0,
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _ValueSlider extends StatelessWidget {
  final HSVColor hsvColor;
  final ValueChanged<double> onChanged;

  const _ValueSlider({
    required this.hsvColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final startColor = hsvColor.withValue(0.15).toColor();
    final endColor = hsvColor.withValue(1.0).toColor();

    return Container(
      height: 36,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.ink, width: 2),
        gradient: LinearGradient(colors: [startColor, endColor]),
      ),
      child: SliderTheme(
        data: SliderTheme.of(context).copyWith(
          trackHeight: 0,
          thumbShape: const RoundSliderThumbShape(
            enabledThumbRadius: 12,
            elevation: 3,
          ),
          thumbColor: AppColors.surface,
          overlayColor: Colors.transparent,
        ),
        child: Slider(
          value: hsvColor.value.clamp(0.15, 1.0),
          min: 0.15,
          max: 1.0,
          onChanged: onChanged,
        ),
      ),
    );
  }
}

// =============================================================================
// Subject Add / Edit Modal Sheet
// =============================================================================

class _SubjectEditModal extends StatefulWidget {
  final Subject? subject;

  const _SubjectEditModal({this.subject});

  static Future<void> show(BuildContext context, {Subject? subject}) {
    final viewModel = context.read<SubjectViewModel>();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: viewModel,
        child: _SubjectEditModal(subject: subject),
      ),
    );
  }

  @override
  State<_SubjectEditModal> createState() => _SubjectEditModalState();
}

class _SubjectEditModalState extends State<_SubjectEditModal> {
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

  void _pickCustomColor() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FreeColorPickerBottomSheet(
        title: '과목 색상 선택',
        initialColor: _selectedColor,
        onColorSelected: (newColor) {
          setState(() {
            _selectedColor = newColor;
          });
          Navigator.of(context).pop();
        },
      ),
    );
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
            const SizedBox(height: 16),
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
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('과목 색상', style: AppTypography.eyebrow),
                GestureDetector(
                  onTap: _pickCustomColor,
                  child: Text(
                    '직접 색상 선택 >',
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.oceanSoft,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                GestureDetector(
                  onTap: _pickCustomColor,
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Color(_selectedColor),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.ink, width: 3),
                    ),
                    child: const Icon(
                      Icons.colorize_rounded,
                      color: AppColors.ink,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: SubjectViewModel.paletteColors.map((colorValue) {
                      final isSelected = _selectedColor == colorValue;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedColor = colorValue;
                          });
                        },
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Color(colorValue),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.ink,
                              width: isSelected ? 3 : 1.5,
                            ),
                          ),
                          child: isSelected
                              ? const Icon(
                                  Icons.check_rounded,
                                  color: AppColors.ink,
                                  size: 20,
                                )
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
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

// =============================================================================
// Bottom Navigation Bar
// =============================================================================

class _ManagementBottomBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTapTab;

  const _ManagementBottomBar({
    required this.currentIndex,
    required this.onTapTab,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(40, 0, 40, 16),
        height: 64,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: AppColors.ink, width: 2),
        ),
        child: Row(
          children: [
            _ManagementBottomNavItem(
              icon: Icons.checklist_rounded,
              label: '과제',
              isSelected: currentIndex == 0,
              onTap: () => onTapTab(0),
            ),
            _ManagementBottomNavItem(
              icon: Icons.menu_book_rounded,
              label: '과목',
              isSelected: currentIndex == 1,
              onTap: () => onTapTab(1),
            ),
          ],
        ),
      ),
    );
  }
}

class _ManagementBottomNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ManagementBottomNavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.ink : AppColors.slate,
              size: 26,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTypography.bodyMedium.copyWith(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                color: isSelected ? AppColors.ink : AppColors.slate,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
