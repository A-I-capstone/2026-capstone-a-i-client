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
    debugPrint('[Parent Pairing] createPairingCode 시작 (parentUid: $parentUid)');
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

      debugPrint('[Parent Pairing] Firestore 문서 생성 시도: pairing_codes/$code');
      await _firestore
          .collection('pairing_codes')
          .doc(code)
          .set(pairingCode.toFirestore());

      debugPrint(
        '[Parent Pairing] 생성된 PIN 문서 저장 완료: $code (parentUid: $parentUid, 만료시간: $expiresAt)',
      );
      return pairingCode;
    } catch (e, st) {
      debugPrint('[Parent Pairing] createPairingCode 오류 발생: $e\n$st');
      return null;
    }
  }

  @override
  Stream<bool> watchPairingStatus(String code) {
    debugPrint('[Parent Pairing] watchPairingStatus 구독 시작 (code: $code)');
    if (code.isEmpty) {
      debugPrint('[Parent Pairing] watchPairingStatus 빈 코드 수신 -> false 반환');
      return Stream.value(false);
    }

    return _firestore
        .collection('pairing_codes')
        .doc(code)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) {
        debugPrint('[Parent Pairing] watchPairingStatus 스냅샷: 문서 없음 ($code)');
        return false;
      }
      final data = snapshot.data();
      if (data == null) {
        debugPrint('[Parent Pairing] watchPairingStatus 스냅샷: 데이터 null ($code)');
        return false;
      }
      final isUsed = data['isUsed'] as bool? ?? false;
      debugPrint('[Parent Pairing] watchPairingStatus 스냅샷 수신 ($code): isUsed=$isUsed, data=$data');
      return isUsed;
    }).handleError((error, st) {
      debugPrint('[Parent Pairing] watchPairingStatus 오류 발생: $error\n$st');
      return false;
    });
  }
}
