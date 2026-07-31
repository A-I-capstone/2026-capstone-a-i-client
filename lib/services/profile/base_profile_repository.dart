import '../../models/profile.dart';

/// Abstract interface for all profile data-access implementations.
///
/// Depends on [Profile] model only — no Flutter/Firestore imports here so
/// this interface can be satisfied by any backend (Firestore, SQLite, mock…).
abstract class BaseProfileRepository {
  /// Returns all profiles for [userId] ordered by [Profile.createdAt] ascending.
  /// Returns an empty list on error.
  Future<List<Profile>> listProfiles(String userId);

  /// Creates a new profile for [userId] with the given [name].
  /// Returns the generated profileId, or an empty string on error.
  Future<String> createProfile(String userId, String name);

  /// Updates the [name] of an existing profile identified by [profileId].
  /// Fails silently on error.
  Future<void> updateProfile(String userId, String profileId, String name);

  /// Permanently deletes the profile document and its entire [chats] subcollection
  /// (including nested [messages] subcollections) for the given [userId] / [profileId].
  /// Fails silently on error.
  Future<void> deleteProfile(String userId, String profileId);
}
