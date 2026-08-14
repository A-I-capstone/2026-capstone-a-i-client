import 'package:flutter_test/flutter_test.dart';
import 'package:capstone_ai_client/models/task.dart';
import 'package:capstone_ai_client/theme/app_colors.dart';

void main() {
  group('Task Overdue Tests', () {
    test('Task without due date is neither past due nor overdue', () {
      const task = Task(id: '1', title: 'No due date task');
      expect(task.isPastDue, false);
      expect(task.isOverdue, false);
    });

    test('Task with future due date is not overdue', () {
      final futureDate = DateTime.now().add(const Duration(days: 3));
      final task = Task(id: '2', title: 'Future task', dueDate: futureDate);
      expect(task.isPastDue, false);
      expect(task.isOverdue, false);
    });

    test('Incomplete task with past due date is overdue', () {
      final pastDate = DateTime.now().subtract(const Duration(days: 2));
      final task = Task(
        id: '3',
        title: 'Overdue task',
        dueDate: pastDate,
        isCompleted: false,
      );
      expect(task.isPastDue, true);
      expect(task.isOverdue, true);
    });

    test('Completed task with past due date is not overdue', () {
      final pastDate = DateTime.now().subtract(const Duration(days: 2));
      final task = Task(
        id: '4',
        title: 'Completed past task',
        dueDate: pastDate,
        isCompleted: true,
      );
      expect(task.isPastDue, true);
      expect(task.isOverdue, false);
    });

    test('AppColors defines overdueRed and overdueText tokens', () {
      expect(AppColors.overdueRed, isNotNull);
      expect(AppColors.overdueText, isNotNull);
    });
  });
}
