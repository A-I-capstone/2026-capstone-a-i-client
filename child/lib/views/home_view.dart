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
import '../services/subject/firestore_subject_repository.dart';
import '../services/task/firestore_task_repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../viewmodels/calendar_viewmodel.dart';
import '../viewmodels/chat_viewmodel.dart';
import '../viewmodels/home_viewmodel.dart';
import '../viewmodels/subject_viewmodel.dart';
import '../widgets/bouncy_button.dart';
import '../widgets/pulse_loader.dart';
import '../widgets/task_add_edit_sheet.dart';
import 'calendar_view.dart';
import 'chat_view.dart';
import 'settings_view.dart';

/// Main Home view for the child app based on task checklist & calendar.
class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<BaseAuthProvider>();
    final userId = authProvider.currentUid ?? '';

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => HomeViewModel(
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
        ChangeNotifierProvider(
          create: (_) => CalendarViewModel(),
        ),
      ],
      child: const _HomeViewContent(),
    );
  }
}

class _HomeViewContent extends StatefulWidget {
  const _HomeViewContent();

  @override
  State<_HomeViewContent> createState() => _HomeViewContentState();
}

class _HomeViewContentState extends State<_HomeViewContent> {
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
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        children: const [
          _TaskChecklistPage(),
          CalendarView(),
        ],
      ),
      bottomNavigationBar: _HomeBottomBar(
        currentIndex: _currentIndex,
        onTapTab: _onTabTapped,
      ),
    );
  }
}

/// The Task Checklist view (First tab of Home).
class _TaskChecklistPage extends StatelessWidget {
  const _TaskChecklistPage();

  @override
  Widget build(BuildContext context) {
    return const SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            sliver: SliverList(
              delegate: SliverChildListDelegate.fixed([
                _HomeHeader(),
                SizedBox(height: 16),
                _UrgentTaskAlert(),
                SizedBox(height: 16),
                _TaskSummarySection(),
                SizedBox(height: 20),
                _TaskControlBar(),
                SizedBox(height: 16),
              ]),
            ),
          ),
          _TaskListSection(),
          SliverToBoxAdapter(
            child: SizedBox(height: 90),
          ),
        ],
      ),
    );
  }
}

/// Top header bar containing Settings button and "과제 관리" placeholder button.
class _HomeHeader extends StatelessWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(
            Icons.settings_rounded,
            color: AppColors.ink,
            size: 32,
          ),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          onPressed: () {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const SettingsView()));
          },
        ),
        BouncyButton(
          backgroundColor: AppColors.ink,
          foregroundColor: AppColors.surface,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          label: '과제 관리',
          icon: const Icon(
            Icons.view_headline_rounded,
            color: AppColors.surface,
            size: 22,
          ),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('과제 관리 기능은 준비 중이에요!'),
                duration: Duration(seconds: 2),
              ),
            );
          },
        ),
      ],
    );
  }
}

/// Urgent task alert banner.
class _UrgentTaskAlert extends StatelessWidget {
  const _UrgentTaskAlert();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<HomeViewModel>();

    if (!viewModel.hasUrgentTask) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.overdueRed,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.ink, width: 2),
      ),
      child: Column(
        children: [
          Align(
            alignment: Alignment.topRight,
            child: GestureDetector(
              onTap: () => context.read<HomeViewModel>().dismissUrgentAlert(),
              child: const Icon(
                Icons.close_rounded,
                color: AppColors.ink,
                size: 24,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            viewModel.urgentTaskMessage,
            textAlign: TextAlign.center,
            style: AppTypography.bodyLarge.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

/// Task summary counter text wrapped in a dismissible card.
class _TaskSummarySection extends StatelessWidget {
  const _TaskSummarySection();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<HomeViewModel>();

    if (!viewModel.isSummaryVisible) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.ink, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.topRight,
            child: GestureDetector(
              onTap: () => context.read<HomeViewModel>().dismissSummary(),
              child: const Icon(
                Icons.close_rounded,
                color: AppColors.ink,
                size: 24,
              ),
            ),
          ),
          const SizedBox(height: 2),
          const Text('✦', style: TextStyle(fontSize: 22, color: AppColors.ink)),
          const SizedBox(height: 6),
          Text(
            '${viewModel.remainingTasksCount}개의 과제가 남아 있어요.\n'
            '${viewModel.dueThisWeekCount}개의 과제의 마감기한이 이번 주 안이에요.',
            style: AppTypography.headlineMedium.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

/// Controls bar with "+ 추가" button and compact sort button.
class _TaskControlBar extends StatelessWidget {
  const _TaskControlBar();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<HomeViewModel>();
    final subjectViewModel = context.read<SubjectViewModel>();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            '과제 목록',
            style: AppTypography.headlineMedium.copyWith(fontSize: 22),
          ),
        ),
        Row(
          children: [
            _AddTaskButton(
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => MultiProvider(
                    providers: [
                      ChangeNotifierProvider.value(value: viewModel),
                      ChangeNotifierProvider.value(value: subjectViewModel),
                    ],
                    child: TaskAddEditSheet(
                      onSave: (title, dueDate, subtasks, subjectId) {
                        viewModel.addTask(title, dueDate, subtasks, subjectId);
                      },
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 6),
            _SortMenuButton(
              selectedOption: viewModel.sortOption,
              onSelected: (option) => viewModel.setSortOption(option),
            ),
          ],
        ),
      ],
    );
  }
}

class _AddTaskButton extends StatelessWidget {
  final VoidCallback onTap;

  const _AddTaskButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: AppColors.ink, width: 2),
        ),
        child: Text(
          '+ 추가',
          style: AppTypography.bodyMedium.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
      ),
    );
  }
}

