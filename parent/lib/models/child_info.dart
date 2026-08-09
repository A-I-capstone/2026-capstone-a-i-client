import 'package:cloud_firestore/cloud_firestore.dart';

/// Representation of a child linked to the parent.
class ChildInfo {
  final String childUid;
  final String familyId;
  final String nickname;
  final DateTime pairedAt;

  ChildInfo({
    required this.childUid,
    required this.familyId,
    required this.nickname,
    required this.pairedAt,
  });

  factory ChildInfo.fromFirestore({
    required String familyId,
    required Map<String, dynamic> familyData,
    String? nickname,
  }) {
    final rawNickname = nickname ?? familyData['nickname'] as String?;
    final defaultNickname = (rawNickname != null && rawNickname.isNotEmpty)
        ? rawNickname
        : '이름 없는 자녀';

    return ChildInfo(
      childUid: familyData['childUid'] as String? ?? '',
      familyId: familyId,
      nickname: defaultNickname,
      pairedAt: (familyData['pairedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
