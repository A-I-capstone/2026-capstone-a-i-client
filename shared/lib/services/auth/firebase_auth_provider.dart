import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'base_auth_provider.dart';

/// [BaseAuthProvider] implementation backed by Firebase Anonymous Auth.
///
/// Used by both the parent app and the child app.
/// Swap this class in [main.dart] to change the auth backend
/// without modifying any ViewModel or Repository code.
class FirebaseAuthProvider implements BaseAuthProvider {
  final FirebaseAuth _auth;

  FirebaseAuthProvider({FirebaseAuth? auth})
      : _auth = auth ?? FirebaseAuth.instance;

  @override
  String? get currentUid => _auth.currentUser?.uid;

  @override
  Future<String> signInAnonymously() async {
    try {
      final existing = _auth.currentUser;
      if (existing != null) return existing.uid;

      final credential = await _auth.signInAnonymously();
      return credential.user?.uid ?? '';
    } catch (e, st) {
      debugPrint('[FirebaseAuthProvider] signInAnonymously error: $e\n$st');
      return '';
    }
  }

  @override
  Future<bool> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.delete();
        debugPrint('[FirebaseAuthProvider] deleteAccount 성공');
        return true;
      }
      return true;
    } catch (e, st) {
      debugPrint('[FirebaseAuthProvider] deleteAccount error: $e\n$st');
      return false;
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      debugPrint('[FirebaseAuthProvider] signOut 성공');
    } catch (e, st) {
      debugPrint('[FirebaseAuthProvider] signOut error: $e\n$st');
    }
  }
}
