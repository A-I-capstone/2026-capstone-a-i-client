import 'package:cloud_firestore/cloud_firestore.dart';

/// Data model representing child user info stored in Firestore at: `users/{userId}`
class UserProfile {
  final String uid;
  final String name;
  final String avatar;
  final DateTime createdAt;

  const UserProfile({
    required this.uid,
    required this.name,
    this.avatar = '',
    required this.createdAt,
  });

  factory UserProfile.fromFirestore(Map<String, dynamic> data, String uid) {
    return UserProfile(
      uid: uid,
      name: (data['name'] as String?) ?? '내 친구',
      avatar: (data['avatar'] as String?) ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'avatar': avatar,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  UserProfile copyWith({String? name, String? avatar}) {
    return UserProfile(
      uid: uid,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      createdAt: createdAt,
    );
  }
}
