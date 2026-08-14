import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared/shared.dart';

import '../main.dart'
    show modelName, systemPrompt, titleModelName, titleSystemPrompt;
import '../models/subject.dart';
import '../models/task.dart';
import '../services/chat/firestore_chat_repository.dart';
import '../services/llm/gemini_provider.dart';
import '../services/llm/provider_manager.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../viewmodels/calendar_viewmodel.dart';
import '../viewmodels/chat_viewmodel.dart';
import '../viewmodels/home_viewmodel.dart';
import '../viewmodels/subject_viewmodel.dart';
import '../widgets/pulse_loader.dart';
import '../widgets/task_add_edit_sheet.dart';
import 'chat_view.dart';
import 'settings_view.dart';

/// Calendar view dividing the screen into top-half calendar and bottom-half tasks.
class CalendarView extends StatelessWidget {
  const CalendarView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            _CalendarTopHeader(),
            Expanded(
              child: _CalendarContentLayout(),
            ),
          ],
        ),
      ),
    );
  }
}

/// Top header bar for Calendar view.
class _CalendarTopHeader extends StatelessWidget {
  const _CalendarTopHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(
              Icons.settings_rounded,
              color: AppColors.ink,
              size: 30,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            onPressed: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const SettingsView()));
            },
          ),
          const Text(
            '캘린더',
            style: AppTypography.headlineMedium,
          ),
          const SizedBox(width: 44),
        ],
      ),
    );
  }
}

/// Main layout dividing top half (Calendar) and bottom half (Task list).
class _CalendarContentLayout extends StatelessWidget {
  const _CalendarContentLayout();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        _CalendarTopSection(),
        Divider(
          color: AppColors.ink,
          thickness: 2,
          height: 2,
        ),
        Expanded(
          child: _CalendarBottomSection(),
        ),
      ],
    );
  }
}

/// Top half of the screen containing Month navigation, Weekday row, and Calendar Grid.
class _CalendarTopSection extends StatelessWidget {
  const _CalendarTopSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _MonthNavigator(),
          SizedBox(height: 6),
          _WeekdayHeaderRow(),
          SizedBox(height: 4),
          _CalendarMonthGrid(),
        ],
      ),
    );
  }
}

/// Header for Month navigation with Prev/Next buttons and "오늘" shortcut.
class _MonthNavigator extends StatelessWidget {
  const _MonthNavigator();

  @override
  Widget build(BuildContext context) {
    final calendarVm = context.watch<CalendarViewModel>();
    final focused = calendarVm.focusedMonth;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(
              '${focused.year}년 ${focused.month}월',
              style: AppTypography.headlineMedium.copyWith(fontSize: 20),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => calendarVm.goToToday(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.sunriseYellow,
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: AppColors.ink, width: 1.5),
                ),
                child: Text(
                  '오늘',
                  style: AppTypography.bodyMedium.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
              ),
            ),
          ],
        ),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left_rounded, size: 28),
              color: AppColors.ink,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              onPressed: () => calendarVm.previousMonth(),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right_rounded, size: 28),
              color: AppColors.ink,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              onPressed: () => calendarVm.nextMonth(),
            ),
          ],
        ),
      ],
    );
  }
}

/// Weekday labels row (일 ~ 토).
class _WeekdayHeaderRow extends StatelessWidget {
  const _WeekdayHeaderRow();

  static const List<String> _weekdays = ['일', '월', '화', '수', '목', '금', '토'];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(7, (index) {
        final label = _weekdays[index];
        final textColor = index == 0
            ? AppColors.tangerine
            : (index == 6 ? AppColors.oceanSoft : AppColors.ink);

        return Expanded(
          child: Center(
            child: Text(
              label,
              style: AppTypography.bodyMedium.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: textColor,
              ),
            ),
          ),
        );
      }),
    );
  }
}

/// Grid displaying days of the focused month.
class _CalendarMonthGrid extends StatelessWidget {
  const _CalendarMonthGrid();

