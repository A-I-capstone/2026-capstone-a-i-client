import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/settings/source_settings_viewmodel.dart';

class SourceSettingsView extends StatelessWidget {
  const SourceSettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SourceSettingsViewModel(),
      child: const _SourceSettingsViewContent(),
    );
  }
}

class _SourceSettingsViewContent extends StatefulWidget {
  const _SourceSettingsViewContent();

  @override
  State<_SourceSettingsViewContent> createState() => _SourceSettingsViewContentState();
}

class _SourceSettingsViewContentState extends State<_SourceSettingsViewContent> {
  final TextEditingController _inputController = TextEditingController();
  final Color _themeColor = const Color(0xFFFFDAB9); // Peach puff (matches parent menu color)

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  void _addSource(SourceSettingsViewModel viewModel) {
    if (_inputController.text.trim().isNotEmpty) {
      viewModel.addSource(_inputController.text);
      _inputController.clear();
      FocusScope.of(context).unfocus();
    }
  }

  void _showEditDialog(BuildContext context, SourceSettingsViewModel viewModel, int index, String currentSource) {
    final TextEditingController editController = TextEditingController(text: currentSource);

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: ContinuousRectangleBorder(borderRadius: BorderRadius.circular(40)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  '출처 수정',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF4A4A4A)),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: editController,
                  decoration: InputDecoration(
                    hintText: '차단할 URL이나 키워드 입력',
                    hintStyle: const TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: const Color(0xFFF8F9FA),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('취소', style: TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFB74D), // Darker peach/orange for contrast
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: ContinuousRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () {
                          viewModel.editSource(index, editController.text);
                          Navigator.of(context).pop();
                        },
                        child: const Text('저장', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<SourceSettingsViewModel>();

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8), // Soft pastel blue background
      appBar: AppBar(
        title: const Text(
          '출처 설정',
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
        child: Column(
          children: [
            // Input Area
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: ShapeDecoration(
                  color: Colors.white,
                  shape: ContinuousRectangleBorder(
                    borderRadius: BorderRadius.circular(40),
                  ),
                  shadows: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _inputController,
                        decoration: const InputDecoration(
                          hintText: '차단할 출처 (예: youtube.com)',
                          hintStyle: TextStyle(color: Colors.grey, fontSize: 16),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                        onSubmitted: (_) => _addSource(viewModel),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFB74D), // Darker peach/orange for contrast
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.add_rounded, color: Colors.white),
                        onPressed: () => _addSource(viewModel),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // List Area
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                child: Container(
                  decoration: ShapeDecoration(
                    color: Colors.white,
                    shape: ContinuousRectangleBorder(
                      borderRadius: BorderRadius.circular(40),
                    ),
                    shadows: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    itemCount: viewModel.blacklistedSources.length,
                    separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFEEEEEE)),
                    itemBuilder: (context, index) {
                      final source = viewModel.blacklistedSources[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                source,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF4A4A4A),
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit_rounded, color: Colors.grey),
                              onPressed: () => _showEditDialog(context, viewModel, index, source),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_rounded, color: Colors.redAccent),
                              onPressed: () => viewModel.deleteSource(index),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
