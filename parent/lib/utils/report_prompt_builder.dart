import '../models/task.dart';
import '../viewmodels/report_viewmodel.dart';

/// Helper utility to construct a condensed, context-rich prompt for the LLM.
class ReportPromptBuilder {
  /// Builds a formatted user prompt combining child task achievements,
  /// subject aggregations, overdue statuses, and selective chat snippets.
  static String build({
    required String childName,
    required TimePeriod period,
    required List<Task> filteredTasks,
    required Map<String, List<String>> chatSnippets,
  }) {
    final buffer = StringBuffer();

    buffer.writeln('아동 이름: $childName');
    buffer.writeln('분석 대상 기간: ${period.label}');
    buffer.writeln();

    // 1. Overall stats
    final total = filteredTasks.length;
    final completed = filteredTasks.where((t) => t.isCompleted).toList();
    final now = DateTime.now();

    final overdue = filteredTasks.where((t) {
      if (t.isCompleted) {
        return t.dueDate != null &&
            t.completedAt != null &&
            t.completedAt!.isAfter(t.dueDate!);
      } else {
        return t.dueDate != null && t.dueDate!.isBefore(now);
      }
    }).toList();

    final inProgress = filteredTasks.where((t) {
      return !t.isCompleted && (t.dueDate == null || !t.dueDate!.isBefore(now));
    }).toList();

    buffer.writeln('[과제 성과 전체 요약]');
    buffer.writeln('- 총 과제 수: $total개');
    buffer.writeln('- 완료된 과제: ${completed.length}개');
    buffer.writeln('- 진행 중인 과제: ${inProgress.length}개');
    buffer.writeln('- 마감 초과 과제: ${overdue.length}개');
    buffer.writeln();

    // 2. Subject breakdown
    final subjectStats = <String, Map<String, int>>{};
    for (final task in filteredTasks) {
      final subject = task.subject.isEmpty ? '기타' : task.subject;
      subjectStats.putIfAbsent(subject, () => {'completed': 0, 'overdue': 0});

      if (task.isCompleted) {
        subjectStats[subject]!['completed'] =
            (subjectStats[subject]!['completed'] ?? 0) + 1;
      }
      final isTaskOverdue = task.isCompleted
          ? (task.dueDate != null &&
              task.completedAt != null &&
              task.completedAt!.isAfter(task.dueDate!))
          : (task.dueDate != null && task.dueDate!.isBefore(now));

      if (isTaskOverdue) {
        subjectStats[subject]!['overdue'] =
            (subjectStats[subject]!['overdue'] ?? 0) + 1;
      }
    }

    if (subjectStats.isNotEmpty) {
      buffer.writeln('[과목별 성과]');
      subjectStats.forEach((subject, stats) {
        buffer.writeln(
            '- $subject: ${stats['completed']}개 완료, ${stats['overdue']}개 마감 초과');
      });
      buffer.writeln();
    }

    // 3. Overdue task details (Important signal)
    if (overdue.isNotEmpty) {
      buffer.writeln('[마감 초과 과제 세부 리스트]');
      for (final t in overdue) {
        final dueStr = t.dueDate != null
            ? '${t.dueDate!.month}/${t.dueDate!.day}'
            : '미지정';
        final subjectStr = t.subject.isEmpty ? '기타' : t.subject;
        buffer.writeln('- [$subjectStr] ${t.title} (마감일: $dueStr)');
      }
      buffer.writeln();
    }

    // 4. Completed tasks (Only if completed <= 10)
    if (completed.isNotEmpty && completed.length <= 10) {
      buffer.writeln('[완료된 과제 리스트]');
      for (final t in completed) {
        final subjectStr = t.subject.isEmpty ? '기타' : t.subject;
        buffer.writeln('- [$subjectStr] ${t.title}');
      }
      buffer.writeln();
    }

    // 5. Chat conversation snippets
    if (chatSnippets.isNotEmpty) {
      buffer.writeln('[과제 수행 중 아동과의 대화 일부]');
      chatSnippets.forEach((taskTitle, messages) {
        buffer.writeln('관련 과제: "$taskTitle"');
        for (final msg in messages) {
          buffer.writeln('  - 아동: "$msg"');
        }
      });
      buffer.writeln();
    }

    buffer.writeln('위 데이터 분석 결과를 토대로 지정된 보고서 구조에 맞춰 리포트를 작성해 주세요.');

    return buffer.toString();
  }
}
