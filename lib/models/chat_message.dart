import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_ai/firebase_ai.dart';

enum MessageSender { user, ai }

/// Data model representing a single chat message.
///
/// Extended with Firestore serialization helpers and a [toContent] converter
/// so this model can be handed directly to the firebase_ai SDK as history.
class ChatMessage {
  final String id;
  final MessageSender sender;
  final String text;
  final DateTime timestamp;

  const ChatMessage({
    required this.id,
    required this.sender,
    required this.text,
    required this.timestamp,
  });

  bool get isUser => sender == MessageSender.user;
  bool get isAi => sender == MessageSender.ai;

  // ---------------------------------------------------------------------------
  // Firestore serialization
  // ---------------------------------------------------------------------------

  /// Reconstructs a [ChatMessage] from a Firestore document snapshot.
  /// Uses `'model'` role (firebase_ai convention) to represent AI messages.
  factory ChatMessage.fromFirestore(Map<String, dynamic> data, String id) {
    return ChatMessage(
      id: id,
      sender: data['role'] == 'user' ? MessageSender.user : MessageSender.ai,
      text: data['text'] as String? ?? '',
      timestamp: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  /// Converts this message to a Firestore-compatible map.
  /// AI messages are stored with `role: 'model'` to match the firebase_ai SDK.
  Map<String, dynamic> toFirestore() => {
        'role': isUser ? 'user' : 'model',
        'text': text,
        'createdAt': Timestamp.fromDate(timestamp),
      };

  // ---------------------------------------------------------------------------
  // firebase_ai SDK conversion
  // ---------------------------------------------------------------------------

  /// Converts this message to a [Content] object for use as LLM history.
  /// User messages become [Content.text], AI messages become [Content.model].
  Content toContent() => isUser
      ? Content.text(text)
      : Content.model([TextPart(text)]);
}
