import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/settings/chatbot_safety_settings_viewmodel.dart';

class ChatbotSafetySettingsView extends StatelessWidget {
  const ChatbotSafetySettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ChatbotSafetySettingsViewModel(),
      child: const _ChatbotSafetySettingsViewContent(),
    );
  }
}

class _ChatbotSafetySettingsViewContent extends StatelessWidget {
  const _ChatbotSafetySettingsViewContent();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ChatbotSafetySettingsViewModel>();

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8), // Soft pastel blue background
      appBar: AppBar(
        title: const Text(
          '챗봇 세이프티 설정',
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
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
            decoration: ShapeDecoration(
              color: Colors.white,
              shape: ContinuousRectangleBorder(
                borderRadius: BorderRadius.circular(50), // Organic continuous curve
              ),
              shadows: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: List.generate(viewModel.categories.length, (index) {
                final category = viewModel.categories[index];
                
                final colors = [
                  const Color(0xFFF06292), // Darker Pastel Pink (Pink 300)
                  const Color(0xFFFFA726), // Darker Pastel Orange (Orange 400)
                  const Color(0xFF66BB6A), // Darker Pastel Green (Green 400)
                  const Color(0xFF42A5F5), // Darker Pastel Blue (Blue 400)
                ];
                final color = colors[index % colors.length];

                return Padding(
                  padding: EdgeInsets.only(bottom: index == viewModel.categories.length - 1 ? 0 : 24.0),
                  child: _SafetyCategoryItem(
                    category: category,
                    color: color,
                    onChanged: (value) => viewModel.updateLevel(index, value),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _SafetyCategoryItem extends StatelessWidget {
  final SafetyCategory category;
  final Color color;
  final ValueChanged<double> onChanged;

  const _SafetyCategoryItem({
    required this.category,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Text(
                    category.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF4A4A4A),
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () => _showDescriptionDialog(context, category, color),
                    child: const Icon(
                      Icons.info_outline_rounded,
                      size: 20,
                      color: Color(0xFF9E9E9E), // Grey info icon
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    category.level.label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: color, 
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () => _showLevelDescriptionDialog(context),
                  child: const Icon(
                    Icons.info_outline_rounded,
                    size: 20,
                    color: Color(0xFF9E9E9E), // Grey info icon
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: color,
            inactiveTrackColor: color.withOpacity(0.2),
            thumbColor: color,
            overlayColor: color.withOpacity(0.15),
            valueIndicatorColor: color,
            trackHeight: 8.0,
            tickMarkShape: const RoundSliderTickMarkShape(tickMarkRadius: 4),
            activeTickMarkColor: Colors.white.withOpacity(0.6),
            inactiveTickMarkColor: color.withOpacity(0.5),
            valueIndicatorTextStyle: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          child: Slider(
            value: category.level.index.toDouble(),
            min: 0,
            max: 3,
            divisions: 3,
            label: category.level.label,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  void _showDescriptionDialog(BuildContext context, SafetyCategory category, Color color) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: ContinuousRectangleBorder(borderRadius: BorderRadius.circular(50)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.info_rounded, color: color, size: 40),
                ),
                const SizedBox(height: 20),
                Text(
                  category.title,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF4A4A4A)),
                ),
                const SizedBox(height: 16),
                Text(
                  category.description,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, height: 1.6, fontWeight: FontWeight.w500, color: Colors.grey),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: ContinuousRectangleBorder(borderRadius: BorderRadius.circular(40)),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('확인', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showLevelDescriptionDialog(BuildContext context) {
    const greyColor = Color(0xFF757575);
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: ContinuousRectangleBorder(borderRadius: BorderRadius.circular(50)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.shield_rounded, color: greyColor, size: 32),
                    SizedBox(width: 8),
                    Text(
                      '차단 수준 안내',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF4A4A4A)),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildLevelDescriptionRow('차단 안함', '유해 콘텐츠일 가능성과 관계없이 모든 콘텐츠를 차단하지 않습니다.', greyColor),
                _buildLevelDescriptionRow('소수 차단', '유해할 가능성이 매우 높은 콘텐츠만 선별하여 차단합니다.', greyColor),
                _buildLevelDescriptionRow('일부 차단', '유해할 가능성이 중간 이상인 콘텐츠들을 폭넓게 차단합니다.', greyColor),
                _buildLevelDescriptionRow('대부분 차단', '유해할 가능성이 조금이라도 있다면 가장 엄격하게 차단합니다.', greyColor),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: greyColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: ContinuousRectangleBorder(borderRadius: BorderRadius.circular(40)),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('확인', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLevelDescriptionRow(String title, String description, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 14, height: 1.5, color: Color(0xFF4A4A4A)),
          children: [
            TextSpan(
              text: '$title : ',
              style: TextStyle(fontWeight: FontWeight.w800, color: color),
            ),
            TextSpan(
              text: description,
              style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
