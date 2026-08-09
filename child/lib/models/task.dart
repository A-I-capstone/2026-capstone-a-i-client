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

/// Model representing a task in the child app.
class Task {
  final String id;
  final String title;
  final DateTime? createdAt;
  final DateTime? dueDate;
  final bool isCompleted;
  final List<SubTask> subtasks;
  final String chatId;

  const Task({
    required this.id,
    required this.title,
    this.createdAt,
    this.dueDate,
    this.isCompleted = false,
    this.subtasks = const [],
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
    final endOfWeek = DateTime(now.year, now.month, now.day + (7 - now.weekday));
    return dueDate!.isBefore(endOfWeek.add(const Duration(days: 1))) || isDueToday;
  }

  Task copyWith({
    String? id,
    String? title,
    DateTime? createdAt,
    DateTime? dueDate,
    bool? isCompleted,
    List<SubTask>? subtasks,
    String? chatId,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      dueDate: dueDate ?? this.dueDate,
      isCompleted: isCompleted ?? this.isCompleted,
      subtasks: subtasks ?? this.subtasks,
      chatId: chatId ?? this.chatId,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'isCompleted': isCompleted,
      'subtasks': subtasks.map((s) => s.toFirestore()).toList(),
      'chatId': chatId,
    };
  }

  factory Task.fromFirestore(Map<String, dynamic> data, String id) {
    final subtasksData = data['subtasks'] as List<dynamic>? ?? [];
    return Task(
      id: id,
      title: data['title'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      dueDate: (data['dueDate'] as Timestamp?)?.toDate(),
      isCompleted: data['isCompleted'] as bool? ?? false,
      subtasks: subtasksData
          .map((s) => SubTask.fromFirestore(Map<String, dynamic>.from(s as Map)))
          .toList(),
      chatId: data['chatId'] as String? ?? '',
    );
  }
}
