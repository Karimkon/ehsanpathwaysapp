// File generated manually from GoogleService-Info.plist and google-services.json
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        return ios;
    }
  }

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCKbycvaQumUTz9vw6yYaJaqrga85zkzf8',
    appId: '1:246875707165:ios:5c4b7a6a6c52e718bc73f4',
    messagingSenderId: '246875707165',
    projectId: 'ehsanpathways',
    storageBucket: 'ehsanpathways.firebasestorage.app',
    iosBundleId: 'com.ehsanpathways.ehsanPathways',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDUEGHFM852L48Hjn4uADhjw5w_DqYL-TE',
    appId: '1:246875707165:android:5c5476a34cbf0e39bc73f4',
    messagingSenderId: '246875707165',
    projectId: 'ehsanpathways',
    storageBucket: 'ehsanpathways.firebasestorage.app',
  );
}
