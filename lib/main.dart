import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: 'assets/config/.env');

  // BaseChatRepository typed — swap to a different backend by changing this
  // single line without touching ViewModel or View code.
  final BaseChatRepository repository = FirestoreChatRepository();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ChatViewModel(
            repository: repository,
          ),
        ),
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
