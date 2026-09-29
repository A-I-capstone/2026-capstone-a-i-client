import 'package:flutter_test/flutter_test.dart';
import 'package:shared/models/safety_settings_model.dart';

void main() {
  group('SafetySettingsModel Tests', () {
    test('toSafetySettings produces SafetySettings with null method for Google AI compatibility', () {
      const model = SafetySettingsModel(
        harassment: 1,
        hateSpeech: 0,
        sexuallyExplicit: 2,
        dangerousContent: 1,
      );

      final settings = model.toSafetySettings();

      expect(settings.length, 4);
      for (final setting in settings) {
        expect(setting.method, isNull,
            reason: 'HarmBlockMethod must be null for google AI backend compatibility');
      }
    });
  });
}