  @override
  Widget build(BuildContext context) {
    final calendarVm = context.watch<CalendarViewModel>();
    final homeVm = context.watch<HomeViewModel>();
    final subjectVm = context.watch<SubjectViewModel>();

    final focused = calendarVm.focusedMonth;
    final daysInMonth = DateTime(focused.year, focused.month + 1, 0).day;
    final firstWeekday = DateTime(focused.year, focused.month, 1).weekday;
    final leadingOffset = firstWeekday % 7; // Sunday start: 0 for Sun, 1 for Mon...
    final prevMonthDays = DateTime(focused.year, focused.month, 0).day;

    final totalCount = leadingOffset + daysInMonth;
    final trailingCount = (7 - (totalCount % 7)) % 7;
    final cellCount = totalCount + trailingCount;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1.1,
      ),
      itemCount: cellCount,
      itemBuilder: (context, index) {
        final cellDate = _calculateCellDate(
          index,
          leadingOffset,
          daysInMonth,
          prevMonthDays,
          focused,
        );
        final isCurrentMonth = index >= leadingOffset && index < totalCount;
        final isSelected = calendarVm.isSameDay(cellDate, calendarVm.selectedDate);
        final isToday = calendarVm.isSameDay(cellDate, DateTime.now());
        final tasksForDay = calendarVm.getTasksForDate(homeVm.tasks, cellDate);

        return _CalendarDayCell(
          date: cellDate,
          isCurrentMonth: isCurrentMonth,
          isSelected: isSelected,
          isToday: isToday,
          tasks: tasksForDay,
          subjectVm: subjectVm,
          onTap: () => calendarVm.selectDate(cellDate),
        );
      },
    );
  }

  DateTime _calculateCellDate(
    int index,
    int leadingOffset,
    int daysInMonth,
    int prevMonthDays,
    DateTime focused,
  ) {
    if (index < leadingOffset) {
      final day = prevMonthDays - leadingOffset + index + 1;
      return DateTime(focused.year, focused.month - 1, day);
    } else if (index >= leadingOffset + daysInMonth) {
      final day = index - (leadingOffset + daysInMonth) + 1;
      return DateTime(focused.year, focused.month + 1, day);
    } else {
      final day = index - leadingOffset + 1;
      return DateTime(focused.year, focused.month, day);
    }
  }
}

/// Single date cell in the calendar grid.
class _CalendarDayCell extends StatelessWidget {
  final DateTime date;
  final bool isCurrentMonth;
  final bool isSelected;
  final bool isToday;
  final List<Task> tasks;
  final SubjectViewModel subjectVm;
  final VoidCallback onTap;

  const _CalendarDayCell({
    required this.date,
    required this.isCurrentMonth,
    required this.isSelected,
    required this.isToday,
    required this.tasks,
    required this.subjectVm,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _DateNumberBadge(
            day: date.day,
            isSelected: isSelected,
            isToday: isToday,
            isCurrentMonth: isCurrentMonth,
          ),
          const SizedBox(height: 2),
          _DeadlineDotsRow(
            tasks: tasks,
            subjectVm: subjectVm,
          ),
        ],
      ),
    );
  }
}

/// Badge circle or pill around the day number.
class _DateNumberBadge extends StatelessWidget {
  final int day;
  final bool isSelected;
  final bool isToday;
  final bool isCurrentMonth;

