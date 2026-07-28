import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: 'assets/config/.env');
  runApp(
    MultiProvider(providers: [], child: const CapstoneAiApp()),
    /* // Legacy code
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
            final storage = const SecureStorageImpl();
            final repository = ChatRepository(storage: storage);
            return ChatViewModel(chatRepository: repository);
          },
        ),
<<<<<<< HEAD
        ChangeNotifierProvider(
          create: (_) {
            final storage = const SecureStorageImpl();
            final repository = ChatRepository(storage: storage);
            return ChatViewModel(chatRepository: repository);
          },
        ),
=======
>>>>>>> 8ea63f1555afd4c299eaf9ad98ddc4f4664b3ed1
        ChangeNotifierProvider(create: (_) => FontSizeViewModel()),
      ],
      child: const CapstoneAiApp(),
    ),
  );
  */
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
