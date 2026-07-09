import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/chat_view_model.dart';
import '../settings/settings_view.dart';

class ChatView extends StatelessWidget {
  const ChatView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE1F5FE), // 하늘색 배경
      appBar: const _ChatAppBar(),
      drawer: const _ChatDrawer(),
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
        onPressed: () {
          Scaffold.of(context).openDrawer();
        },
      ),
      actions: [
        IconButton(
          icon: const Icon(
            Icons.settings_rounded,
            color: Color(0xFF424242),
            size: 32,
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsView()),
            );
          },
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

class _ChatDrawer extends StatelessWidget {
  const _ChatDrawer();

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.8,
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            // 위쪽 절반: 메뉴 버튼들
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      '메뉴',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF424242),
                      ),
                    ),
                    const SizedBox(height: 32),
                    _DrawerButton(
                      icon: Icons.add_rounded,
                      label: '새로운 이야기 시작하기',
                      backgroundColor: const Color(0xFF81D4FA).withValues(alpha: 0.2),
                      iconColor: const Color(0xFF81D4FA),
                      onTap: () {
                        // TODO: 새 채팅 로직
                      },
                    ),
                    const SizedBox(height: 16),
                    _DrawerButton(
                      icon: Icons.search_rounded,
                      label: '이전 이야기 찾기',
                      backgroundColor: const Color(0xFFFFD54F).withValues(alpha: 0.2),
                      iconColor: const Color(0xFFFFB300),
                      onTap: () {
                        // TODO: 검색 로직
                      },
                    ),
                  ],
                ),
              ),
            ),
            // 아래쪽 절반: 최근 채팅 목록
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(24, 24, 24, 16),
                      child: Text(
                        '최근 나눈 이야기',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF757575),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Consumer<ChatViewModel>(
                        builder: (context, viewModel, child) {
                          return ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: viewModel.chatHistory.length,
                            itemBuilder: (context, index) {
                              final session = viewModel.chatHistory[index];
                              return _HistoryItem(
                                title: session.title,
                                onTap: () {
                                  // TODO: 해당 채팅으로 이동
                                },
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color backgroundColor;
  final Color iconColor;
  final VoidCallback onTap;

  const _DrawerButton({
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF424242),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryItem extends StatelessWidget {
  final String title;
  final VoidCallback onTap;

  const _HistoryItem({required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.chat_bubble_rounded, color: Color(0xFFE0E0E0), size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF616161),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFFBDBDBD)),
          ],
        ),
      ),
    );
  }
}
