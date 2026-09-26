import 'package:shared/shared.dart';

import 'base_llm_provider.dart';
import 'gemini_provider.dart';

/// Facade that routes chat messages to the active [BaseLLMProvider].
///
/// [ChatViewModel] depends on this class, not on concrete providers directly,
/// keeping the ViewModel decoupled from any specific AI SDK.
///
/// When the parent changes AI safety settings, call [rebuildWithSafetySettings]
/// to atomically swap both providers with the new configuration.
class ProviderManager {
  BaseLLMProvider _provider;
  BaseLLMProvider _titleProvider;

  // Configuration needed to rebuild providers when safety settings change.
  final String _modelName;
  final String _systemPrompt;
  final String _titleModelName;
  final String _titleSystemPrompt;

  ProviderManager({
    required BaseLLMProvider provider,
    required BaseLLMProvider titleProvider,
    required String modelName,
    required String systemPrompt,
    required String titleModelName,
    required String titleSystemPrompt,
  })  : _provider = provider,
        _titleProvider = titleProvider,
        _modelName = modelName,
        _systemPrompt = systemPrompt,
        _titleModelName = titleModelName,
        _titleSystemPrompt = titleSystemPrompt;

  /// Delegates to the active provider's streaming method.
  Stream<String> sendMessageStream(
    String userMessage, {
    List history = const [],
  }) =>
      _provider.sendMessageStream(userMessage, history: history);

  /// Generates a chat title based on the first user message.
  Future<String> generateTitle(String firstMessage) async {
    final stream = _titleProvider.sendMessageStream(firstMessage);
    final buffer = StringBuffer();
    await for (final chunk in stream) {
      buffer.write(chunk);
    }
    return buffer.toString().trim();
  }

  /// Replaces both providers with new instances that use [settings].
  ///
  /// The old providers are disposed before being replaced. Safe to call from
  /// the ViewModel whenever the Firestore safety-settings stream emits a new
  /// value.
  Future<void> rebuildWithSafetySettings(SafetySettingsModel settings) async {
    final oldProvider = _provider;
    final oldTitleProvider = _titleProvider;

    _provider = GeminiProvider(
      modelName: _modelName,
      systemPrompt: _systemPrompt,
      safetySettings: settings,
    );

    _titleProvider = GeminiProvider(
      modelName: _titleModelName,
      systemPrompt: _titleSystemPrompt,
      safetySettings: settings,
    );

    await oldProvider.dispose();
    await oldTitleProvider.dispose();
  }

  Future<void> dispose() async {
    await _provider.dispose();
    await _titleProvider.dispose();
  }
}
