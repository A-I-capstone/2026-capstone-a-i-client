import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'viewmodels/chat_view_model.dart';
import 'viewmodels/settings/font_size_viewmodel.dart';
import 'views/chat/chat_view.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ChatViewModel()),
        ChangeNotifierProvider(create: (_) => FontSizeViewModel()),
      ],
      child: const CapstoneAiApp(),
    ),
  );
}

class CapstoneAiApp extends StatelessWidget {
  const CapstoneAiApp({super.key});

  @override
  Widget build(BuildContext context) {
    final fontSizeVM = context.watch<FontSizeViewModel>();

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
          data: mediaQuery.copyWith(
            textScaler: TextScaler.linear(fontSizeVM.currentScale),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const ChatView(),
    );
  }
}
