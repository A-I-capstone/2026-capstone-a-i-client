import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../main.dart';
import '../models/task.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../viewmodels/report_viewmodel.dart';
import '../widgets/bouncy_button.dart';

/// Entry point for the Parent Report Screen.
///
/// Accepts [childUid] and [childName] from the calling widget and wires up
/// the [ReportViewModel] via [ChangeNotifierProvider].
class ReportView extends StatelessWidget {
  final String childUid;
  final String childName;

  const ReportView({
    super.key,
    required this.childUid,
    required this.childName,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ReportViewModel(
        childUid: childUid,
        childName: childName,
        modelName: modelName,
        systemPrompt: reportSystemPrompt,
      ),
      child: _ReportContent(childName: childName),
    );
  }
}

// ─────────────────────────────────────────────
// Root scaffold
// ─────────────────────────────────────────────

class _ReportContent extends StatelessWidget {
  final String childName;

  const _ReportContent({required this.childName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _ReportHeader(childName: childName)),
            const SliverToBoxAdapter(child: _PeriodSelector()),
            const SliverToBoxAdapter(child: _SectionDivider()),
            const SliverToBoxAdapter(child: _AiSummarySection()),
            const SliverToBoxAdapter(child: _SectionDivider()),
            const SliverToBoxAdapter(child: _PendingTasksSection()),
            const SliverToBoxAdapter(child: _SectionDivider()),
            const SliverToBoxAdapter(child: _SubjectBarChartSection()),
            const SliverToBoxAdapter(child: _SectionDivider()),
            const SliverToBoxAdapter(child: _SubmissionPieSection()),
            const SliverToBoxAdapter(child: SizedBox(height: 48)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Shared helpers
// ─────────────────────────────────────────────

class _SectionDivider extends StatelessWidget {
  const _SectionDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      color: AppColors.border,
      height: 1,
      thickness: 1,
      indent: 20,
      endIndent: 20,
    );
  }
}

class _SectionEyebrow extends StatelessWidget {
  final String label;

  const _SectionEyebrow({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: AppTypography.eyebrow,
    );
  }
}

// ─────────────────────────────────────────────
// Header
// ─────────────────────────────────────────────

class _ReportHeader extends StatelessWidget {
  final String childName;

  const _ReportHeader({required this.childName});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
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
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '$childName의 리포트',
              style: AppTypography.headlineMedium.copyWith(fontSize: 22),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Period selector
// ─────────────────────────────────────────────

class _PeriodSelector extends StatelessWidget {
  const _PeriodSelector();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ReportViewModel>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: TimePeriod.values.map((p) {
          final isSelected = vm.period == p;
          return Expanded(
            child: GestureDetector(
              onTap: () => vm.setPeriod(p),
              behavior: HitTestBehavior.opaque,
              child: _PeriodTab(label: p.label, isSelected: isSelected),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _PeriodTab extends StatelessWidget {
  final String label;
  final bool isSelected;

  const _PeriodTab({required this.label, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          style: AppTypography.bodyMedium.copyWith(
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? AppColors.ink : AppColors.slate,
          ),
        ),
        const SizedBox(height: 4),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 2,
          color: isSelected ? AppColors.ink : Colors.transparent,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// ─────────────────────────────────────────────
// AI summary section
// ─────────────────────────────────────────────

class _AiSummarySection extends StatelessWidget {
  const _AiSummarySection();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ReportViewModel>();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionEyebrow(label: 'AI 요약'),
          const SizedBox(height: 12),
          if (vm.isSummaryLoading)
            const _AiSummaryLoadingCard()
          else if (vm.summaryError.isNotEmpty)
            _AiSummaryErrorCard(
              message: vm.summaryError,
              onRetry: () => vm.generateAiSummary(),
            )
          else if (vm.hasSummary)
            _AiSummaryResultCard(summaryText: vm.aiSummary)
          else
            _AiSummaryErrorCard(
              message: '요약 정보를 준비하지 못했어요.',
              onRetry: () => vm.generateAiSummary(),
            ),
        ],
      ),
    );
  }
}

class _AiSummaryLoadingCard extends StatelessWidget {
  const _AiSummaryLoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 120),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: AppColors.ink,
            strokeWidth: 3,
          ),
          const SizedBox(height: 12),
          Text(
            'AI가 학습 내용을 분석 중이에요...',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.slate,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _AiSummaryResultCard extends StatelessWidget {
  final String summaryText;

  const _AiSummaryResultCard({required this.summaryText});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: SelectableText(
        summaryText,
        style: AppTypography.bodyMedium.copyWith(
          color: AppColors.ink,
          height: 1.65,
          fontSize: 15,
        ),
      ),
    );
  }
}

class _AiSummaryErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _AiSummaryErrorCard({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Column(
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.slate,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          BouncyButton(
            label: '다시 시도',
            backgroundColor: AppColors.sunriseYellow,
            foregroundColor: AppColors.ink,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            onTap: onRetry,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Pending tasks
// ─────────────────────────────────────────────

class _PendingTasksSection extends StatelessWidget {
  const _PendingTasksSection();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ReportViewModel>();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionEyebrow(label: '해야 할 과제'),
          const SizedBox(height: 12),
          if (vm.isLoading)
            const _LoadingPlaceholder()
          else if (vm.pendingTasks.isEmpty)
            const _EmptyState(message: '미완료 과제가 없어요! 🎉')
          else
            _PendingTaskList(tasks: vm.pendingTasks),
        ],
      ),
    );
  }
}

class _PendingTaskList extends StatelessWidget {
  final List<Task> tasks;

