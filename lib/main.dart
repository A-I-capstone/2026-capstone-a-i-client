import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'viewmodels/chat_viewmodel.dart';
import 'views/chat_view.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'firebase_options.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'services/chat/base_chat_repository.dart';
import 'services/chat/firestore_chat_repository.dart';
import 'services/llm/gemini_provider.dart';
import 'services/llm/provider_manager.dart';

late final String _modelName;
late final String _systemPrompt;
late final String _titleModelName;
late final String _titleSystemPrompt;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FirebaseAppCheck.instance.activate(
    providerAndroid:
        AndroidDebugProvider(), // use AndroidPlayIntegrityProvider() for production
  );

  final remoteConfig = FirebaseRemoteConfig.instance;
  await remoteConfig.setConfigSettings(
    RemoteConfigSettings(
      fetchTimeout: const Duration(seconds: 10),
      minimumFetchInterval: const Duration(seconds: 10),
    ),
  );

  await remoteConfig.setDefaults(const {
    "model_name": "gemini-3.6-flash",
    "title_model_name": "gemini-3.6-flash",
    "title_system_prompt": "You are a title generator. Generate a concise, child-friendly title (max 5 words) summarizing the user's message. Output only the title, without quotes.",
  });

  try {
    await remoteConfig.fetchAndActivate();
  } catch (e) {
    // TODO: child-friendly한 오류 화면 만들기
    debugPrint('Error fetching Remote Config: $e');
  }

  _modelName = remoteConfig.getString('model_name');
  _systemPrompt = remoteConfig.getString('system_prompt');
  _titleModelName = remoteConfig.getString('title_model_name');
  _titleSystemPrompt = remoteConfig.getString('title_system_prompt');

  // system_prompt must never be empty — the AI cannot operate safely without it.
  // Detailed error UI will be added in a future phase; fail fast for now.
  if (_systemPrompt.isEmpty) {
    throw Exception(
      '[Config Error] system_prompt is empty. '
      'Please set a valid system prompt in Firebase Remote Config.',
    );
  }

  debugPrint('Remote Config model_name: $_modelName');
  debugPrint('Remote Config system_prompt set');

  remoteConfig.onConfigUpdated.listen((event) async {
    await remoteConfig.activate();
    _modelName = remoteConfig.getString("model_name");
    _systemPrompt = remoteConfig.getString("system_prompt");
    _titleModelName = remoteConfig.getString("title_model_name");
    _titleSystemPrompt = remoteConfig.getString("title_system_prompt");
    debugPrint('Remote Config updated model_name: $_modelName');
    debugPrint('Remote Config system_prompt updated');
    debugPrint('Remote Config title configs updated');
  });

  final providerManager = ProviderManager(
    provider: GeminiProvider(
      modelName: _modelName,
      systemPrompt: _systemPrompt,
    ),
    titleProvider: GeminiProvider(
      modelName: _titleModelName,
      systemPrompt: _titleSystemPrompt,
    ),
  );

  // BaseChatRepository typed — swap to a different backend by changing this
  // single line without touching ViewModel or View code.
  final BaseChatRepository repository = FirestoreChatRepository();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ChatViewModel(
            providerManager: providerManager,
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
      theme: AppTheme.lightTheme,
      home: const ChatView(),
    );
  }
}
