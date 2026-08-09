import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_font.dart';

class SettingsViewModel extends ChangeNotifier {
  // ── SharedPreferences keys ──────────────────────────────────────────────
  static const _keyFontFamily = 'settings_font_family';
  static const _keyIsBold = 'settings_is_bold';
  static const _keyTextSize = 'settings_text_size';

  static const double defaultTextSize = 18.0;

  // ── Fonts ──────────────────────────────────────────────────────────────
  /// All fonts registered in pubspec.yaml (NanumMyeongjo excluded per design guide).
  static const List<AppFont> availableFonts = [
    AppFont(displayName: '기본 폰트', fontFamily: null),
    AppFont(displayName: '나눔고딕', fontFamily: 'NanumGothic'),
    AppFont(displayName: '나눔스퀘어', fontFamily: 'NanumSquare'),
    AppFont(displayName: '나눔스퀘어 ac', fontFamily: 'NanumSquare_ac'),
    AppFont(displayName: '나눔스퀘어 라운드', fontFamily: 'NanumSquareRound'),
    AppFont(displayName: '나눔바른펜', fontFamily: 'NanumBarunpen'),
  ];

  String _selectedFontDisplayName = '기본 폰트';
  bool _isBold = false;
  double _textSize = defaultTextSize;

  String get selectedFontDisplayName => _selectedFontDisplayName;

  AppFont get selectedFont =>
      availableFonts.firstWhere(
        (f) => f.displayName == _selectedFontDisplayName,
        orElse: () => availableFonts.first,
      );

  /// The fontFamily string for the currently selected font (null = system default).
  String? get fontFamily => selectedFont.fontFamily;

  bool get isBold => _isBold;
  double get textSize => _textSize;

  // ── Init ───────────────────────────────────────────────────────────────

  /// Must be called once after construction (awaited in main()).
  Future<void> init() async {
    await _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _selectedFontDisplayName =
          prefs.getString(_keyFontFamily) ?? '기본 폰트';
      _isBold = prefs.getBool(_keyIsBold) ?? false;
      _textSize = prefs.getDouble(_keyTextSize) ?? defaultTextSize;
    } catch (_) {
      // Fail gracefully; defaults are already set above.
    }
    notifyListeners();
  }

  // ── Setters (persist immediately) ─────────────────────────────────────

  Future<void> setFontFamily(String displayName) async {
    if (_selectedFontDisplayName == displayName) return;
    _selectedFontDisplayName = displayName;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyFontFamily, displayName);
    } catch (_) {}
  }

  Future<void> toggleBold() async {
    _isBold = !_isBold;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyIsBold, _isBold);
    } catch (_) {}
  }

  Future<void> setTextSize(double size) async {
    if (_textSize == size) return;
    _textSize = size;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_keyTextSize, size);
    } catch (_) {}
  }
}
