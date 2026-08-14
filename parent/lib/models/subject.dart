import 'package:cloud_firestore/cloud_firestore.dart';

/// Data model representing a Subject (과목) in the parent app.
/// Read-only mirror of child's subject collection: `users/{childUid}/subjects/{subjectId}`.
class Subject {
  final String id;
  final String name;
  final int colorValue;
  final DateTime? createdAt;

  const Subject({
    required this.id,
    required this.name,
    required this.colorValue,
    this.createdAt,
  });

  factory Subject.fromFirestore(Map<String, dynamic> data, String id) {
    return Subject(
      id: id,
      name: data['name'] as String? ?? '',
      colorValue: data['colorValue'] as int? ?? 0xFFFFC533,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
