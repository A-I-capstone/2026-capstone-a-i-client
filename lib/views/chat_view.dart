import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../viewmodels/chat_viewmodel.dart';
import '../widgets/bouncy_button.dart';
import '../widgets/pulse_loader.dart';
import '../widgets/chat/chat_bubble.dart';
import '../widgets/chat/chat_input_bar.dart';

/// Main Chat Screen (View layer)
class ChatView extends StatefulWidget {
  const ChatView({super.key});
  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  @override
  void initState() {
    super.initState();
    // Schedule after the first frame so context.read is safe to call.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint('[View] initState → initialize() 호출');
      context.read<ChatViewModel>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: const _ChatAppBar(),
      drawer: const _EmptyMenuDrawer(),
      body: SafeArea(
        child: Column(
          children: const [
            Expanded(child: _MessageListArea()),
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
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      centerTitle: true,
      toolbarHeight: 64,
      backgroundColor: AppColors.bg,
      surfaceTintColor: Colors.transparent,
      leadingWidth: 64,
      leading: Builder(
        builder: (drawerContext) => Center(
          child: BouncyButton(
            isCircle: true,
            backgroundColor: Colors.transparent,
            padding: const EdgeInsets.all(8),
            icon: const Icon(
              Icons.menu_rounded,
              color: AppColors.ink,
              size: 32,
            ),
            onTap: () => Scaffold.of(drawerContext).openDrawer(),
          ),
        ),
      ),
      actions: [
        Center(
          child: Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: BouncyButton(
              isCircle: true,
              backgroundColor: Colors.transparent,
              padding: const EdgeInsets.all(8),
              icon: const Icon(
                Icons.star_rounded,
                color: AppColors.ink,
                size: 32,
              ),
              onTap: () {},
            ),
          ),
        ),
      ],
    );
  }
}

/// Empty side menu (Drawer)
class _EmptyMenuDrawer extends StatelessWidget {
  const _EmptyMenuDrawer();

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.bg,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('메뉴', style: AppTypography.headlineMedium),
              SizedBox(height: 16),
              Expanded(child: SizedBox.shrink()),
            ],
          ),
        ),
      ),
    );
  }
}

class _MessageListArea extends StatelessWidget {
  const _MessageListArea();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ChatViewModel>();
    final messages = viewModel.messages;

    if (messages.isEmpty && !viewModel.isLoading) {
      return const _CenteredWelcomeHeader();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12.0),
      itemCount: messages.length + (viewModel.isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index < messages.length) {
          return ChatBubble(message: messages[index]);
        } else {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 12.0),
            child: PulseLoader(size: 36),
          );
        }
      },
    );
  }
}

/// Centered welcome greeting header displayed in the middle of the screen
class _CenteredWelcomeHeader extends StatelessWidget {
  const _CenteredWelcomeHeader();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: const [
            Text(
              '안녕! 오늘은 어떤 얘기를 나눠볼까?',
              textAlign: TextAlign.center,
              style: AppTypography.headlineLarge,
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatInputArea extends StatelessWidget {
  const _ChatInputArea();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ChatViewModel>();

    return ChatInputBar(
      isListening: viewModel.isListening,
      onToggleListening: viewModel.toggleListening,
      onSend: (text) => viewModel.sendMessage(text),
    );
  }
}
