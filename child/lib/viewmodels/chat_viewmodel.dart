import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared/shared.dart';

import '../models/chat_message.dart';
import '../models/chat_session.dart';
import '../models/profile.dart';
import '../services/chat/base_chat_repository.dart';
import '../services/llm/provider_manager.dart';
import 'profile_viewmodel.dart';

/// ViewModel managing chat state and business logic.
/// Extends ChangeNotifier and strictly avoids importing material.dart or
/// referencing BuildContext.
///
/// Depends on [BaseChatRepository] (not the concrete Firestore class) so the
/// storage backend can be swapped in [main.dart] without touching this file.
///
/// Depends on [ProfileViewModel] to read the currently active profile ID.
/// When the active profile changes, callers must invoke [switchToProfile]
/// to reset the chat state and start a fresh session under the new profile.
class ChatViewModel extends ChangeNotifier {
  final ProviderManager _providerManager;
  final BaseChatRepository _repository;
  final ProfileViewModel _profileViewModel;
  final BaseAuthProvider _authProvider;

  ChatViewModel({
    required ProviderManager providerManager,
    required BaseChatRepository repository,
    required ProfileViewModel profileViewModel,
    required BaseAuthProvider authProvider,
  }) : _providerManager = providerManager,
       _repository = repository,
       _profileViewModel = profileViewModel,
       _authProvider = authProvider;

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

  /// List of past chat sessions shown in the Drawer.
  final List<ChatSession> _chatSessions = [];
  bool _isLoadingSessions = false;

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

  /// Unmodifiable view of past sessions for the Drawer list.
  List<ChatSession> get chatSessions => List.unmodifiable(_chatSessions);
  bool get isLoadingSessions => _isLoadingSessions;

  /// Non-empty while the AI is actively streaming a response.
  /// The View should render this as a live "typing" bubble.
  String get streamingBuffer => _streamingBuffer;
  bool get isStreaming => _isStreaming;

  // ---------------------------------------------------------------------------
  // Convenience accessor
  // ---------------------------------------------------------------------------

  /// Returns the active profile's ID. Falls back to an empty string so all
  /// repository calls degrade gracefully when no profile is set.
  String get _profileId => _profileViewModel.activeProfile?.id ?? '';

  // ---------------------------------------------------------------------------
  // Sign-in helper (called by ChatView before ProfileViewModel.initialize)
  // ---------------------------------------------------------------------------

  /// Signs in anonymously and caches the userId internally.
  /// Subsequent calls to [initialize] will reuse the cached userId.
  /// Returns the userId (empty string on failure).
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

