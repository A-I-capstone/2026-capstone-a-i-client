import 'package:cloud_firestore/cloud_firestore.dart';

/// Data model representing a user profile stored in Firestore at:
///   users/{deviceUid}/profiles/{profileId}
class Profile {
  final String id;
  final String name;

  /// Avatar URL or asset path. Empty string until avatar upload is implemented.
  final String avatar;

  final DateTime createdAt;

  const Profile({
    required this.id,
    required this.name,
    this.avatar = '',
    required this.createdAt,
  });

  /// Creates a [Profile] from a Firestore document snapshot.
  factory Profile.fromFirestore(Map<String, dynamic> data, String id) {
    return Profile(
      id: id,
      name: (data['name'] as String?) ?? '내 친구',
      avatar: (data['avatar'] as String?) ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Converts this profile to a Firestore-compatible map.
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'avatar': avatar,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Returns a copy of this profile with the given fields replaced.
  Profile copyWith({String? name, String? avatar}) {
    return Profile(
      id: id,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      createdAt: createdAt,
    );
  }
}
