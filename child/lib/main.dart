import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared/shared.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme/app_theme.dart';
import 'viewmodels/settings_viewmodel.dart';
import 'viewmodels/user_viewmodel.dart';
import 'views/child_pairing_view.dart';
import 'views/home_view.dart';
import 'views/nickname_setup_view.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'services/user/user_repository.dart';

const _kPairingComplete = 'pairing_complete';

late String modelName;
late String systemPrompt;
late String titleModelName;
late String titleSystemPrompt;
late String reportSystemPrompt;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  /*
  await FirebaseAppCheck.instance.activate(
    providerAndroid: AndroidDebugProvider(),
    providerWeb: WebDebugProvider(),
  );
  */

  final remoteConfig = FirebaseRemoteConfig.instance;
  await remoteConfig.setConfigSettings(
    RemoteConfigSettings(
      fetchTimeout: const Duration(seconds: 10),
      minimumFetchInterval: const Duration(seconds: 10),
    ),
  );

  await remoteConfig.setDefaults(const {
    'model_name': 'gemini-3.6-flash',
    'title_model_name': 'gemini-3.6-flash',
  });

  try {
    await remoteConfig.fetchAndActivate();
  } catch (e) {
    debugPrint('Error fetching Remote Config: $e');
  }

  modelName = remoteConfig.getString('model_name');
  systemPrompt = remoteConfig.getString('system_prompt');
  titleModelName = remoteConfig.getString('title_model_name');
  titleSystemPrompt = remoteConfig.getString('title_system_prompt');
  reportSystemPrompt = remoteConfig.getString('report_system_prompt');

  if (systemPrompt.isEmpty) {
    throw Exception(
      '[Config Error] system_prompt is empty. '
      'Please set a valid system prompt in Firebase Remote Config.',
    );
  }

  debugPrint('Remote Config model_name: $modelName');
  debugPrint('Remote Config title_model_name: $titleModelName');
  debugPrint('Remote Config system_prompt set');
  debugPrint('Remote Config title_system_prompt set');
  debugPrint('Remote Config report_system_prompt set');

  remoteConfig.onConfigUpdated.listen((event) async {
    await remoteConfig.activate();
    modelName = remoteConfig.getString('model_name');
    systemPrompt = remoteConfig.getString('system_prompt');
    titleModelName = remoteConfig.getString('title_model_name');
    titleSystemPrompt = remoteConfig.getString('title_system_prompt');
    reportSystemPrompt = remoteConfig.getString('report_system_prompt');
  });

  // Auth
  final BaseAuthProvider authProvider = FirebaseAuthProvider();
  final String userId = await authProvider.signInAnonymously();

  // Check pairing status
  final prefs = await SharedPreferences.getInstance();
  final isPaired = prefs.getBool(_kPairingComplete) ?? false;

  final userRepository = UserRepository();
  final userViewModel = UserViewModel(repository: userRepository);
  await userViewModel.initialize(userId);

  final settingsViewModel = SettingsViewModel();
  await settingsViewModel.init();

  runApp(
    MultiProvider(
      providers: [
        Provider<BaseAuthProvider>.value(value: authProvider),
        ChangeNotifierProvider<UserViewModel>.value(value: userViewModel),
        ChangeNotifierProvider<SettingsViewModel>.value(
          value: settingsViewModel,
        ),
      ],
      child: CapstoneAiApp(userId: userId, isPaired: isPaired, prefs: prefs),
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
          ? const HomeView()
          : _PairingGate(userId: userId, prefs: prefs),
    );
  }
}

/// Gate handling ChildPairingView -> NicknameSetupView -> HomeView flow.
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
          MaterialPageRoute(
            builder: (_) => NicknameSetupView(
              onCompleted: () {
                navigator.pushReplacement(
                  MaterialPageRoute(builder: (_) => const HomeView()),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
