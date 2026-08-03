import 'package:flutter/material.dart';

/// Terms of Service Agreement View for Parent App.
class TermsView extends StatefulWidget {
  final VoidCallback onAccepted;

  const TermsView({super.key, required this.onAccepted});

  @override
  State<TermsView> createState() => _TermsViewState();
}

class _TermsViewState extends State<TermsView> {
  bool _isChecked = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F4F2),
      appBar: AppBar(
        title: const Text('서비스 이용약관'),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '부모용 서비스 이용약관',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF3A3936),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFADAAA4)),
                  ),
                  child: const SingleChildScrollView(
                    child: Text(
                      '[이용약관 내용 플레이스홀더]\n\n'
                      '본 약관은 AI 캡스톤 부모용 서비스 이용에 관한 제반 사항을 규정합니다.\n\n'
                      '1. 개인정보 수집 및 이용 목적\n'
                      '자녀의 서비스 사용 현황 및 대화 안전 모니터링 기능 제공\n\n'
                      '2. 익명 인증 안내\n'
                      '본 앱은 익명 인증을 사용하며, 페어링 코드를 통해 자녀 앱과 안전하게 연동됩니다.\n\n'
                      '3. 약관 변경 관련\n'
                      '약관 변경 시 사전 공지 후 적용됩니다.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF3A3936),
                        height: 1.6,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Checkbox(
                    value: _isChecked,
                    activeColor: const Color(0xFF0440FE),
                    onChanged: (val) {
                      setState(() {
                        _isChecked = val ?? false;
                      });
                    },
                  ),
                  const Expanded(
                    child: Text(
                      '위 이용약관 내용을 확인하였으며 이에 동의합니다.',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF3A3936),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isChecked ? widget.onAccepted : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isChecked
                      ? const Color(0xFF3A3936)
                      : const Color(0xFFADAAA4),
                  disabledBackgroundColor: const Color(0xFFADAAA4),
                ),
                child: const Text('동의하고 시작하기'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
