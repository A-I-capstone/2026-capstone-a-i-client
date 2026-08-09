import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../models/chat_message.dart';
import '../../models/chat_session.dart';
import 'base_chat_repository.dart';

/// Concrete [BaseChatRepository] that communicates directly with Cloud Firestore.
///
/// Firestore data structure:
///   users/{userId}/chats/{chatId}
///     ├── title:        String
///     ├── updatedAt:    Timestamp
///     ├── messageCount: int
///     └── messages/ (subcollection)
///          └── {messageId}
///               ├── role:      'user' | 'model'
///               ├── text:      String
///               └── createdAt: Timestamp
class FirestoreChatRepository implements BaseChatRepository {
  final FirebaseFirestore _firestore;

  FirestoreChatRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  CollectionReference<Map<String, dynamic>> _chatsRef(String userId) =>
      _firestore.collection('users').doc(userId).collection('chats');

  // ---------------------------------------------------------------------------
  // BaseChatRepository implementation
  // ---------------------------------------------------------------------------

  @override
  Future<String> createChat(String userId) async {
    try {
      final chatRef = _chatsRef(userId).doc();

      await chatRef.set({
        'title': '새 대화',
        'updatedAt': FieldValue.serverTimestamp(),
        'messageCount': 0,
      });

      return chatRef.id;
    } catch (e, st) {
      debugPrint('[FirestoreChatRepository] createChat error: $e\n$st');
      return '';
    }
  }

  @override
  Future<List<ChatMessage>> loadMessages(String userId, String chatId) async {
    try {
      final snapshot = await _chatsRef(userId)
          .doc(chatId)
          .collection('messages')
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
    String chatId,
    ChatMessage message,
  ) async {
    try {
      final messagesRef =
          _chatsRef(userId).doc(chatId).collection('messages');

      await messagesRef.doc(message.id).set(message.toFirestore());

      // Keep the parent chat's updatedAt in sync.
      await _chatsRef(userId).doc(chatId).update({
        'updatedAt': FieldValue.serverTimestamp(),
        'messageCount': FieldValue.increment(1),
      });
      debugPrint(
        '[Firestore] 채팅 updatedAt 갱신 및 messageCount +1 완료 (chatId: $chatId)',
      );
    } catch (e, st) {
      debugPrint('[FirestoreChatRepository] saveMessage error: $e\n$st');
    }
  }

  @override
  Future<List<ChatSession>> listChats(String userId) async {
    try {
      final snapshot = await _chatsRef(
        userId,
      ).orderBy('updatedAt', descending: true).get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        final updatedAt =
            (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now();
        final messageCount = (data['messageCount'] as int?) ?? 0;
        return ChatSession(
          id: doc.id,
          title: (data['title'] as String?) ?? '새 대화',
          updatedAt: updatedAt,
          messageCount: messageCount,
        );
      }).toList();
    } catch (e, st) {
      debugPrint('[FirestoreChatRepository] listChats error: $e\n$st');
      return [];
    }
  }

  @override
  Future<void> deleteChat(String userId, String chatId) async {
    debugPrint(
      '[Firestore] deleteChat() 호출됨 (userId: $userId, chatId: $chatId)',
    );
    try {
      final chatRef = _chatsRef(userId).doc(chatId);
      final messagesSnapshot = await chatRef.collection('messages').get();
      final batch = _firestore.batch();
      for (final doc in messagesSnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      await chatRef.delete();
      debugPrint('[Firestore] deleteChat() 완료 → chatId: $chatId 삭제됨');
    } catch (e, st) {
      debugPrint('[Firestore] deleteChat() 오류: $e\n$st');
    }
  }

  @override
  Future<void> updateChatTitle(
    String userId,
    String chatId,
    String newTitle,
  ) async {
    try {
      await _chatsRef(userId).doc(chatId).update({'title': newTitle});
      debugPrint(
        '[Firestore] updateChatTitle() 완료 → chatId: $chatId, title: $newTitle',
      );
    } catch (e, st) {
      debugPrint('[FirestoreChatRepository] updateChatTitle error: $e\n$st');
    }
  }
}
