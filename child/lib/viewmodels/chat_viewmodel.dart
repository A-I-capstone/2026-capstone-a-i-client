import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared/shared.dart';

import '../models/chat_message.dart';
import '../models/task.dart';
import '../services/chat/base_chat_repository.dart';
import '../services/llm/provider_manager.dart';

/// ViewModel managing per-task chat state and business logic.
class ChatViewModel extends ChangeNotifier {
  final ProviderManager _providerManager;
  final BaseChatRepository _repository;
  final BaseAuthProvider _authProvider;

  final Task task;

  String _userId = '';
  final List<ChatMessage> _messages = [];
  final List<ChatMessage> _historyWindow = [];
  static const int _historyWindowSize = 10;

  bool _isListening = false;
  bool _isLoading = false;
  bool _isInitialized = false;

  String _streamingBuffer = '';
  bool _isStreaming = false;

  ChatViewModel({
    required ProviderManager providerManager,
    required BaseChatRepository repository,
    required BaseAuthProvider authProvider,
    required this.task,
    required String userId,
  })  : _providerManager = providerManager,
        _repository = repository,
        _authProvider = authProvider,
        _userId = userId;

  // ---------------------------------------------------------------------------
  // Public getters
  // ---------------------------------------------------------------------------

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isListening => _isListening;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;

  String get streamingBuffer => _streamingBuffer;
  bool get isStreaming => _isStreaming;

  // ---------------------------------------------------------------------------
  // Initialization
  // ---------------------------------------------------------------------------

  Future<void> initialize() async {
    if (_isInitialized) return;

    _isLoading = true;
    notifyListeners();

    try {
      if (_userId.isEmpty) {
        _userId = await _authProvider.signInAnonymously();
      }

      final loaded = await _repository.loadMessages(
        _userId,
        task.id,
        task.chatId,
      );

      _messages
        ..clear()
        ..addAll(loaded);

      _historyWindow
        ..clear()
        ..addAll(
          _messages.length > _historyWindowSize
              ? _messages.sublist(_messages.length - _historyWindowSize)
              : List.of(_messages),
        );

      _isInitialized = true;
    } catch (e) {
      debugPrint('[ChatViewModel] initialize() failed: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  void toggleListening() {
    _isListening = !_isListening;
    notifyListeners();
  }

  Future<void> sendMessage(String text) async {
    final trimmedText = text.trim();
    if (trimmedText.isEmpty) return;

    final userMsg = ChatMessage(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      sender: MessageSender.user,
      text: trimmedText,
      timestamp: DateTime.now(),
    );

    _messages.add(userMsg);
    _addToHistoryWindow(userMsg);
    _isLoading = true;
    _isStreaming = true;
    _streamingBuffer = '';
    notifyListeners();

    unawaited(_repository.saveMessage(_userId, task.id, task.chatId, userMsg));

    // Construct prompt context with Task info
    final subtaskInfo = task.subtasks.isEmpty
        ? '세부 과제 없음'
        : task.subtasks.map((s) => '- ${s.title} (${s.isCompleted ? "완료" : "미완료"})').join('\n');

    final contextPrompt = '[과제 정보]\n- 과제 제목: ${task.title}\n- 세부 과제:\n$subtaskInfo\n\n[사용자 질문]\n$trimmedText';

    try {
      debugPrint('[ChatViewModel] sendMessage() → Task AI 스트리밍 시작');
      await for (final chunk in _providerManager.sendMessageStream(
        contextPrompt,
        history: List.of(_historyWindow),
      )) {
        _streamingBuffer += chunk;
        notifyListeners();
      }

      final aiMsg = ChatMessage(
        id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
        sender: MessageSender.ai,
        text: _streamingBuffer,
        timestamp: DateTime.now(),
      );

      _messages.add(aiMsg);
      _addToHistoryWindow(aiMsg);

      unawaited(_repository.saveMessage(_userId, task.id, task.chatId, aiMsg));
    } catch (e, st) {
      debugPrint('[ChatViewModel] AI 스트리밍 중 오류 발생: $e\n$st');
      _messages.add(
        ChatMessage(
          id: 'fallback_${DateTime.now().millisecondsSinceEpoch}',
          sender: MessageSender.ai,
          text: '어머, 잠깐 생각이 딴 데로 갔나 봐! 다시 한 번 이야기해 줄래?',
          timestamp: DateTime.now(),
        ),
      );
    } finally {
      _streamingBuffer = '';
      _isLoading = false;
      _isStreaming = false;
      notifyListeners();
    }
  }

  void _addToHistoryWindow(ChatMessage message) {
    _historyWindow.add(message);
    if (_historyWindow.length > _historyWindowSize) {
      _historyWindow.removeAt(0);
    }
  }

  @override
  Future<void> dispose() async {
    await _providerManager.dispose();
    super.dispose();
  }
}
