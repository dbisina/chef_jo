// lib/config/firebase_config.dart
import 'package:firebase_core/firebase_core.dart';
import 'env.dart';

class FirebaseConfig {
  static FirebaseOptions get firebaseOptions => FirebaseOptions(
    apiKey: EnvConfig.firebaseApiKey,
    authDomain: EnvConfig.firebaseAuthDomain,
    projectId: EnvConfig.firebaseProjectId,
    storageBucket: EnvConfig.firebaseStorageBucket,
    messagingSenderId: EnvConfig.firebaseMessagingSenderId,
    appId: EnvConfig.firebaseAppId,
    measurementId: EnvConfig.firebaseMeasurementId,
  );

  static Future<void> initializeFirebase() async {
    await Firebase.initializeApp(
      options: firebaseOptions,
    );
  }
}