class _SortMenuButton extends StatelessWidget {
  final TaskSortOption selectedOption;
  final ValueChanged<TaskSortOption> onSelected;

  const _SortMenuButton({
    required this.selectedOption,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        cardColor: AppColors.surface,
      ),
      child: PopupMenuButton<TaskSortOption>(
        initialValue: selectedOption,
        icon: const Icon(
          Icons.swap_vert_rounded,
          color: AppColors.ink,
          size: 26,
        ),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.ink, width: 2),
        ),
        onSelected: onSelected,
        itemBuilder: (context) => const [
          PopupMenuItem(
            value: TaskSortOption.dueDate,
            child: Text('마감 기한 순', style: AppTypography.bodyMedium),
          ),
          PopupMenuItem(
            value: TaskSortOption.createdDate,
            child: Text('최신 생성 순', style: AppTypography.bodyMedium),
          ),
        ],
      ),
    );
  }
}

/// List section rendering tasks directly on the background without card containers.
class _TaskListSection extends StatelessWidget {
  const _TaskListSection();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<HomeViewModel>();
    final tasks = viewModel.tasks;

    if (viewModel.isLoading) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Center(child: PulseLoader(size: 36)),
        ),
      );
    }

    if (tasks.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Center(
            child: Text(
              '등록된 과제가 없어요!\n[+ 추가] 버튼을 눌러보세요.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyLarge.copyWith(color: AppColors.slate),
            ),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final task = tasks[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: _TaskRowTile(task: task),
          );
        }, childCount: tasks.length),
      ),
    );
  }
}

/// Single Task item rendered without background card, with subject chip, checkbox,
/// deadline label, and "채팅으로 이동 >" button.
class _TaskRowTile extends StatelessWidget {
  final Task task;

  const _TaskRowTile({required this.task});

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
        padding: EdgeInsets.all(isOverdue ? 12 : 0),
        decoration: BoxDecoration(
          color: isOverdue ? AppColors.overdueRed : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: isOverdue
              ? Border.all(color: AppColors.ink, width: 2)
              : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TaskCheckbox(
              isCompleted: task.isCompleted,
              onTap: () => homeViewModel.toggleTask(task.id),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _TaskContent(
                task: task,
                subject: subject,
                onToggleSubtask: (subtaskId) =>
                    homeViewModel.toggleSubtask(task.id, subtaskId),
              ),
            ),
            const SizedBox(width: 8),
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
          size: 30,
        ),
      ),
    );
  }
}

class _TaskContent extends StatelessWidget {
  final Task task;
  final Subject? subject;
  final ValueChanged<String> onToggleSubtask;

  const _TaskContent({
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
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: Color(s.colorValue),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.ink, width: 1.5),
            ),
            child: Text(
              s.name,
              style: AppTypography.bodyMedium.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
          ),
        ],
        Text(
          task.title,
          style: AppTypography.bodyLarge.copyWith(
            fontSize: 19,
            fontWeight: FontWeight.w700,
            decoration: task.isCompleted ? TextDecoration.lineThrough : null,
            color: task.isCompleted ? AppColors.slate : AppColors.ink,
          ),
        ),
        if (dueDate != null) ...[
          const SizedBox(height: 3),
          Text(
            task.isOverdue
                ? '(마감기한 지남: ${dueDate.month}월 ${dueDate.day}일)'
                : task.isDueToday
                    ? '(마감기한: 오늘)'
                    : '(마감기한: ${dueDate.month}월 ${dueDate.day}일)',
            style: AppTypography.bodyMedium.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: task.isOverdue
                  ? AppColors.overdueText
                  : task.isDueToday
                      ? AppColors.tangerine
                      : AppColors.slate,
            ),
          ),
        ],
        if (task.subtasks.isNotEmpty) ...[
          const SizedBox(height: 8),
          for (final st in task.subtasks) ...[
            GestureDetector(
              onTap: () => onToggleSubtask(st.id),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Icon(
                      st.isCompleted
                          ? Icons.check_box_rounded
                          : Icons.check_box_outline_blank_rounded,
                      color: AppColors.ink,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        st.title,
                        style: AppTypography.bodyMedium.copyWith(
                          fontSize: 14,
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: AppColors.ink, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '채팅으로 이동',
              style: AppTypography.bodyMedium.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(width: 2),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.ink,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

/// Floating iOS-style bottom navigation bar with animated tab switching.
class _HomeBottomBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTapTab;

  const _HomeBottomBar({
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
            _BottomNavItem(
              icon: Icons.check_circle_outline_rounded,
              label: '과제',
              isSelected: currentIndex == 0,
              onTap: () => onTapTab(0),
            ),
            _BottomNavItem(
              icon: Icons.calendar_month_rounded,
              label: '캘린더',
              isSelected: currentIndex == 1,
              onTap: () => onTapTab(1),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _BottomNavItem({
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
