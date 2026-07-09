class ChatbotToneSettings {
  final int vocabularyLevel; // 1 ('쉬운말') ~ 5 ('어려운 말')
  final int toneLevel;       // 1 ('친근함') ~ 5 ('선생님')
  final int focusLevel;      // 1 ('공감')   ~ 5 ('지식')

  const ChatbotToneSettings({
    this.vocabularyLevel = 3,
    this.toneLevel = 3,
    this.focusLevel = 3,
  });

  ChatbotToneSettings copyWith({
    int? vocabularyLevel,
    int? toneLevel,
    int? focusLevel,
  }) {
    return ChatbotToneSettings(
      vocabularyLevel: vocabularyLevel ?? this.vocabularyLevel,
      toneLevel: toneLevel ?? this.toneLevel,
      focusLevel: focusLevel ?? this.focusLevel,
    );
  }
}
