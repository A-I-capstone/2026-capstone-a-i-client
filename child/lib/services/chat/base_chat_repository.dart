import '../../models/chat_message.dart';

/// Abstract interface for chat data-access implementations per task.
///
/// Firestore data path: `users/{userId}/tasks/{taskId}/chats/{chatId}`
abstract class BaseChatRepository {
  /// Loads all messages for [chatId] under `users/{userId}/tasks/{taskId}/chats/{chatId}/messages`.
  /// Ordered by createdAt ascending. Returns an empty list on error.
  Future<List<ChatMessage>> loadMessages(
    String userId,
    String taskId,
    String chatId,
  );

  /// Saves [message] to `users/{userId}/tasks/{taskId}/chats/{chatId}/messages/{message.id}`.
  /// Swallows errors so execution can proceed without blocking the UI.
  Future<void> saveMessage(
    String userId,
    String taskId,
    String chatId,
    ChatMessage message,
  );
}
