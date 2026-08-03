import 'package:flutter/material.dart';

/// Parent App Main Home View.
///
/// Features:
/// - AppBar with title
/// - Hamburger menu icon button on the top right
/// - Empty body placeholder (detailed implementation to follow later)
class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F4F2),
      appBar: AppBar(
        title: const Text('부모 대시보드'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.menu),
            tooltip: '메뉴',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('햄버거 메뉴 준비 중입니다.'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
        ],
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
