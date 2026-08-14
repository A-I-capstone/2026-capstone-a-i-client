import 'package:cloud_firestore/cloud_firestore.dart';

/// SubTask inside a Task.
class SubTask {
  final String id;
  final String title;
  final bool isCompleted;

  const SubTask({
    required this.id,
    required this.title,
    this.isCompleted = false,
  });

  SubTask copyWith({String? id, String? title, bool? isCompleted}) {
    return SubTask(
      id: id ?? this.id,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {'id': id, 'title': title, 'isCompleted': isCompleted};
  }

  factory SubTask.fromFirestore(Map<String, dynamic> data) {
    return SubTask(
      id: data['id'] as String? ?? '',
      title: data['title'] as String? ?? '',
      isCompleted: data['isCompleted'] as bool? ?? false,
    );
  }
}

// Sentinel for copyWith: distinguishes "not provided" from "explicitly null".
const Object _sentinel = Object();

/// Model representing a task in the child app.
class Task {
  final String id;
  final String title;
  final DateTime? createdAt;
  final DateTime? dueDate;
  final DateTime? completedAt;
  final bool isCompleted;
  final List<SubTask> subtasks;
  final String chatId;

  /// Subject ID referencing the document in `users/{userId}/subjects/{subjectId}`.
  /// Empty string means no subject assigned.
  final String subjectId;

  const Task({
    required this.id,
    required this.title,
    this.createdAt,
    this.dueDate,
    this.completedAt,
    this.isCompleted = false,
    this.subtasks = const [],
    this.chatId = '',
    this.subjectId = '',
  });

  bool get isDueToday {
    final d = dueDate;
    if (d == null) return false;
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  bool get isDueThisWeek {
    final d = dueDate;
    if (d == null) return false;
    final now = DateTime.now();
    final endOfWeek = DateTime(
      now.year,
      now.month,
      now.day + (7 - now.weekday),
    );
    return d.isBefore(endOfWeek.add(const Duration(days: 1))) || isDueToday;
  }

  bool get isPastDue {
    final d = dueDate;
    if (d == null) return false;
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    return d.isBefore(startOfDay);
  }

  bool get isOverdue => !isCompleted && isPastDue;

  Task copyWith({
    String? id,
    String? title,
    DateTime? createdAt,
    Object? dueDate = _sentinel,
    Object? completedAt = _sentinel,
    bool? isCompleted,
    List<SubTask>? subtasks,
    String? chatId,
    String? subjectId,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      dueDate: dueDate == _sentinel ? this.dueDate : dueDate as DateTime?,
      completedAt: completedAt == _sentinel
          ? this.completedAt
          : completedAt as DateTime?,
      isCompleted: isCompleted ?? this.isCompleted,
      subtasks: subtasks ?? this.subtasks,
      chatId: chatId ?? this.chatId,
      subjectId: subjectId ?? this.subjectId,
    );
  }

  Map<String, dynamic> toFirestore() {
    final created = createdAt;
    final due = dueDate;
    final completed = completedAt;
    return {
      'title': title,
      'createdAt': created != null
          ? Timestamp.fromDate(created)
          : FieldValue.serverTimestamp(),
      'dueDate': due != null ? Timestamp.fromDate(due) : null,
      'completedAt': completed != null ? Timestamp.fromDate(completed) : null,
      'isCompleted': isCompleted,
      'subtasks': subtasks.map((s) => s.toFirestore()).toList(),
      'chatId': chatId,
      'subjectId': subjectId,
    };
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
      chatId: data['chatId'] as String? ?? '',
      subjectId: data['subjectId'] as String? ?? '',
    );
  }
}
