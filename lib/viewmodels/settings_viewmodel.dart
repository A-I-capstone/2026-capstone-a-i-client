import 'package:flutter/foundation.dart';

class SettingsViewModel extends ChangeNotifier {
  // TTS Voice
  String _ttsVoice = '다정한 목소리 1';
  final List<String> availableVoices = ['다정한 목소리 1', '씩씩한 목소리 1', '차분한 목소리 1'];

  String get ttsVoice => _ttsVoice;
  void setTtsVoice(String voice) {
    if (_ttsVoice != voice) {
      _ttsVoice = voice;
      notifyListeners();
    }
  }

  // Text Settings
  double _textSize = 18.0;
  double get textSize => _textSize;
  void setTextSize(double size) {
    if (_textSize != size) {
      _textSize = size;
      notifyListeners();
    }
  }

  String _fontFamily = '기본 폰트';
  final List<String> availableFonts = ['기본 폰트', '둥근 폰트', '반듯한 폰트'];

  String get fontFamily => _fontFamily;
  void setFontFamily(String font) {
    if (_fontFamily != font) {
      _fontFamily = font;
      notifyListeners();
    }
  }

  bool _isBold = false;
  bool get isBold => _isBold;
  void toggleBold() {
    _isBold = !_isBold;
    notifyListeners();
  }
}
