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
        return macos;
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // Placeholder configurations - replace with actual Firebase project values when available
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAgUhHU8wSJgO5MVNy95tMT07NEjzMOfz0',
    appId: '1:448618578101:web:0b650370bb29e29cac3efc',
    messagingSenderId: '448618578101',
    projectId: 'taskflow-voice-app',
    authDomain: 'taskflow-voice-app.firebaseapp.com',
    storageBucket: 'taskflow-voice-app.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAgUhHU8wSJgO5MVNy95tMT07NEjzMOfz0',
    appId: '1:448618578101:android:0b650370bb29e29cac3efc',
    messagingSenderId: '448618578101',
    projectId: 'taskflow-voice-app',
    storageBucket: 'taskflow-voice-app.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAgUhHU8wSJgO5MVNy95tMT07NEjzMOfz0',
    appId: '1:448618578101:ios:0b650370bb29e29cac3efc',
    messagingSenderId: '448618578101',
    projectId: 'taskflow-voice-app',
    storageBucket: 'taskflow-voice-app.appspot.com',
    iosBundleId: 'com.taskflow.voiceTodoApp',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyAgUhHU8wSJgO5MVNy95tMT07NEjzMOfz0',
    appId: '1:448618578101:ios:0b650370bb29e29cac3efc',
    messagingSenderId: '448618578101',
    projectId: 'taskflow-voice-app',
    storageBucket: 'taskflow-voice-app.appspot.com',
    iosBundleId: 'com.taskflow.voiceTodoApp',
  );
} 