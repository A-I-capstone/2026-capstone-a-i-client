/// Abstract base class for all LLM provider implementations.
///
/// Any concrete provider (e.g. [GeminiProvider]) must implement this contract.
/// This layer is the single integration point for the [ProviderManager].
///
/// Extension points for future phases:
///   - TODO: Add preprocessInput(String input) hook for input sanitisation
///   - TODO: Add postprocessOutput(String output) hook for output filtering
abstract class BaseLLMProvider {
  /// Sends [userMessage] to the underlying model with optional [history] and
  /// returns a token-by-token [Stream<String>].
  ///
  /// [history] should contain the most recent N turns of the conversation
  /// (managed by the ViewModel's sliding window). Callers should listen to
  /// this stream to progressively render the AI response.
  ///
  /// The stream completes normally when the model finishes generating.
  /// On error the stream emits an error event; callers are responsible for
  /// discarding any partial output and showing a child-friendly fallback.
  Stream<String> sendMessageStream(
    String userMessage, {
    List history = const [],
  });

  /// Releases any resources held by this provider (e.g. open sessions).
  Future<void> dispose();
}
