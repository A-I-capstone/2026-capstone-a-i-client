import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../models/child_info.dart';

/// Service responsible for managing parent account settings,
/// including child unlinking and cascading data deletion.
class ParentAccountService {
  final FirebaseFirestore? firestore;

  ParentAccountService({this.firestore});

  FirebaseFirestore get _db => firestore ?? FirebaseFirestore.instance;

  /// Fetches the list of all paired children for [parentUid].
  Future<List<ChildInfo>> fetchPairedChildren(String parentUid) async {
    if (parentUid.isEmpty) return [];

    try {
      final familySnap = await _db
          .collection('families')
          .where('parentUid', isEqualTo: parentUid)
          .where('status', isEqualTo: 'active')
          .get();

      final List<ChildInfo> results = [];
      for (final doc in familySnap.docs) {
        final familyId = doc.id;
        final familyData = doc.data();
        final childUid = familyData['childUid'] as String? ?? '';

        String? childName;
        if (childUid.isNotEmpty) {
          try {
            final userDoc = await _db.collection('users').doc(childUid).get();
            if (userDoc.exists) {
              final userData = userDoc.data() ?? {};
              childName = userData['name'] as String? ??
                  userData['nickname'] as String?;
            }
          } catch (e) {
            debugPrint('[ParentAccountService] 유저 정보 조회 실패 ($childUid): $e');
          }
        }

        results.add(
          ChildInfo.fromFirestore(
            familyId: familyId,
            familyData: familyData,
            name: childName,
          ),
        );
      }

      results.sort((a, b) => b.pairedAt.compareTo(a.pairedAt));
      return results;
    } catch (e, st) {
      debugPrint('[ParentAccountService] fetchPairedChildren error: $e\n$st');
      return [];
    }
  }

  /// Unlinks a child by deleting the corresponding `families/{familyId}` document.
  /// Child app data is preserved.
  Future<bool> unlinkChild(String familyId) async {
    if (familyId.isEmpty) return false;

    try {
      debugPrint('[ParentAccountService] 자녀 연동 해제 시작: familyId=$familyId');
      await _db.collection('families').doc(familyId).delete();
      debugPrint('[ParentAccountService] 자녀 연동 해제 완료: familyId=$familyId');
      return true;
    } catch (e, st) {
      debugPrint('[ParentAccountService] unlinkChild error: $e\n$st');
      return false;
    }
  }

  /// Permanently deletes all data associated with [parentUid] and all linked children.
  /// Cascades through child tasks, chats, messages, subjects, user documents,
  /// family links, and pairing codes.
  Future<bool> deleteAllParentData(String parentUid) async {
    if (parentUid.isEmpty) return false;

    debugPrint('[ParentAccountService] 전체 데이터 삭제 시작: parentUid=$parentUid');
    try {
      // 1. Find all linked families
      final familiesSnap = await _db
          .collection('families')
          .where('parentUid', isEqualTo: parentUid)
          .get();

      final Set<String> childUids = {};
      final List<String> familyDocIds = [];

      for (final doc in familiesSnap.docs) {
        familyDocIds.add(doc.id);
        final childUid = doc.data()['childUid'] as String? ?? '';
        if (childUid.isNotEmpty) {
          childUids.add(childUid);
        }
      }

      // 2. Cascade delete all data for each child
      for (final childUid in childUids) {
        await _deleteChildData(childUid);
      }

      // 3. Delete all family relationship documents
      for (final familyId in familyDocIds) {
        try {
          await _db.collection('families').doc(familyId).delete();
        } catch (e) {
          debugPrint('[ParentAccountService] family doc 삭제 실패 ($familyId): $e');
        }
      }

      // 4. Delete pairing codes created by this parent
      try {
        final pairingCodesSnap = await _db
            .collection('pairing_codes')
            .where('parentUid', isEqualTo: parentUid)
            .get();

        for (final doc in pairingCodesSnap.docs) {
          await doc.reference.delete();
        }
      } catch (e) {
        debugPrint('[ParentAccountService] pairing_codes 삭제 오류: $e');
      }

      // 5. Delete parent user doc if exists
      try {
        final parentUserRef = _db.collection('users').doc(parentUid);
        final parentUserSnap = await parentUserRef.get();
        if (parentUserSnap.exists) {
          await parentUserRef.delete();
        }
      } catch (e) {
        debugPrint('[ParentAccountService] parent user doc 삭제 오류: $e');
      }

      debugPrint('[ParentAccountService] 전체 데이터 삭제 완료: parentUid=$parentUid');
      return true;
    } catch (e, st) {
      debugPrint('[ParentAccountService] deleteAllParentData error: $e\n$st');
      return false;
    }
  }

  /// Helper to delete all Firestore documents and subcollections for [childUid].
  Future<void> _deleteChildData(String childUid) async {
    try {
      debugPrint('[ParentAccountService] 자녀 데이터 삭제 시작: childUid=$childUid');
      final childUserRef = _db.collection('users').doc(childUid);

      // A. Delete tasks and their subcollections (chats -> messages)
      final tasksSnap = await childUserRef.collection('tasks').get();
      for (final taskDoc in tasksSnap.docs) {
        final chatsSnap = await taskDoc.reference.collection('chats').get();
        for (final chatDoc in chatsSnap.docs) {
          final messagesSnap =
              await chatDoc.reference.collection('messages').get();
          for (final msgDoc in messagesSnap.docs) {
            await msgDoc.reference.delete();
          }
          await chatDoc.reference.delete();
        }
        await taskDoc.reference.delete();
      }

      // B. Delete subjects
      final subjectsSnap = await childUserRef.collection('subjects').get();
      for (final subjDoc in subjectsSnap.docs) {
        await subjDoc.reference.delete();
      }

      // C. Delete child user document
      await childUserRef.delete();
      debugPrint('[ParentAccountService] 자녀 데이터 삭제 완료: childUid=$childUid');
    } catch (e, st) {
      debugPrint('[ParentAccountService] _deleteChildData error: $e\n$st');
    }
  }
}
