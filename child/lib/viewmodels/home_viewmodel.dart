import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/task.dart';
import '../services/task/base_task_repository.dart';

enum TaskSortOption { dueDate, createdDate }

/// ViewModel managing state and business logic for [HomeView].
class HomeViewModel extends ChangeNotifier {
  final BaseTaskRepository _taskRepository;
  final String _userId;

  List<Task> _tasks = [];
  bool _isLoading = false;
  bool _isUrgentAlertDismissed = false;
  bool _isSummaryDismissed = false;
  TaskSortOption _sortOption = TaskSortOption.dueDate;

  StreamSubscription<List<Task>>? _tasksSubscription;

  HomeViewModel({
    required BaseTaskRepository taskRepository,
    required String userId,
  }) : _taskRepository = taskRepository,
       _userId = userId {
    _initStream();
  }

  // ---------------------------------------------------------------------------
  // Getters
  // ---------------------------------------------------------------------------

  List<Task> get tasks {
    final list = List<Task>.from(_tasks);
    if (_sortOption == TaskSortOption.dueDate) {
      list.sort((a, b) {
        if (a.dueDate == null && b.dueDate == null) return 0;
        if (a.dueDate == null) return 1;
        if (b.dueDate == null) return -1;
        return a.dueDate!.compareTo(b.dueDate!);
      });
    } else {
      list.sort((a, b) {
        if (a.createdAt == null && b.createdAt == null) return 0;
        if (a.createdAt == null) return 1;
        if (b.createdAt == null) return -1;
        return b.createdAt!.compareTo(a.createdAt!);
      });
    }
    return list;
  }

  bool get isLoading => _isLoading;
  TaskSortOption get sortOption => _sortOption;

  int get remainingTasksCount =>
      _tasks.where((task) => !task.isCompleted).length;

  int get dueThisWeekCount =>
      _tasks.where((task) => !task.isCompleted && task.isDueThisWeek).length;

  bool get hasUrgentTask =>
      !_isUrgentAlertDismissed &&
      _tasks.any((task) => !task.isCompleted && task.isDueToday);

  String get urgentTaskMessage => '오늘이 마감일인 과제가 있어요!';

  bool get isSummaryVisible => !_isSummaryDismissed;

  // ---------------------------------------------------------------------------
  // Methods
  // ---------------------------------------------------------------------------

  void _initStream() {
    if (_userId.isEmpty) return;
    _isLoading = true;
    notifyListeners();

    _tasksSubscription?.cancel();
    _tasksSubscription = _taskRepository
        .streamTasks(_userId)
        .listen(
          (loadedTasks) {
            _tasks = loadedTasks;
            _isLoading = false;
            notifyListeners();
          },
          onError: (error) {
            debugPrint('[HomeViewModel] Stream error: $error');
            _isLoading = false;
            notifyListeners();
          },
        );
  }

  void setSortOption(TaskSortOption option) {
    _sortOption = option;
    notifyListeners();
  }

  Future<void> addTask(
    String title,
    DateTime? dueDate,
    List<String> subtaskTitles,
  ) async {
    try {
      final subtasks = subtaskTitles
          .where((t) => t.trim().isNotEmpty)
          .map(
            (t) => SubTask(
              id: 'st_${DateTime.now().microsecondsSinceEpoch}',
              title: t.trim(),
            ),
          )
          .toList();

      final newTask = Task(
        id: '',
        title: title,
        dueDate: dueDate,
        subtasks: subtasks,
      );

      await _taskRepository.createTask(_userId, newTask);
    } catch (e) {
      debugPrint('[HomeViewModel] addTask error: $e');
    }
  }

  Future<void> updateTask(Task task) async {
    try {
      await _taskRepository.updateTask(_userId, task);
    } catch (e) {
      debugPrint('[HomeViewModel] updateTask error: $e');
    }
  }

  Future<void> toggleTask(String taskId) async {
    try {
      final index = _tasks.indexWhere((t) => t.id == taskId);
      if (index != -1) {
        final task = _tasks[index];
        final updated = task.copyWith(isCompleted: !task.isCompleted);
        await _taskRepository.updateTask(_userId, updated);
      }
    } catch (e) {
      debugPrint('[HomeViewModel] toggleTask error: $e');
    }
  }

  Future<void> toggleSubtask(String taskId, String subtaskId) async {
    try {
      await _taskRepository.toggleSubtask(_userId, taskId, subtaskId);
    } catch (e) {
      debugPrint('[HomeViewModel] toggleSubtask error: $e');
    }
  }

  Future<void> deleteTask(String taskId) async {
    try {
      await _taskRepository.deleteTask(_userId, taskId);
    } catch (e) {
      debugPrint('[HomeViewModel] deleteTask error: $e');
    }
  }

  void dismissUrgentAlert() {
    _isUrgentAlertDismissed = true;
    notifyListeners();
  }

  void dismissSummary() {
    _isSummaryDismissed = true;
    notifyListeners();
  }

  @override
  void dispose() {
    _tasksSubscription?.cancel();
    super.dispose();
  }
}
