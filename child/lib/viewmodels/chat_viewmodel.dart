import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared/shared.dart';

import '../models/chat_message.dart';
import '../models/chat_session.dart';
import '../services/chat/base_chat_repository.dart';
import '../services/llm/provider_manager.dart';
import 'user_viewmodel.dart';

/// ViewModel managing chat state and business logic.
/// Extends ChangeNotifier and strictly avoids importing material.dart or
/// referencing BuildContext.
///
/// Depends on [BaseChatRepository] and [UserViewModel].
class ChatViewModel extends ChangeNotifier {
  final ProviderManager _providerManager;
  final BaseChatRepository _repository;
  final UserViewModel _userViewModel;
  final BaseAuthProvider _authProvider;

  ChatViewModel({
    required ProviderManager providerManager,
    required BaseChatRepository repository,
    required UserViewModel userViewModel,
    required BaseAuthProvider authProvider,
  })  : _providerManager = providerManager,
        _repository = repository,
        _userViewModel = userViewModel,
        _authProvider = authProvider;

  // ---------------------------------------------------------------------------
  // State
  // ---------------------------------------------------------------------------

  final List<ChatMessage> _messages = [];
  final List<ChatMessage> _historyWindow = [];
  static const int _historyWindowSize = 10;

  String _userId = '';
  String _chatId = '';

  bool _isListening = false;
  bool _isLoading = false;
  bool _isInitialized = false;

  final List<ChatSession> _chatSessions = [];
  bool _isLoadingSessions = false;

  String _streamingBuffer = '';
  bool _isStreaming = false;

  // ---------------------------------------------------------------------------
  // Public getters
  // ---------------------------------------------------------------------------

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isListening => _isListening;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;

  List<ChatSession> get chatSessions => List.unmodifiable(_chatSessions);
  bool get isLoadingSessions => _isLoadingSessions;

  String get streamingBuffer => _streamingBuffer;
  bool get isStreaming => _isStreaming;

  // ---------------------------------------------------------------------------
  // Sign-in helper
  // ---------------------------------------------------------------------------

  Future<String> signInAndGetUserId() async {
    if (_userId.isNotEmpty) return _userId;
    try {
      _userId = await _authProvider.signInAnonymously();
    } catch (e, st) {
      debugPrint('[ChatViewModel] signInAndGetUserId() 오류: $e\n$st');
    }
    return _userId;
  }

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

      await _userViewModel.initialize(_userId);

      _chatId = await _repository.createChat(_userId);

      final loaded = await _repository.loadMessages(_userId, _chatId);
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

      unawaited(_deleteEmptyChats(exceptions: [_chatId]));
    } catch (_) {
      debugPrint(
        '[ChatViewModel] initialize() failed; continuing without history.',
      );
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

    final isFirstMessage = _messages.isEmpty;

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

    unawaited(_repository.saveMessage(_userId, _chatId, userMsg));

    if (isFirstMessage) {
      unawaited(_generateAndSetChatTitle(trimmedText));
    }

    try {
      debugPrint('[ChatViewModel] sendMessage() → AI 스트리밍 시작');
      await for (final chunk in _providerManager.sendMessageStream(
        trimmedText,
        history: List.of(_historyWindow),
      )) {
        _streamingBuffer += chunk;
        notifyListeners();
      }
      debugPrint('[ChatViewModel] AI 스트리밍 완료 (총 길이: ${_streamingBuffer.length}자)');

      final aiMsg = ChatMessage(
        id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
        sender: MessageSender.ai,
        text: _streamingBuffer,
        timestamp: DateTime.now(),
      );

      _messages.add(aiMsg);
      _addToHistoryWindow(aiMsg);

      unawaited(_repository.saveMessage(_userId, _chatId, aiMsg));
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

  Future<void> _generateAndSetChatTitle(String firstMessage) async {
    try {
      final generatedTitle = await _providerManager.generateTitle(firstMessage);
      if (generatedTitle.isNotEmpty) {
        await _repository.updateChatTitle(
          _userId,
          _chatId,
          generatedTitle,
        );
        unawaited(loadChatSessions());
      }
    } catch (e) {
      debugPrint('[Title Gen] error: $e');
    }
  }

  void clearMessages() {
    _messages.clear();
    _historyWindow.clear();
    notifyListeners();
  }

  Future<void> startNewChat() async {
    if (_userId.isEmpty) return;
    _isLoading = true;
    notifyListeners();
    try {
      final newChatId = await _repository.createChat(_userId);
      if (newChatId.isEmpty) return;

      _chatId = newChatId;
      _messages.clear();
      _historyWindow.clear();

      unawaited(_deleteEmptyChats(exceptions: [newChatId]));
    } catch (_) {
      debugPrint(
        '[ChatViewModel] startNewChat() failed; keeping current session.',
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadChatSessions() async {
    if (_userId.isEmpty) return;
    _isLoadingSessions = true;
    notifyListeners();
    try {
      final sessions = await _repository.listChats(_userId);
      _chatSessions
        ..clear()
        ..addAll(
          sessions.where((s) => !(s.id == _chatId && s.messageCount == 0)),
        );
    } catch (e) {
      debugPrint('[ChatViewModel] loadChatSessions() 오류: $e');
    } finally {
      _isLoadingSessions = false;
      notifyListeners();
    }
  }

  Future<void> loadChat(String sessionId) async {
    if (_userId.isEmpty || sessionId.isEmpty) return;
    if (_chatId == sessionId) return;

    final previousWasEmpty = _messages.isEmpty;

    _isLoading = true;
    notifyListeners();

    try {
      _chatId = sessionId;
      final loaded = await _repository.loadMessages(
        _userId,
        _chatId,
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

      if (previousWasEmpty) {
        unawaited(_deleteEmptyChats(exceptions: [_chatId]));
      }
    } catch (e) {
      debugPrint('[ChatViewModel] loadChat() failed: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Future<void> _deleteEmptyChats({required List<String> exceptions}) async {
    if (_userId.isEmpty) return;
    try {
      final allSessions = await _repository.listChats(_userId);
      final toDelete = allSessions
          .where((s) => s.messageCount == 0 && !exceptions.contains(s.id))
          .toList();
      if (toDelete.isEmpty) return;
      for (final session in toDelete) {
        unawaited(_repository.deleteChat(_userId, session.id));
      }
    } catch (e, st) {
      debugPrint('[ViewModel] _deleteEmptyChats() 오류: $e\n$st');
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
