import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/storage/secure_storage_impl.dart';
import 'repositories/chat_repository.dart';
import 'viewmodels/chat/chat_viewmodel.dart';
import 'viewmodels/settings/font_size_viewmodel.dart';
import 'views/chat/chat_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: 'assets/config/.env');
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) {
            final storage = const SecureStorageImpl();
            final repository = ChatRepository(storage: storage);
            return ChatViewModel(chatRepository: repository);
          },
        ),
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
