import 'package:flutter/foundation.dart';
import '../models/task.dart';

/// ViewModel managing state and business logic for the Calendar view.
class CalendarViewModel extends ChangeNotifier {
  late DateTime _selectedDate;
  late DateTime _focusedMonth;

  CalendarViewModel() {
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
    _focusedMonth = DateTime(now.year, now.month, 1);
  }

  DateTime get selectedDate => _selectedDate;
  DateTime get focusedMonth => _focusedMonth;

  /// Selects a date and notifies listeners.
  void selectDate(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    if (_selectedDate != normalized) {
      _selectedDate = normalized;
      if (_focusedMonth.year != date.year || _focusedMonth.month != date.month) {
        _focusedMonth = DateTime(date.year, date.month, 1);
      }
      notifyListeners();
    }
  }

  /// Navigates to the previous month.
  void previousMonth() {
    _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1, 1);
    notifyListeners();
  }

  /// Navigates to the next month.
  void nextMonth() {
    _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 1);
    notifyListeners();
  }

  /// Navigates to today's date and month.
  void goToToday() {
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
    _focusedMonth = DateTime(now.year, now.month, 1);
    notifyListeners();
  }

  /// Returns tasks with a due date matching the specified [date].
  List<Task> getTasksForDate(List<Task> tasks, DateTime date) {
    return tasks.where((task) {
      final due = task.dueDate;
      if (due == null) return false;
      return due.year == date.year &&
          due.month == date.month &&
          due.day == date.day;
    }).toList();
  }

  /// Returns tasks with a due date matching the currently [selectedDate].
  List<Task> getTasksForSelectedDate(List<Task> tasks) {
    return getTasksForDate(tasks, _selectedDate);
  }

  /// Returns tasks that do not have a due date (`dueDate == null`).
  List<Task> getUndatedTasks(List<Task> tasks) {
    return tasks.where((task) => task.dueDate == null).toList();
  }

  /// Checks if [date1] and [date2] represent the same day.
  bool isSameDay(DateTime? date1, DateTime? date2) {
    if (date1 == null || date2 == null) return false;
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }
}