  const _DateNumberBadge({
    required this.day,
    required this.isSelected,
    required this.isToday,
    required this.isCurrentMonth,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isSelected
        ? AppColors.surface
        : (!isCurrentMonth
            ? AppColors.border
            : (isToday ? AppColors.oceanSoft : AppColors.ink));

    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.ink
            : (isToday ? const Color(0xFFE8F0FE) : Colors.transparent),
        shape: BoxShape.circle,
        border: isSelected
            ? Border.all(color: AppColors.ink, width: 1.5)
            : (isToday && !isSelected
                ? Border.all(color: AppColors.oceanSoft, width: 1.5)
                : null),
      ),
      alignment: Alignment.center,
      child: Text(
        '$day',
        style: TextStyle(
          fontSize: 14,
          fontWeight: isSelected || isToday ? FontWeight.w800 : FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}

/// Row of colored circles representing task deadlines and their subject colors.
class _DeadlineDotsRow extends StatelessWidget {
  final List<Task> tasks;
  final SubjectViewModel subjectVm;

  const _DeadlineDotsRow({
    required this.tasks,
    required this.subjectVm,
  });

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) {
      return const SizedBox(height: 6);
    }

    final displayTasks = tasks.take(4).toList();

    return SizedBox(
      height: 6,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (final task in displayTasks) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1),
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(subjectVm.getColorForSubject(task.subjectId)),
                  border: Border.all(color: AppColors.ink, width: 0.8),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Bottom half of the screen showing tasks for the selected date, followed by undated tasks.
class _CalendarBottomSection extends StatelessWidget {
  const _CalendarBottomSection();

  @override
  Widget build(BuildContext context) {
    final calendarVm = context.watch<CalendarViewModel>();
    final homeVm = context.watch<HomeViewModel>();

    if (homeVm.isLoading) {
      return const Center(child: PulseLoader(size: 36));
    }

    final selectedTasks = calendarVm.getTasksForSelectedDate(homeVm.tasks);
    final undatedTasks = calendarVm.getUndatedTasks(homeVm.tasks);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 90),
      children: [
        _SelectedDateHeader(
          selectedDate: calendarVm.selectedDate,
          taskCount: selectedTasks.length,
        ),
        const SizedBox(height: 12),
        if (selectedTasks.isEmpty)
          const _EmptyDateTaskNotice()
        else
          for (final task in selectedTasks) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _CalendarTaskRowTile(task: task),
            ),
          ],
        const SizedBox(height: 16),
        _UndatedSectionDivider(count: undatedTasks.length),
        const SizedBox(height: 12),
        if (undatedTasks.isEmpty)
          const _EmptyUndatedNotice()
        else
          for (final task in undatedTasks) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _CalendarTaskRowTile(task: task),
            ),
          ],
      ],
    );
  }
}

/// Header indicating the currently selected date.
class _SelectedDateHeader extends StatelessWidget {
  final DateTime selectedDate;
  final int taskCount;

  const _SelectedDateHeader({
    required this.selectedDate,
    required this.taskCount,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isToday = selectedDate.year == now.year &&
        selectedDate.month == now.month &&
        selectedDate.day == now.day;

    final dateLabel =
        '${selectedDate.month}월 ${selectedDate.day}일${isToday ? ' (오늘)' : ''} 마감 과제';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          dateLabel,
          style: AppTypography.headlineMedium.copyWith(fontSize: 19),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: taskCount > 0 ? AppColors.marigold : AppColors.surface,
            borderRadius: BorderRadius.circular(100),
            border: Border.all(color: AppColors.ink, width: 1.5),
          ),
          child: Text(
            '$taskCount개',
            style: AppTypography.bodyMedium.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
        ),
      ],
    );
  }
}

