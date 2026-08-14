import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared/shared.dart';

import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'viewmodels/onboarding_viewmodel.dart';
import 'views/child_list_view.dart';
import 'views/pairing_view.dart';
import 'views/terms_view.dart';

late String modelName;
late String reportSystemPrompt;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  /*
  TODO: uncomment later
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

  await remoteConfig.setDefaults(const {'model_name': 'gemini-3.6-flash'});

  try {
    await remoteConfig.fetchAndActivate();
  } catch (e) {
    debugPrint('Error fetching Remote Config: $e');
  }

  modelName = remoteConfig.getString('model_name');
  reportSystemPrompt = remoteConfig.getString('report_system_prompt');

  debugPrint('Remote Config model_name: $modelName');
  debugPrint('Remote Config report_system_prompt set');

  remoteConfig.onConfigUpdated.listen((event) async {
    await remoteConfig.activate();
    modelName = remoteConfig.getString('model_name');
    reportSystemPrompt = remoteConfig.getString('report_system_prompt');
  });

  // 1. Auth via shared BaseAuthProvider (FirebaseAuthProvider)
  final BaseAuthProvider authProvider = FirebaseAuthProvider();
  final String parentUid = await authProvider.signInAnonymously();
  debugPrint('[Parent Main] 익명 로그인 완료: parentUid=$parentUid');

  // 2. Onboarding ViewModel Init (SharedPreferences)
  final onboardingViewModel = ParentOnboardingViewModel();
  await onboardingViewModel.init();
  debugPrint(
    '[Parent Main] 온보딩 상태 확인: termsAccepted=${onboardingViewModel.termsAccepted}, pairingComplete=${onboardingViewModel.pairingComplete}',
  );

  runApp(
    MultiProvider(
      providers: [
        Provider<BaseAuthProvider>.value(value: authProvider),
        ChangeNotifierProvider<ParentOnboardingViewModel>.value(
          value: onboardingViewModel,
        ),
      ],
      child: ParentApp(parentUid: parentUid),
    ),
  );
}

class ParentApp extends StatelessWidget {
  final String parentUid;

  const ParentApp({super.key, required this.parentUid});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '부모용 앱',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: Consumer<ParentOnboardingViewModel>(
        builder: (context, onboarding, child) {
          if (onboarding.isLoading) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(color: Color(0xFF3A3936)),
              ),
            );
          }

          // Step 1: Terms Agreement
          if (!onboarding.termsAccepted) {
            return TermsView(
              onAccepted: () {
                onboarding.acceptTerms();
              },
            );
          }

          // Step 2: Pairing Screen (cannot pop/skip until paired)
          if (!onboarding.pairingComplete) {
            return ParentPairingView(
              parentUid: parentUid,
              isFirstSetup: true,
              onPairingComplete: () {
                onboarding.completePairing();
              },
            );
          }

          // Step 3: Child Selection List View
          return ChildListView(parentUid: parentUid);
        },
      ),
    );
  }
}
