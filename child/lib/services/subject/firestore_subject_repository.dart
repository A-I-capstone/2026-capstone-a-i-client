import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../models/subject.dart';
import 'base_subject_repository.dart';

/// Concrete implementation of [BaseSubjectRepository] using Firebase Firestore.
/// Data path: `users/{userId}/subjects/{subjectId}`
class FirestoreSubjectRepository implements BaseSubjectRepository {
  final FirebaseFirestore _firestore;

  FirestoreSubjectRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _subjectsRef(String userId) =>
      _firestore.collection('users').doc(userId).collection('subjects');

  @override
  Stream<List<Subject>> streamSubjects(String userId) {
    return _subjectsRef(userId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Subject.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  @override
  Future<List<Subject>> loadSubjects(String userId) async {
    try {
      final snapshot = await _subjectsRef(userId)
          .orderBy('createdAt', descending: false)
          .get();
      return snapshot.docs
          .map((doc) => Subject.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e, st) {
      debugPrint('[FirestoreSubjectRepository] loadSubjects error: $e\n$st');
      return [];
    }
  }

  @override
  Future<Subject?> createSubject(String userId, Subject subject) async {
    try {
      final docRef = _subjectsRef(userId).doc();
      final newSubject = subject.copyWith(
        id: docRef.id,
        createdAt: subject.createdAt ?? DateTime.now(),
      );
      await docRef.set(newSubject.toFirestore());
      return newSubject;
    } catch (e, st) {
      debugPrint('[FirestoreSubjectRepository] createSubject error: $e\n$st');
      return null;
    }
  }

  @override
  Future<void> updateSubject(String userId, Subject subject) async {
    try {
      await _subjectsRef(userId).doc(subject.id).update(subject.toFirestore());
    } catch (e, st) {
      debugPrint('[FirestoreSubjectRepository] updateSubject error: $e\n$st');
    }
  }

  @override
  Future<void> deleteSubject(String userId, String subjectId) async {
    try {
      await _subjectsRef(userId).doc(subjectId).delete();
    } catch (e, st) {
      debugPrint('[FirestoreSubjectRepository] deleteSubject error: $e\n$st');
    }
  }
}
