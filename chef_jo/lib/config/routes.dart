import 'package:flutter/material.dart';
import '../screens/auth_screen.dart';
import '../screens/home_screen.dart';
import '../screens/recipe_generator_screen.dart';
import '../screens/recipe_list_screen.dart';
import '../screens/recipe_detail_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/pantry_screen.dart';
import '../screens/shopping_list_screen.dart';
import '../screens/cooking_mode_screen.dart';
import '../models/recipe_model.dart';
import '../screens/splash_screen.dart';

class Routes {
  static const String initial = '/';
  static const String auth = '/auth';
  static const String home = '/home';
  static const String recipe = '/recipe';
  static const String recipeGenerator = '/recipe_generator';
  static const String recipes = '/recipes';
  static const String detail = '/detail';
  static const String profile = '/profile';
  static const String pantry = '/pantry';
  static const String shoppingList = '/shopping_list';
  static const String cookingMode = '/cooking_mode';

  static Map<String, WidgetBuilder> get routes => {
    initial: (context) => SplashScreen(),
    auth: (context) => AuthScreen(),
    home: (context) => HomeScreen(),
    recipe: (context) => RecipeGeneratorScreen(),
    recipeGenerator: (context) => RecipeGeneratorScreen(),
    recipes: (context) => RecipeListScreen(),
    detail: (context) => RecipeDetailScreen(recipe: ModalRoute.of(context)?.settings.arguments as Recipe),
    profile: (context) => ProfileScreen(),
    pantry: (context) => PantryScreen(),
    shoppingList: (context) => ShoppingListScreen(),
    cookingMode: (context) => CookingModeScreen(),
  };
}