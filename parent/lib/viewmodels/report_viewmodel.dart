import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared/shared.dart';

import '../models/task.dart';
import '../utils/report_prompt_builder.dart';

/// Time period filter options for the report screen.
enum TimePeriod { week, month, quarter, all }

extension TimePeriodLabel on TimePeriod {
  String get label {
    switch (this) {
      case TimePeriod.week:
        return '일주일';
      case TimePeriod.month:
        return '한 달';
      case TimePeriod.quarter:
        return '한 분기';
      case TimePeriod.all:
        return '전체';
    }
  }
}

/// Classification for the submission pie chart.
enum SubmissionStatus {
  /// Completed before or without a due date.
  onTime,

  /// Due date has passed and task was not completed, or completed after due date.
  lateOrMissed,

  /// Not yet completed and due date is still in the future (or no due date).
  inProgress,
}

/// ViewModel for the Parent Report Screen.
///
/// Reads ALL of the child's tasks from Firestore in real-time and exposes
/// period-filtered, aggregated state to the view, as well as AI summary generation.
class ReportViewModel extends ChangeNotifier {
  final String childUid;
  final String childName;
  final String modelName;
  final String systemPrompt;

  ReportViewModel({
    required this.childUid,
    required this.childName,
    required this.modelName,
    required this.systemPrompt,
  }) {
    _subscribeToTasks();
  }

  List<Task> _allTasks = [];
  bool _isLoading = true;
  TimePeriod _period = TimePeriod.week;
  StreamSubscription<QuerySnapshot>? _subscription;

  // ── AI Summary State ─────────────────────────────────────────────────────

  String _aiSummary = '';
  bool _isSummaryLoading = false;
  String _summaryError = '';

  bool get isLoading => _isLoading;
  TimePeriod get period => _period;

  String get aiSummary => _aiSummary;
  bool get isSummaryLoading => _isSummaryLoading;
  String get summaryError => _summaryError;
  bool get hasSummary => _aiSummary.isNotEmpty;

  // ── Period filter ────────────────────────────────────────────────────────

  void setPeriod(TimePeriod period) {
    if (_period == period) return;
    _period = period;
    notifyListeners();
    generateAiSummary();
  }

  DateTime? get _cutoff {
    final now = DateTime.now();
    switch (_period) {
      case TimePeriod.week:
        return now.subtract(const Duration(days: 7));
      case TimePeriod.month:
        return now.subtract(const Duration(days: 30));
      case TimePeriod.quarter:
        return now.subtract(const Duration(days: 90));
      case TimePeriod.all:
        return null;
    }
  }

  List<Task> get filteredTasks {
    final cut = _cutoff;
    if (cut == null) return List.unmodifiable(_allTasks);
    return _allTasks.where((t) {
      final created = t.createdAt;
      if (created == null) return false;
      return created.isAfter(cut);
    }).toList();
  }

  // ── Derived state ────────────────────────────────────────────────────────

  /// Tasks that are not yet completed (within the selected period).
  List<Task> get pendingTasks =>
      filteredTasks.where((t) => !t.isCompleted).toList();

  /// Subject → completed task count. Empty subject is grouped as '기타'.
  Map<String, int> get subjectAchievement {
    final result = <String, int>{};
    for (final task in filteredTasks) {
      if (!task.isCompleted) continue;
      final key = task.subject.isEmpty ? '기타' : task.subject;
      result[key] = (result[key] ?? 0) + 1;
    }
    return result;
  }

