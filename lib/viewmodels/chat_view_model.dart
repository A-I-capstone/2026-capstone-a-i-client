import 'package:flutter/foundation.dart';
import '../models/chat_message.dart';
import '../models/chat_session.dart';

class ChatViewModel extends ChangeNotifier {
  final List<ChatMessage> _messages = [];
  List<ChatMessage> get messages => List.unmodifiable(_messages);

  final List<ChatSession> _chatHistory = [
    ChatSession(id: '1', title: '어제 한 이야기: 공룡 친구들'),
    ChatSession(id: '2', title: '저번 주: 우주 탐험대'),
    ChatSession(id: '3', title: '우리가 만든 마법 동화'),
  ];
  List<ChatSession> get chatHistory => List.unmodifiable(_chatHistory);

  String _inputText = '';
  String get inputText => _inputText;

  void updateInputText(String text) {
    _inputText = text;
    notifyListeners();
  }

  void sendMessage() {
    if (_inputText.trim().isEmpty) return;

    try {
      final newMessage = ChatMessage(
        id: DateTime.now().toString(),
        text: _inputText.trim(),
        isUser: true,
      );
      
      _messages.add(newMessage);
      _inputText = '';
      notifyListeners();
      
      // Simulate AI response (mock data)
      _simulateResponse();
    } catch (e) {
      // Child-Friendly Exception Handling: Fail silently or degrade gracefully
      debugPrint('Error sending message: $e');
    }
  }

  Future<void> _simulateResponse() async {
    try {
      await Future.delayed(const Duration(seconds: 1));
      final response = ChatMessage(
        id: DateTime.now().toString(),
        text: "안녕! 만나서 반가워. 오늘은 어떤 이야기를 해볼까?",
        isUser: false,
      );
      _messages.add(response);
      notifyListeners();
    } catch (e) {
      debugPrint('Error simulating response: $e');
    }
  }
}
