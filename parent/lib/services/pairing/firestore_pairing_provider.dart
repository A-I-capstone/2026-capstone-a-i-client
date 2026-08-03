import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../models/pairing_code.dart';
import 'base_pairing_provider.dart';

/// Concrete [BaseParentPairingProvider] implementation backed by Cloud Firestore.
class FirestoreParentPairingProvider implements BaseParentPairingProvider {
  final FirebaseFirestore _firestore;

  FirestoreParentPairingProvider({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<PairingCode?> createPairingCode(String parentUid) async {
    try {
      final secureRandom = Random.secure();
      final codeInt = secureRandom.nextInt(900000) + 100000; // 6-digit PIN
      final code = codeInt.toString();

      final now = DateTime.now();
      final expiresAt = now.add(const Duration(minutes: 5));

      final pairingCode = PairingCode(
        code: code,
        parentUid: parentUid,
        createdAt: now,
        expiresAt: expiresAt,
        isUsed: false,
        attempts: 0,
      );

      await _firestore
          .collection('pairing_codes')
          .doc(code)
          .set(pairingCode.toFirestore());

      debugPrint('[FirestoreParentPairingProvider] 생성된 핀: $code (만료시간: $expiresAt)');
      return pairingCode;
    } catch (e, st) {
      debugPrint('[FirestoreParentPairingProvider] createPairingCode 오류: $e\n$st');
      return null;
    }
  }

  @override
  Stream<bool> watchPairingStatus(String code) {
    if (code.isEmpty) return Stream.value(false);

    return _firestore
        .collection('pairing_codes')
        .doc(code)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) return false;
      final data = snapshot.data();
      if (data == null) return false;
      final isUsed = data['isUsed'] as bool? ?? false;
      return isUsed;
    }).handleError((error) {
      debugPrint('[FirestoreParentPairingProvider] watchPairingStatus 오류: $error');
      return false;
    });
  }
}
