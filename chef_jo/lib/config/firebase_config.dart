// lib/config/firebase_config.dart
import 'package:firebase_core/firebase_core.dart';

class FirebaseConfig {
  static final FirebaseOptions firebaseOptions = FirebaseOptions(
    apiKey: "YOUR_API_KEY",
    authDomain: "chef-jo-app.firebaseapp.com",
    projectId: "chef-jo-app",
    storageBucket: "chef-jo-app.appspot.com",
    messagingSenderId: "YOUR_MESSAGING_SENDER_ID",
    appId: "YOUR_APP_ID",
    measurementId: "YOUR_MEASUREMENT_ID"
  );

  static Future<void> initializeFirebase() async {
    await Firebase.initializeApp(
      options: firebaseOptions,
    );
  }
}