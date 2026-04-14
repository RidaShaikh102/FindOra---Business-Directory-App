import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
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

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAL6k_GrCHtC6bn8l3pqfxBkp2QJ7WG_PE',
    appId: '1:670309274911:web:e6d73bdf30ffae3d0e0c2a',
    messagingSenderId: '670309274911',
    projectId: 'findora-40f21',
    authDomain: 'findora-40f21.firebaseapp.com',
    storageBucket: 'findora-40f21.firebasestorage.app',
    measurementId: 'G-K1KJ1REBFD',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBhYNp9KKoxJukubigeiXXEnTLH1PbHbEE',
    appId: '1:670309274911:android:6d040f8d767ca9830e0c2a',
    messagingSenderId: '670309274911',
    projectId: 'findora-40f21',
    storageBucket: 'findora-40f21.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBYJ9VSoHZdJP5JCQabFM9KjVu15Gkz-ZU',
    appId: '1:670309274911:ios:20a4e74d0b28e6a80e0c2a',
    messagingSenderId: '670309274911',
    projectId: 'findora-40f21',
    storageBucket: 'findora-40f21.firebasestorage.app',
    androidClientId:
        '670309274911-85k8fg3vm8e55s4f5rj6fh5cnvrp8idr.apps.googleusercontent.com',
    iosClientId:
        '670309274911-jgoa30330aj7gcosnliq2ckmvpt751ri.apps.googleusercontent.com',
    iosBundleId: 'com.example.findora',
  );
}
