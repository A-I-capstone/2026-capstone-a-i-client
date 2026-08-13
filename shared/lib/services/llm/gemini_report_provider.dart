import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart';

/// Gemini provider specifically designed for one-shot report summary generation.
///
/// Communicates with Gemini via the [FirebaseAI.googleAI] backend.
class GeminiReportProvider {
  final String modelName;
  final String systemPrompt;

  late final GenerativeModel _model;

  GeminiReportProvider({
    required this.modelName,
    required this.systemPrompt,
  }) {
    _model = FirebaseAI.googleAI().generativeModel(
      model: modelName,
      systemInstruction: Content.system(systemPrompt),
    );
  }

  /// Generates a report summary from the given prompt.
  ///
  /// Returns the generated summary text, or an empty string if generation fails.
  Future<String> generateText(String prompt) async {
    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      return response.text ?? '';
    } catch (e, stackTrace) {
      debugPrint('[GeminiReportProvider] generateText error: $e\n$stackTrace');
      rethrow;
    }
  }
}
