import '../../models/chat_message.dart';
import '../../models/chat_session.dart';

/// Abstract interface for all chat data-access implementations.
///
/// All methods require both [userId] (device UID) and [profileId] so that
/// chat data is stored under the active user profile:
///   users/{userId}/profiles/{profileId}/chats/{chatId}
///
/// The ViewModel depends only on this interface, so the underlying storage
/// backend (Firestore, Supabase, SQLite…) can be swapped without touching
/// any ViewModel code.
abstract class BaseChatRepository {
  /// Signs in anonymously and returns the user's UID.
  /// If a session already exists the existing UID is returned unchanged.
  Future<String> signInAnonymously();

  /// Creates a new chat room for the given [userId] / [profileId] pair
  /// and returns its generated [chatId].
  Future<String> createChat(String userId, String profileId);

  /// Returns all messages in [chatId] ordered by creation time (ascending).
  Future<List<ChatMessage>> loadMessages(
    String userId,
    String profileId,
    String chatId,
  );

  /// Persists a single [message] to storage.
  /// Implementations should fail silently on error — this is intended to be
  /// called fire-and-forget via [unawaited].
  Future<void> saveMessage(
    String userId,
    String profileId,
    String chatId,
    ChatMessage message,
  );

  /// Returns all chat sessions for the given [userId] / [profileId] pair,
  /// ordered by most recently updated (descending). Returns an empty list on error.
  Future<List<ChatSession>> listChats(String userId, String profileId);

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