  /// Categorises each task for the pie chart.
  ///
  /// Rules:
  /// 1. onTime       — completed && (no dueDate || completedAt <= dueDate)
  /// 2. lateOrMissed — dueDate is past && (not completed || completedAt > dueDate)
  /// 3. inProgress   — not completed && (no dueDate || dueDate is in the future)
  Map<SubmissionStatus, int> get submissionStats {
    final counts = {
      SubmissionStatus.onTime: 0,
      SubmissionStatus.lateOrMissed: 0,
      SubmissionStatus.inProgress: 0,
    };

    final now = DateTime.now();

    for (final task in filteredTasks) {
      final due = task.dueDate;
      final completedAt = task.completedAt;

      if (task.isCompleted) {
        // Completed on time: no due date, or finished before/on due date.
        if (due == null ||
            (completedAt != null && !completedAt.isAfter(due))) {
          counts[SubmissionStatus.onTime] =
              counts[SubmissionStatus.onTime]! + 1;
        } else {
          // Completed after due date.
          counts[SubmissionStatus.lateOrMissed] =
              counts[SubmissionStatus.lateOrMissed]! + 1;
        }
      } else {
        // Not completed.
        if (due != null && due.isBefore(now)) {
          // Due date already passed — missed.
          counts[SubmissionStatus.lateOrMissed] =
              counts[SubmissionStatus.lateOrMissed]! + 1;
        } else {
          // Still in progress.
          counts[SubmissionStatus.inProgress] =
              counts[SubmissionStatus.inProgress]! + 1;
        }
      }
    }

    return counts;
  }

  int get onTimeCount => submissionStats[SubmissionStatus.onTime] ?? 0;
  int get lateOrMissedCount =>
      submissionStats[SubmissionStatus.lateOrMissed] ?? 0;
  int get inProgressCount => submissionStats[SubmissionStatus.inProgress] ?? 0;

  // ── AI Summary Generation ─────────────────────────────────────────────────

  /// Generates the AI summary automatically upon entry or period change.
  Future<void> generateAiSummary() async {
    _isSummaryLoading = true;
    _summaryError = '';
    _aiSummary = '';
    notifyListeners();

    try {
      final chatSnippets = await _fetchChatSnippets();

      final prompt = ReportPromptBuilder.build(
        childName: childName,
        period: _period,
        filteredTasks: filteredTasks,
        chatSnippets: chatSnippets,
      );

      final provider = GeminiReportProvider(
        modelName: modelName.isNotEmpty ? modelName : 'gemini-3.6-flash',
        systemPrompt: systemPrompt,
      );

      final result = await provider.generateText(prompt);
      if (result.trim().isEmpty) {
        _summaryError = '요약 내용을 생성하지 못했어요. 잠시 후 다시 시도해 주세요.';
      } else {
        _aiSummary = result.trim();
      }
    } catch (e, st) {
      debugPrint('[ReportViewModel] generateAiSummary error: $e\n$st');
      _summaryError = '요약을 불러오지 못했어요. 잠시 후 다시 시도해 주세요.';
    } finally {
      _isSummaryLoading = false;
      notifyListeners();
    }
  }

  /// Fetches condensed user chat messages for tasks within the active period.
  Future<Map<String, List<String>>> _fetchChatSnippets() async {
    final snippets = <String, List<String>>{};

    // Compression rule: skip chat snippets for long periods or large task counts
    if (_period == TimePeriod.quarter ||
        _period == TimePeriod.all ||
        filteredTasks.length > 15) {
      return snippets;
    }

    final tasksWithChat = filteredTasks
        .where((t) => t.chatId.isNotEmpty)
        .take(3)
        .toList();

    for (final task in tasksWithChat) {
      try {
        final messagesSnap = await FirebaseFirestore.instance
            .collection('users')
            .doc(childUid)
            .collection('tasks')
            .doc(task.id)
            .collection('chats')
            .doc(task.chatId)
            .collection('messages')
            .orderBy('createdAt', descending: false)
            .limit(20)
            .get();

        final userMsgs = messagesSnap.docs
            .where((doc) => doc.data()['role'] == 'user')
            .map((doc) => doc.data()['text'] as String? ?? '')
            .where((text) => text.trim().isNotEmpty)
            .toList();

        if (userMsgs.isNotEmpty) {
          if (userMsgs.length > 5) {
            snippets[task.title] = [
              ...userMsgs.take(2),
              '...',
              ...userMsgs.skip(userMsgs.length - 2),
            ];
          } else {
            snippets[task.title] = userMsgs;
          }
        }
      } catch (e) {
        debugPrint('[ReportViewModel] _fetchChatSnippets error: $e');
      }
    }

    return snippets;
  }

  // ── Firestore subscription ────────────────────────────────────────────────

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
              _allTasks = snapshot.docs
                  .map((doc) => Task.fromFirestore(doc.data(), doc.id))
                  .toList();
              _isLoading = false;
              notifyListeners();
              generateAiSummary();
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
