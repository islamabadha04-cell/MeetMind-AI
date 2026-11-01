// File generated for MeetMind AI — Phase 6B.1 Firebase Foundation
// Target Firebase Project: meetmind-ai-74519
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows.',
        );
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
    apiKey: 'AIzaSyAVogcGOhsv2UgEAOEsCICkfMRrfD8dd_4',
    appId: '1:790778332182:web:b4a2c8ebbd8720a61f6137',
    messagingSenderId: '790778332182',
    projectId: 'meetmind-ai-74519',
    authDomain: 'meetmind-ai-74519.firebaseapp.com',
    storageBucket: 'meetmind-ai-74519.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBua8C8xhkywrS6EHbxy9BBuaS5qFCmCa0',
    appId: '1:790778332182:android:211a1b9fc7c53e7d1f6137',
    messagingSenderId: '790778332182',
    projectId: 'meetmind-ai-74519',
    storageBucket: 'meetmind-ai-74519.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyA9YT5FyfHvx4Nio8NqU94UitUcYuW4DOc',
    appId: '1:790778332182:ios:137f95ef50fc1efc1f6137',
    messagingSenderId: '790778332182',
    projectId: 'meetmind-ai-74519',
    storageBucket: 'meetmind-ai-74519.firebasestorage.app',
    iosBundleId: 'com.meetmind.ai.mobile',
  );
}