/// Notice shown when there are no tasks due on the selected date.
class _EmptyDateTaskNotice extends StatelessWidget {
  const _EmptyDateTaskNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Center(
        child: Text(
          '이 날짜에 마감인 과제가 없어요!',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.slate,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// Divider and label separating dated tasks from undated tasks.
class _UndatedSectionDivider extends StatelessWidget {
  final int count;

  const _UndatedSectionDivider({required this.count});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Divider(
                color: AppColors.border,
                thickness: 1.5,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                '마감일 미지정 과제 ($count)',
                style: AppTypography.bodyMedium.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.slate,
                ),
              ),
            ),
            const Expanded(
              child: Divider(
                color: AppColors.border,
                thickness: 1.5,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Notice shown when there are no undated tasks.
class _EmptyUndatedNotice extends StatelessWidget {
  const _EmptyUndatedNotice();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Text(
          '마감일이 지정되지 않은 과제가 없어요.',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.border,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

/// Individual Task item tile rendered in the Calendar task list.
class _CalendarTaskRowTile extends StatelessWidget {
  final Task task;

  const _CalendarTaskRowTile({required this.task});

  @override
  Widget build(BuildContext context) {
    final homeViewModel = context.read<HomeViewModel>();
    final subjectViewModel = context.watch<SubjectViewModel>();
    final subject = subjectViewModel.getSubjectById(task.subjectId);
    final isOverdue = task.isOverdue;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPress: () => _showEditSheet(context),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isOverdue ? AppColors.overdueRed : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.ink, width: 2),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TaskCheckbox(
              isCompleted: task.isCompleted,
              onTap: () => homeViewModel.toggleTask(task.id),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _TaskDetailContent(
                task: task,
                subject: subject,
                onToggleSubtask: (subtaskId) =>
                    homeViewModel.toggleSubtask(task.id, subtaskId),
              ),
            ),
            const SizedBox(width: 6),
            _ChatNavButton(
              onTap: () => _navigateToChat(context, task),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditSheet(BuildContext context) {
    final homeViewModel = context.read<HomeViewModel>();
    final subjectViewModel = context.read<SubjectViewModel>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: homeViewModel),
          ChangeNotifierProvider.value(value: subjectViewModel),
        ],
        child: TaskAddEditSheet(
          task: task,
          onSave: (title, dueDate, subtasks, subjectId) {
            homeViewModel.editTask(
              task,
              title,
              dueDate,
              subtasks,
              subjectId,
            );
          },
        ),
      ),
    );
  }

  void _navigateToChat(BuildContext context, Task task) {
    final authProvider = context.read<BaseAuthProvider>();
    final userId = authProvider.currentUid ?? '';

    final providerManager = ProviderManager(
      provider: GeminiProvider(
        modelName: modelName,
        systemPrompt: systemPrompt,
      ),
      titleProvider: GeminiProvider(
        modelName: titleModelName,
        systemPrompt: titleSystemPrompt,
      ),
    );

    final chatVm = ChatViewModel(
      providerManager: providerManager,
      repository: FirestoreChatRepository(),
      authProvider: authProvider,
      task: task,
      userId: userId,
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: chatVm,
          child: ChatView(task: task),
        ),
      ),
    );
  }
}

class _TaskCheckbox extends StatelessWidget {
  final bool isCompleted;
  final VoidCallback onTap;

  const _TaskCheckbox({
    required this.isCompleted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Icon(
          isCompleted
              ? Icons.check_box_rounded
              : Icons.check_box_outline_blank_rounded,
          color: AppColors.ink,
          size: 26,
        ),
      ),
    );
  }
}

class _TaskDetailContent extends StatelessWidget {
  final Task task;
  final Subject? subject;
  final ValueChanged<String> onToggleSubtask;

  const _TaskDetailContent({
    required this.task,
    required this.subject,
    required this.onToggleSubtask,
  });

  @override
  Widget build(BuildContext context) {
    final dueDate = task.dueDate;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (subject case final s?) ...[
          Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Color(s.colorValue),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.ink, width: 1.2),
            ),
            child: Text(
              s.name,
              style: AppTypography.bodyMedium.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
          ),
        ],
        Text(
          task.title,
          style: AppTypography.bodyLarge.copyWith(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            decoration: task.isCompleted ? TextDecoration.lineThrough : null,
            color: task.isCompleted ? AppColors.slate : AppColors.ink,
          ),
        ),
        if (task.isOverdue && dueDate != null) ...[
          const SizedBox(height: 2),
          Text(
            '(마감기한 지남: ${dueDate.month}월 ${dueDate.day}일)',
            style: AppTypography.bodyMedium.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.overdueText,
            ),
          ),
        ],
        if (task.subtasks.isNotEmpty) ...[
          const SizedBox(height: 6),
          for (final st in task.subtasks) ...[
            GestureDetector(
              onTap: () => onToggleSubtask(st.id),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 1.5),
                child: Row(
                  children: [
                    Icon(
                      st.isCompleted
                          ? Icons.check_box_rounded
                          : Icons.check_box_outline_blank_rounded,
                      color: AppColors.ink,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        st.title,
                        style: AppTypography.bodyMedium.copyWith(
                          fontSize: 13,
                          decoration:
                              st.isCompleted ? TextDecoration.lineThrough : null,
                          color:
                              st.isCompleted ? AppColors.slate : AppColors.ink,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ],
    );
  }
}

class _ChatNavButton extends StatelessWidget {
  final VoidCallback onTap;

  const _ChatNavButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.bg,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: AppColors.ink, width: 1.2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '채팅',
              style: AppTypography.bodyMedium.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(width: 2),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.ink,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
