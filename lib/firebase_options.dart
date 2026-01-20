import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
        return windows;
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
    apiKey: 'AIzaSyDgc-FQW_npFb6xu0glkj1UtSjogdbEqVA',
    appId: '1:460260151216:web:ec65ef24a9ae4da37a5075',
    messagingSenderId: '460260151216',
    projectId: 'my-qna-hub',
    authDomain: 'my-qna-hub.firebaseapp.com',
    storageBucket: 'my-qna-hub.firebasestorage.app',
    measurementId: 'G-V6P4HCQ7TK',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAnNko4fopcLBt74ZdXTJFuQ4M39DE_MdQ',
    appId: '1:460260151216:android:799db55700f043d97a5075',
    messagingSenderId: '460260151216',
    projectId: 'my-qna-hub',
    storageBucket: 'my-qna-hub.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCWT8MkhH8iT4pFPCuIkVxfugv21LPL3gE',
    appId: '1:460260151216:ios:50d04fd86e755bc27a5075',
    messagingSenderId: '460260151216',
    projectId: 'my-qna-hub',
    storageBucket: 'my-qna-hub.firebasestorage.app',
    iosClientId: '460260151216-cthm329tamjpq25s2pg87er2dlsf4bj3.apps.googleusercontent.com',
    iosBundleId: 'com.quahub.android',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCWT8MkhH8iT4pFPCuIkVxfugv21LPL3gE',
    appId: '1:460260151216:ios:50d04fd86e755bc27a5075',
    messagingSenderId: '460260151216',
    projectId: 'my-qna-hub',
    storageBucket: 'my-qna-hub.firebasestorage.app',
    iosClientId: '460260151216-cthm329tamjpq25s2pg87er2dlsf4bj3.apps.googleusercontent.com',
    iosBundleId: 'com.quahub.android',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDgc-FQW_npFb6xu0glkj1UtSjogdbEqVA',
    appId: '1:460260151216:web:0be4c86a7d27cf647a5075',
    messagingSenderId: '460260151216',
    projectId: 'my-qna-hub',
    authDomain: 'my-qna-hub.firebaseapp.com',
    storageBucket: 'my-qna-hub.firebasestorage.app',
    measurementId: 'G-95S1MGK2WT',
  );

}