import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../models/village_state.dart';
import 'base_village_repository.dart';

/// Concrete [BaseVillageRepository] using Cloud Firestore.
///
/// Firestore data path:
///   `users/{userId}/profiles/{profileId}/village/data`
class FirestoreVillageRepository implements BaseVillageRepository {
  final FirebaseFirestore _firestore;

  FirestoreVillageRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _villageDocRef(
    String userId,
    String profileId,
  ) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('profiles')
        .doc(profileId)
        .collection('village')
        .doc('data');
  }

  @override
  Future<VillageState> loadVillageState(String userId, String profileId) async {
    if (userId.isEmpty || profileId.isEmpty) {
      return VillageState.empty();
    }

    try {
      final doc = await _villageDocRef(userId, profileId).get();
      if (doc.exists && doc.data() != null) {
        return VillageState.fromFirestore(doc.data()!);
      }
      return VillageState.empty();
    } catch (e, st) {
      debugPrint('[FirestoreVillageRepository] loadVillageState error: $e\n$st');
      // Graceful degradation with safe fallback value
      return VillageState.empty();
    }
  }

  @override
  Future<void> saveVillageState(
    String userId,
    String profileId,
    VillageState state,
  ) async {
    if (userId.isEmpty || profileId.isEmpty) return;

    try {
      await _villageDocRef(userId, profileId).set(
        state.toFirestore(),
        SetOptions(merge: true),
      );
    } catch (e, st) {
      debugPrint('[FirestoreVillageRepository] saveVillageState error: $e\n$st');
      // Fail silently without disrupting UX
    }
  }
}
