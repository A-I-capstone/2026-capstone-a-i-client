import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(MultiProvider(providers: [], child: const CapstoneAiApp()));
}

class CapstoneAiApp extends StatelessWidget {
  const CapstoneAiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Capstone AI Client',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Roboto', // Custom modern font if available
        useMaterial3: true,
        primarySwatch: Colors.blue,
      ),
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        return MediaQuery(
          data: mediaQuery.copyWith(),
          child: child ?? const SizedBox.shrink(),
        );
      },
      //home: const ChatView(),
    );
  }
}
