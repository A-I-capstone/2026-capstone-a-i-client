import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../models/chat_message.dart';
import 'base_chat_repository.dart';

/// Concrete [BaseChatRepository] communicating directly with Cloud Firestore.
///
/// Firestore data structure:
///   users/{userId}/tasks/{taskId}/chats/{chatId}/messages/{messageId}
class FirestoreChatRepository implements BaseChatRepository {
  final FirebaseFirestore _firestore;

  FirestoreChatRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _messagesRef(
    String userId,
    String taskId,
    String chatId,
  ) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('tasks')
        .doc(taskId)
        .collection('chats')
        .doc(chatId)
        .collection('messages');
  }

  @override
  Future<List<ChatMessage>> loadMessages(
    String userId,
    String taskId,
    String chatId,
  ) async {
    try {
      final snapshot = await _messagesRef(userId, taskId, chatId)
          .orderBy('createdAt', descending: false)
          .get();

      return snapshot.docs
          .map((doc) => ChatMessage.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e, st) {
      debugPrint('[FirestoreChatRepository] loadMessages error: $e\n$st');
      return [];
    }
  }

  @override
  Future<void> saveMessage(
    String userId,
    String taskId,
    String chatId,
    ChatMessage message,
  ) async {
    try {
      final ref = _messagesRef(userId, taskId, chatId);
      await ref.doc(message.id).set(message.toFirestore());

      // Update parent chat document timestamp
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('tasks')
          .doc(taskId)
          .collection('chats')
          .doc(chatId)
          .update({
        'updatedAt': FieldValue.serverTimestamp(),
        'messageCount': FieldValue.increment(1),
      });
    } catch (e, st) {
      debugPrint('[FirestoreChatRepository] saveMessage error: $e\n$st');
    }
  }
}
