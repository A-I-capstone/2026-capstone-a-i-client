import 'package:flutter/foundation.dart';
import '../../models/chat_message.dart';
import '../../repositories/chat_repository.dart';

class ChatViewModel extends ChangeNotifier {
  final ChatRepository _chatRepository;

  final List<ChatMessage> _chatHistory = [];
  bool _isLoading = false;

  ChatViewModel({required ChatRepository chatRepository})
      : _chatRepository = chatRepository;

  List<ChatMessage> get chatHistory => _chatHistory;
  bool get isLoading => _isLoading;

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    // Add user message
    _chatHistory.add(
      ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: text,
        isUser: true,
      ),
    );
    
    _isLoading = true; // Show loading bubble in UI
    notifyListeners();

    final aiMessageId = DateTime.now().millisecondsSinceEpoch.toString() + "_ai";

    try {
      final stream = _chatRepository.sendMessageStream(text);
      String fullResponse = "";
      bool isFirstChunk = true;

      await for (final chunkResponse in stream) {
        if (isFirstChunk) {
          _isLoading = false; // Hide loading bubble
          isFirstChunk = false;
          // Add the initial AI message
          _chatHistory.add(
            ChatMessage(
              id: aiMessageId,
              text: "",
              isUser: false,
            ),
          );
        }

        if (chunkResponse.isSuccess) {
          fullResponse += chunkResponse.message;
          final index = _chatHistory.indexWhere((m) => m.id == aiMessageId);
          if (index != -1) {
            _chatHistory[index] = ChatMessage(
              id: aiMessageId,
              text: fullResponse,
              isUser: false,
            );
            notifyListeners();
          }
        } else {
          // Handle error gracefully via chat bubble
          final index = _chatHistory.indexWhere((m) => m.id == aiMessageId);
          if (index != -1) {
            _chatHistory[index] = ChatMessage(
              id: aiMessageId,
              text: chunkResponse.message, // The friendly fallback message
              isUser: false,
            );
            notifyListeners();
          }
          break; // Stop listening to stream on error
        }
      }
      
      // Safety net: in case stream was completely empty without errors
      if (isFirstChunk) {
        _isLoading = false;
        notifyListeners();
      }

    } catch (e) {
      _isLoading = false;
      final index = _chatHistory.indexWhere((m) => m.id == aiMessageId);
      if (index != -1) {
        _chatHistory[index] = ChatMessage(
          id: aiMessageId,
          text: "Oops, my brain needs a quick break! Let's try again in a moment.",
          isUser: false,
        );
        notifyListeners();
      }
    }
  }
}
