import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/task.dart';

/// Enum for sort options, mirroring child app.
enum TaskSortOption { dueDate, createdDate }

/// ViewModel for the Parent Home Screen.
///
/// Reads the child's task list from Firestore in real-time and exposes
/// read-only derived state to the View.
class HomeViewModel extends ChangeNotifier {
  final String childUid;

  HomeViewModel({required this.childUid}) {
    _subscribeToTasks();
  }

  List<Task> _tasks = [];
  bool _isLoading = true;
  TaskSortOption _sortOption = TaskSortOption.dueDate;
  StreamSubscription<QuerySnapshot>? _subscription;

  List<Task> get tasks {
    final sorted = List<Task>.from(_tasks);
    switch (_sortOption) {
      case TaskSortOption.dueDate:
        sorted.sort((a, b) {
          if (a.dueDate == null && b.dueDate == null) return 0;
          if (a.dueDate == null) return 1;
          if (b.dueDate == null) return -1;
          return a.dueDate!.compareTo(b.dueDate!);
        });
      case TaskSortOption.createdDate:
        sorted.sort((a, b) {
          if (a.createdAt == null && b.createdAt == null) return 0;
          if (a.createdAt == null) return 1;
          if (b.createdAt == null) return -1;
          return b.createdAt!.compareTo(a.createdAt!);
        });
    }
    return sorted;
  }

  List<Task> get pendingTasks =>
      tasks.where((t) => !t.isCompleted).toList();

  List<Task> get completedTasks =>
      tasks.where((t) => t.isCompleted).toList();

  bool get isLoading => _isLoading;
  TaskSortOption get sortOption => _sortOption;

  int get remainingCount => pendingTasks.length;
  int get dueThisWeekCount =>
      pendingTasks.where((t) => t.isDueThisWeek).length;
  bool get hasUrgentTask => pendingTasks.any((t) => t.isDueToday);

  void setSortOption(TaskSortOption option) {
    _sortOption = option;
    notifyListeners();
  }

  void _subscribeToTasks() {
    if (childUid.isEmpty) {
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      _subscription = FirebaseFirestore.instance
          .collection('users')
          .doc(childUid)
          .collection('tasks')
          .snapshots()
          .listen(
            (snapshot) {
              _tasks = snapshot.docs
                  .map(
                    (doc) => Task.fromFirestore(
                      doc.data(),
                      doc.id,
                    ),
                  )
                  .toList();
              _isLoading = false;
              notifyListeners();
            },
            onError: (_) {
              // Fail silently — show empty state rather than error screen.
              _isLoading = false;
              notifyListeners();
            },
          );
    } catch (_) {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
