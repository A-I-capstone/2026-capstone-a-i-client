import 'package:flutter/foundation.dart';
import '../../models/chatbot_tone_settings.dart';

class ChatbotToneViewModel extends ChangeNotifier {
  ChatbotToneSettings _settings = const ChatbotToneSettings();

  int get vocabularyLevel => _settings.vocabularyLevel;
  int get toneLevel => _settings.toneLevel;
  int get focusLevel => _settings.focusLevel;

  void updateVocabularyLevel(double value) {
    try {
      final intLevel = value.round().clamp(1, 5);
      if (_settings.vocabularyLevel == intLevel) return;

      _settings = _settings.copyWith(vocabularyLevel: intLevel);
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating vocabulary level: $e');
    }
  }

  void updateToneLevel(double value) {
    try {
      final intLevel = value.round().clamp(1, 5);
      if (_settings.toneLevel == intLevel) return;

      _settings = _settings.copyWith(toneLevel: intLevel);
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating tone level: $e');
    }
  }

  void updateFocusLevel(double value) {
    try {
      final intLevel = value.round().clamp(1, 5);
      if (_settings.focusLevel == intLevel) return;

      _settings = _settings.copyWith(focusLevel: intLevel);
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating focus level: $e');
    }
  }
}
