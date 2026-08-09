import '../../models/task.dart';

/// Abstract interface for Task data-access operations.
abstract class BaseTaskRepository {
  /// Loads all tasks for [userId], ordered by `createdAt` descending.
  Future<List<Task>> loadTasks(String userId);

  /// Stream of tasks for [userId] for real-time updates.
  Stream<List<Task>> streamTasks(String userId);

  /// Creates a new task under `users/{userId}/tasks`.
  /// Automatically initializes a chat document under `users/{userId}/tasks/{taskId}/chats/{chatId}`.
  /// Returns the created Task with assigned IDs.
  Future<Task?> createTask(String userId, Task task);

  /// Updates an existing task document.
  Future<void> updateTask(String userId, Task task);

  /// Deletes a task document and its nested sub-collections.
  Future<void> deleteTask(String userId, String taskId);

  /// Toggles completion status of a specific subtask.
  Future<void> toggleSubtask(String userId, String taskId, String subtaskId);
}
