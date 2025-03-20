// models/recipe_model.dart
import 'ingredient_model.dart';
/// A class representing a recipe.
/// It contains various properties such as title, description, ingredients,
/// instructions, and nutritional information.
/// The class also includes methods for JSON serialization and deserialization.
/// The [Recipe] class is used to represent a recipe in the application.
/// 
class Recipe {
  final String id;
  final String title;
  final String description;
  final List<String> cuisineTypes;
  final List<Ingredient> ingredients;
  final List<String> instructions;
  final String? imageUrl;
  final int prepTimeMinutes;
  final int cookTimeMinutes;
  final int servings;
  final Map<String, double> nutritionInfo;
  final double matchPercentage;

  Recipe({
    required this.id,
    required this.title,
    required this.description,
    required this.cuisineTypes,
    required this.ingredients,
    required this.instructions,
    this.imageUrl,
    required this.prepTimeMinutes,
    required this.cookTimeMinutes,
    required this.servings,
    required this.nutritionInfo,
    this.matchPercentage = 0.0,
  });

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      cuisineTypes: List<String>.from(json['cuisineTypes'] ?? []),
      ingredients: (json['ingredients'] as List?)
          ?.map((i) => Ingredient.fromJson(i))
          .toList() ?? [],
      instructions: List<String>.from(json['instructions'] ?? []),
      imageUrl: json['imageUrl'],
      prepTimeMinutes: json['prepTimeMinutes'] ?? 0,
      cookTimeMinutes: json['cookTimeMinutes'] ?? 0,
      servings: json['servings'] ?? 2,
      nutritionInfo: Map<String, double>.from(json['nutritionInfo'] ?? {}),
      matchPercentage: json['matchPercentage']?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'cuisineTypes': cuisineTypes,
      'ingredients': ingredients.map((i) => i.toJson()).toList(),
      'instructions': instructions,
      'imageUrl': imageUrl,
      'prepTimeMinutes': prepTimeMinutes,
      'cookTimeMinutes': cookTimeMinutes,
      'servings': servings,
      'nutritionInfo': nutritionInfo,
      'matchPercentage': matchPercentage,
    };
  }
}