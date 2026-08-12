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

  SubTask copyWith({
    String? id,
    String? title,
    bool? isCompleted,
  }) {
    return SubTask(
      id: id ?? this.id,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'title': title,
      'isCompleted': isCompleted,
    };
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

  /// Subject label for the task (e.g. '수학', '영어').
  /// Empty string means no subject assigned — aggregated as '기타'.
  final String subject;

  const Task({
    required this.id,
    required this.title,
    this.createdAt,
    this.dueDate,
    this.completedAt,
    this.isCompleted = false,
    this.subtasks = const [],
    this.chatId = '',
    this.subject = '',
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
    final endOfWeek = DateTime(now.year, now.month, now.day + (7 - now.weekday));
    return dueDate!.isBefore(endOfWeek.add(const Duration(days: 1))) || isDueToday;
  }

  Task copyWith({
    String? id,
    String? title,
    DateTime? createdAt,
    Object? dueDate = _sentinel,
    Object? completedAt = _sentinel,
    bool? isCompleted,
    List<SubTask>? subtasks,
    String? chatId,
    String? subject,
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
      subject: subject ?? this.subject,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'isCompleted': isCompleted,
      'subtasks': subtasks.map((s) => s.toFirestore()).toList(),
      'chatId': chatId,
      'subject': subject,
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
          .map((s) => SubTask.fromFirestore(Map<String, dynamic>.from(s as Map)))
          .toList(),
      chatId: data['chatId'] as String? ?? '',
      subject: data['subject'] as String? ?? '',
    );
  }
}
