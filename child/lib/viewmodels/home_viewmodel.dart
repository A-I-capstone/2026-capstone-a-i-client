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
        final aDue = a.dueDate;
        final bDue = b.dueDate;
        if (aDue == null && bDue == null) return 0;
        if (aDue == null) return 1;
        if (bDue == null) return -1;
        return aDue.compareTo(bDue);
      });
    } else {
      list.sort((a, b) {
        final aCreated = a.createdAt;
        final bCreated = b.createdAt;
        if (aCreated == null && bCreated == null) return 0;
        if (aCreated == null) return 1;
        if (bCreated == null) return -1;
        return bCreated.compareTo(aCreated);
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

  bool get hasOverdueTask => _tasks.any((task) => task.isOverdue);

  bool get hasUrgentTask =>
      !_isUrgentAlertDismissed &&
      _tasks.any(
        (task) => task.isOverdue || (!task.isCompleted && task.isDueToday),
      );

  String get urgentTaskMessage {
    if (hasOverdueTask) {
      return '마감일이 지난 과제가 있어요!\n얼른 확인해 볼까요?';
    }
    return '오늘이 마감일인 과제가 있어요!';
  }

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
    String subjectId,
  ) async {
    try {
      final subtasks = subtaskTitles
          .where((t) => t.trim().isNotEmpty)
          .map(
            (t) => SubTask(
              id: 'st_${DateTime.now().microsecondsSinceEpoch}_${t.hashCode}',
              title: t.trim(),
            ),
          )
          .toList();

      final newTask = Task(
        id: '',
        title: title,
        dueDate: dueDate,
        subtasks: subtasks,
        subjectId: subjectId,
      );

      await _taskRepository.createTask(_userId, newTask);
    } catch (e) {
      debugPrint('[HomeViewModel] addTask error: $e');
    }
  }

  Future<void> editTask(
    Task originalTask,
    String title,
    DateTime? dueDate,
    List<String> subtaskTitles,
    String subjectId,
  ) async {
    try {
      final subtasks = subtaskTitles
          .where((t) => t.trim().isNotEmpty)
          .map((t) {
            final existingIndex =
                originalTask.subtasks.indexWhere((st) => st.title == t.trim());
            if (existingIndex != -1) {
              return originalTask.subtasks[existingIndex];
            }
            return SubTask(
              id: 'st_${DateTime.now().microsecondsSinceEpoch}_${t.hashCode}',
              title: t.trim(),
            );
          })
          .toList();

      final updated = originalTask.copyWith(
        title: title,
        dueDate: dueDate,
        subtasks: subtasks,
        subjectId: subjectId,
      );

      await _taskRepository.updateTask(_userId, updated);
    } catch (e) {
      debugPrint('[HomeViewModel] editTask error: $e');
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
        final nowCompleted = !task.isCompleted;
        final updated = task.copyWith(
          isCompleted: nowCompleted,
          completedAt: nowCompleted ? DateTime.now() : null,
        );
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
