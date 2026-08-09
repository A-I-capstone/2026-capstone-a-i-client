import 'package:cloud_firestore/cloud_firestore.dart';

/// Representation of a child linked to the parent.
class ChildInfo {
  final String childUid;
  final String familyId;
  final String name;
  final DateTime pairedAt;

  ChildInfo({
    required this.childUid,
    required this.familyId,
    required this.name,
    required this.pairedAt,
  });

  factory ChildInfo.fromFirestore({
    required String familyId,
    required Map<String, dynamic> familyData,
    String? name,
  }) {
    final rawName = name ??
        familyData['name'] as String? ??
        familyData['nickname'] as String?;
    final defaultName =
        (rawName != null && rawName.isNotEmpty) ? rawName : '이름 없는 자녀';

    return ChildInfo(
      childUid: familyData['childUid'] as String? ?? '',
      familyId: familyId,
      name: defaultName,
      pairedAt: (familyData['pairedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
