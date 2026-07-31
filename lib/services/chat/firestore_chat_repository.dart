import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../models/chat_message.dart';
import '../../models/chat_session.dart';
import 'base_chat_repository.dart';

/// Concrete [BaseChatRepository] that communicates directly with
/// Firebase Anonymous Auth and Cloud Firestore.
///
/// Firestore data structure:
///   users/{userId}/chats/{chatId}
///     ├── title: String
///     ├── updatedAt: Timestamp
///     ├── messageCount: int
///     └── messages/ (subcollection)
///          └── {messageId}
///               ├── role: 'user' | 'model'
///               ├── text: String
///               └── createdAt: Timestamp
class FirestoreChatRepository implements BaseChatRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  FirestoreChatRepository({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  // ---------------------------------------------------------------------------
  // BaseChatRepository implementation
  // ---------------------------------------------------------------------------

  @override
  Future<String> signInAnonymously() async {
    try {
      // Reuse existing session if already signed in.
      final existingUser = _auth.currentUser;
      if (existingUser != null) return existingUser.uid;

      final credential = await _auth.signInAnonymously();
      return credential.user?.uid ?? '';
    } catch (e, st) {
      debugPrint('[FirestoreChatRepository] signInAnonymously error: $e\n$st');
      return '';
    }
  }

  @override
  Future<String> createChat(String userId) async {
    try {
      final chatRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('chats')
          .doc(); // auto-generated chatId

      await chatRef.set({
        // TODO: Replace fixed title with auto-generated title in a future phase.
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
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('chats')
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
      final messagesRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('chats')
          .doc(chatId)
          .collection('messages');

      await messagesRef.doc(message.id).set(message.toFirestore());

      // Keep the parent chat's updatedAt in sync.
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('chats')
          .doc(chatId)
          .update({
            'updatedAt': FieldValue.serverTimestamp(),
            'messageCount': FieldValue.increment(1),
          });
      debugPrint(
        '[Firestore] 채팅 updatedAt 갱신 및 messageCount +1 완료 (chatId: $chatId)',
      );
    } catch (e, st) {
      debugPrint('[FirestoreChatRepository] saveMessage error: $e\n$st');
      // Intentionally swallowed — caller uses unawaited fire-and-forget.
    }
  }

  @override
  Future<List<ChatSession>> listChats(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('chats')
          .orderBy('updatedAt', descending: true)
          .get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        final updatedAt =
            (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now();
        final messageCount = (data['messageCount'] as int?) ?? 0;
        debugPrint(
          '[Firestore]   - chatId: ${doc.id}, title: "${data['title']}", updatedAt: $updatedAt, messageCount: $messageCount',
        );
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
      final chatRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('chats')
          .doc(chatId);
      // Firestore does not automatically delete subcollections when a document
      // is deleted, so we must delete all messages first.
      final messagesSnapshot = await chatRef.collection('messages').get();
      debugPrint(
        '[Firestore] deleteChat() → messages 서브컬렉션 ${messagesSnapshot.docs.length}개 삭제 중',
      );
      final batch = _firestore.batch();
      for (final doc in messagesSnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      debugPrint('[Firestore] deleteChat() → messages 서브컬렉션 삭제 완료');
      // Now delete the parent chat document itself.
      await chatRef.delete();
      debugPrint('[Firestore] deleteChat() 완료 → chatId: $chatId 삭제됨');
    } catch (e, st) {
      debugPrint('[Firestore] deleteChat() 오류: $e\n$st');
      // Intentionally swallowed — callers treat this as fire-and-forget.
    }
  }
}