  const _PendingTaskList({required this.tasks});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (int i = 0; i < tasks.length; i++) ...[
          _ReportTaskTile(task: tasks[i]),
          if (i < tasks.length - 1) const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _ReportTaskTile extends StatelessWidget {
  final Task task;

  const _ReportTaskTile({required this.task});

  @override
  Widget build(BuildContext context) {
    final bool isOverdue =
        task.dueDate != null && task.dueDate!.isBefore(DateTime.now());

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isOverdue ? const Color(0xFFFADBD8) : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_box_outline_blank_rounded,
            color: isOverdue ? AppColors.tangerine : AppColors.ink,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(child: _ReportTaskTileText(task: task, isOverdue: isOverdue)),
        ],
      ),
    );
  }
}

class _ReportTaskTileText extends StatelessWidget {
  final Task task;
  final bool isOverdue;

  const _ReportTaskTileText({
    required this.task,
    required this.isOverdue,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          task.title,
          style: AppTypography.bodyLarge.copyWith(
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (task.dueDate != null) ...[
          const SizedBox(height: 2),
          Text(
            isOverdue
                ? '마감 초과: ${task.dueDate!.month}월 ${task.dueDate!.day}일'
                : '마감: ${task.dueDate!.month}월 ${task.dueDate!.day}일',
            style: AppTypography.bodyMedium.copyWith(
              fontSize: 13,
              color: isOverdue ? AppColors.tangerine : AppColors.slate,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Subject bar chart
// ─────────────────────────────────────────────

class _SubjectBarChartSection extends StatelessWidget {
  const _SubjectBarChartSection();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ReportViewModel>();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionEyebrow(label: '과목별 성취도'),
          const SizedBox(height: 4),
          Text(
            '완료한 과제 수',
            style: AppTypography.bodyMedium.copyWith(
              fontSize: 13,
              color: AppColors.slate,
            ),
          ),
          const SizedBox(height: 16),
          if (vm.isLoading)
            const _LoadingPlaceholder()
          else if (vm.subjectAchievement.isEmpty)
            const _EmptyState(message: '완료된 과제가 없어요')
          else
            _SubjectBarChart(data: vm.subjectAchievement),
        ],
      ),
    );
  }
}

class _SubjectBarChart extends StatelessWidget {
  final Map<String, int> data;

  const _SubjectBarChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final entries = data.entries.toList();
    final maxY = entries.map((e) => e.value).reduce((a, b) => a > b ? a : b);

    final groups = List.generate(entries.length, (i) {
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: entries[i].value.toDouble(),
            color: AppColors.marigold,
            width: 28,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: maxY.toDouble() + 1,
              color: AppColors.border.withAlpha(60),
            ),
          ),
        ],
      );
    });

    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY.toDouble() + 1,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barTouchData: BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= entries.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '${entries[idx].value}',
                      style: AppTypography.bodyMedium.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= entries.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      entries[idx].key,
                      style: AppTypography.bodyMedium.copyWith(
                        fontSize: 13,
                        color: AppColors.ink,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: groups,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Submission pie chart
// ─────────────────────────────────────────────

class _SubmissionPieSection extends StatelessWidget {
  const _SubmissionPieSection();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ReportViewModel>();
    final total = vm.onTimeCount + vm.lateOrMissedCount + vm.inProgressCount;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionEyebrow(label: '제출 현황'),
          const SizedBox(height: 16),
          if (vm.isLoading)
            const _LoadingPlaceholder()
          else if (total == 0)
            const _EmptyState(message: '과제가 없어요')
          else
            _PieChartRow(vm: vm, total: total),
        ],
      ),
    );
  }
}

