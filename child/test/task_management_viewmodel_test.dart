import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:capstone_ai_client/models/task.dart';
import 'package:capstone_ai_client/services/task/base_task_repository.dart';
import 'package:capstone_ai_client/viewmodels/task_management_viewmodel.dart';

class MockTaskRepository implements BaseTaskRepository {
  final StreamController<List<Task>> _streamController =
      StreamController<List<Task>>.broadcast();

  final List<Task> updatedTasks = [];
  final List<String> deletedTaskIds = [];
  List<Task> currentTasks = [];

  void emit(List<Task> tasks) {
    currentTasks = tasks;
    _streamController.add(tasks);
  }

  @override
  Stream<List<Task>> streamTasks(String userId) {
    return _streamController.stream;
  }

  @override
  Future<List<Task>> loadTasks(String userId) async {
    return currentTasks;
  }

  @override
  Future<Task?> createTask(String userId, Task task) async {
    return task;
  }

  @override
  Future<void> updateTask(String userId, Task task) async {
    updatedTasks.add(task);
    final index = currentTasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      currentTasks[index] = task;
    }
    _streamController.add(currentTasks);
  }

  @override
  Future<void> deleteTask(String userId, String taskId) async {
    deletedTaskIds.add(taskId);
    currentTasks.removeWhere((t) => t.id == taskId);
    _streamController.add(currentTasks);
  }

  @override
  Future<void> toggleSubtask(
    String userId,
    String taskId,
    String subtaskId,
  ) async {}

  void dispose() {
    _streamController.close();
  }
}

List<Task> getSampleTasks() => [
      const Task(
        id: 'task_1',
        title: '수학 숙제',
        isCompleted: false,
        subtasks: [
          SubTask(id: 'st_1', title: '문제집 10쪽', isCompleted: false),
        ],
      ),
      Task(
        id: 'task_2',
        title: '영어 단어 암기',
        isCompleted: true,
        completedAt: DateTime.now(),
        subtasks: const [
          SubTask(id: 'st_2', title: 'Unit 1 단어', isCompleted: true),
        ],
      ),
      const Task(
        id: 'task_3',
        title: '과학 실험 보고서',
        isCompleted: false,
        subtasks: [],
      ),
    ];

void main() {
  group('TaskManagementViewModel Tests', () {
    late MockTaskRepository mockRepo;
    late TaskManagementViewModel viewModel;

    setUp(() {
      mockRepo = MockTaskRepository();
      viewModel = TaskManagementViewModel(
        taskRepository: mockRepo,
        userId: 'test_child_123',
      );
    });

    tearDown(() {
      viewModel.dispose();
      mockRepo.dispose();
    });

    test('Selection methods correctly track selected task IDs', () async {
      mockRepo.emit(getSampleTasks());
      await Future<void>.delayed(Duration.zero);

      expect(viewModel.tasks.length, 3);
      expect(viewModel.selectedCount, 0);

      viewModel.toggleSelection('task_1');
      expect(viewModel.isSelected('task_1'), isTrue);
      expect(viewModel.isSelected('task_2'), isFalse);
      expect(viewModel.selectedCount, 1);

      viewModel.toggleSelection('task_2');
      expect(viewModel.selectedCount, 2);

      viewModel.toggleSelection('task_1');
      expect(viewModel.isSelected('task_1'), isFalse);
      expect(viewModel.selectedCount, 1);

      viewModel.selectAll();
      expect(viewModel.selectedCount, 3);
      expect(viewModel.isAllSelected, isTrue);

      viewModel.clearSelection();
      expect(viewModel.selectedCount, 0);
    });

    test('batchMarkCompleted marks all selected tasks and subtasks as completed', () async {
      mockRepo.emit(getSampleTasks());
      await Future<void>.delayed(Duration.zero);

      viewModel.toggleSelection('task_1');
      viewModel.toggleSelection('task_3');

      await viewModel.batchMarkCompleted();

      expect(mockRepo.updatedTasks.length, 2);
      final updated1 = mockRepo.updatedTasks.firstWhere((t) => t.id == 'task_1');
      expect(updated1.isCompleted, isTrue);
      expect(updated1.completedAt, isNotNull);
      expect(updated1.subtasks.first.isCompleted, isTrue);

      final updated3 = mockRepo.updatedTasks.firstWhere((t) => t.id == 'task_3');
      expect(updated3.isCompleted, isTrue);
      expect(updated3.completedAt, isNotNull);

      // Selected set should be cleared after batch operation
      expect(viewModel.selectedCount, 0);
    });

    test('batchMarkIncompleted marks all selected tasks and subtasks as incompleted', () async {
      mockRepo.emit(getSampleTasks());
      await Future<void>.delayed(Duration.zero);

      viewModel.toggleSelection('task_2');

      await viewModel.batchMarkIncompleted();

      expect(mockRepo.updatedTasks.length, 1);
      final updated2 = mockRepo.updatedTasks.firstWhere((t) => t.id == 'task_2');
      expect(updated2.isCompleted, isFalse);
      expect(updated2.completedAt, isNull);
      expect(updated2.subtasks.first.isCompleted, isFalse);

      expect(viewModel.selectedCount, 0);
    });

    test('batchDelete deletes all selected tasks and clears selection', () async {
      mockRepo.emit(getSampleTasks());
      await Future<void>.delayed(Duration.zero);

      viewModel.toggleSelection('task_1');
      viewModel.toggleSelection('task_2');

      await viewModel.batchDelete();

      expect(mockRepo.deletedTaskIds, containsAll(['task_1', 'task_2']));
      expect(viewModel.selectedCount, 0);
    });

    test('batchDeleteCompletedTasks deletes only completed tasks', () async {
      mockRepo.emit(getSampleTasks());
      await Future<void>.delayed(Duration.zero);

      expect(viewModel.hasCompletedTasks, isTrue);
      expect(viewModel.completedTasksCount, 1);

      await viewModel.batchDeleteCompletedTasks();

      expect(mockRepo.deletedTaskIds, contains('task_2'));
      expect(mockRepo.deletedTaskIds, isNot(contains('task_1')));
      expect(mockRepo.deletedTaskIds, isNot(contains('task_3')));
    });
  });
}
