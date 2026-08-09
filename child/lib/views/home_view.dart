import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared/shared.dart';

import '../models/task.dart';
import '../services/chat/firestore_chat_repository.dart';
import '../services/llm/gemini_provider.dart';
import '../services/llm/provider_manager.dart';
import '../services/task/firestore_task_repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../viewmodels/chat_viewmodel.dart';
import '../viewmodels/home_viewmodel.dart';
import '../widgets/bouncy_button.dart';
import '../widgets/pulse_loader.dart';
import '../widgets/task_add_edit_sheet.dart';
import 'chat_view.dart';
import 'settings_view.dart';

// TODO: 과제 -> 채팅으로 들어갔을 때 프롬프트에 과제 내용이 반영되도록 하기
// TODO: 부모 앱에서 일단 연동화면 들어가면 못 나가는 버그? 고치기

/// Main Home view for the child app based on task checklist & learning assistance.
class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<BaseAuthProvider>();
    final userId = authProvider.currentUid ?? '';

    return ChangeNotifierProvider(
      create: (_) => HomeViewModel(
        taskRepository: FirestoreTaskRepository(),
        userId: userId,
      ),
      child: const _HomeViewContent(),
    );
  }
}

class _HomeViewContent extends StatelessWidget {
  const _HomeViewContent();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: const SafeArea(
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
          ],
        ),
      ),
      bottomNavigationBar: const _HomeBottomBar(),
    );
  }
}

/// Top header bar containing Settings button and "새 과제 추가" button.
class _HomeHeader extends StatelessWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        BouncyButton(
          isCircle: true,
          backgroundColor: AppColors.sunriseYellow,
          padding: const EdgeInsets.all(10),
          icon: const Icon(
            Icons.settings_rounded,
            color: AppColors.ink,
            size: 32,
          ),
          onTap: () {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const SettingsView()));
          },
        ),
        BouncyButton(
          backgroundColor: AppColors.ink,
          foregroundColor: AppColors.surface,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          label: '새 과제 추가',
          icon: const Icon(
            Icons.add_rounded,
            color: AppColors.surface,
            size: 24,
          ),
          onTap: () {
            TaskAddEditSheet.show(
              context,
              onSave: (title, dueDate, subtasks) {
                context.read<HomeViewModel>().addTask(title, dueDate, subtasks);
              },
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
        color: const Color(0xFFFADBD8),
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

/// Controls bar with sort filter options.
class _TaskControlBar extends StatelessWidget {
  const _TaskControlBar();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<HomeViewModel>();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 6),
          child: Text(
            '과제 목록',
            style: AppTypography.headlineMedium.copyWith(fontSize: 22),
          ),
        ),
        DropdownButton<TaskSortOption>(
          value: viewModel.sortOption,
          underline: const SizedBox.shrink(),
          icon: const Icon(Icons.filter_list_rounded, color: AppColors.ink),
          items: const [
            DropdownMenuItem(
              value: TaskSortOption.dueDate,
              child: Text('마감 기한 순', style: AppTypography.bodyMedium),
            ),
            DropdownMenuItem(
              value: TaskSortOption.createdDate,
              child: Text('최신 생성 순', style: AppTypography.bodyMedium),
            ),
          ],
          onChanged: (val) {
            if (val != null) {
              viewModel.setSortOption(val);
            }
          },
        ),
      ],
    );
  }
}

/// List section rendering tasks as a checklist.
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
              '등록된 과제가 없어요!\n위의 [새 과제 추가] 버튼을 눌러보세요.',
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
            padding: const EdgeInsets.only(bottom: 12),
            child: _TaskRowTile(task: task),
          );
        }, childCount: tasks.length),
      ),
    );
  }
}

/// Single Task item represented as a list item with subtask checklist.
class _TaskRowTile extends StatelessWidget {
  final Task task;

  const _TaskRowTile({required this.task});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.read<HomeViewModel>();

    return Container(
      decoration: BoxDecoration(
        color: task.isDueToday ? const Color(0xFFFFF3CD) : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.ink, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main task row
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => viewModel.toggleTask(task.id),
                  child: Icon(
                    task.isCompleted
                        ? Icons.check_box_rounded
                        : Icons.check_box_outline_blank_rounded,
                    color: AppColors.ink,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: AppTypography.bodyLarge.copyWith(
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                          decoration: task.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                          color: task.isCompleted
                              ? AppColors.slate
                              : AppColors.ink,
                        ),
                      ),
                      if (task.dueDate != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          task.isDueToday
                              ? '(마감기한: 오늘)'
                              : '(마감기한: ${task.dueDate!.month}월 ${task.dueDate!.day}일)',
                          style: AppTypography.bodyMedium.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: task.isDueToday
                                ? AppColors.tangerine
                                : AppColors.slate,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: AppColors.clay,
                    size: 22,
                  ),
                  onPressed: () => viewModel.deleteTask(task.id),
                ),
              ],
            ),
          ),

          // Subtasks list if any
          if (task.subtasks.isNotEmpty) ...[
            const Divider(color: AppColors.border, height: 1, thickness: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 12, 8),
              child: Column(
                children: [
                  for (final st in task.subtasks) ...[
                    GestureDetector(
                      onTap: () => viewModel.toggleSubtask(task.id, st.id),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Icon(
                              st.isCompleted
                                  ? Icons.check_box_rounded
                                  : Icons.check_box_outline_blank_rounded,
                              color: AppColors.ink,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                st.title,
                                style: AppTypography.bodyMedium.copyWith(
                                  decoration: st.isCompleted
                                      ? TextDecoration.lineThrough
                                      : null,
                                  color: st.isCompleted
                                      ? AppColors.slate
                                      : AppColors.ink,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],

          // Chat room navigation button
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.ink, width: 1.5)),
            ),
            child: InkWell(
              onTap: () => _navigateToChat(context, task),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(14),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.chat_bubble_outline_rounded,
                      color: AppColors.ink,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'AI 학습 도움 받기',
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.ink,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToChat(BuildContext context, Task task) {
    final authProvider = context.read<BaseAuthProvider>();
    final userId = authProvider.currentUid ?? '';

    // Create providerManager on demand
    final providerManager = ProviderManager(
      provider: GeminiProvider(
        modelName: 'gemini-3.6-flash',
        systemPrompt: '너는 초등학생을 돕는 친절하고 명확한 AI 학습 도우미야.',
      ),
      titleProvider: GeminiProvider(
        modelName: 'gemini-3.5-flash-lite',
        systemPrompt: '제목 요약 도우미',
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

/// Bottom navigation bar.
class _HomeBottomBar extends StatelessWidget {
  const _HomeBottomBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.ink, width: 2)),
      ),
      child: const SafeArea(
        child: Row(
          children: [
            _BottomNavItem(
              icon: Icons.check_circle_outline_rounded,
              label: '과제',
              isSelected: true,
            ),
            _BottomNavItem(
              icon: Icons.person_outline_rounded,
              label: '프로필',
              isSelected: false,
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

  const _BottomNavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 60,
        child: Center(
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
      ),
    );
  }
}
