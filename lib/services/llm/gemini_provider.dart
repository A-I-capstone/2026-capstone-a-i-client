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
  final String _modelName;
  final String _systemPrompt;

  late final GenerativeModel _model;

  GeminiProvider({
    required String modelName,
    required String systemPrompt,
  })  : _modelName = modelName,
        _systemPrompt = systemPrompt {
    _model = FirebaseAI.googleAI().generativeModel(
      model: _modelName,
      systemInstruction: Content.system(_systemPrompt),
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

    final chat = _model.startChat(history: contentHistory);

    try {
      final responseStream =
          chat.sendMessageStream(Content.text(userMessage));

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

  @override
  Future<void> dispose() async {
    // GenerativeModel holds no persistent resources to release.
    // Placeholder for future clean-up (e.g. closing a gRPC channel).
  }
}