class _PieChartRow extends StatelessWidget {
  final ReportViewModel vm;
  final int total;

  const _PieChartRow({required this.vm, required this.total});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 5,
          child: SizedBox(
            height: 160,
            child: _SubmissionPieChart(
              onTime: vm.onTimeCount,
              lateOrMissed: vm.lateOrMissedCount,
              inProgress: vm.inProgressCount,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 4,
          child: _PieLegend(
            onTime: vm.onTimeCount,
            lateOrMissed: vm.lateOrMissedCount,
            inProgress: vm.inProgressCount,
            total: total,
          ),
        ),
      ],
    );
  }
}

class _SubmissionPieChart extends StatelessWidget {
  final int onTime;
  final int lateOrMissed;
  final int inProgress;

  const _SubmissionPieChart({
    required this.onTime,
    required this.lateOrMissed,
    required this.inProgress,
  });

  @override
  Widget build(BuildContext context) {
    return PieChart(
      PieChartData(
        sectionsSpace: 3,
        centerSpaceRadius: 36,
        sections: _buildSections(),
      ),
    );
  }

  List<PieChartSectionData> _buildSections() {
    final sections = <PieChartSectionData>[];

    if (onTime > 0) {
      sections.add(PieChartSectionData(
        value: onTime.toDouble(),
        color: AppColors.mint,
        title: '',
        radius: 44,
      ));
    }
    if (inProgress > 0) {
      sections.add(PieChartSectionData(
        value: inProgress.toDouble(),
        color: AppColors.oceanSoft,
        title: '',
        radius: 44,
      ));
    }
    if (lateOrMissed > 0) {
      sections.add(PieChartSectionData(
        value: lateOrMissed.toDouble(),
        color: AppColors.tangerine,
        title: '',
        radius: 44,
      ));
    }

    return sections;
  }
}

class _PieLegend extends StatelessWidget {
  final int onTime;
  final int lateOrMissed;
  final int inProgress;
  final int total;

  const _PieLegend({
    required this.onTime,
    required this.lateOrMissed,
    required this.inProgress,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _LegendItem(
          color: AppColors.mint,
          label: '제때 완료',
          count: onTime,
          total: total,
        ),
        const SizedBox(height: 8),
        _LegendItem(
          color: AppColors.oceanSoft,
          label: '진행 중',
          count: inProgress,
          total: total,
        ),
        const SizedBox(height: 8),
        _LegendItem(
          color: AppColors.tangerine,
          label: '마감 초과',
          count: lateOrMissed,
          total: total,
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final int count;
  final int total;

  const _LegendItem({
    required this.color,
    required this.label,
    required this.count,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? (count / total * 100).round() : 0;

    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTypography.bodyMedium.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '$count개 ($pct%)',
                style: AppTypography.bodyMedium.copyWith(
                  fontSize: 12,
                  color: AppColors.slate,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Shared utility widgets
// ─────────────────────────────────────────────

class _LoadingPlaceholder extends StatelessWidget {
  const _LoadingPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 80,
      child: Center(
        child: CircularProgressIndicator(
          color: AppColors.ink,
          strokeWidth: 3,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;

  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      child: Center(
        child: Text(
          message,
          style: AppTypography.bodyMedium.copyWith(color: AppColors.slate),
        ),
      ),
    );
  }
}
