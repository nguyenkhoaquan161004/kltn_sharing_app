import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Platform      Default FirebaseOptions
/// -----         ---------------------
/// web           `webOptions`
/// android       `androidOptions`
/// iOS           `iosOptions`
/// macOS         `macosOptions`
/// windows       `windowsOptions`
/// linux         `linuxOptions`
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
    apiKey: 'AIzaSyCl02_KmoRWgTLYxrQnPHvw6xQpjgQ642c',
    appId: '1:597386688956:web:8425dd2b1bae5aa630d3b9',
    messagingSenderId: '597386688956',
    projectId: 'shareo-78c33',
    authDomain: 'shareo-78c33.firebaseapp.com',
    storageBucket: 'shareo-78c33.firebasestorage.app',
    measurementId: 'G-L3HDBJDL4H',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAaia0uJUVm4AuE9-Lrdf_HZEQ66hmipl8',
    appId: '1:597386688956:android:cef1f54e2e32b88130d3b9',
    messagingSenderId: '597386688956',
    projectId: 'shareo-78c33',
    storageBucket: 'shareo-78c33.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBlpQmaKUxZ4OfxkcrahnsASLbdE49--x8',
    appId: '1:597386688956:ios:da5a7ecec21415f830d3b9',
    messagingSenderId: '597386688956',
    projectId: 'shareo-78c33',
    storageBucket: 'shareo-78c33.firebasestorage.app',
    iosBundleId: 'com.example.kltnSharingApp',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBlpQmaKUxZ4OfxkcrahnsASLbdE49--x8',
    appId: '1:597386688956:ios:da5a7ecec21415f830d3b9',
    messagingSenderId: '597386688956',
    projectId: 'shareo-78c33',
    storageBucket: 'shareo-78c33.firebasestorage.app',
    iosBundleId: 'com.example.kltnSharingApp',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyCl02_KmoRWgTLYxrQnPHvw6xQpjgQ642c',
    appId: '1:597386688956:web:42e9b45e7d00370f30d3b9',
    messagingSenderId: '597386688956',
    projectId: 'shareo-78c33',
    authDomain: 'shareo-78c33.firebaseapp.com',
    storageBucket: 'shareo-78c33.firebasestorage.app',
    measurementId: 'G-V11TZB85C1',
  );
}
