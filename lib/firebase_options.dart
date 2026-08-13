// File generated from Firebase console configs for project wr-pmis.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyASYZ5rujyV6zJWJAYwieDlNMNFy7kZDs8',
    appId: '1:841774449823:android:2e46e99d9a9232108dceaa',
    messagingSenderId: '841774449823',
    projectId: 'wr-pmis',
    storageBucket: 'wr-pmis.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDsCDObnVEugfNfML8Xrbp6_UkhHwDOJP4',
    appId: '1:841774449823:ios:4d2751b30b16679c8dceaa',
    messagingSenderId: '841774449823',
    projectId: 'wr-pmis',
    storageBucket: 'wr-pmis.firebasestorage.app',
    iosBundleId: 'com.synergiz.wrpmismobile',
  );
}
