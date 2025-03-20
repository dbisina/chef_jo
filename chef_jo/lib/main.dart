// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'config/theme.dart';
import 'config/routes.dart';
import 'config/firebase_config.dart';
import 'config/env.dart';
import 'services/auth_service.dart';
import 'services/storage_service.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'screens/splash_screen.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables first
  await EnvConfig.initialize();
  
  // Initialize Firebase with proper configuration
  await FirebaseConfig.initializeFirebase();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        Provider(create: (_) => StorageService()),
      ],
      child: ChefJoApp(),
    ),
  );
}

class ChefJoApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chef Jo',
      theme: ChefJoTheme.lightTheme,
      darkTheme: ChefJoTheme.darkTheme,
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      initialRoute: Routes.initial,
      routes: Routes.routes,
      // Start with splash screen
      home: SplashScreen(),
    );
  }
}