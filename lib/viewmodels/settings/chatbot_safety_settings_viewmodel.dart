import 'package:flutter/foundation.dart';

enum SafetyLevel {
  none('차단 안함'),
  few('소수 차단'),
  some('일부 차단'),
  most('대부분 차단');

  final String label;
  const SafetyLevel(this.label);
}

class SafetyCategory {
  final String title;
  final String description;
  SafetyLevel level;

  SafetyCategory({
    required this.title, 
    required this.description,
    this.level = SafetyLevel.some,
  });
}

class ChatbotSafetySettingsViewModel extends ChangeNotifier {
  final List<SafetyCategory> categories = [
    SafetyCategory(
      title: '괴롭힘', 
      description: '특정 개인이나 집단의 정체성, 또는 보호받아야 할 속성을 겨냥하여 부정적이고 유해한 말을 하는 콘텐츠입니다.',
      level: SafetyLevel.some,
    ),
    SafetyCategory(
      title: '증오심 표현', 
      description: '타인에게 무례하거나 심한 모욕감을 주며, 욕설이 섞인 폭력적인 콘텐츠입니다.',
      level: SafetyLevel.some,
    ),
    SafetyCategory(
      title: '음란물', 
      description: '성적인 행위나 기타 외설적인 내용을 직접적으로 언급하거나 묘사하여 아이에게 부적절한 콘텐츠입니다.',
      level: SafetyLevel.some,
    ),
    SafetyCategory(
      title: '위험', 
      description: '스스로나 타인에게 유해하고 위험한 행동을 하도록 장려하거나 부추기는 콘텐츠입니다.',
      level: SafetyLevel.some,
    ),
  ];

  void updateLevel(int index, double value) {
    int levelIndex = value.round().clamp(0, 3);
    categories[index].level = SafetyLevel.values[levelIndex];
    notifyListeners();
  }
}
