import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/task.dart';
import '../services/task/base_task_repository.dart';

/// ViewModel managing state and business logic for task management & batch operations.
class TaskManagementViewModel extends ChangeNotifier {
  final BaseTaskRepository _taskRepository;
  final String _userId;

  List<Task> _tasks = [];
  final Set<String> _selectedTaskIds = {};
  bool _isLoading = false;
  StreamSubscription<List<Task>>? _tasksSubscription;

  TaskManagementViewModel({
    required BaseTaskRepository taskRepository,
    required String userId,
  })  : _taskRepository = taskRepository,
        _userId = userId {
    _initStream();
  }

  // ---------------------------------------------------------------------------
  // Getters
  // ---------------------------------------------------------------------------

  List<Task> get tasks => List.unmodifiable(_tasks);

  Set<String> get selectedTaskIds => Set.unmodifiable(_selectedTaskIds);

  bool get isLoading => _isLoading;

  int get selectedCount => _selectedTaskIds.length;

  bool get isAllSelected =>
      _tasks.isNotEmpty && _selectedTaskIds.length == _tasks.length;

  bool get hasCompletedTasks => _tasks.any((t) => t.isCompleted);

  int get completedTasksCount => _tasks.where((t) => t.isCompleted).length;

  bool isSelected(String taskId) => _selectedTaskIds.contains(taskId);

  // ---------------------------------------------------------------------------
  // Stream initialization
  // ---------------------------------------------------------------------------

  void _initStream() {
    if (_userId.isEmpty) return;
    _isLoading = true;
    notifyListeners();

    _tasksSubscription?.cancel();
    _tasksSubscription = _taskRepository.streamTasks(_userId).listen(
      (loadedTasks) {
        _tasks = loadedTasks;
        // Clean up any selected IDs that no longer exist in loaded tasks
        final validIds = _tasks.map((t) => t.id).toSet();
        _selectedTaskIds.removeWhere((id) => !validIds.contains(id));
        _isLoading = false;
        notifyListeners();
      },
      onError: (error) {
        debugPrint('[TaskManagementViewModel] Stream error: $error');
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Selection Methods
  // ---------------------------------------------------------------------------

  void toggleSelection(String taskId) {
    if (_selectedTaskIds.contains(taskId)) {
      _selectedTaskIds.remove(taskId);
    } else {
      _selectedTaskIds.add(taskId);
    }
    notifyListeners();
  }

  void selectAll() {
    _selectedTaskIds.addAll(_tasks.map((t) => t.id));
    notifyListeners();
  }

  void clearSelection() {
    _selectedTaskIds.clear();
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Batch Operations
  // ---------------------------------------------------------------------------

  /// Marks all selected tasks (and their subtasks) as completed.
  Future<void> batchMarkCompleted() async {
    if (_selectedTaskIds.isEmpty) return;

    try {
      final idsToUpdate = List<String>.from(_selectedTaskIds);
      await Future.wait(
        idsToUpdate.map((taskId) async {
          final index = _tasks.indexWhere((t) => t.id == taskId);
          if (index != -1) {
            final task = _tasks[index];
            final updatedSubtasks = task.subtasks
                .map((st) => st.copyWith(isCompleted: true))
                .toList();
            final updated = task.copyWith(
              isCompleted: true,
              completedAt: DateTime.now(),
              subtasks: updatedSubtasks,
            );
            await _taskRepository.updateTask(_userId, updated);
          }
        }),
      );
      _selectedTaskIds.clear();
      notifyListeners();
    } catch (e) {
      debugPrint('[TaskManagementViewModel] batchMarkCompleted error: $e');
    }
  }

  /// Marks all selected tasks (and their subtasks) as incomplete.
  Future<void> batchMarkIncompleted() async {
    if (_selectedTaskIds.isEmpty) return;

    try {
      final idsToUpdate = List<String>.from(_selectedTaskIds);
      await Future.wait(
        idsToUpdate.map((taskId) async {
          final index = _tasks.indexWhere((t) => t.id == taskId);
          if (index != -1) {
            final task = _tasks[index];
            final updatedSubtasks = task.subtasks
                .map((st) => st.copyWith(isCompleted: false))
                .toList();
            final updated = task.copyWith(
              isCompleted: false,
              completedAt: null,
              subtasks: updatedSubtasks,
            );
            await _taskRepository.updateTask(_userId, updated);
          }
        }),
      );
      _selectedTaskIds.clear();
      notifyListeners();
    } catch (e) {
      debugPrint('[TaskManagementViewModel] batchMarkIncompleted error: $e');
    }
  }

  /// Deletes all selected tasks from repository.
  Future<void> batchDelete() async {
    if (_selectedTaskIds.isEmpty) return;

    try {
      final idsToDelete = List<String>.from(_selectedTaskIds);
      await Future.wait(
        idsToDelete.map((taskId) => _taskRepository.deleteTask(_userId, taskId)),
      );
      _selectedTaskIds.clear();
      notifyListeners();
    } catch (e) {
      debugPrint('[TaskManagementViewModel] batchDelete error: $e');
    }
  }

  /// Deletes all completed tasks from repository.
  Future<void> batchDeleteCompletedTasks() async {
    try {
      final completedTaskIds = _tasks
          .where((t) => t.isCompleted)
          .map((t) => t.id)
          .toList();
      if (completedTaskIds.isEmpty) return;

      await Future.wait(
        completedTaskIds.map(
          (taskId) => _taskRepository.deleteTask(_userId, taskId),
        ),
      );
      _selectedTaskIds.removeWhere((id) => completedTaskIds.contains(id));
      notifyListeners();
    } catch (e) {
      debugPrint('[TaskManagementViewModel] batchDeleteCompletedTasks error: $e');
    }
  }

  @override
  void dispose() {
    _tasksSubscription?.cancel();
    super.dispose();
  }
}
