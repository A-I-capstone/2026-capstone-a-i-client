import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/settings/chatbot_tone_viewmodel.dart';

class ChatbotToneView extends StatelessWidget {
  const ChatbotToneView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ChatbotToneViewModel(),
      child: Scaffold(
        backgroundColor: const Color(0xFFFFF8D6),
        appBar: AppBar(
          title: const Text(
            '챗봇 수정',
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
          child: _ChatbotToneContent(),
        ),
      ),
    );
  }
}

class _ChatbotToneContent extends StatelessWidget {
  const _ChatbotToneContent();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ChatbotToneViewModel>();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '챗봇의 성격을 조절할 수 있습니다.',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 24),
          _ToneSliderCard(
            title: '어휘',
            icon: Icons.menu_book_rounded,
            leftLabel: '쉬운말',
            rightLabel: '어려운 말',
            value: viewModel.vocabularyLevel,
            cardColor: const Color(0xFFFFE5EC),
            accentColor: const Color(0xFFF06292),
            onChanged: viewModel.updateVocabularyLevel,
          ),
          const SizedBox(height: 20),
          _ToneSliderCard(
            title: '말투',
            icon: Icons.sentiment_satisfied_alt_rounded,
            leftLabel: '친근함',
            rightLabel: '선생님',
            value: viewModel.toneLevel,
            cardColor: const Color(0xFFE8F5E9),
            accentColor: const Color(0xFF66BB6A),
            onChanged: viewModel.updateToneLevel,
          ),
          const SizedBox(height: 20),
          _ToneSliderCard(
            title: '방향',
            icon: Icons.explore_rounded,
            leftLabel: '공감',
            rightLabel: '지식',
            value: viewModel.focusLevel,
            cardColor: const Color(0xFFE3F2FD),
            accentColor: const Color(0xFF42A5F5),
            onChanged: viewModel.updateFocusLevel,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _ToneSliderCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final String leftLabel;
  final String rightLabel;
  final int value;
  final Color cardColor;
  final Color accentColor;
  final ValueChanged<double> onChanged;

  const _ToneSliderCard({
    required this.title,
    required this.icon,
    required this.leftLabel,
    required this.rightLabel,
    required this.value,
    required this.cardColor,
    required this.accentColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: ShapeDecoration(
        color: cardColor,
        shape: ContinuousRectangleBorder(
          borderRadius: BorderRadius.circular(48),
        ),
        shadows: [
          BoxShadow(
            color: cardColor.withOpacity(0.6),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(
            title: title,
            icon: icon,
            accentColor: accentColor,
          ),
          const SizedBox(height: 20),
          _SliderSection(
            value: value,
            accentColor: accentColor,
            leftLabel: leftLabel,
            rightLabel: rightLabel,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _CardHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color accentColor;

  const _CardHeader({
    required this.title,
    required this.icon,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: accentColor, size: 24),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF4A4A4A),
            ),
          ),
        ),
      ],
    );
  }
}

class _SliderSection extends StatelessWidget {
  final int value;
  final Color accentColor;
  final String leftLabel;
  final String rightLabel;
  final ValueChanged<double> onChanged;

  const _SliderSection({
    required this.value,
    required this.accentColor,
    required this.leftLabel,
    required this.rightLabel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: accentColor,
            inactiveTrackColor: Colors.white70,
            thumbColor: accentColor,
            overlayColor: accentColor.withOpacity(0.2),
            trackHeight: 8.0,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 14.0),
          ),
          child: Slider(
            value: value.toDouble(),
            min: 1.0,
            max: 5.0,
            divisions: 4,
            onChanged: onChanged,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                leftLabel,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF64748B),
                ),
              ),
              Text(
                rightLabel,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
