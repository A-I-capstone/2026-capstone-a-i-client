import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared/shared.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme/app_theme.dart';
import 'viewmodels/chat_viewmodel.dart';
import 'viewmodels/profile_viewmodel.dart';
import 'viewmodels/settings_viewmodel.dart';
import 'views/chat_view.dart';
import 'views/child_pairing_view.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'firebase_options.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'services/chat/base_chat_repository.dart';
import 'services/chat/firestore_chat_repository.dart';
import 'services/profile/base_profile_repository.dart';
import 'services/profile/firestore_profile_repository.dart';
import 'services/llm/gemini_provider.dart';
import 'services/llm/provider_manager.dart';

// ---------------------------------------------------------------------------
// SharedPreferences key for pairing completion flag
// ---------------------------------------------------------------------------
const _kPairingComplete = 'pairing_complete';

late final String _modelName;
late final String _systemPrompt;
late final String _titleModelName;
late final String _titleSystemPrompt;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FirebaseAppCheck.instance.activate(
    providerAndroid: AndroidDebugProvider(),
    providerWeb: WebDebugProvider(),
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
    "title_model_name": "gemini-3.5-flash-lite",
  });

  try {
    await remoteConfig.fetchAndActivate();
  } catch (e) {
    debugPrint('Error fetching Remote Config: $e');
  }

  _modelName = remoteConfig.getString('model_name');
  _systemPrompt = remoteConfig.getString('system_prompt');
  _titleModelName = remoteConfig.getString('title_model_name');
  _titleSystemPrompt = remoteConfig.getString('title_system_prompt');

  // system_prompt must never be empty — the AI cannot operate safely without it.
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
  });

  // ---------------------------------------------------------------------------
  // Auth — shared BaseAuthProvider (FirebaseAuthProvider)
  // ---------------------------------------------------------------------------
  final BaseAuthProvider authProvider = FirebaseAuthProvider();
  final String userId = await authProvider.signInAnonymously();

  // ---------------------------------------------------------------------------
  // Check pairing status
  // ---------------------------------------------------------------------------
  final prefs = await SharedPreferences.getInstance();
  final isPaired = prefs.getBool(_kPairingComplete) ?? false;

  // ---------------------------------------------------------------------------
  // LLM and repositories
  // ---------------------------------------------------------------------------
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
  final BaseChatRepository chatRepository = FirestoreChatRepository();

  // BaseProfileRepository typed — same swap-friendly pattern.
  final BaseProfileRepository profileRepository = FirestoreProfileRepository();

  // ProfileViewModel is created first so it can be passed into ChatViewModel.
  final profileViewModel = ProfileViewModel(repository: profileRepository);

  // SettingsViewModel is initialised before runApp so that persisted settings
  // (font, text size, TTS voice) are ready before the first frame is drawn.
  final settingsViewModel = SettingsViewModel();
  await settingsViewModel.init();

  runApp(
    MultiProvider(
      providers: [
        Provider<BaseAuthProvider>.value(value: authProvider),
        ChangeNotifierProvider<ProfileViewModel>.value(value: profileViewModel),
        ChangeNotifierProvider<SettingsViewModel>.value(
          value: settingsViewModel,
        ),
        ChangeNotifierProvider(
          create: (_) => ChatViewModel(
            providerManager: providerManager,
            repository: chatRepository,
            profileViewModel: profileViewModel,
            authProvider: authProvider,
          ),
        ),
      ],
      child: CapstoneAiApp(
        userId: userId,
        isPaired: isPaired,
        prefs: prefs,
      ),
    ),
  );
}

class CapstoneAiApp extends StatelessWidget {
  final String userId;
  final bool isPaired;
  final SharedPreferences prefs;

  const CapstoneAiApp({
    super.key,
    required this.userId,
    required this.isPaired,
    required this.prefs,
  });

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsViewModel>();

    return MaterialApp(
      title: 'Capstone AI Client',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.buildTheme(
        fontFamily: settings.fontFamily,
        isBold: settings.isBold,
      ),
      // Override textScaler for all descendants so the font-size slider
      // affects every text widget in the app without individual wiring.
      builder: (context, child) {
        final scale = settings.textSize / SettingsViewModel.defaultTextSize;
        return MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: isPaired
          ? const ChatView()
          : _PairingGate(userId: userId, prefs: prefs),
    );
  }
}

/// Wraps [ChildPairingView] and pushes [ChatView] once pairing succeeds.
class _PairingGate extends StatefulWidget {
  final String userId;
  final SharedPreferences prefs;
  const _PairingGate({required this.userId, required this.prefs});

  @override
  State<_PairingGate> createState() => _PairingGateState();
}

class _PairingGateState extends State<_PairingGate> {
  @override
  Widget build(BuildContext context) {
    return ChildPairingView(
      childUid: widget.userId,
      onPaired: (familyId) async {
        final navigator = Navigator.of(context);
        await widget.prefs.setBool(_kPairingComplete, true);
        if (!mounted) return;
        navigator.pushReplacement(
          MaterialPageRoute(builder: (_) => const ChatView()),
        );
      },
    );
  }
}
