import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/font_size_option.dart';
import '../../viewmodels/settings/font_size_viewmodel.dart';

class FontSizeView extends StatelessWidget {
  const FontSizeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8D6),
      appBar: AppBar(
        title: const Text(
          '글자 크기 조절',
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
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF4A4A4A),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: const SafeArea(
        child: _FontSizeContent(),
      ),
    );
  }
}

class _FontSizeContent extends StatelessWidget {
  const _FontSizeContent();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<FontSizeViewModel>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PreviewBubble(scale: viewModel.currentScale),
          const SizedBox(height: 24),
          const Text(
            '원하는 크기를 선택해 봐요!',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 12),
          const Expanded(child: _OptionListView()),
        ],
      ),
    );
  }
}

class _PreviewBubble extends StatelessWidget {
  final double scale;

  const _PreviewBubble({required this.scale});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.elasticOut,
      padding: const EdgeInsets.all(24),
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: ContinuousRectangleBorder(
          borderRadius: BorderRadius.circular(48),
        ),
        shadows: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome_rounded, color: Color(0xFFFFB300)),
              SizedBox(width: 8),
              Text(
                '미리보기',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF9E9E9E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '안녕! 글자 크기가\n이렇게 예쁘게 바뀌어 보여요 😊',
            style: TextStyle(
              fontSize: 18 * scale,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF424242),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionListView extends StatelessWidget {
  const _OptionListView();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<FontSizeViewModel>();

    return ListView.separated(
      itemCount: viewModel.options.length,
      separatorBuilder: (context, index) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final option = viewModel.options[index];
        final isSelected = viewModel.selectedIndex == index;

        return _FontSizeOptionCard(
          option: option,
          isSelected: isSelected,
          onTap: () => viewModel.selectSize(index),
        );
      },
    );
  }
}

class _FontSizeOptionCard extends StatefulWidget {
  final FontSizeOption option;
  final bool isSelected;
  final VoidCallback onTap;

  const _FontSizeOptionCard({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_FontSizeOptionCard> createState() => _FontSizeOptionCardState();
}

class _FontSizeOptionCardState extends State<_FontSizeOptionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
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
    final backgroundColor = widget.isSelected
        ? const Color(0xFFFFD1DC) // Pastel pink active
        : Colors.white;

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
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: ShapeDecoration(
            color: backgroundColor,
            shape: ContinuousRectangleBorder(
              borderRadius: BorderRadius.circular(44),
            ),
            shadows: [
              BoxShadow(
                color: widget.isSelected
                    ? const Color(0xFFFFD1DC).withOpacity(0.6)
                    : Colors.black.withOpacity(0.03),
                blurRadius: widget.isSelected ? 14 : 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: widget.isSelected ? Colors.white : const Color(0xFFF5F5F5),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.format_size_rounded,
                  size: 24,
                  color: widget.isSelected
                      ? const Color(0xFFE91E63)
                      : const Color(0xFF757575),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.option.label,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF4A4A4A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.option.description,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF757575),
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.isSelected)
                const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFFE91E63),
                  size: 28,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
