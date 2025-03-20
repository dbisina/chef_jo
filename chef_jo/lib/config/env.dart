// lib/config/env.dart

import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Environment configuration handling class
class EnvConfig {
  /// Initialize environment variables
  static Future<void> initialize() async {
    await dotenv.load(fileName: ".env");
  }

  /// Get an environment variable
  static String get(String key, {String defaultValue = ''}) {
    return dotenv.env[key] ?? defaultValue;
  }

  // API keys
  static String get openAiApiKey => get('OPENAI_API_KEY');
  static String get openAiApiUrl => get('OPENAI_API_URL', defaultValue: 'https://api.openai.com/v1/chat/completions');
  
  // Firebase config
  static String get firebaseApiKey => get('FIREBASE_API_KEY');
  static String get firebaseAuthDomain => get('FIREBASE_AUTH_DOMAIN');
  static String get firebaseProjectId => get('FIREBASE_PROJECT_ID');
  static String get firebaseStorageBucket => get('FIREBASE_STORAGE_BUCKET');
  static String get firebaseMessagingSenderId => get('FIREBASE_MESSAGING_SENDER_ID');
  static String get firebaseAppId => get('FIREBASE_APP_ID');
  static String get firebaseMeasurementId => get('FIREBASE_MEASUREMENT_ID');
}