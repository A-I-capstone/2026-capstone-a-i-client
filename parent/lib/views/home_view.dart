import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/task.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../viewmodels/home_viewmodel.dart';
import '../widgets/bouncy_button.dart';

import 'parent_settings_view.dart';
import 'report_view.dart';


/// Parent App Main Home View.
///
/// Layout (mirrors mockup):
///   1. Header row  — settings icon (left), child name (center), back icon (right)
///   2. 부모 리포트 — prominent CTA button (placeholder)
///   3. Task list   — same design language as child app, read-only
class HomeView extends StatelessWidget {
  final String childUid;
  final String? childName;

  const HomeView({
    super.key,
    required this.childUid,
    this.childName,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => HomeViewModel(childUid: childUid),
      child: _HomeContent(childName: childName),
    );
  }
}

class _HomeContent extends StatelessWidget {
  final String? childName;

  const _HomeContent({this.childName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              sliver: SliverList(
                delegate: SliverChildListDelegate.fixed([
                  _HomeHeader(childName: childName),
                  const SizedBox(height: 20),
                  const _ReportButton(),
                  const SizedBox(height: 24),
                  const _TaskControlBar(),
                  const SizedBox(height: 12),
                ]),
              ),
            ),
            const _TaskListSection(),
            // Extra bottom padding so last card clears the screen.
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Header
// ─────────────────────────────────────────────

/// Top bar: settings icon on the left, child name in center, back icon on the right.
class _HomeHeader extends StatelessWidget {
  final String? childName;

  const _HomeHeader({this.childName});

  @override
  Widget build(BuildContext context) {
    final parentUid = context.watch<HomeViewModel>().childUid; // fallback or pass parentUid

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        BouncyButton(
          isCircle: true,
          backgroundColor: AppColors.surface,
          padding: const EdgeInsets.all(10),
          icon: const Icon(
            Icons.settings_rounded,
            color: AppColors.ink,
            size: 26,
          ),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ParentSettingsView(parentUid: parentUid),
              ),
            );
          },
        ),
        if (childName != null && childName!.isNotEmpty)
          Expanded(
            child: Text(
              '$childName의 과제',
              textAlign: TextAlign.center,
              style: AppTypography.headlineMedium.copyWith(fontSize: 20),
            ),
          )
        else
          const SizedBox.shrink(),
        BouncyButton(
          isCircle: true,
          backgroundColor: AppColors.sunriseYellow,
          padding: const EdgeInsets.all(10),
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: AppColors.ink,
            size: 26,
          ),
          onTap: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          },
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// 부모 리포트 Button (placeholder)
// ─────────────────────────────────────────────

/// Prominent "부모 리포트" CTA — navigates to the Report screen.
class _ReportButton extends StatelessWidget {
  const _ReportButton();

  @override
  Widget build(BuildContext context) {
    final vm = context.read<HomeViewModel>();
    return GestureDetector(
      onTap: () {
        // childName is passed as a constructor param on _HomeContent,
        // but we access it here through the widget tree via context.
        final childName =
            (context.findAncestorWidgetOfExactType<_HomeContent>()?.childName) ?? '';
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ReportView(
              childUid: vm.childUid,
              childName: childName,
            ),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.sunriseYellow, AppColors.marigold],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.ink, width: 2.5),
          boxShadow: const [
            BoxShadow(
              color: Color(0x22000000),
              blurRadius: 0,
              offset: Offset(4, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: AppColors.ink,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.bar_chart_rounded,
                color: AppColors.sunriseYellow,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '부모 리포트',
                    style: AppTypography.headlineMedium.copyWith(
                      fontSize: 24,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '아이의 학습 현황을 확인해 보세요',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.ink,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.ink,
              size: 28,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Task Controls
// ─────────────────────────────────────────────

class _TaskControlBar extends StatelessWidget {
  const _TaskControlBar();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<HomeViewModel>();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 5),
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
            if (val != null) viewModel.setSortOption(val);
          },
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Task List
// ─────────────────────────────────────────────

class _TaskListSection extends StatelessWidget {
  const _TaskListSection();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<HomeViewModel>();

    if (viewModel.isLoading) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Center(
            child: CircularProgressIndicator(
              color: AppColors.ink,
              strokeWidth: 3,
            ),
          ),
        ),
      );
    }

    final pending = viewModel.pendingTasks;
    final completed = viewModel.completedTasks;

    if (pending.isEmpty && completed.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Center(
            child: Text(
              '등록된 과제가 없어요!',
              textAlign: TextAlign.center,
              style: AppTypography.bodyLarge.copyWith(color: AppColors.slate),
            ),
          ),
        ),
      );
    }

