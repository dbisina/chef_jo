import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'config/theme.dart';
import 'config/routes.dart';
import 'config/firebase_config.dart';
import 'services/auth_service.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseConfig.initializeFirebase();
  
  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthService(),
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
      home: Consumer<AuthService>(
        builder: (context, authService, _) {
          return authService.currentUser != null
              ? HomeScreen()
              : AuthScreen();
        },
      ),
    );
  }
}