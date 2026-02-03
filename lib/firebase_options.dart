import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return const FirebaseOptions(
        apiKey: 'AIzaSyDgc-FQW_npFb6xu0glkj1UtSjogdbEqVA',
        appId: '1:460260151216:web:0be4c86a7d27cf647a5075',
        messagingSenderId: '460260151216',
        projectId: 'my-qna-hub',
        authDomain: 'my-qna-hub.firebaseapp.com',
        storageBucket: 'my-qna-hub.firebasestorage.app',
        measurementId: 'G-95S1MGK2WT',
      );
    }
    if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      return const FirebaseOptions(
        apiKey: 'AIzaSyCWT8MkhH8iT4pFPCuIkVxfugv21LPL3gE',
        appId: '1:460260151216:ios:50d04fd86e755bc27a5075',
        messagingSenderId: '460260151216',
        projectId: 'my-qna-hub',
        storageBucket: 'my-qna-hub.firebasestorage.app',
        iosBundleId: 'com.quahub.android',
      );
    }
    return const FirebaseOptions(
      apiKey: 'AIzaSyAnNko4fopcLBt74ZdXTJFuQ4M39DE_MdQ',
      appId: '1:460260151216:android:799db55700f043d97a5075',
      messagingSenderId: '460260151216',
      projectId: 'my-qna-hub',
      storageBucket: 'my-qna-hub.firebasestorage.app',
      androidClientId:
          '460260151216-tr73b26rdbvq8jsnlkui7nt899og22m2.apps.googleusercontent.com',
    );
  }
}
