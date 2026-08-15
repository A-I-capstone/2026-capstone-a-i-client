import 'package:flutter/foundation.dart';
import 'package:shared/shared.dart';

import '../models/child_info.dart';
import '../services/settings/parent_account_service.dart';
import 'onboarding_viewmodel.dart';

/// ViewModel for managing settings screen state,
/// including child unlinking and cascading account data deletion.
class ParentSettingsViewModel extends ChangeNotifier {
  final String parentUid;
  final ParentAccountService _accountService;

  ParentSettingsViewModel({
    required this.parentUid,
    ParentAccountService? accountService,
  }) : _accountService = accountService ?? ParentAccountService() {
    loadChildren();
  }

  List<ChildInfo> _children = [];
  bool _isLoading = false;
  bool _isProcessing = false;
  String? _errorMessage;

  List<ChildInfo> get children => List.unmodifiable(_children);
  bool get isLoading => _isLoading;
  bool get isProcessing => _isProcessing;
  String? get errorMessage => _errorMessage;

  /// Loads the list of currently paired children from Firestore.
  Future<void> loadChildren() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _children = await _accountService.fetchPairedChildren(parentUid);
    } catch (e, st) {
      debugPrint('[ParentSettingsViewModel] loadChildren error: $e\n$st');
      _children = [];
      _errorMessage = '자녀 목록을 불러오지 못했습니다.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Unlinks a specific child by [familyId].
  /// Child app data is preserved.
  Future<bool> unlinkChild(String familyId) async {
    if (familyId.isEmpty) return false;

    _isProcessing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _accountService.unlinkChild(familyId);
      if (success) {
        _children.removeWhere((c) => c.familyId == familyId);
      } else {
        _errorMessage = '자녀 연동 해제에 실패했습니다. 다시 시도해 주세요.';
      }
      return success;
    } catch (e, st) {
      debugPrint('[ParentSettingsViewModel] unlinkChild error: $e\n$st');
      _errorMessage = '오류가 발생했습니다. 잠시 후 다시 시도해 주세요.';
      return false;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  /// Permanently deletes all data associated with this parent and all linked children,
  /// deletes the Firebase Auth account, and resets onboarding state.
  Future<bool> deleteAllData({
    required BaseAuthProvider authProvider,
    required ParentOnboardingViewModel onboardingViewModel,
  }) async {
    _isProcessing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Delete all Firestore data for parent and linked children
      final success = await _accountService.deleteAllParentData(parentUid);
      if (!success) {
        _errorMessage = '데이터 삭제 중 오류가 발생했습니다. 다시 시도해 주세요.';
        _isProcessing = false;
        notifyListeners();
        return false;
      }

      // 2. Delete Auth account
      await authProvider.deleteAccount();

      // 3. Reset local SharedPreferences onboarding flags
      await onboardingViewModel.resetAll();

      _children.clear();
      return true;
    } catch (e, st) {
      debugPrint('[ParentSettingsViewModel] deleteAllData error: $e\n$st');
      _errorMessage = '데이터 삭제 처리 중 문제가 발생했습니다.';
      return false;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }
}
