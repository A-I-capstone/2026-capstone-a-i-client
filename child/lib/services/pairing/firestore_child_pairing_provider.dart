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
    debugPrint(
      '[Child Pairing] submitPairingCode 시작 (입력된 PIN: "$code", childUid: "$childUid")',
    );
    try {
      final codeRef = _firestore.collection('pairing_codes').doc(code);
      debugPrint('[Child Pairing] Firestore 조회 시도: pairing_codes/$code');
      final codeSnap = await codeRef.get();

      if (!codeSnap.exists) {
        debugPrint('[Child Pairing] [검증 실패] Firestore에 해당 PIN 문서가 존재하지 않음: "$code"');
        return '';
      }

      final data = codeSnap.data();
      if (data == null) {
        debugPrint('[Child Pairing] [검증 실패] 문서 데이터가 null입니다: "$code"');
        return '';
      }
      debugPrint('[Child Pairing] Firestore 문서 데이터 확인: $data');

      // 1. Already used check
      if ((data['isUsed'] as bool?) == true) {
        debugPrint('[Child Pairing] [검증 실패] 이미 사용된 코드입니다: isUsed=true ($code)');
        return '';
      }

      // 2. Expiry check
      final expiresAt = (data['expiresAt'] as Timestamp?)?.toDate();
      final now = DateTime.now();
      debugPrint('[Child Pairing] 만료시간 검사: expiresAt=$expiresAt, 현재시간=$now');
      if (expiresAt == null || now.isAfter(expiresAt)) {
        debugPrint(
          '[Child Pairing] [검증 실패] 만료된 코드입니다 (만료: $expiresAt, 현재: $now)',
        );
        return '';
      }

      // 3. Attempts check (> 5 → expired)
      final attempts = (data['attempts'] as int?) ?? 0;
      debugPrint('[Child Pairing] 시도 횟수 확인: attempts=$attempts');
      if (attempts > 5) {
        debugPrint('[Child Pairing] [검증 실패] 시도 횟수(5회) 초과: attempts=$attempts');
        return '';
      }

      final parentUid = (data['parentUid'] as String?) ?? '';
      if (parentUid.isEmpty) {
        debugPrint('[Child Pairing] [검증 실패] parentUid가 비어 있습니다 ($code)');
        return '';
      }
      debugPrint('[Child Pairing] 검증 통과! parentUid: $parentUid');

      // 4. Atomic batch: mark code as used + create family document
      final familyRef = _firestore.collection('families').doc();
      debugPrint('[Child Pairing] Batch Write 실행 (생성될 familyId: ${familyRef.id})');
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
        '[Child Pairing] Batch Write 완료! 페어링 성공 → familyId: ${familyRef.id}, parentUid: $parentUid, childUid: $childUid',
      );
      return familyRef.id;
    } catch (e, st) {
      debugPrint('[Child Pairing] submitPairingCode 치명적 오류 발생: $e\n$st');
      return '';
    }
  }

  /// Increments the attempts counter for [code] when validation fails.
  /// Called fire-and-forget — never throws.
  Future<void> incrementAttempts(String code) async {
    debugPrint('[Child Pairing] incrementAttempts 시도 (code: $code)');
    try {
      await _firestore.collection('pairing_codes').doc(code).update({
        'attempts': FieldValue.increment(1),
      });
      debugPrint('[Child Pairing] incrementAttempts 완료 (code: $code)');
    } catch (e) {
      debugPrint('[Child Pairing] incrementAttempts 오류: $e');
    }
  }
}
