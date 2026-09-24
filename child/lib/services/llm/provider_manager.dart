import 'package:flutter/foundation.dart';

import 'base_llm_provider.dart';
import 'gemini_provider.dart';

/// Facade that routes chat messages to the active [BaseLLMProvider].
///
/// [ChatViewModel] depends on this class, not on concrete providers directly,
/// keeping the ViewModel decoupled from any specific AI SDK.
///
/// Extension points for future phases:
///   - TODO: Activate [switchProvider] when dynamic model switching is needed.
class ProviderManager {
  BaseLLMProvider _provider;
  final BaseLLMProvider _titleProvider;

  // Fields stored for recreation when grounding state changes.
  final String _modelName;
  final String _systemPrompt;

  ProviderManager({
    required BaseLLMProvider provider,
    required BaseLLMProvider titleProvider,
    required String modelName,
    required String systemPrompt,
  }) : _provider = provider,
       _titleProvider = titleProvider,
       _modelName = modelName,
       _systemPrompt = systemPrompt;

  /// Delegates to the active provider's streaming method.
  Stream<String> sendMessageStream(
    String userMessage, {
    List history = const [],
  }) => _provider.sendMessageStream(userMessage, history: history);

  /// Generates a chat title based on the first user message.
  Future<String> generateTitle(String firstMessage) async {
    final stream = _titleProvider.sendMessageStream(firstMessage);
    final buffer = StringBuffer();
    await for (final chunk in stream) {
      buffer.write(chunk);
    }
    return buffer.toString().trim();
  }

  /// Replaces the active chat provider with one reflecting the new grounding
  /// state. Called by [ChatViewModel] when the user toggles the setting.
  Future<void> updateGrounding(bool isEnabled) async {
    try {
      await _provider.dispose();
    } catch (e) {
      debugPrint('[ProviderManager] dispose error during updateGrounding: $e');
    }
    _provider = GeminiProvider(
      modelName: _modelName,
      systemPrompt: _systemPrompt,
      isGroundingEnabled: isEnabled,
    );
    debugPrint('[ProviderManager] updateGrounding → grounding=${isEnabled ? "ON" : "OFF"}');
  }

  // TODO: Uncomment and extend when multi-provider routing is required.
  // void switchProvider(BaseLLMProvider newProvider) {
  //   _provider.dispose();
  //   _provider = newProvider;
  // }

  Future<void> dispose() async {
    await _provider.dispose();
    await _titleProvider.dispose();
  }
}
