import 'package:flutter_test/flutter_test.dart';
import 'package:capstone_ai_client/models/task.dart';
import 'package:capstone_ai_client/viewmodels/calendar_viewmodel.dart';

void main() {
  group('CalendarViewModel Tests', () {
    late CalendarViewModel viewModel;

    setUp(() {
      viewModel = CalendarViewModel();
    });

    test('Initial dates are set to today and first of current month', () {
      final now = DateTime.now();
      expect(viewModel.selectedDate.year, now.year);
      expect(viewModel.selectedDate.month, now.month);
      expect(viewModel.selectedDate.day, now.day);

      expect(viewModel.focusedMonth.year, now.year);
      expect(viewModel.focusedMonth.month, now.month);
      expect(viewModel.focusedMonth.day, 1);
    });

    test('selectDate updates selectedDate and focusedMonth if month changed', () {
      final targetDate = DateTime(2026, 12, 25);
      viewModel.selectDate(targetDate);

      expect(viewModel.selectedDate, DateTime(2026, 12, 25));
      expect(viewModel.focusedMonth, DateTime(2026, 12, 1));
    });

    test('previousMonth and nextMonth update focusedMonth correctly', () {
      viewModel.selectDate(DateTime(2026, 5, 15));
      expect(viewModel.focusedMonth.month, 5);

      viewModel.previousMonth();
      expect(viewModel.focusedMonth.month, 4);

      viewModel.nextMonth();
      expect(viewModel.focusedMonth.month, 5);
    });

    test('goToToday resets to current date and month', () {
      viewModel.selectDate(DateTime(2025, 1, 1));
      expect(viewModel.selectedDate.year, 2025);

      viewModel.goToToday();
      final now = DateTime.now();
      expect(viewModel.selectedDate.year, now.year);
      expect(viewModel.selectedDate.month, now.month);
      expect(viewModel.selectedDate.day, now.day);
    });

    test('getTasksForDate and getUndatedTasks filter tasks properly', () {
      final tasks = [
        Task(
          id: '1',
          title: 'Math Homework',
          dueDate: DateTime(2026, 8, 14, 10, 0),
          subjectId: 'sub_math',
        ),
        Task(
          id: '2',
          title: 'English Reading',
          dueDate: DateTime(2026, 8, 14, 18, 0),
          subjectId: 'sub_eng',
        ),
        Task(
          id: '3',
          title: 'Science Project',
          dueDate: DateTime(2026, 8, 20),
          subjectId: 'sub_sci',
        ),
        const Task(
          id: '4',
          title: 'Clean desk',
          dueDate: null,
          subjectId: 'sub_other',
        ),
      ];

      final tasksOnAug14 = viewModel.getTasksForDate(tasks, DateTime(2026, 8, 14));
      expect(tasksOnAug14.length, 2);
      expect(tasksOnAug14.map((t) => t.id), containsAll(['1', '2']));

      viewModel.selectDate(DateTime(2026, 8, 14));
      final selectedTasks = viewModel.getTasksForSelectedDate(tasks);
      expect(selectedTasks.length, 2);

      final undated = viewModel.getUndatedTasks(tasks);
      expect(undated.length, 1);
      expect(undated.first.id, '4');
    });
  });
}
