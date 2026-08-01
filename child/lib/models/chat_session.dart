/// Data model representing a chat session (conversation room).
///
/// Corresponds to the Firestore document at:
///   users/{userId}/chats/{chatId}
class ChatSession {
  final String id;
  final String title;
  final DateTime updatedAt;

  /// Total number of messages saved in this session (user + AI combined).
  /// Written by [FirestoreChatRepository.saveMessage] via FieldValue.increment(1).
  final int messageCount;
  const ChatSession({
    required this.id,
    required this.title,
    required this.updatedAt,
    required this.messageCount,
  });
}
