import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'viewmodels/chat_view_model.dart';
import 'views/chat/chat_view.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ChatViewModel()),
      ],
      child: const CapstoneAiApp(),
    ),
  );
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
      home: const ChatView(),
    );
  }
}
