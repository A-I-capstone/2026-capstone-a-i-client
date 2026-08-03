import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'base_child_pairing_provider.dart';

/// [BaseChildPairingProvider] backed by Cloud Firestore.
///
/// Validates the pairing code and atomically creates the `families` document
/// using a Firestore batch write.
///
/// Firestore structure written:
///   pairing_codes/{code}
///     └── isUsed: true   (updated on success)
///
///   families/{familyId}
///     ├── parentUid: String
///     ├── childUid:  String
///     ├── pairedAt:  Timestamp
///     └── status:    "active"
class FirestoreChildPairingProvider implements BaseChildPairingProvider {
  final FirebaseFirestore _firestore;

  FirestoreChildPairingProvider({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<String> submitPairingCode({
    required String code,
    required String childUid,
  }) async {
    try {
      final codeRef = _firestore.collection('pairing_codes').doc(code);
      final codeSnap = await codeRef.get();

      if (!codeSnap.exists) {
        debugPrint('[FirestoreChildPairingProvider] 코드 없음: $code');
        return '';
      }

      final data = codeSnap.data()!;

      // 1. Already used check
      if ((data['isUsed'] as bool?) == true) {
        debugPrint('[FirestoreChildPairingProvider] 이미 사용된 코드: $code');
        return '';
      }

      // 2. Expiry check
      final expiresAt = (data['expiresAt'] as Timestamp?)?.toDate();
      if (expiresAt == null || DateTime.now().isAfter(expiresAt)) {
        debugPrint('[FirestoreChildPairingProvider] 만료된 코드: $code');
        return '';
      }

      // 3. Attempts check (> 5 → expired)
      final attempts = (data['attempts'] as int?) ?? 0;
      if (attempts > 5) {
        debugPrint('[FirestoreChildPairingProvider] 시도 횟수 초과: $code');
        return '';
      }

      final parentUid = (data['parentUid'] as String?) ?? '';
      if (parentUid.isEmpty) {
        debugPrint('[FirestoreChildPairingProvider] parentUid 없음: $code');
        return '';
      }

      // 4. Atomic batch: mark code as used + create family document
      final familyRef = _firestore.collection('families').doc();
      final batch = _firestore.batch();

      batch.update(codeRef, {'isUsed': true});
      batch.set(familyRef, {
        'parentUid': parentUid,
        'childUid': childUid,
        'pairedAt': FieldValue.serverTimestamp(),
        'status': 'active',
      });

      await batch.commit();

      debugPrint(
        '[FirestoreChildPairingProvider] 페어링 완료 → familyId: ${familyRef.id}',
      );
      return familyRef.id;
    } catch (e, st) {
      debugPrint('[FirestoreChildPairingProvider] submitPairingCode 오류: $e\n$st');
      return '';
    }
  }

  /// Increments the attempts counter for [code] when validation fails.
  /// Called fire-and-forget — never throws.
  Future<void> incrementAttempts(String code) async {
    try {
      await _firestore.collection('pairing_codes').doc(code).update({
        'attempts': FieldValue.increment(1),
      });
    } catch (e) {
      debugPrint('[FirestoreChildPairingProvider] incrementAttempts 오류: $e');
    }
  }
}
