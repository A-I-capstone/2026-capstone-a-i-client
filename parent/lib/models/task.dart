import 'package:cloud_firestore/cloud_firestore.dart';

/// SubTask inside a Task — read-only mirror of the child app schema.
class SubTask {
  final String id;
  final String title;
  final bool isCompleted;

  const SubTask({
    required this.id,
    required this.title,
    this.isCompleted = false,
  });

  factory SubTask.fromFirestore(Map<String, dynamic> data) {
    return SubTask(
      id: data['id'] as String? ?? '',
      title: data['title'] as String? ?? '',
      isCompleted: data['isCompleted'] as bool? ?? false,
    );
  }
}

/// Task model for the parent app — read-only view of child's Firestore data.
///
/// Firestore path: users/{childUid}/tasks/{taskId}
class Task {
  final String id;
  final String title;
  final DateTime? createdAt;
  final DateTime? dueDate;
  final DateTime? completedAt;
  final bool isCompleted;
  final List<SubTask> subtasks;

  /// Subject label for the task (e.g. '수학', '영어').
  /// Empty string means no subject assigned — aggregated as '기타'.
  final String subject;

  /// Chat ID associated with this task.
  final String chatId;

  const Task({
    required this.id,
    required this.title,
    this.createdAt,
    this.dueDate,
    this.completedAt,
    this.isCompleted = false,
    this.subtasks = const [],
    this.subject = '',
    this.chatId = '',
  });

  bool get isDueToday {
    if (dueDate == null) return false;
    final now = DateTime.now();
    return dueDate!.year == now.year &&
        dueDate!.month == now.month &&
        dueDate!.day == now.day;
  }

  bool get isDueThisWeek {
    if (dueDate == null) return false;
    final now = DateTime.now();
    final endOfWeek = DateTime(
      now.year,
      now.month,
      now.day + (7 - now.weekday),
    );
    return dueDate!.isBefore(endOfWeek.add(const Duration(days: 1))) ||
        isDueToday;
  }

  factory Task.fromFirestore(Map<String, dynamic> data, String id) {
    final subtasksData = data['subtasks'] as List<dynamic>? ?? [];
    return Task(
      id: id,
      title: data['title'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      dueDate: (data['dueDate'] as Timestamp?)?.toDate(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
      isCompleted: data['isCompleted'] as bool? ?? false,
      subtasks: subtasksData
          .map(
            (s) => SubTask.fromFirestore(Map<String, dynamic>.from(s as Map)),
          )
          .toList(),
      subject: data['subject'] as String? ?? '',
      chatId: data['chatId'] as String? ?? '',
    );
  }
}
