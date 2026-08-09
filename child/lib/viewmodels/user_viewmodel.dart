import 'package:flutter/foundation.dart';
import '../services/user/user_repository.dart';

/// ViewModel managing child user state (e.g. nickname stored in `users/{userId}.name`).
class UserViewModel extends ChangeNotifier {
  final UserRepository _repository;

  UserViewModel({required UserRepository repository})
      : _repository = repository;

  String _userId = '';
  String _name = '내 친구';
  bool _isLoading = false;

  String get userId => _userId;
  String get name => _name;
  bool get isLoading => _isLoading;

  /// Initializes state with [userId], fetching existing name from Firestore.
  Future<void> initialize(String userId) async {
    _userId = userId;
    _isLoading = true;
    notifyListeners();

    try {
      _name = await _repository.getName(_userId, defaultName: '내 친구');
    } catch (e, st) {
      debugPrint('[UserViewModel] initialize error: $e\n$st');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Updates the child user's name in Firestore and local state.
  Future<void> updateName(String newName) async {
    final trimmed = newName.trim();
    if (trimmed.isEmpty || _userId.isEmpty) return;

    _isLoading = true;
    notifyListeners();

    try {
      await _repository.updateName(_userId, trimmed);
      _name = trimmed;
    } catch (e, st) {
      debugPrint('[UserViewModel] updateName error: $e\n$st');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
