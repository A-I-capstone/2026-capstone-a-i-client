import 'package:flutter/services.dart' show rootBundle;
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../core/storage/key_value_store.dart';
import '../models/chat_response.dart';

class ChatRepository {
  final KeyValueStore _storage;

  ChatRepository({required KeyValueStore storage}) : _storage = storage;

  Stream<ChatResponse> sendMessageStream(String message) async* {
    try {
      final apiKey = dotenv.env["GEMINI_API_KEY"];
      if (apiKey == null || apiKey.isEmpty) {
        yield ChatResponse.error(
          message:
              "I need a special key to talk! Please ask a grown-up to help set it up.",
          errorCode: "MISSING_API_KEY",
        );
        return;
      }

      // Load system prompt
      String systemInstruction = "";
      try {
        systemInstruction = await rootBundle.loadString(
          'prompts/system_prompt.md',
        );
      } catch (e) {
        // Proceed without system instructions if it fails to load
      }

      final model = GenerativeModel(
        model: 'gemini-3.1-flash-lite',
        apiKey: apiKey,
        systemInstruction: systemInstruction.isNotEmpty
            ? Content.system(systemInstruction)
            : null,
      );

      final content = [Content.text(message)];
      final responseStream = model.generateContentStream(content);

      await for (final chunk in responseStream) {
        if (chunk.text != null && chunk.text!.isNotEmpty) {
          yield ChatResponse.success(chunk.text!);
        }
      }
    } catch (e) {
      yield ChatResponse.error(
        message:
            "Oops, my brain needs a quick break! Let's try again in a moment.",
        errorCode: "NETWORK_OR_API_ERROR",
      );
    }
  }
}
