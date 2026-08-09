import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Service managing user data stored at `users/{userId}`.
class UserRepository {
  final FirebaseFirestore _firestore;

  UserRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _userRef(String userId) =>
      _firestore.collection('users').doc(userId);

  /// Gets the user's name from Firestore `users/{userId}`.
  /// If document does not exist or name is empty, returns default fallback [defaultName].
  Future<String> getName(String userId, {String defaultName = '내 친구'}) async {
    try {
      final doc = await _userRef(userId).get();
      if (doc.exists && doc.data() != null) {
        final name = doc.data()!['name'] as String?;
        if (name != null && name.trim().isNotEmpty) {
          return name.trim();
        }
      }
    } catch (e, st) {
      debugPrint('[UserRepository] getName error: $e\n$st');
    }
    return defaultName;
  }

  /// Sets or updates the user's name at `users/{userId}` (field: `name`).
  Future<void> updateName(String userId, String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    try {
      await _userRef(userId).set({
        'name': trimmed,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      debugPrint('[UserRepository] updateName success: $trimmed for $userId');
    } catch (e, st) {
      debugPrint('[UserRepository] updateName error: $e\n$st');
    }
  }
}
