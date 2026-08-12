import 'package:cloud_firestore/cloud_firestore.dart';

/// Data model representing a Subject (과목).
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

  Subject copyWith({
    String? id,
    String? name,
    int? colorValue,
    DateTime? createdAt,
  }) {
    return Subject(
      id: id ?? this.id,
      name: name ?? this.name,
      colorValue: colorValue ?? this.colorValue,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'colorValue': colorValue,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  factory Subject.fromFirestore(Map<String, dynamic> data, String id) {
    return Subject(
      id: id,
      name: data['name'] as String? ?? '',
      colorValue: data['colorValue'] as int? ?? 0xFFFFC533,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
