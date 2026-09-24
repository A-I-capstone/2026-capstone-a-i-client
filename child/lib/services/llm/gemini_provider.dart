import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart';

import '../../models/chat_message.dart';
import 'base_llm_provider.dart';

/// Concrete [BaseLLMProvider] that communicates with Gemini via the
/// Firebase AI (Google AI backend) SDK.
///
/// Uses [FirebaseAI.googleAI] and the Chat Session API so that conversation
/// history can be injected without changing the public interface.
///
/// When [isGroundingEnabled] is true, [Tool.googleSearch] is attached to the
/// model so that responses are grounded with live Google Search results.
class GeminiProvider implements BaseLLMProvider {
  final String modelName;
  final String systemPrompt;
  final bool isGroundingEnabled;

  late GenerativeModel _model;

  GeminiProvider({
    required this.modelName,
    required this.systemPrompt,
    this.isGroundingEnabled = false,
  }) {
    _model = _buildModel();
  }

  GenerativeModel _buildModel() {
    return FirebaseAI.googleAI().generativeModel(
      model: modelName,
      systemInstruction: Content.system(systemPrompt),
      tools: isGroundingEnabled ? [Tool.googleSearch()] : null,
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
    var hasYielded = false;

    try {
      final responseStream = chat.sendMessageStream(Content.text(userMessage));

      await for (final response in responseStream) {
        // TODO: postprocessOutput() hook — apply output filtering here
        final text = response.text ?? '';
        if (text.isNotEmpty) {
          hasYielded = true;
          yield text;
        }
      }
    } catch (e, stackTrace) {
      // Graceful degradation: If grounding was enabled and failed before yielding
      // any tokens (e.g. 429 quota exceeded on unbilled project or search tool error),
      // seamlessly fall back to non-grounded generation so the child receives an answer.
      if (isGroundingEnabled && !hasYielded) {
        debugPrint(
          '[GeminiProvider] Grounding streaming failed ($e). '
          'Gracefully falling back to non-grounded model...',
        );
        try {
          final fallbackModel = FirebaseAI.googleAI().generativeModel(
            model: modelName,
            systemInstruction: Content.system(systemPrompt),
          );
          final fallbackChat = fallbackModel.startChat(history: contentHistory);
          final fallbackStream =
              fallbackChat.sendMessageStream(Content.text(userMessage));

          await for (final response in fallbackStream) {
            yield response.text ?? '';
          }
          return;
        } catch (fallbackError, fallbackStackTrace) {
          debugPrint(
            '[GeminiProvider] Fallback without grounding also failed: $fallbackError\n$fallbackStackTrace',
          );
        }
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
    sb.writeln('[GROUNDING] Google Search: ${isGroundingEnabled ? "ON" : "OFF"}');
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
