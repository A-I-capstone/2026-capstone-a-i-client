class ChatMessage {
  final String id;
  final String text;
  final bool isUser;

  const ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
  });
}
