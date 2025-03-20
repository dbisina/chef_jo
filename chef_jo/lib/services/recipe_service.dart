// services/recipe_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/recipe_model.dart';

class RecipeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // This URL would be your Firebase Cloud Function or other API endpoint
  final String apiUrl = 'YOUR_RECIPE_API_ENDPOINT';
  
  Future<List<Recipe>> generateRecipes(
    List<String> ingredients, 
    List<String> dietaryPreferences,
    List<String> allergies,
  ) async {
    try {
      // For demo purposes, we'll use a simulated API call
      // In production, replace with actual API call to ML service
      
      // Simulate API processing time
      await Future.delayed(Duration(seconds: 2));
      
      // Get recipes from Firestore (simulating ML model results)
      QuerySnapshot snapshot = await _firestore
          .collection('recipes')
          .limit(5)
          .get();
          
      List<Recipe> recipes = snapshot.docs
          .map((doc) => Recipe.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
          
      // Calculate match percentage (in real app, this would come from ML model)
      for (var i = 0; i < recipes.length; i++) {
        // Simple matching algorithm for demonstration
        int matchedIngredients = 0;
        for (var ingredient in recipes[i].ingredients) {
          if (ingredients.contains(ingredient.name.toLowerCase())) {
            matchedIngredients++;
          }
        }
        
        double matchPercentage = matchedIngredients / recipes[i].ingredients.length * 100;
        
        // Create a new recipe with updated match percentage
        recipes[i] = Recipe(
          id: recipes[i].id,
          title: recipes[i].title,
          description: recipes[i].description,
          cuisineTypes: recipes[i].cuisineTypes,
          ingredients: recipes[i].ingredients,
          instructions: recipes[i].instructions,
          imageUrl: recipes[i].imageUrl,
          prepTimeMinutes: recipes[i].prepTimeMinutes,
          cookTimeMinutes: recipes[i].cookTimeMinutes,
          servings: recipes[i].servings,
          nutritionInfo: recipes[i].nutritionInfo,
          matchPercentage: matchPercentage,
        );
      }
      
      // Sort by match percentage
      recipes.sort((a, b) => b.matchPercentage.compareTo(a.matchPercentage));
      
      return recipes;
    } catch (e) {
      print('Error generating recipes: $e');
      throw Exception('Failed to generate recipes');
    }
  }
  
  Future<List<Recipe>> getSavedRecipes(List<String> recipeIds) async {
    try {
      List<Recipe> recipes = [];
      
      for (String id in recipeIds) {
        DocumentSnapshot doc = await _firestore
            .collection('recipes')
            .doc(id)
            .get();
            
        if (doc.exists) {
          recipes.add(Recipe.fromJson(doc.data() as Map<String, dynamic>));
        }
      }
      
      return recipes;
    } catch (e) {
      print('Error getting saved recipes: $e');
      throw Exception('Failed to retrieve saved recipes');
    }
  }
  
  Future<void> saveRecipe(String userId, String recipeId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .update({
            'savedRecipes': FieldValue.arrayUnion([recipeId])
          });
    } catch (e) {
      print('Error saving recipe: $e');
      throw Exception('Failed to save recipe');
    }
  }
}