    // Build item list: pending tasks first, then a "완료한 과제" section header,
    // then completed tasks.
    final items = <_ListItem>[
      for (final t in pending) _TaskItem(task: t),
      if (completed.isNotEmpty) _SectionHeaderItem('완료한 과제'),
      for (final t in completed) _TaskItem(task: t),
    ];

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final item = items[index];
            if (item is _SectionHeaderItem) {
              return _CompletedSectionHeader(label: item.label);
            }
            final taskItem = item as _TaskItem;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _TaskRowTile(task: taskItem.task),
            );
          },
          childCount: items.length,
        ),
      ),
    );
  }
}

// Simple sealed-style helper classes so the builder can distinguish rows.
abstract class _ListItem {}

class _TaskItem extends _ListItem {
  final Task task;
  _TaskItem({required this.task});
}

class _SectionHeaderItem extends _ListItem {
  final String label;
  _SectionHeaderItem(this.label);
}

class _CompletedSectionHeader extends StatelessWidget {
  final String label;

  const _CompletedSectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(5, 8, 0, 12),
      child: Text(
        label,
        style: AppTypography.headlineMedium.copyWith(fontSize: 22),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Task Tile — read-only, same design as child app
// ─────────────────────────────────────────────

class _TaskRowTile extends StatelessWidget {
  final Task task;

  const _TaskRowTile({required this.task});

  @override
  Widget build(BuildContext context) {
    // Urgent = due today + not completed → pink tint (same as child).
    final bool isUrgent = task.isDueToday && !task.isCompleted;
    final Color tileBg = isUrgent
        ? const Color(0xFFFADBD8)
        : task.isCompleted
            ? AppColors.surface
            : AppColors.surface;

    return Container(
      decoration: BoxDecoration(
        color: tileBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.ink, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TaskTileMain(task: task),
          if (task.subtasks.isNotEmpty) _TaskSubtaskList(task: task),
        ],
      ),
    );
  }
}

class _TaskTileMain extends StatelessWidget {
  final Task task;

  const _TaskTileMain({required this.task});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Row(
        children: [
          Icon(
            task.isCompleted
                ? Icons.check_box_rounded
                : Icons.check_box_outline_blank_rounded,
            color: task.isCompleted ? AppColors.slate : AppColors.ink,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(child: _TaskTileText(task: task)),
        ],
      ),
    );
  }
}

class _TaskTileText extends StatelessWidget {
  final Task task;

  const _TaskTileText({required this.task});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          task.title,
          style: AppTypography.bodyLarge.copyWith(
            fontSize: 19,
            fontWeight: FontWeight.w700,
            decoration:
                task.isCompleted ? TextDecoration.lineThrough : null,
            color: task.isCompleted ? AppColors.slate : AppColors.ink,
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
              color: task.isDueToday ? AppColors.tangerine : AppColors.slate,
            ),
          ),
        ],
      ],
    );
  }
}

class _TaskSubtaskList extends StatelessWidget {
  final Task task;

  const _TaskSubtaskList({required this.task});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Divider(color: AppColors.border, height: 1, thickness: 1),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 12, 8),
          child: Column(
            children: [
              for (final st in task.subtasks)
                Padding(
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
            ],
          ),
        ),
      ],
    );
  }
}
