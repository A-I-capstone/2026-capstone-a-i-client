import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart';
import 'package:shared/shared.dart';

import '../../models/chat_message.dart';
import 'base_llm_provider.dart';

/// Exception thrown when Gemini blocks a response due to safety settings.
///
/// Callers should catch this and display a child-friendly message instead of
/// a technical error.
class ContentBlockedException implements Exception {
  const ContentBlockedException();

  @override
  String toString() => 'ContentBlockedException: Response blocked by safety filter.';
}

/// Concrete [BaseLLMProvider] that communicates with Gemini via the
/// Firebase AI (Google AI backend) SDK.
///
/// Uses [FirebaseAI.googleAI] and the Chat Session API so that conversation
/// history can be injected without changing the public interface.
///
/// Accepts an optional [SafetySettingsModel] that is converted to a full
/// [List<SafetySetting>] (including the always-on jailbreak block) when the
/// [GenerativeModel] is instantiated.
class GeminiProvider implements BaseLLMProvider {
  final String modelName;
  final String systemPrompt;
  final SafetySettingsModel safetySettings;

  late final GenerativeModel _model;

  GeminiProvider({
    required this.modelName,
    required this.systemPrompt,
    SafetySettingsModel? safetySettings,
  }) : safetySettings = safetySettings ?? const SafetySettingsModel() {
    _model = FirebaseAI.googleAI().generativeModel(
      model: modelName,
      systemInstruction: Content.system(systemPrompt),
      safetySettings: this.safetySettings.toSafetySettings(),
    );
  }

  @override
  Stream<String> sendMessageStream(
    String userMessage, {
    List history = const [],
  }) async* {
    // Convert ChatMessage list to firebase_ai Content list.
    // Each ChatMessage carries its own toContent() converter.
    final contentHistory = history
        .whereType<ChatMessage>()
        .map((m) => m.toContent())
        .toList();

    _printDebugContext(userMessage, history);

    final chat = _model.startChat(history: contentHistory);

    try {
      final responseStream = chat.sendMessageStream(Content.text(userMessage));

      await for (final response in responseStream) {
        // Check if the response was blocked by safety filters.
        // When blocked, response.text is null and promptFeedback may indicate
        // the block reason. We surface a typed exception so the caller can
        // display a child-friendly fallback message.
        final candidates = response.candidates;
        if (candidates.isNotEmpty) {
          final finishReason = candidates.first.finishReason;
          if (finishReason == FinishReason.safety ||
              finishReason == FinishReason.other) {
            debugPrint(
              '[GeminiProvider] 콘텐츠 차단됨: finishReason=$finishReason',
            );
            throw const ContentBlockedException();
          }
        }

        final text = response.text;
        if (text != null && text.isNotEmpty) {
          yield text;
        }
      }
    } on ContentBlockedException {
      rethrow;
    } catch (e, stackTrace) {
      // Check if the error message indicates a safety block (SDK-level throw).
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('safety') ||
          errorStr.contains('block') ||
          errorStr.contains('harm')) {
        debugPrint('[GeminiProvider] 안전 필터에 의해 차단됨 (예외): $e');
        throw const ContentBlockedException();
      }

      debugPrint('[GeminiProvider] Streaming error: $e\n$stackTrace');
      // Re-throw so the caller (ProviderManager / ChatViewModel) can
      // discard the partial buffer and show a child-friendly fallback.
      rethrow;
    }
  }

  void _printDebugContext(String userMessage, List history) {
    final sb = StringBuffer();
    sb.writeln('==================== [Chat LLM Context] ====================');
    sb.writeln('[SYSTEM PROMPT]');
    sb.writeln(systemPrompt);
    sb.writeln('\n[SAFETY SETTINGS]');
    sb.writeln(safetySettings.toFirestore());
    sb.writeln('\n[CONVERSATION HISTORY (${history.length} items)]');

    if (history.isEmpty) {
      sb.writeln('(Empty history)');
    } else {
      for (var i = 0; i < history.length; i++) {
        final item = history[i];
        if (item is ChatMessage) {
          final role = item.isUser ? 'USER' : 'ASSISTANT';
          sb.writeln('  [$i] [$role]: ${item.text}');
        } else if (item is Content) {
          final role = item.role == 'user' ? 'USER' : 'ASSISTANT';
          final text = item.parts
              .map((p) => p is TextPart ? p.text : p.toString())
              .join('');
          sb.writeln('  [$i] [$role]: $text');
        } else {
          sb.writeln('  [$i]: $item');
        }
      }
    }

    sb.writeln('\n[CURRENT USER MESSAGE]');
    sb.writeln(userMessage);
    sb.writeln('============================================================');

    debugPrint(sb.toString());
  }

  @override
  Future<void> dispose() async {
    // GenerativeModel holds no persistent resources to release.
    // Placeholder for future clean-up (e.g. closing a gRPC channel).
  }
}
