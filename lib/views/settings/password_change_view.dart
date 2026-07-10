import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/settings/password_change_viewmodel.dart';

class PasswordChangeView extends StatelessWidget {
  const PasswordChangeView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PasswordChangeViewModel(),
      child: const _PasswordChangeViewContent(),
    );
  }
}

class _PasswordChangeViewContent extends StatefulWidget {
  const _PasswordChangeViewContent();

  @override
  State<_PasswordChangeViewContent> createState() => _PasswordChangeViewContentState();
}

class _PasswordChangeViewContentState extends State<_PasswordChangeViewContent> {
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<PasswordChangeViewModel>();

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        title: const Text(
          '비밀번호 변경',
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
        child: Stack(
          children: [
            // Hidden TextField that stays mounted across steps to keep keyboard active
            SizedBox(
              width: 1,
              height: 1,
              child: Opacity(
                opacity: 0,
                child: TextField(
                  controller: _passwordController,
                  focusNode: _focusNode,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  autofocus: true,
                  onChanged: (val) {
                    setState(() {});
                    if (val.length == 4) {
                      _handleAutoSubmit(viewModel);
                    }
                  },
                ),
              ),
            ),
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.05, 0),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
                      child: child,
                    ),
                  );
                },
                child: _buildStepContent(viewModel),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleAutoSubmit(PasswordChangeViewModel viewModel) {
    if (viewModel.step == PasswordChangeStep.enterNew) {
      Future.delayed(const Duration(milliseconds: 150), () {
        viewModel.submitFirstPassword(_passwordController.text);
        if (viewModel.step == PasswordChangeStep.confirmNew) {
          _passwordController.clear();
          setState(() {});
        }
      });
    } else if (viewModel.step == PasswordChangeStep.confirmNew) {
      Future.delayed(const Duration(milliseconds: 150), () {
        FocusScope.of(context).unfocus();
        final isSuccess = viewModel.submitConfirmPassword(_passwordController.text);
        if (isSuccess) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('비밀번호가 성공적으로 변경되었습니다!')),
          );
        } else {
          _passwordController.clear();
          setState(() {});
          _focusNode.requestFocus();
        }
      });
    }
  }

  Widget _buildStepContent(PasswordChangeViewModel viewModel) {
    switch (viewModel.step) {
      case PasswordChangeStep.enterNew:
        return _buildVisualStep(
          key: const ValueKey('step_1'),
          title: '새로운 비밀번호를 입력해주세요.',
          errorMessage: viewModel.errorMessage,
        );
      case PasswordChangeStep.confirmNew:
        return _buildVisualStep(
          key: const ValueKey('step_2'),
          title: '비밀번호를 한 번 더 입력해주세요.',
          errorMessage: viewModel.errorMessage,
        );
    }
  }

  Widget _buildPinIndicator(int length) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (index) {
        final isFilled = index < length;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 12),
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isFilled ? const Color(0xFF4A4A4A) : Colors.transparent,
            border: Border.all(
              color: const Color(0xFF4A4A4A),
              width: 2.5,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildVisualStep({
    required Key key,
    required String title,
    required String errorMessage,
  }) {
    return GestureDetector(
      onTap: () => _focusNode.requestFocus(),
      behavior: HitTestBehavior.opaque,
      child: Container(
        key: key,
        constraints: const BoxConstraints(minHeight: 300),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 32),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF4A4A4A)),
            ),
            const SizedBox(height: 64),
            _buildPinIndicator(_passwordController.text.length),
            if (errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 48.0),
                child: Text(
                  errorMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFFE57373), fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
