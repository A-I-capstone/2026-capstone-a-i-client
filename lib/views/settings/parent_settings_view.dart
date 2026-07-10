import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/settings/parent_settings_viewmodel.dart';
import 'screen_time_settings_view.dart';
import 'chatbot_safety_settings_view.dart';
import 'source_settings_view.dart';
import 'password_change_view.dart';

class ParentSettingsView extends StatelessWidget {
  const ParentSettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ParentSettingsViewModel(),
      child: const _ParentSettingsViewContent(),
    );
  }
}

class _ParentSettingsViewContent extends StatelessWidget {
  const _ParentSettingsViewContent();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ParentSettingsViewModel>();
    
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8), // Soft pastel blue background
      appBar: AppBar(
        title: const Text(
          '부모용 설정',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: Color(0xFF4A4A4A),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF4A4A4A)),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ParentSettingsCard(
                title: '출처 설정',
                icon: Icons.source_rounded,
                color: const Color(0xFFFFDAB9), // Peach puff
                onTap: () {
                  viewModel.onSourceSettingsClicked();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const SourceSettingsView(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              _ParentSettingsCard(
                title: '스크린 타임 설정',
                icon: Icons.timer_rounded,
                color: const Color(0xFFE2F0CB), // Pastel green
                onTap: () {
                  viewModel.onScreenTimeSettingsClicked();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const ScreenTimeSettingsView(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              _ParentSettingsCard(
                title: '부모 리포트 설정',
                icon: Icons.insert_chart_rounded,
                color: const Color(0xFFFFC3A0), // Pastel orange
                onTap: viewModel.onParentReportSettingsClicked,
              ),
              const SizedBox(height: 16),
              _ParentSettingsCard(
                title: '챗봇 세이프티 설정',
                icon: Icons.security_rounded,
                color: const Color(0xFFD4A5A5), // Pastel dusty rose
                onTap: () {
                  viewModel.onChatbotSafetySettingsClicked();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const ChatbotSafetySettingsView(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              _ParentSettingsCard(
                title: '비밀번호 변경',
                icon: Icons.password_rounded,
                color: const Color(0xFFB5EAD7), // Pastel mint
                onTap: () {
                  viewModel.onPasswordChangeClicked();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const PasswordChangeView(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _ParentSettingsCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ParentSettingsCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  State<_ParentSettingsCard> createState() => _ParentSettingsCardState();
}

class _ParentSettingsCardState extends State<_ParentSettingsCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          decoration: ShapeDecoration(
            color: widget.color,
            shape: ContinuousRectangleBorder(
              borderRadius: BorderRadius.circular(50), // Organic continuous curve
            ),
            shadows: [
              BoxShadow(
                color: widget.color.withOpacity(0.4),
                blurRadius: 10,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: Colors.white70,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  widget.icon,
                  size: 28,
                  color: const Color(0xFF4A4A4A),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF4A4A4A),
                  ),
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: Color(0xFF4A4A4A),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
