import '../../models/chat_message.dart';
import '../../models/chat_session.dart';

/// Abstract interface for chat data-access implementations.
///
/// Firestore data path: `users/{userId}/chats/{chatId}`
abstract class BaseChatRepository {
  /// Creates a new chat room document under `users/{userId}/chats`.
  /// Returns the generated chatId, or an empty string on error.
  Future<String> createChat(String userId);

  /// Loads all messages for [chatId] under `users/{userId}/chats/{chatId}/messages`.
  /// Ordered by createdAt ascending. Returns an empty list on error.
  Future<List<ChatMessage>> loadMessages(String userId, String chatId);

  /// Saves [message] to `users/{userId}/chats/{chatId}/messages/{message.id}`.
  /// Also updates the parent chat document's `updatedAt` timestamp and increments `messageCount`.
  /// Swallows errors so execution can proceed without blocking the UI.
  Future<void> saveMessage(String userId, String chatId, ChatMessage message);

  /// Lists all chat sessions for [userId], ordered by `updatedAt` descending.
  /// Returns an empty list on error.
  Future<List<ChatSession>> listChats(String userId);

  /// Deletes the chat room document and all nested messages for [chatId].
  /// Fails silently on error.
  Future<void> deleteChat(String userId, String chatId);

  /// Updates the `title` field of the chat room document.
  Future<void> updateChatTitle(String userId, String chatId, String newTitle);
}
