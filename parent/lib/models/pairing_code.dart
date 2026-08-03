import 'package:cloud_firestore/cloud_firestore.dart';

/// Representation of a document in the `pairing_codes` collection.
///
/// pairing_codes/{code}
///   * code (String): 6-digit document ID
///   * parentUid (String): Auth UID of the parent generating the PIN
///   * createdAt (Timestamp): Creation time
///   * expiresAt (Timestamp): Expiration time (createdAt + 5 minutes)
///   * isUsed (bool): Pairing completion status
///   * attempts (int): Failed attempts count (default 0)
class PairingCode {
  final String code;
  final String parentUid;
  final DateTime createdAt;
  final DateTime expiresAt;
  final bool isUsed;
  final int attempts;

  PairingCode({
    required this.code,
    required this.parentUid,
    required this.createdAt,
    required this.expiresAt,
    required this.isUsed,
    required this.attempts,
  });

  factory PairingCode.fromFirestore(Map<String, dynamic> data, String id) {
    return PairingCode(
      code: id,
      parentUid: data['parentUid'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiresAt: (data['expiresAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isUsed: data['isUsed'] as bool? ?? false,
      attempts: data['attempts'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'parentUid': parentUid,
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'isUsed': isUsed,
      'attempts': attempts,
    };
  }
}
