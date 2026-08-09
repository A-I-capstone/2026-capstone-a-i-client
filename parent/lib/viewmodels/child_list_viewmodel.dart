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
        (snapshot) async {
          final List<ChildInfo> loadedChildren = [];

          for (final doc in snapshot.docs) {
            final data = doc.data();
            final childUid = data['childUid'] as String? ?? '';

            String? nickname;
            if (childUid.isNotEmpty) {
              try {
                final userDoc =
                    await _firestore.collection('users').doc(childUid).get();
                if (userDoc.exists && userDoc.data() != null) {
                  final userData = userDoc.data()!;
                  nickname = userData['name'] as String? ??
                      userData['nickname'] as String?;
                }
              } catch (e) {
                debugPrint('[ChildListViewModel] 자녀 닉네임 로드 실패: $e');
              }
            }

            loadedChildren.add(
              ChildInfo.fromFirestore(
                familyId: doc.id,
                familyData: data,
                nickname: nickname,
              ),
            );
          }

          _children = loadedChildren;
          _isLoading = false;
          notifyListeners();
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

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
