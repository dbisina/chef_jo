import 'package:flutter/material.dart';
import '../screens/auth_screen.dart';
import '../screens/home_screen.dart';
import '../screens/recipe_screen.dart';
import '../screens/recipe_detail_screen.dart';
import '../screens/profile_screen.dart';

class Routes {
  static const String initial = '/';
  static const String auth = '/auth';
  static const String home = '/home';
  static const String recipe = '/recipe';
  static const String detail = '/detail';
  static const String profile = '/profile';

  static Map<String, WidgetBuilder> get routes => {
    auth: (context) => AuthScreen(),
    home: (context) => HomeScreen(),
    recipe: (context) => RecipeGeneratorScreen(),
    detail: (context) => RecipeDetailScreen(recipe: String,),
    profile: (context) => ProfileScreen(),
  };
}