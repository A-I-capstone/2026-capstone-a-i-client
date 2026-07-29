/// Data model representing a chat session (conversation room).
///
/// Corresponds to the Firestore document at:
///   users/{userId}/chats/{chatId}
class ChatSession {
  final String id;
  final String title;
  final DateTime updatedAt;

  const ChatSession({
    required this.id,
    required this.title,
    required this.updatedAt,
  });
}
