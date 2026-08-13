import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart';

import '../../models/chat_message.dart';
import 'base_llm_provider.dart';

/// Concrete [BaseLLMProvider] that communicates with Gemini via the
/// Firebase AI (Google AI backend) SDK.
///
/// Uses [FirebaseAI.googleAI] and the Chat Session API so that conversation
/// history can be injected without changing the public interface.
class GeminiProvider implements BaseLLMProvider {
  final String modelName;
  final String systemPrompt;

  late final GenerativeModel _model;

  GeminiProvider({required this.modelName, required this.systemPrompt}) {
    _model = FirebaseAI.googleAI().generativeModel(
      model: modelName,
      systemInstruction: Content.system(systemPrompt),
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
        // TODO: postprocessOutput() hook — apply output filtering here
        yield response.text ?? '';
      }
    } catch (e, stackTrace) {
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
