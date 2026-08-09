import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/child_info.dart';

/// ViewModel for managing the list of children paired with the parent.
class ChildListViewModel extends ChangeNotifier {
  final String parentUid;
  final FirebaseFirestore _firestore;

  ChildListViewModel({
    required this.parentUid,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance {
    _subscribeToChildren();
  }

  List<ChildInfo> _children = [];
  bool _isLoading = true;
  StreamSubscription<QuerySnapshot>? _subscription;
  final Map<String, StreamSubscription<DocumentSnapshot>> _childUserSubscriptions = {};
  final Map<String, ChildInfo> _childInfoMap = {};

  List<ChildInfo> get children => List.unmodifiable(_children);
  bool get isLoading => _isLoading;
  bool get isEmpty => !_isLoading && _children.isEmpty;

  void _subscribeToChildren() {
    if (parentUid.isEmpty) {
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      _subscription = _firestore
          .collection('families')
          .where('parentUid', isEqualTo: parentUid)
          .where('status', isEqualTo: 'active')
          .snapshots()
          .listen(
        (snapshot) {
          final activeFamilyIds = <String>{};

          for (final doc in snapshot.docs) {
            final familyId = doc.id;
            activeFamilyIds.add(familyId);
            final data = doc.data();
            final childUid = data['childUid'] as String? ?? '';

            if (childUid.isNotEmpty && !_childUserSubscriptions.containsKey(familyId)) {
              _childUserSubscriptions[familyId] = _firestore
                  .collection('users')
                  .doc(childUid)
                  .snapshots()
                  .listen(
                (userDoc) {
                  final userData = userDoc.data() ?? {};
                  final name = userData['name'] as String? ??
                      userData['nickname'] as String?;

                  _childInfoMap[familyId] = ChildInfo.fromFirestore(
                    familyId: familyId,
                    familyData: data,
                    name: name,
                  );
                  _updateChildrenList();
                },
                onError: (e) {
                  debugPrint('[ChildListViewModel] 자녀 유저 문서 수신 실패 ($childUid): $e');
                },
              );
            }
          }

          // Clean up subscriptions for removed families
          final removedFamilyIds = _childUserSubscriptions.keys
              .where((id) => !activeFamilyIds.contains(id))
              .toList();

          for (final familyId in removedFamilyIds) {
            _childUserSubscriptions[familyId]?.cancel();
            _childUserSubscriptions.remove(familyId);
            _childInfoMap.remove(familyId);
          }

          if (snapshot.docs.isEmpty) {
            _updateChildrenList();
          }
        },
        onError: (error) {
          debugPrint('[ChildListViewModel] families 쿼리 에러: $error');
          _isLoading = false;
          notifyListeners();
        },
      );
    } catch (e) {
      debugPrint('[ChildListViewModel] _subscribeToChildren 에러: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  void _updateChildrenList() {
    _children = _childInfoMap.values.toList()
      ..sort((a, b) => b.pairedAt.compareTo(a.pairedAt));
    _isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    for (final sub in _childUserSubscriptions.values) {
      sub.cancel();
    }
    _childUserSubscriptions.clear();
    super.dispose();
  }
}
