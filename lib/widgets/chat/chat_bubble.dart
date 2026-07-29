import 'package:flutter/material.dart';
import '../../models/chat_message.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

/// Child-friendly message bubble component with 24px radius and 2px Ink outlines.
class ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatBubble({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final alignment = isUser ? Alignment.centerRight : Alignment.centerLeft;
    final bgColor = isUser ? AppColors.marigold : AppColors.surface;

    return Align(
      alignment: alignment,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 12.0),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 14.0),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(24.0),
            topRight: const Radius.circular(24.0),
            bottomLeft: Radius.circular(isUser ? 24.0 : 4.0),
            bottomRight: Radius.circular(isUser ? 4.0 : 24.0),
          ),
          border: Border.all(color: AppColors.ink, width: 2.0),
        ),
        child: Text(
          message.text,
          style: AppTypography.bodyLarge,
        ),
      ),
    );
  }
}
