// File generated for parent app.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for parent app.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for ios.',
        );
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos.',
        );
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBSk2k-Y7NcYb0KK-wIU2Wq4Dmm95yAUsQ',
    appId: '1:103993825834:web:5d26096f1b83fe4074c153',
    messagingSenderId: '103993825834',
    projectId: 'capstone-a-ai',
    authDomain: 'capstone-a-ai.firebaseapp.com',
    storageBucket: 'capstone-a-ai.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDFW07s4-hYrV99ah8XcPRT93n6ehMdvww',
    appId: '1:103993825834:android:0d0d3c7de9ffb14774c153',
    messagingSenderId: '103993825834',
    projectId: 'capstone-a-ai',
    storageBucket: 'capstone-a-ai.firebasestorage.app',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBSk2k-Y7NcYb0KK-wIU2Wq4Dmm95yAUsQ',
    appId: '1:103993825834:web:cc3fd48925a7861074c153',
    messagingSenderId: '103993825834',
    projectId: 'capstone-a-ai',
    authDomain: 'capstone-a-ai.firebaseapp.com',
    storageBucket: 'capstone-a-ai.firebasestorage.app',
  );
}
