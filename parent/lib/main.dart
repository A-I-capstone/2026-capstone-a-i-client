import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared/shared.dart';

import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'viewmodels/onboarding_viewmodel.dart';
import 'views/child_list_view.dart';
import 'views/pairing_view.dart';
import 'views/terms_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await FirebaseAppCheck.instance.activate(
    providerAndroid: AndroidDebugProvider(),
    providerWeb: WebDebugProvider(),
  );

  // 1. Auth via shared BaseAuthProvider (FirebaseAuthProvider)
  final BaseAuthProvider authProvider = FirebaseAuthProvider();
  final String parentUid = await authProvider.signInAnonymously();

  // 2. Onboarding ViewModel Init (SharedPreferences)
  final onboardingViewModel = ParentOnboardingViewModel();
  await onboardingViewModel.init();

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

