import 'package:flutter/foundation.dart';

import '../models/profile.dart';
import '../services/profile/base_profile_repository.dart';

/// ViewModel managing the list of user profiles and which one is active.
///
/// Extends ChangeNotifier and strictly avoids importing material.dart or
/// referencing BuildContext.
///
/// Lifecycle:
///   1. Call [initialize(userId)] once after anonymous sign-in.
///   2. If no profiles exist a default profile is created automatically.
///   3. Consumers can call [switchProfile], [createProfile],
///      [updateProfile], and [deleteProfile] at any time after initialization.
class ProfileViewModel extends ChangeNotifier {
  final BaseProfileRepository _repository;

  ProfileViewModel({required BaseProfileRepository repository})
      : _repository = repository;

  // ---------------------------------------------------------------------------
  // State
  // ---------------------------------------------------------------------------

  String _userId = '';
  final List<Profile> _profiles = [];
  Profile? _activeProfile;
  bool _isLoading = false;

  // ---------------------------------------------------------------------------
  // Public getters
  // ---------------------------------------------------------------------------

  List<Profile> get profiles => List.unmodifiable(_profiles);
  Profile? get activeProfile => _activeProfile;
  String get userId => _userId;
  bool get isLoading => _isLoading;


  // ---------------------------------------------------------------------------
  // Initialization
  // ---------------------------------------------------------------------------

  /// Must be called once after the user's [userId] has been obtained via
  /// anonymous sign-in.
  ///
  /// Loads the profile list; if the list is empty a default profile named
  /// "내 친구" is automatically created and selected.
  Future<void> initialize(String userId) async {
    _userId = userId;
    _isLoading = true;
    notifyListeners();

    try {
      await _loadProfiles();

      // Auto-create a default profile when none exist.
      if (_profiles.isEmpty) {
        debugPrint('[ProfileViewModel] 프로필 없음 → 기본 프로필 생성 중');
        final newId = await _repository.createProfile(userId, '내 친구');
        if (newId.isNotEmpty) {
          await _loadProfiles();
        }
      }

      // Select the first profile as the active one.
      if (_activeProfile == null && _profiles.isNotEmpty) {
        _activeProfile = _profiles.first;
        debugPrint(
          '[ProfileViewModel] 활성 프로필 설정: ${_activeProfile?.name} (${_activeProfile?.id})',
        );
      }
    } catch (e, st) {
      debugPrint('[ProfileViewModel] initialize() 오류: $e\n$st');
      // Fail silently — the app continues even if profile loading fails.
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  /// Switches the active profile to [profile].
  /// Notifies listeners so dependent ViewModels (e.g. ChatViewModel) can react.
  void switchProfile(Profile profile) {
    if (_activeProfile?.id == profile.id) return;
    _activeProfile = profile;
    debugPrint('[ProfileViewModel] 프로필 전환: ${profile.name} (${profile.id})');
    notifyListeners();
  }

  /// Creates a new profile with the given [name] and appends it to the list.
  /// Returns the new [Profile], or null on failure.
  Future<Profile?> createProfile(String name) async {
    if (_userId.isEmpty || name.trim().isEmpty) return null;
    _isLoading = true;
    notifyListeners();

    try {
      final newId = await _repository.createProfile(_userId, name.trim());
      if (newId.isEmpty) return null;

      await _loadProfiles();
      final created = _profiles.where((p) => p.id == newId).firstOrNull;
      return created;
    } catch (e, st) {
      debugPrint('[ProfileViewModel] createProfile() 오류: $e\n$st');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Updates the name of the profile identified by [profileId].
  Future<void> updateProfile(String profileId, String name) async {
    if (_userId.isEmpty || name.trim().isEmpty) return;
    _isLoading = true;
    notifyListeners();

    try {
      await _repository.updateProfile(_userId, profileId, name.trim());
      await _loadProfiles();

      // Keep _activeProfile in sync if it was the one being renamed.
      if (_activeProfile?.id == profileId) {
        _activeProfile = _profiles.where((p) => p.id == profileId).firstOrNull;
      }
    } catch (e, st) {
      debugPrint('[ProfileViewModel] updateProfile() 오류: $e\n$st');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Deletes the profile identified by [profileId].
  ///
  /// The currently active profile cannot be deleted — callers must ensure
  /// they never invoke this with [activeProfile.id].
  ///
  /// If the deleted profile was somehow the active one (edge case), the first
  /// remaining profile is selected automatically.
  Future<void> deleteProfile(String profileId) async {
    if (_userId.isEmpty) return;

    // Guard: never delete the active profile.
    if (_activeProfile?.id == profileId) {
      debugPrint(
        '[ProfileViewModel] deleteProfile() 거부됨 — 활성 프로필은 삭제 불가',
      );
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      await _repository.deleteProfile(_userId, profileId);
      await _loadProfiles();

      // Fallback: if active profile somehow became invalid, select the first.
      final stillActive =
          _profiles.any((p) => p.id == (_activeProfile?.id ?? ''));
      if (!stillActive && _profiles.isNotEmpty) {
        _activeProfile = _profiles.first;
      }
    } catch (e, st) {
      debugPrint('[ProfileViewModel] deleteProfile() 오류: $e\n$st');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  Future<void> _loadProfiles() async {
    final loaded = await _repository.listProfiles(_userId);
    _profiles
      ..clear()
      ..addAll(loaded);
  }
}
