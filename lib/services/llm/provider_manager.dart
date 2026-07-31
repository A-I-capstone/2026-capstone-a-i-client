import 'base_llm_provider.dart';

/// Facade that routes chat messages to the active [BaseLLMProvider].
///
/// [ChatViewModel] depends on this class, not on concrete providers directly,
/// keeping the ViewModel decoupled from any specific AI SDK.
///
/// Extension points for future phases:
///   - TODO: Activate [switchProvider] when dynamic model switching is needed.
class ProviderManager {
  final BaseLLMProvider _provider;
  final BaseLLMProvider _titleProvider;

  ProviderManager({
    required BaseLLMProvider provider,
    required BaseLLMProvider titleProvider,
  })  : _provider = provider,
        _titleProvider = titleProvider;

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
