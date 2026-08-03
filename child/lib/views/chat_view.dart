import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/chat_message.dart';
import '../models/chat_session.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../viewmodels/chat_viewmodel.dart';
import '../viewmodels/profile_viewmodel.dart';
import '../widgets/bouncy_button.dart';
import '../widgets/pulse_loader.dart';
import '../widgets/chat/chat_bubble.dart';
import '../widgets/chat/chat_input_bar.dart';
import 'settings_view.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      debugPrint('[View] initState → ProfileViewModel.initialize() 호출');
      // 1. Sign in and initialise profiles (auto-creates default if needed).
      final chatVm = context.read<ChatViewModel>();
      final profileVm = context.read<ProfileViewModel>();

      // Sign in first to get the userId.
      final userId = await chatVm.signInAndGetUserId();

      // Initialise profiles under that userId.
      await profileVm.initialize(userId);

      // Then initialise the chat session under the now-active profile.
      debugPrint('[View] initState → ChatViewModel.initialize() 호출');
      await chatVm.initialize();
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: const _ChatAppBar(),
      drawer: const _MenuDrawer(),
      onDrawerChanged: (isOpened) {
        if (isOpened) {
          context.read<ChatViewModel>().loadChatSessions();
        }
      },
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

/// Side menu Drawer with recent chat session list in the bottom half.
class _MenuDrawer extends StatelessWidget {
  const _MenuDrawer();

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.bg,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _DrawerTopSection(),
            const _DrawerDivider(),
            const Expanded(child: _RecentChatList()),
          ],
        ),
      ),
    );
  }
}

/// Top half of the drawer — title and menu actions.
class _DrawerTopSection extends StatelessWidget {
  const _DrawerTopSection();
  @override
  Widget build(BuildContext context) {
    final viewModel = context.read<ChatViewModel>();
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('메뉴', style: AppTypography.headlineMedium),
            const SizedBox(height: 24),
            _DrawerMenuTile(
              icon: Icons.chat_bubble_outline_rounded,
              label: '새 대화 시작',
              onTap: () {
                Navigator.of(context).pop(); // Drawer 닫기
                viewModel.startNewChat();
              },
            ),
            _DrawerMenuTile(
              icon: Icons.settings_outlined, 
              label: '설정',
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const SettingsView()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// A single tappable menu row in the top section.
class _DrawerMenuTile extends StatelessWidget {
  const _DrawerMenuTile({required this.icon, required this.label, this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            child: Row(
              children: [
                Icon(icon, color: AppColors.ink, size: 24),
                const SizedBox(width: 16),
                Text(label, style: AppTypography.bodyLarge),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Wavy-inspired divider separating the top and bottom drawer sections.
class _DrawerDivider extends StatelessWidget {
  const _DrawerDivider();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(color: AppColors.border, thickness: 1.5),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 12, bottom: 8),
            child: Text(
              '최근 대화',
              style: AppTypography.eyebrow.copyWith(
                fontSize: 14,
                letterSpacing: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom half — scrollable list of recent chat sessions.
class _RecentChatList extends StatelessWidget {
  const _RecentChatList();
  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ChatViewModel>();
    if (viewModel.isLoadingSessions) {
      return const Center(child: PulseLoader(size: 32));
    }
    final sessions = viewModel.chatSessions;
    if (sessions.isEmpty) {
      return const _EmptyChatListPlaceholder();
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: sessions.length,
      itemBuilder: (context, index) {
        return _ChatSessionTile(session: sessions[index]);
      },
    );
  }
}

/// Friendly placeholder when there are no past sessions yet.
class _EmptyChatListPlaceholder extends StatelessWidget {
  const _EmptyChatListPlaceholder();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          '아직 대화 기록이 없어요',
          style: AppTypography.bodyMedium.copyWith(color: AppColors.border),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

/// A single recent chat session row.
class _ChatSessionTile extends StatelessWidget {
  const _ChatSessionTile({required this.session});
  final ChatSession session;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.of(context).pop();
            context.read<ChatViewModel>().loadChat(session.id);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.border.withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: AppColors.sunriseYellow,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.chat_bubble_rounded,
                    color: AppColors.ink,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        session.title,
                        style: AppTypography.bodyMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_formatDate(session.updatedAt)} • 대화 ${session.messageCount}개',
                        style: AppTypography.bodyMedium.copyWith(
                          fontSize: 13,
                          color: AppColors.slate,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.border,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return '오늘';
    if (diff.inDays == 1) return '어제';
    if (diff.inDays < 7) return '${diff.inDays}일 전';
    return '${date.month}월 ${date.day}일';
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
          if (viewModel.isStreaming && viewModel.streamingBuffer.isNotEmpty) {
            return ChatBubble(
              message: ChatMessage(
                id: 'streaming_buffer',
                sender: MessageSender.ai,
                text: viewModel.streamingBuffer,
                timestamp: DateTime.now(),
              ),
            );
          }
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
