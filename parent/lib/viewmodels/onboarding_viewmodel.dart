import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String kParentTermsAccepted = 'parent_terms_accepted';
const String kParentPairingComplete = 'parent_pairing_complete';
const String kParentChildUid = 'parent_child_uid';

/// ViewModel for parent onboarding flow (Terms Agreement & Pairing status persistence).
class ParentOnboardingViewModel extends ChangeNotifier {
  bool _termsAccepted = false;
  bool _pairingComplete = false;
  bool _isLoading = true;
  String? _childUid;

  bool get termsAccepted => _termsAccepted;
  bool get pairingComplete => _pairingComplete;
  bool get isLoading => _isLoading;

  /// UID of the paired child — available after pairing is complete.
  String? get childUid => _childUid;

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      _termsAccepted = prefs.getBool(kParentTermsAccepted) ?? false;
      _pairingComplete = prefs.getBool(kParentPairingComplete) ?? false;
      _childUid = prefs.getString(kParentChildUid);
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

  /// Completes pairing and persists [childUid] so that it survives app restarts.
  Future<void> completePairing({String? childUid}) async {
    _pairingComplete = true;
    _childUid = childUid;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(kParentPairingComplete, true);
      if (childUid != null) {
        await prefs.setString(kParentChildUid, childUid);
      }
    } catch (e) {
      debugPrint('[ParentOnboardingViewModel] completePairing error: $e');
    }
  }
}
