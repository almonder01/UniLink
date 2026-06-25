import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError('Unsupported platform');
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDMaye_YqWAYN_iAdO4a9k_dZJoWsu8h_8',
    appId: '1:781427660711:web:244591e4f8ae7c14390882',
    messagingSenderId: '781427660711',
    projectId: 'unilink-91ac5',
    authDomain: 'unilink-91ac5.firebaseapp.com',
    storageBucket: 'unilink-91ac5.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDMaye_YqWAYN_iAdO4a9k_dZJoWsu8h_8',
    appId: '1:781427660711:android:fc042848d4e92b87390882',
    messagingSenderId: '781427660711',
    projectId: 'unilink-91ac5',
    storageBucket: 'unilink-91ac5.firebasestorage.app',
  );
}
