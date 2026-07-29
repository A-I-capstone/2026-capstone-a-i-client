import 'base_llm_provider.dart';

/// Facade that routes chat messages to the active [BaseLLMProvider].
///
/// [ChatViewModel] depends on this class, not on concrete providers directly,
/// keeping the ViewModel decoupled from any specific AI SDK.
///
/// Extension points for future phases:
///   - TODO: Activate [switchProvider] when dynamic model switching is needed.
class ProviderManager {
  BaseLLMProvider _provider;

  ProviderManager({required BaseLLMProvider provider}) : _provider = provider;

  /// Delegates to the active provider's streaming method.
  Stream<String> sendMessageStream(
    String userMessage, {
    List history = const [],
  }) =>
      _provider.sendMessageStream(userMessage, history: history);

  // TODO: Uncomment and extend when multi-provider routing is required.
  // void switchProvider(BaseLLMProvider newProvider) {
  //   _provider.dispose();
  //   _provider = newProvider;
  // }

  Future<void> dispose() => _provider.dispose();
}
