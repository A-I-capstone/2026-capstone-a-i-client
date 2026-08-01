import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../bouncy_button.dart';

/// Larger, borderless chat input bar with vivid solid primary color fill and larger icons.
class ChatInputBar extends StatefulWidget {
  final ValueChanged<String> onSend;
  final VoidCallback onToggleListening;
  final bool isListening;

  const ChatInputBar({
    super.key,
    required this.onSend,
    required this.onToggleListening,
    required this.isListening,
  });

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  final TextEditingController _controller = TextEditingController();

  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      widget.onSend(text);
      _controller.clear();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
      color: AppColors.bg,
      child: _InputField(
        controller: _controller,
        onSubmitted: _handleSend,
        isListening: widget.isListening,
        onToggleListening: widget.onToggleListening,
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSubmitted;
  final bool isListening;
  final VoidCallback onToggleListening;

  const _InputField({
    required this.controller,
    required this.onSubmitted,
    required this.isListening,
    required this.onToggleListening,
  });

  @override
  Widget build(BuildContext context) {
    final micColor = isListening ? AppColors.ocean : AppColors.ink;

    return TextField(
      controller: controller,
      style: AppTypography.bodyLarge.copyWith(color: AppColors.ink),
      textInputAction: TextInputAction.send,
      onSubmitted: (_) => onSubmitted(),
      decoration: InputDecoration(
        hintText: '메시지를 입력해 봐...',
        hintStyle: AppTypography.bodyLarge.copyWith(color: AppColors.ink.withValues(alpha: 0.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 18.0),
        filled: true,
        fillColor: AppColors.marigold, // Solid vivid brand color
        suffixIcon: Padding(
          padding: const EdgeInsets.only(right: 12.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              BouncyButton(
                isCircle: true,
                backgroundColor: isListening ? AppColors.tangerine : AppColors.ocean,
                padding: const EdgeInsets.all(8),
                icon: Icon(
                  isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                  color: AppColors.surface,
                  size: 24,
                ),
                onTap: onToggleListening,
              ),
              const SizedBox(width: 6),
              BouncyButton(
                isCircle: true,
                backgroundColor: AppColors.ocean,
                padding: const EdgeInsets.all(8),
                icon: const Icon(
                  Icons.send_rounded,
                  color: AppColors.surface,
                  size: 24,
                ),
                onTap: onSubmitted,
              ),
            ],
          ),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(32.0),
          borderSide: BorderSide.none, // No border outline
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(32.0),
          borderSide: BorderSide.none, // No border outline
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(32.0),
          borderSide: BorderSide.none, // No border outline
        ),
      ),
    );
  }
}
