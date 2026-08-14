import 'package:flutter_test/flutter_test.dart';
import 'package:parent/models/subject.dart';
import 'package:parent/models/task.dart';
import 'package:parent/utils/report_prompt_builder.dart';
import 'package:parent/viewmodels/report_viewmodel.dart';

void main() {
  group('Task & Subject Model Tests', () {
    test('Task.fromFirestore parses subjectId correctly', () {
      final taskData = {
        'title': '수학 문제집 10쪽',
        'isCompleted': true,
        'subjectId': 'subj_math_123',
        'chatId': 'chat_456',
        'subtasks': [
          {'id': 'st_1', 'title': '1번부터 5번', 'isCompleted': true},
        ],
      };

      final task = Task.fromFirestore(taskData, 'task_1');
      expect(task.id, 'task_1');
      expect(task.title, '수학 문제집 10쪽');
      expect(task.isCompleted, isTrue);
      expect(task.subjectId, 'subj_math_123');
      expect(task.subtasks.length, 1);
    });

    test('Task.fromFirestore falls back to subject field for legacy data', () {
      final legacyData = {
        'title': '영어 단어 외우기',
        'isCompleted': false,
        'subject': 'legacy_subj_id',
      };

      final task = Task.fromFirestore(legacyData, 'task_legacy');
      expect(task.subjectId, 'legacy_subj_id');
    });

    test('Subject.fromFirestore parses attributes correctly', () {
      final subjectData = {
        'name': '수학',
        'colorValue': 0xFFFFC533,
      };

      final subject = Subject.fromFirestore(subjectData, 'subj_math_123');
      expect(subject.id, 'subj_math_123');
      expect(subject.name, '수학');
      expect(subject.colorValue, 0xFFFFC533);
    });
  });

  group('ReportPromptBuilder with Subject Mapping Tests', () {
    test('build maps subjectId to subject name correctly', () {
      const subject = Subject(
        id: 'subj_math_123',
        name: '수학',
        colorValue: 0xFFFFC533,
      );

      final task = Task.fromFirestore({
        'title': '분수 덧셈 문제 풀기',
        'isCompleted': true,
        'subjectId': 'subj_math_123',
      }, 'task_1');

      final prompt = ReportPromptBuilder.build(
        childName: '민수',
        period: TimePeriod.week,
        filteredTasks: [task],
        chatSnippets: {},
        subjectsMap: {'subj_math_123': subject},
      );

      expect(prompt, contains('- 수학: 1개 완료, 0개 마감 초과'));
      expect(prompt, contains('- [수학] 분수 덧셈 문제 풀기'));
    });

    test('build groups unknown subjectId as 기타', () {
      final task = Task.fromFirestore({
        'title': '일기 쓰기',
        'isCompleted': true,
        'subjectId': 'unknown_id',
      }, 'task_2');

      final prompt = ReportPromptBuilder.build(
        childName: '민수',
        period: TimePeriod.week,
        filteredTasks: [task],
        chatSnippets: {},
        subjectsMap: {},
      );

      expect(prompt, contains('- 기타: 1개 완료, 0개 마감 초과'));
      expect(prompt, contains('- [기타] 일기 쓰기'));
    });
  });
}
