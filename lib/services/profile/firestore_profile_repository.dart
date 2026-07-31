import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../models/profile.dart';
import 'base_profile_repository.dart';

/// Concrete [BaseProfileRepository] that reads/writes to Cloud Firestore.
///
/// Firestore data structure:
///   users/{userId}/profiles/{profileId}
///     ├── name:      String
///     ├── avatar:    String   (empty until avatar upload is implemented)
///     └── createdAt: Timestamp
class FirestoreProfileRepository implements BaseProfileRepository {
  final FirebaseFirestore _firestore;

  FirestoreProfileRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  CollectionReference<Map<String, dynamic>> _profilesRef(String userId) =>
      _firestore.collection('users').doc(userId).collection('profiles');

  // ---------------------------------------------------------------------------
  // BaseProfileRepository implementation
  // ---------------------------------------------------------------------------

  @override
  Future<List<Profile>> listProfiles(String userId) async {
    try {
      final snapshot = await _profilesRef(userId)
          .orderBy('createdAt', descending: false)
          .get();
      return snapshot.docs
          .map((doc) => Profile.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e, st) {
      debugPrint('[FirestoreProfileRepository] listProfiles error: $e\n$st');
      return [];
    }
  }

  @override
  Future<String> createProfile(String userId, String name) async {
    try {
      final ref = _profilesRef(userId).doc();
      await ref.set({
        'name': name,
        'avatar': '',
        'createdAt': FieldValue.serverTimestamp(),
      });
      return ref.id;
    } catch (e, st) {
      debugPrint('[FirestoreProfileRepository] createProfile error: $e\n$st');
      return '';
    }
  }

  @override
  Future<void> updateProfile(
    String userId,
    String profileId,
    String name,
  ) async {
    try {
      await _profilesRef(userId).doc(profileId).update({'name': name});
    } catch (e, st) {
      debugPrint('[FirestoreProfileRepository] updateProfile error: $e\n$st');
    }
  }

  @override
  Future<void> deleteProfile(String userId, String profileId) async {
    debugPrint(
      '[FirestoreProfileRepository] deleteProfile() 호출됨 '
      '(userId: $userId, profileId: $profileId)',
    );
    try {
      final profileRef = _profilesRef(userId).doc(profileId);

      // 1. Delete all messages inside each chat of this profile.
      final chatsSnapshot =
          await profileRef.collection('chats').get();

      final batch = _firestore.batch();

      for (final chatDoc in chatsSnapshot.docs) {
        final messagesSnapshot =
            await chatDoc.reference.collection('messages').get();
        for (final msgDoc in messagesSnapshot.docs) {
          batch.delete(msgDoc.reference);
        }
        batch.delete(chatDoc.reference);
      }

      await batch.commit();
      debugPrint(
        '[FirestoreProfileRepository] deleteProfile() → chats + messages 삭제 완료',
      );

      // 2. Delete the profile document itself.
      await profileRef.delete();
      debugPrint(
        '[FirestoreProfileRepository] deleteProfile() 완료 → profileId: $profileId',
      );
    } catch (e, st) {
      debugPrint('[FirestoreProfileRepository] deleteProfile error: $e\n$st');
    }
  }
}
