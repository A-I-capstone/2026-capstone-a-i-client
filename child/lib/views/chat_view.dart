import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/chat_message.dart';
import '../models/task.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../viewmodels/chat_viewmodel.dart';
import '../widgets/bouncy_button.dart';
import '../widgets/pulse_loader.dart';
import '../widgets/chat/chat_bubble.dart';
import '../widgets/chat/chat_input_bar.dart';

/// Task-specific AI Chat Screen (View layer)
class ChatView extends StatefulWidget {
  final Task task;

  const ChatView({super.key, required this.task});

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final chatVm = context.read<ChatViewModel>();
      debugPrint('[ChatView] initState → initialize() for task: ${widget.task.title}');
      await chatVm.initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: _ChatAppBar(title: widget.task.title),
      body: SafeArea(
        child: Column(
          children: [
            _TaskSubtasksProgressHeader(task: widget.task),
            const Expanded(child: _MessageListArea()),
            const _ChatInputArea(),
          ],
        ),
      ),
    );
  }
}

class _ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;

  const _ChatAppBar({required this.title});

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      centerTitle: true,
      toolbarHeight: 60,
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(2),
        child: Divider(color: AppColors.ink, height: 2, thickness: 2),
      ),
      leading: Center(
        child: BouncyButton(
          isCircle: true,
          backgroundColor: Colors.transparent,
          padding: const EdgeInsets.all(8),
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: AppColors.ink,
            size: 28,
          ),
          onTap: () => Navigator.of(context).pop(),
        ),
      ),
      title: Text(
        '$title 학습 도움',
        style: AppTypography.headlineMedium.copyWith(fontSize: 18),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

/// Collapsible header showing task subtasks checklist at the top of chat view.
class _TaskSubtasksProgressHeader extends StatefulWidget {
  final Task task;

  const _TaskSubtasksProgressHeader({required this.task});

  @override
  State<_TaskSubtasksProgressHeader> createState() =>
      _TaskSubtasksProgressHeaderState();
}

class _TaskSubtasksProgressHeaderState
    extends State<_TaskSubtasksProgressHeader> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    final subtasks = widget.task.subtasks;
    if (subtasks.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.ink, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '진행사항 (${subtasks.where((s) => s.isCompleted).length}/${subtasks.length})',
                  style: AppTypography.bodyLarge.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Icon(
                  _isExpanded
                      ? Icons.arrow_drop_up_rounded
                      : Icons.arrow_drop_down_rounded,
                  color: AppColors.ink,
                  size: 28,
                ),
              ],
            ),
          ),
          if (_isExpanded) ...[
            const SizedBox(height: 8),
            const Divider(color: AppColors.border, height: 1),
            const SizedBox(height: 8),
            Column(
              children: [
                for (final st in subtasks) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Icon(
                          st.isCompleted
                              ? Icons.check_box_rounded
                              : Icons.check_box_outline_blank_rounded,
                          color: AppColors.ink,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          st.title,
                          style: AppTypography.bodyMedium.copyWith(
                            fontSize: 14,
                            decoration: st.isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                            color: st.isCompleted
                                ? AppColors.slate
                                : AppColors.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
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

class _CenteredWelcomeHeader extends StatelessWidget {
  const _CenteredWelcomeHeader();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ChatViewModel>();

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              '\'${viewModel.task.title}\' 과제 준비 힘내자!\n무엇이든 물어봐!',
              textAlign: TextAlign.center,
              style: AppTypography.headlineLarge.copyWith(fontSize: 22),
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
