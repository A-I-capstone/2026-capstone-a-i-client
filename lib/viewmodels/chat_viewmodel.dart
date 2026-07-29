import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/chat_message.dart';
import '../services/chat/base_chat_repository.dart';
import '../services/llm/provider_manager.dart';

/// ViewModel managing chat state and business logic.
/// Extends ChangeNotifier and strictly avoids importing material.dart or
/// referencing BuildContext.
///
/// Depends on [BaseChatRepository] (not the concrete Firestore class) so the
/// storage backend can be swapped in [main.dart] without touching this file.
class ChatViewModel extends ChangeNotifier {
  final ProviderManager _providerManager;
  final BaseChatRepository _repository;

  ChatViewModel({
    required ProviderManager providerManager,
    required BaseChatRepository repository,
  })  : _providerManager = providerManager,
        _repository = repository;

  // ---------------------------------------------------------------------------
  // State
  // ---------------------------------------------------------------------------

  /// All messages shown in the UI (full history, immutable view).
  final List<ChatMessage> _messages = [];

  /// Sliding window of the most recent [_historyWindowSize] messages sent to
  /// the LLM as context. Kept separate so the UI always shows the full list
  /// regardless of how many turns the model remembers.
  final List<ChatMessage> _historyWindow = [];

  /// Maximum number of messages kept in the LLM context window.
  static const int _historyWindowSize = 10;

  String _userId = '';
  String _chatId = '';

  bool _isListening = false;
  bool _isLoading = false;
  bool _isInitialized = false;

  // Streaming state
  String _streamingBuffer = '';
  bool _isStreaming = false;

  // ---------------------------------------------------------------------------
  // Public getters
  // ---------------------------------------------------------------------------

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isListening => _isListening;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;

  /// Non-empty while the AI is actively streaming a response.
  /// The View should render this as a live "typing" bubble.
  String get streamingBuffer => _streamingBuffer;
  bool get isStreaming => _isStreaming;

  // ---------------------------------------------------------------------------
  // Initialization
  // ---------------------------------------------------------------------------

  /// Must be called once from the View's [initState] (or [didChangeDependencies]).
  /// Signs in anonymously, creates a new chat room, and loads any prior messages.
  Future<void> initialize() async {
    if (_isInitialized) return;

    _isLoading = true;
    notifyListeners();

    try {
      // 1. Obtain user ID via anonymous sign-in.
      _userId = await _repository.signInAnonymously();

      // 2. Create a brand-new chat session every launch.
      _chatId = await _repository.createChat(_userId);

      // 3. Load full message history for this chat (empty for a new chatId).
      //    Keeping this call here makes it easy to switch to loading an
      //    existing chatId from a chat-list UI in the future.
      final loaded = await _repository.loadMessages(_userId, _chatId);
      _messages
        ..clear()
        ..addAll(loaded);

      // 4. Prime the LLM context window with the most recent messages.
      _historyWindow
        ..clear()
        ..addAll(
          _messages.length > _historyWindowSize
              ? _messages.sublist(_messages.length - _historyWindowSize)
              : List.of(_messages),
        );

      _isInitialized = true;
    } catch (_) {
      // Fail silently — the app continues without history.
      debugPrint('[ChatViewModel] initialize() failed; continuing without history.');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  /// Toggle speech-to-text voice recognition state.
  void toggleListening() {
    _isListening = !_isListening;
    notifyListeners();
  }

  /// Sends [text] to the LLM and progressively updates [streamingBuffer]
  /// as tokens arrive. On completion the final text is committed to
  /// [messages]. On error the buffer is discarded and a child-friendly
  /// fallback message is appended instead.
  ///
  /// Firestore saves happen fire-and-forget in the background so the UI
  /// is never blocked by network latency.
  Future<void> sendMessage(String text) async {
    final trimmedText = text.trim();
    if (trimmedText.isEmpty) return;

    // 1. Build the user message.
    final userMsg = ChatMessage(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      sender: MessageSender.user,
      text: trimmedText,
      timestamp: DateTime.now(),
    );

    // 2. Add to the in-memory lists immediately (optimistic UI update).
    _messages.add(userMsg);
    _addToHistoryWindow(userMsg);
    _isLoading = true;
    _isStreaming = true;
    _streamingBuffer = '';
    notifyListeners();

    // 3. Persist the user message in the background — do not await.
    unawaited(_repository.saveMessage(_userId, _chatId, userMsg));

    try {
      // 4. Stream the AI response, passing the current history window.
      await for (final chunk in _providerManager.sendMessageStream(
        trimmedText,
        history: List.of(_historyWindow),
      )) {
        _streamingBuffer += chunk;
        notifyListeners();
      }

      // 5. Stream completed — commit the full response as an immutable ChatMessage.
      final aiMsg = ChatMessage(
        id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
        sender: MessageSender.ai,
        text: _streamingBuffer,
        timestamp: DateTime.now(),
      );

      _messages.add(aiMsg);
      _addToHistoryWindow(aiMsg);

      // 6. Persist the AI message in the background — do not await.
      unawaited(_repository.saveMessage(_userId, _chatId, aiMsg));
    } catch (_) {
      // 7. On any error: discard all received tokens and show a child-friendly
      //    fallback. Never surface technical error messages to the child.
      _messages.add(ChatMessage(
        id: 'fallback_${DateTime.now().millisecondsSinceEpoch}',
        sender: MessageSender.ai,
        text: '어머, 잠깐 생각이 딴 데로 갔나 봐! 다시 한 번 이야기해 줄래?',
        timestamp: DateTime.now(),
      ));
    } finally {
      // 8. Always clear streaming state regardless of outcome.
      _streamingBuffer = '';
      _isLoading = false;
      _isStreaming = false;
      notifyListeners();
    }
  }

  void clearMessages() {
    _messages.clear();
    _historyWindow.clear();
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Appends [message] to [_historyWindow] and evicts the oldest entry if the
  /// window exceeds [_historyWindowSize].
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
