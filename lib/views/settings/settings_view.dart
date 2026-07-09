import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/settings/settings_viewmodel.dart';
import 'chatbot_tone_view.dart';
import 'font_size_view.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SettingsViewModel(),
      child: const _SettingsViewContent(),
    );
  }
}

class _SettingsViewContent extends StatelessWidget {
  const _SettingsViewContent();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<SettingsViewModel>();
    
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8D6), // Light pastel yellow background
      appBar: AppBar(
        title: const Text(
          '설정',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: Color(0xFF4A4A4A),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SettingsCard(
                title: '글자 크기',
                icon: Icons.format_size_rounded,
                color: const Color(0xFFFFD1DC), // Pastel pink
                onTap: () {
                  viewModel.onTextSizeClicked();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const FontSizeView(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),
              _SettingsCard(
                title: '기억 관리',
                icon: Icons.auto_awesome_rounded,
                color: const Color(0xFFB5EAD7), // Pastel mint green
                onTap: viewModel.onMemoryClicked,
              ),
              const SizedBox(height: 20),
              _SettingsCard(
                title: '챗봇 수정',
                icon: Icons.face_retouching_natural_rounded,
                color: const Color(0xFFC7CEEA), // Pastel periwinkle
                onTap: () {
                  viewModel.onChatbotClicked();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ChatbotToneView(),
                    ),
                  );
                },
              ),
              
              const Spacer(),
              
              _ParentSettingsButton(
                onTap: viewModel.onParentSettingsClicked,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _SettingsCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  State<_SettingsCard> createState() => _SettingsCardState();
}

class _SettingsCardState extends State<_SettingsCard> with SingleTickerProviderStateMixin {
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
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          decoration: ShapeDecoration(
            color: widget.color,
            shape: ContinuousRectangleBorder(
              borderRadius: BorderRadius.circular(60), // Organic continuous curve
            ),
            shadows: [
              BoxShadow(
                color: widget.color.withOpacity(0.5),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Colors.white60,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  widget.icon,
                  size: 32,
                  color: const Color(0xFF4A4A4A),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF4A4A4A),
                  ),
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: Color(0xFF4A4A4A),
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ParentSettingsButton extends StatefulWidget {
  final VoidCallback onTap;

  const _ParentSettingsButton({required this.onTap});

  @override
  State<_ParentSettingsButton> createState() => _ParentSettingsButtonState();
}

class _ParentSettingsButtonState extends State<_ParentSettingsButton> with SingleTickerProviderStateMixin {
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
          padding: const EdgeInsets.symmetric(vertical: 24),
          decoration: ShapeDecoration(
            color: const Color(0xFFEBE8D5), // Yellowish gray background
            shape: ContinuousRectangleBorder(
              borderRadius: BorderRadius.circular(40), // Organic continuous curve
            ),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.admin_panel_settings_rounded,
                color: Color(0xFF64748B),
                size: 28,
              ),
              SizedBox(width: 12),
              Text(
                '부모용 설정으로 이동',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
