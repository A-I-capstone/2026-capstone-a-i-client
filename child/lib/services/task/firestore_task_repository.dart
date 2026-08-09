import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../models/task.dart';
import 'base_task_repository.dart';

/// Concrete implementation of [BaseTaskRepository] using Firebase Firestore.
///
/// Data paths:
///   users/{userId}/tasks/{taskId}
///   users/{userId}/tasks/{taskId}/chats/{chatId}
class FirestoreTaskRepository implements BaseTaskRepository {
  final FirebaseFirestore _firestore;

  FirestoreTaskRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _tasksRef(String userId) =>
      _firestore.collection('users').doc(userId).collection('tasks');

  @override
  Future<List<Task>> loadTasks(String userId) async {
    try {
      final snapshot = await _tasksRef(userId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Task.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e, st) {
      debugPrint('[FirestoreTaskRepository] loadTasks error: $e\n$st');
      return [];
    }
  }

  @override
  Stream<List<Task>> streamTasks(String userId) {
    return _tasksRef(userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Task.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  @override
  Future<Task?> createTask(String userId, Task task) async {
    try {
      final taskRef = _tasksRef(userId).doc();
      final chatId = 'chat_${taskRef.id}';

      final newTask = task.copyWith(
        id: taskRef.id,
        chatId: chatId,
        createdAt: task.createdAt ?? DateTime.now(),
      );

      // Create Task document
      await taskRef.set(newTask.toFirestore());

      // Initialize Chat room document under task
      final chatRef = taskRef.collection('chats').doc(chatId);
      await chatRef.set({
        'title': '${newTask.title} 학습 도우미',
        'updatedAt': FieldValue.serverTimestamp(),
        'messageCount': 0,
      });

      return newTask;
    } catch (e, st) {
      debugPrint('[FirestoreTaskRepository] createTask error: $e\n$st');
      return null;
    }
  }

  @override
  Future<void> updateTask(String userId, Task task) async {
    try {
      await _tasksRef(userId).doc(task.id).update(task.toFirestore());
    } catch (e, st) {
      debugPrint('[FirestoreTaskRepository] updateTask error: $e\n$st');
    }
  }

  @override
  Future<void> deleteTask(String userId, String taskId) async {
    try {
      final taskDocRef = _tasksRef(userId).doc(taskId);

      // Delete messages in chat subcollection first if present
      final chatsSnapshot = await taskDocRef.collection('chats').get();
      for (final chatDoc in chatsSnapshot.docs) {
        final messagesSnapshot = await chatDoc.reference.collection('messages').get();
        final batch = _firestore.batch();
        for (final msgDoc in messagesSnapshot.docs) {
          batch.delete(msgDoc.reference);
        }
        batch.delete(chatDoc.reference);
        await batch.commit();
      }

      await taskDocRef.delete();
    } catch (e, st) {
      debugPrint('[FirestoreTaskRepository] deleteTask error: $e\n$st');
    }
  }

  @override
  Future<void> toggleSubtask(
    String userId,
    String taskId,
    String subtaskId,
  ) async {
    try {
      final docSnapshot = await _tasksRef(userId).doc(taskId).get();
      if (!docSnapshot.exists || docSnapshot.data() == null) return;

      final task = Task.fromFirestore(docSnapshot.data()!, docSnapshot.id);
      final updatedSubtasks = task.subtasks.map((st) {
        if (st.id == subtaskId) {
          return st.copyWith(isCompleted: !st.isCompleted);
        }
        return st;
      }).toList();

      await _tasksRef(userId).doc(taskId).update({
        'subtasks': updatedSubtasks.map((s) => s.toFirestore()).toList(),
      });
    } catch (e, st) {
      debugPrint('[FirestoreTaskRepository] toggleSubtask error: $e\n$st');
    }
  }
}
