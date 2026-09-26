import 'package:flutter/foundation.dart';
import 'package:shared/shared.dart';

import '../services/settings/safety_settings_service.dart';

/// ViewModel for the parent's AI safety settings screen.
///
/// Manages the slider values for the four adjustable harm categories and
/// persists them to Firestore via [SafetySettingsService] whenever the parent
/// saves changes.
class SafetySettingsViewModel extends ChangeNotifier {
  final String familyId;
  final SafetySettingsService _service;

  bool _isLoading = false;
  bool _isSaving = false;
  bool _saveSuccess = false;
  String? _errorMessage;

  // Mutable slider state (0 = strictest / low, 2 = most permissive / high)
  int _harassment = 2;
  int _hateSpeech = 2;
  int _sexuallyExplicit = 2;
  int _dangerousContent = 2;

  SafetySettingsViewModel({
    required this.familyId,
    SafetySettingsService? service,
  }) : _service = service ?? SafetySettingsService() {
    _loadSettings();
  }

  // ---------------------------------------------------------------------------
  // Getters
  // ---------------------------------------------------------------------------

  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  bool get saveSuccess => _saveSuccess;
  String? get errorMessage => _errorMessage;

  int get harassment => _harassment;
  int get hateSpeech => _hateSpeech;
  int get sexuallyExplicit => _sexuallyExplicit;
  int get dangerousContent => _dangerousContent;

  // ---------------------------------------------------------------------------
  // Load
  // ---------------------------------------------------------------------------

  Future<void> _loadSettings() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final settings = await _service.fetchSafetySettings(familyId);
      _applyModel(settings);
    } catch (e, st) {
      debugPrint('[SafetySettingsViewModel] _loadSettings error: $e\n$st');
      _errorMessage = '설정을 불러오지 못했습니다.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _applyModel(SafetySettingsModel model) {
    _harassment = model.harassment;
    _hateSpeech = model.hateSpeech;
    _sexuallyExplicit = model.sexuallyExplicit;
    _dangerousContent = model.dangerousContent;
  }

  // ---------------------------------------------------------------------------
  // Slider setters (called during drag — no Firestore write yet)
  // ---------------------------------------------------------------------------

  void setHarassment(int value) {
    if (_harassment == value) return;
    _harassment = value;
    _saveSuccess = false;
    notifyListeners();
  }

  void setHateSpeech(int value) {
    if (_hateSpeech == value) return;
    _hateSpeech = value;
    _saveSuccess = false;
    notifyListeners();
  }

  void setSexuallyExplicit(int value) {
    if (_sexuallyExplicit == value) return;
    _sexuallyExplicit = value;
    _saveSuccess = false;
    notifyListeners();
  }

  void setDangerousContent(int value) {
    if (_dangerousContent == value) return;
    _dangerousContent = value;
    _saveSuccess = false;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Save
  // ---------------------------------------------------------------------------

  /// Persists all current slider values to Firestore.
  Future<void> saveSettings() async {
    _isSaving = true;
    _saveSuccess = false;
    _errorMessage = null;
    notifyListeners();

    final model = SafetySettingsModel(
      harassment: _harassment,
      hateSpeech: _hateSpeech,
      sexuallyExplicit: _sexuallyExplicit,
      dangerousContent: _dangerousContent,
    );

    try {
      final ok = await _service.updateSafetySettings(familyId, model);
      if (ok) {
        _saveSuccess = true;
      } else {
        _errorMessage = '설정 저장에 실패했습니다. 다시 시도해 주세요.';
      }
    } catch (e, st) {
      debugPrint('[SafetySettingsViewModel] saveSettings error: $e\n$st');
      _errorMessage = '오류가 발생했습니다. 잠시 후 다시 시도해 주세요.';
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }
}
