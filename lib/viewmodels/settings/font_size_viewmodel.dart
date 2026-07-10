import 'package:flutter/foundation.dart';
import '../../models/font_size_option.dart';

class FontSizeViewModel extends ChangeNotifier {
  final List<FontSizeOption> _options = const [
    FontSizeOption(
      label: '작은 글자',
      scale: 0.85,
      description: '아담하고 귀여운 크기예요',
    ),
    FontSizeOption(
      label: '보통 글자',
      scale: 1.0,
      description: '기본으로 보기 편한 크기예요',
    ),
    FontSizeOption(
      label: '큰 글자',
      scale: 1.2,
      description: '시원시원하게 큰 크기예요',
    ),
    FontSizeOption(
      label: '아주 큰 글자',
      scale: 1.4,
      description: '큼직하고 뚜렷하게 보여요',
    ),
  ];

  List<FontSizeOption> get options => List.unmodifiable(_options);

  int _selectedIndex = 1; // Default to '보통 글자' (1.0 scale)
  int get selectedIndex => _selectedIndex;

  double get currentScale {
    try {
      if (_selectedIndex >= 0 && _selectedIndex < _options.length) {
        return _options[_selectedIndex].scale;
      }
      return 1.0;
    } catch (e) {
      debugPrint('Error retrieving current scale: $e');
      return 1.0;
    }
  }

  FontSizeOption get currentOption {
    try {
      if (_selectedIndex >= 0 && _selectedIndex < _options.length) {
        return _options[_selectedIndex];
      }
      return _options[1];
    } catch (e) {
      debugPrint('Error retrieving current option: $e');
      return _options[1];
    }
  }

  void selectSize(int index) {
    try {
      if (index < 0 || index >= _options.length) return;
      if (_selectedIndex == index) return;

      _selectedIndex = index;
      notifyListeners();
    } catch (e) {
      debugPrint('Error selecting font size: $e');
    }
  }
}