  /// Must be called once from the View's [initState] (or [didChangeDependencies]).
  /// Signs in anonymously, creates a new chat room, and loads any prior messages.
  ///
  /// Assumes [ProfileViewModel.initialize] has already been called so that
  /// [_profileViewModel.activeProfile] is non-null.
  Future<void> initialize() async {
    if (_isInitialized) return;

    _isLoading = true;
    notifyListeners();

    try {
      // 1. Obtain user ID via anonymous sign-in (reuses cached value if already
      //    set by [signInAndGetUserId] called from ChatView.initState).
      if (_userId.isEmpty) {
        _userId = await _authProvider.signInAnonymously();
      }

      // 2. Create a brand-new chat session under the active profile.
      _chatId = await _repository.createChat(_userId, _profileId);

      // 3. Load full message history for this chat (empty for a new chatId).
      final loaded = await _repository.loadMessages(
        _userId,
        _profileId,
        _chatId,
      );
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

      // 5. Background cleanup: delete empty sessions from previous runs.
      //    The current _chatId is always excluded from deletion.
      unawaited(_deleteEmptyChats(exceptions: [_chatId]));
    } catch (_) {
      // Fail silently — the app continues without history.
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

    final isFirstMessage = _messages.isEmpty;

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
    unawaited(_repository.saveMessage(_userId, _profileId, _chatId, userMsg));

    if (isFirstMessage) {
      unawaited(_generateAndSetChatTitle(trimmedText));
    }

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
      unawaited(_repository.saveMessage(_userId, _profileId, _chatId, aiMsg));
    } catch (_) {
      // 7. On any error: discard all received tokens and show a child-friendly
      //    fallback. Never surface technical error messages to the child.
      _messages.add(
        ChatMessage(
          id: 'fallback_${DateTime.now().millisecondsSinceEpoch}',
          sender: MessageSender.ai,
          text: '어머, 잠깐 생각이 딴 데로 갔나 봐! 다시 한 번 이야기해 줄래?',
          timestamp: DateTime.now(),
        ),
      );
    } finally {
      // 8. Always clear streaming state regardless of outcome.
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
          _profileId,
          _chatId,
          generatedTitle,
        );
        // Refresh the local drawer list in the background
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

  /// Creates a brand-new chat session in Firestore, clears the current
  /// message list, and resets the LLM history window so the next conversation
  /// starts fresh. Fails silently — the UI simply keeps the existing session.
  Future<void> startNewChat() async {
    if (_userId.isEmpty) return;
    _isLoading = true;
    notifyListeners();
    try {
      final newChatId = await _repository.createChat(_userId, _profileId);
      if (newChatId.isEmpty) return; // createChat failed silently

      _chatId = newChatId;
      _messages.clear();
      _historyWindow.clear();

      // Background cleanup: delete sessions with no messages.
      unawaited(_deleteEmptyChats(exceptions: [newChatId]));
    } catch (_) {
      // Fail silently — child stays in the current session.
      debugPrint(
        '[ChatViewModel] startNewChat() failed; keeping current session.',
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Switches the active profile context by resetting all chat state and
  /// starting a fresh chat session under [profile].
  ///
  /// Should be called whenever [ProfileViewModel.activeProfile] changes.
  Future<void> switchToProfile(Profile profile) async {
    if (_userId.isEmpty) return;
    debugPrint(
      '[ChatViewModel] switchToProfile() → ${profile.name} (${profile.id})',
    );

    _isLoading = true;
    _messages.clear();
    _historyWindow.clear();
    _chatId = '';
    notifyListeners();

    try {
      // Create a fresh chat session under the new profile.
      final newChatId = await _repository.createChat(_userId, profile.id);
      if (newChatId.isEmpty) return;

      _chatId = newChatId;

      // Background cleanup: remove empty sessions for the new profile.
      unawaited(_deleteEmptyChats(exceptions: [newChatId]));
    } catch (e, st) {
      debugPrint('[ChatViewModel] switchToProfile() 오류: $e\n$st');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetches the full list of chat sessions from the repository and updates
  /// [chatSessions]. Safe to call multiple times (e.g. every time the Drawer
  /// opens). Fails silently to keep the child-friendly UX.
  Future<void> loadChatSessions() async {
    if (_userId.isEmpty || _profileId.isEmpty) return;
    _isLoadingSessions = true;
    notifyListeners();
    try {
      final sessions = await _repository.listChats(_userId, _profileId);
      debugPrint(
        '[ChatViewModel] loadChatSessions() 전체 DB 세션 수: ${sessions.length} (현재 _chatId: $_chatId)',
      );
      for (final s in sessions) {
        debugPrint(
          '[ChatViewModel]   - session(id: ${s.id}, messageCount: ${s.messageCount})',
        );
      }
      _chatSessions
        ..clear()
        ..addAll(
          sessions.where((s) => !(s.id == _chatId && s.messageCount == 0)),
        );
      debugPrint(
        '[ChatViewModel] loadChatSessions() 필터링 후 서랍(Drawer) 노출 세션 수: ${_chatSessions.length}',
      );
    } catch (e) {
      debugPrint('[ChatViewModel] loadChatSessions() 오류: $e');
    } finally {
      _isLoadingSessions = false;
      notifyListeners();
    }
  }

  /// Loads a specific chat session by ID and makes it the active session.
  /// Fails silently to keep child-friendly UX.
  Future<void> loadChat(String sessionId) async {
    if (_userId.isEmpty || sessionId.isEmpty) return;
    if (_chatId == sessionId) return;

    final previousChatId = _chatId;
    final previousWasEmpty = _messages.isEmpty;
    debugPrint(
      '[ChatViewModel] loadChat() 호출됨: 이전 _chatId = $previousChatId (isEmpty: $previousWasEmpty) -> 이동할 sessionId = $sessionId',
    );

    _isLoading = true;
    notifyListeners();

    try {
      _chatId = sessionId;
      final loaded = await _repository.loadMessages(
        _userId,
        _profileId,
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
      debugPrint('[ChatViewModel] loadChat() 완료: 불러온 메시지 수 = ${loaded.length}');

      // 이전 채팅방이 비어있었다면 백그라운드 정리를 수행 (현재 이동한 채팅방은 예외 처리)
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

  /// Fetches all sessions for the current user+profile and deletes any that
  /// have [ChatSession.messageCount] == 0, skipping IDs listed in [exceptions].
  ///
  /// Designed to be called fire-and-forget via [unawaited] so it never blocks
  /// the UI. Fails silently on error.
  Future<void> _deleteEmptyChats({required List<String> exceptions}) async {
    if (_profileId.isEmpty) return;
    debugPrint('[ViewModel] _deleteEmptyChats() 호출됨 (exceptions: $exceptions)');
    try {
      final allSessions = await _repository.listChats(_userId, _profileId);
      final toDelete = allSessions
          .where((s) => s.messageCount == 0 && !exceptions.contains(s.id))
          .toList();
      if (toDelete.isEmpty) {
        debugPrint('[ViewModel] _deleteEmptyChats() 삭제 대상 없음');
        return;
      }
      debugPrint('[ViewModel] _deleteEmptyChats() 삭제 대상 ${toDelete.length}개:');
      for (final session in toDelete) {
        debugPrint('[ViewModel]   - 빈 채팅 삭제: ${session.id}');
        unawaited(_repository.deleteChat(_userId, _profileId, session.id));
      }
    } catch (e, st) {
      debugPrint('[ViewModel] _deleteEmptyChats() 오류: $e\n$st');
    }
  }

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
