import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Tệp cấu hình kết nối Firebase tự động hỗ trợ đa nền tảng (Android & Web)
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        return android;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBuAXgzZ2Q8wbe4jXsAGvfjjRk5ccd9_ns',
    appId: '1:119011257696:web:6814b787593c683b944205',
    messagingSenderId: '119011257696',
    projectId: 'prm323-lab3',
    authDomain: 'prm323-lab3.firebaseapp.com',
    storageBucket: 'prm323-lab3.firebasestorage.app',
    measurementId: 'G-PRM323LAB3',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBuAXgzZ2Q8wbe4jXsAGvfjjRk5ccd9_ns',
    appId: '1:119011257696:android:92bd205a8de7e496944205',
    messagingSenderId: '119011257696',
    projectId: 'prm323-lab3',
    storageBucket: 'prm323-lab3.firebasestorage.app',
  );
}

