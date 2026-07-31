import '../../models/chat_message.dart';
import '../../models/chat_session.dart';

/// Abstract interface for all chat data-access implementations.
///
/// Mirrors [BaseLLMProvider] in the llm/ layer — the ViewModel depends only
/// on this interface, so the underlying storage backend (Firestore, Supabase,
/// SQLite, …) can be swapped without touching any ViewModel code.
///
/// Extension points for future phases (stub — do not implement yet):
///   - TODO: updateChatTitle(String userId, String chatId, String title)
abstract class BaseChatRepository {
  /// Signs in anonymously and returns the user's UID.
  /// If a session already exists the existing UID is returned unchanged.
  Future<String> signInAnonymously();

  /// Creates a new chat room for [userId] and returns its generated [chatId].
  /// Each call always produces a brand-new chat; no previous conversation is
  /// resumed automatically.
  Future<String> createChat(String userId);

  /// Returns all messages in [chatId] ordered by creation time (ascending).
  Future<List<ChatMessage>> loadMessages(String userId, String chatId);

  /// Persists a single [message] to storage.
  /// Implementations should fail silently on error — this is intended to be
  /// called fire-and-forget via [unawaited].
  Future<void> saveMessage(String userId, String chatId, ChatMessage message);

  /// Returns all chat sessions for [userId] ordered by most recently updated
  /// (descending). Returns an empty list on error.
  Future<List<ChatSession>> listChats(String userId);

  /// Permanently deletes the chat document and all its messages subcollection
  /// for the given [userId] / [profileId] / [chatId] triple.
  /// Fails silently on error.
  Future<void> deleteChat(String userId, String profileId, String chatId);

  /// Updates the title of the chat document.
  Future<void> updateChatTitle(
    String userId,
    String profileId,
    String chatId,
    String newTitle,
  );
}
