import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:capstone_ai_client/models/task.dart';
import 'package:capstone_ai_client/services/task/base_task_repository.dart';
import 'package:capstone_ai_client/viewmodels/home_viewmodel.dart';

class MockTaskRepository implements BaseTaskRepository {
  final StreamController<List<Task>> _streamController =
      StreamController<List<Task>>.broadcast();

  Task? lastUpdatedTask;
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
    lastUpdatedTask = task;
    final index = currentTasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      currentTasks[index] = task;
    }
    _streamController.add(currentTasks);
  }

  @override
  Future<void> deleteTask(String userId, String taskId) async {
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

void main() {
  group('HomeViewModel toggleTask subtasks synchronization', () {
    late MockTaskRepository mockRepo;
    late HomeViewModel viewModel;

    setUp(() {
      mockRepo = MockTaskRepository();
      viewModel = HomeViewModel(
        taskRepository: mockRepo,
        userId: 'test_child_user',
      );
    });

    tearDown(() {
      viewModel.dispose();
      mockRepo.dispose();
    });

    test('Completing a task automatically marks all subtasks as completed', () async {
      final initialTask = Task(
        id: 'task_1',
        title: '수학 숙제',
        isCompleted: false,
        subtasks: const [
          SubTask(id: 'st_1', title: '문제집 10쪽 풀기', isCompleted: false),
          SubTask(id: 'st_2', title: '오답노트 작성', isCompleted: false),
        ],
      );

      mockRepo.emit([initialTask]);
      await Future<void>.delayed(Duration.zero);

      await viewModel.toggleTask('task_1');

      expect(mockRepo.lastUpdatedTask, isNotNull);
      expect(mockRepo.lastUpdatedTask!.isCompleted, true);
      expect(mockRepo.lastUpdatedTask!.completedAt, isNotNull);
      expect(mockRepo.lastUpdatedTask!.subtasks.length, 2);
      expect(
        mockRepo.lastUpdatedTask!.subtasks.every((st) => st.isCompleted),
        isTrue,
      );
    });

    test('Unmarking a completed task automatically marks all subtasks as uncompleted', () async {
      final initialTask = Task(
        id: 'task_2',
        title: '과학 보고서',
        isCompleted: true,
        completedAt: DateTime.now(),
        subtasks: const [
          SubTask(id: 'st_1', title: '실험하기', isCompleted: true),
          SubTask(id: 'st_2', title: '결과 정리', isCompleted: true),
        ],
      );

      mockRepo.emit([initialTask]);
      await Future<void>.delayed(Duration.zero);

      await viewModel.toggleTask('task_2');

      expect(mockRepo.lastUpdatedTask, isNotNull);
      expect(mockRepo.lastUpdatedTask!.isCompleted, false);
      expect(mockRepo.lastUpdatedTask!.completedAt, isNull);
      expect(mockRepo.lastUpdatedTask!.subtasks.length, 2);
      expect(
        mockRepo.lastUpdatedTask!.subtasks.every((st) => !st.isCompleted),
        isTrue,
      );
    });

    test('Unmarking a task with partially completed subtasks resets all subtasks to uncompleted', () async {
      final initialTask = Task(
        id: 'task_3',
        title: '영어 단어 외우기',
        isCompleted: true,
        completedAt: DateTime.now(),
        subtasks: const [
          SubTask(id: 'st_1', title: 'Day 1 단어', isCompleted: true),
          SubTask(id: 'st_2', title: 'Day 2 단어', isCompleted: false),
        ],
      );

      mockRepo.emit([initialTask]);
      await Future<void>.delayed(Duration.zero);

      await viewModel.toggleTask('task_3');

      expect(mockRepo.lastUpdatedTask, isNotNull);
      expect(mockRepo.lastUpdatedTask!.isCompleted, false);
      expect(
        mockRepo.lastUpdatedTask!.subtasks.every((st) => !st.isCompleted),
        isTrue,
      );
    });

    test('Toggling a task with no subtasks updates task completion smoothly', () async {
      const initialTask = Task(
        id: 'task_4',
        title: '일기 쓰기',
        isCompleted: false,
        subtasks: [],
      );

      mockRepo.emit([initialTask]);
      await Future<void>.delayed(Duration.zero);

      await viewModel.toggleTask('task_4');

      expect(mockRepo.lastUpdatedTask, isNotNull);
      expect(mockRepo.lastUpdatedTask!.isCompleted, true);
      expect(mockRepo.lastUpdatedTask!.subtasks, isEmpty);
    });
  });
}
