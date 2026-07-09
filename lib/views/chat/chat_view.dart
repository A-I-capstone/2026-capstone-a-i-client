import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/chat_view_model.dart';

class ChatView extends StatelessWidget {
  const ChatView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE1F5FE), // 하늘색 배경
      appBar: const _ChatAppBar(),
      body: const SafeArea(
        child: Column(
          children: [
            Expanded(child: _GreetingBody()),
            _ChatInputArea(),
          ],
        ),
      ),
    );
  }
}

class _ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _ChatAppBar();

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(
          Icons.menu_rounded,
          color: Color(0xFF424242),
          size: 32,
        ),
        onPressed: () {}, // To be implemented
      ),
      actions: [
        IconButton(
          icon: const Icon(
            Icons.settings_rounded,
            color: Color(0xFF424242),
            size: 32,
          ),
          onPressed: () {}, // To be implemented
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _GreetingBody extends StatelessWidget {
  const _GreetingBody();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 800),
        curve: Curves.elasticOut,
        builder: (context, value, child) {
          return Transform.scale(
            scale: value,
            child: const Text(
              "안녕! 반가워요 😊\n어떤 재미있는 이야기를 할까요?",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF424242),
                height: 1.5,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ChatInputArea extends StatelessWidget {
  const _ChatInputArea();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ChatViewModel>();
    final controller = TextEditingController.fromValue(
      TextEditingValue(
        text: viewModel.inputText,
        selection: TextSelection.collapsed(offset: viewModel.inputText.length),
      ),
    );

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Container(
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 255, 240, 157), // 노란색 입력 위젯
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                onChanged: viewModel.updateInputText,
                decoration: const InputDecoration(
                  hintText: "메세지를 입력해주세요...",
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.black38),
                ),
                style: const TextStyle(fontSize: 18, color: Colors.black87),
              ),
            ),
            const SizedBox(width: 8),
            _SendButton(
              isActive: viewModel.inputText.trim().isNotEmpty,
              onTap: viewModel.sendMessage,
            ),
          ],
        ),
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  final bool isActive;
  final VoidCallback onTap;

  const _SendButton({required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isActive ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(12),
        decoration: const BoxDecoration(
          color: Color(0xFF81D4FA),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.send_rounded,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }
}
