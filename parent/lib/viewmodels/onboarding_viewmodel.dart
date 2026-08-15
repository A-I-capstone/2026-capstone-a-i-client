import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String kParentTermsAccepted = 'parent_terms_accepted';
const String kParentPairingComplete = 'parent_pairing_complete';

/// ViewModel for parent onboarding flow (Terms Agreement & Pairing status persistence).
class ParentOnboardingViewModel extends ChangeNotifier {
  bool _termsAccepted = false;
  bool _pairingComplete = false;
  bool _isLoading = true;

  bool get termsAccepted => _termsAccepted;
  bool get pairingComplete => _pairingComplete;
  bool get isLoading => _isLoading;

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      _termsAccepted = prefs.getBool(kParentTermsAccepted) ?? false;
      _pairingComplete = prefs.getBool(kParentPairingComplete) ?? false;
    } catch (e, st) {
      debugPrint('[ParentOnboardingViewModel] init error: $e\n$st');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> acceptTerms() async {
    _termsAccepted = true;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(kParentTermsAccepted, true);
    } catch (e) {
      debugPrint('[ParentOnboardingViewModel] acceptTerms error: $e');
    }
  }

  /// Completes pairing and persists pairing state.
  Future<void> completePairing() async {
    _pairingComplete = true;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(kParentPairingComplete, true);
    } catch (e) {
      debugPrint('[ParentOnboardingViewModel] completePairing error: $e');
    }
  }

  /// Resets terms and pairing flags in state and SharedPreferences (e.g. on account data deletion).
  Future<void> resetAll() async {
    _termsAccepted = false;
    _pairingComplete = false;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(kParentTermsAccepted);
      await prefs.remove(kParentPairingComplete);
      debugPrint('[ParentOnboardingViewModel] resetAll 완료: 모든 온보딩 상태 초기화');
    } catch (e) {
      debugPrint('[ParentOnboardingViewModel] resetAll error: $e');
    }
  }
}

