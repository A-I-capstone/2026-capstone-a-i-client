import 'package:flutter/material.dart';

/// Parent App Main Home View.
///
/// Features:
/// - AppBar with centered title
/// - Settings icon button on the top left
/// - Empty body placeholder (detailed implementation to follow later)
class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F4F2),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.settings),
          tooltip: '설정',
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('설정 메뉴 준비 중입니다.'),
                duration: Duration(seconds: 1),
              ),
            );
          },
        ),
        title: const Text('부모 대시보드'),
        centerTitle: true,
      ),
      body: const Center(
        child: Text(
          '부모 화면 준비 중',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Color(0xFF667595),
          ),
        ),
      ),
    );
  }
}
