import 'package:cloud_firestore/cloud_firestore.dart';

/// Representation of a document in the `families` collection.
///
/// families/{familyId}
///   * parentUid (String)
///   * childUid (String)
///   * pairedAt (Timestamp)
///   * status (String): "active"
class FamilyRelationship {
  final String familyId;
  final String parentUid;
  final String childUid;
  final DateTime pairedAt;
  final String status;

  FamilyRelationship({
    required this.familyId,
    required this.parentUid,
    required this.childUid,
    required this.pairedAt,
    required this.status,
  });

  factory FamilyRelationship.fromFirestore(
    Map<String, dynamic> data,
    String id,
  ) {
    return FamilyRelationship(
      familyId: id,
      parentUid: data['parentUid'] as String? ?? '',
      childUid: data['childUid'] as String? ?? '',
      pairedAt: (data['pairedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: data['status'] as String? ?? 'active',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'parentUid': parentUid,
      'childUid': childUid,
      'pairedAt': Timestamp.fromDate(pairedAt),
      'status': status,
    };
  }
}
