// services/recipe_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/recipe_model.dart';
import '../models/ingredient_model.dart';

class RecipeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // This URL would be your Firebase Cloud Function or other API endpoint
  // For AI integration, you would typically use a cloud function or external AI service
  final String apiUrl = 'YOUR_RECIPE_API_ENDPOINT';
  
  Future<List<Recipe>> generateRecipes({
    required List<Ingredient> ingredients,
    String? cuisine,
    String? mealType,
    String? difficulty,
    List<String>? dietaryRestrictions,
    int limit = 5,
  }) async {
    try {
      // For AI integration, you would call your AI service here
      // The following is a placeholder implementation that simulates AI generation
      
      // 1. Prepare the input for AI
      final ingredientNames = ingredients.map((i) => i.name).toList();
      
      // 2. Call AI service (simulated for now)
      // Simulate API processing time
      await Future.delayed(Duration(seconds: 2));
      
      // 3. Get recipes from Firestore (simulating ML model results)
      QuerySnapshot snapshot = await _firestore
          .collection('recipes')
          .limit(limit)
          .get();
          
      List<Recipe> recipes = snapshot.docs
          .map((doc) => Recipe.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
          
      // 4. Calculate match percentage (in real app, this would come from ML model)
      List<Recipe> matchedRecipes = [];
      for (var recipe in recipes) {
        // Simple matching algorithm for demonstration
        int matchedIngredients = 0;
        int availableIngredients = 0;
        List<Ingredient> missingIngredientsList = [];
        
        for (var recipeIngredient in recipe.ingredients) {
          bool found = false;
          for (var userIngredient in ingredients) {
            if (recipeIngredient.name.toLowerCase() == userIngredient.name.toLowerCase()) {
              found = true;
              matchedIngredients++;
              break;
            }
          }
          
          if (found) {
            availableIngredients++;
          } else {
            missingIngredientsList.add(recipeIngredient);
          }
        }
        
        double matchPercentage = recipe.ingredients.isNotEmpty
            ? (matchedIngredients / recipe.ingredients.length) * 100
            : 0;
        
        // Create a new recipe with updated match percentage
        Recipe matchedRecipe = Recipe(
          id: recipe.id,
          title: recipe.title,
          description: recipe.description,
          cuisineTypes: recipe.cuisineTypes,
          ingredients: recipe.ingredients,
          instructions: recipe.instructions,
          imageUrl: recipe.imageUrl,
          prepTimeMinutes: recipe.prepTimeMinutes,
          cookTimeMinutes: recipe.cookTimeMinutes,
          servings: recipe.servings,
          nutritionInfo: recipe.nutritionInfo,
          matchPercentage: matchPercentage,
          availableIngredients: availableIngredients,
          missingIngredients: missingIngredientsList,
          tags: recipe.tags,
          calories: recipe.calories,
        );
        
        // Filter by cuisine if specified
        if (cuisine != null && cuisine != 'Any' && 
            !recipe.cuisineTypes.contains(cuisine)) {
          continue;
        }
        
        // Apply dietary restrictions filter if specified
        if (dietaryRestrictions != null && dietaryRestrictions.isNotEmpty) {
          bool meetsRestrictions = true;
          for (var restriction in dietaryRestrictions) {
            // This is a simplified check - in a real app, you'd have more sophisticated filtering
            if (!recipe.tags.contains(restriction)) {
              meetsRestrictions = false;
              break;
            }
          }
          
          if (!meetsRestrictions) continue;
        }
        
        matchedRecipes.add(matchedRecipe);
      }
      
      // 5. Sort by match percentage
      matchedRecipes.sort((a, b) => b.matchPercentage.compareTo(a.matchPercentage));
      
      return matchedRecipes;
    } catch (e) {
      print('Error generating recipes: $e');
      throw Exception('Failed to generate recipes: $e');
    }
  }
  
  // Future implementation for AI integration
  Future<List<Recipe>> generateRecipesWithAI({
    required List<Ingredient> ingredients,
    String? cuisine,
    String? mealType, 
    List<String>? dietaryRestrictions,
  }) async {
    try {
      // 1. Format the ingredients for the AI
      final ingredientNames = ingredients.map((i) => i.name).join(', ');
      
      // 2. Build prompt for AI
      String prompt = "Generate a recipe using these ingredients: $ingredientNames";
      if (cuisine != null && cuisine != 'Any') {
        prompt += ", in $cuisine cuisine";
      }
      if (mealType != null && mealType != 'Any') {
        prompt += ", for $mealType";
      }
      if (dietaryRestrictions != null && dietaryRestrictions.isNotEmpty) {
        prompt += ", with these dietary restrictions: ${dietaryRestrictions.join(', ')}";
      }
      
      // 3. Call AI API - Uncomment and use your preferred AI service
      /*
      final response = await http.post(
        Uri.parse(apiUrl),
        body: jsonEncode({
          'prompt': prompt,
          'max_tokens': 1000,
        }),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer YOUR_API_KEY'
        },
      );
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        // Parse the AI response into Recipe objects
        // This will depend on the format of your AI's response
        // ...
      } else {
        throw Exception('Failed to call AI service: ${response.statusCode}');
      }
      */
      
      // For now, return sample recipes
      return generateRecipes(
        ingredients: ingredients, 
        cuisine: cuisine,
        mealType: mealType,
        dietaryRestrictions: dietaryRestrictions,
      );
      
    } catch (e) {
      print('Error generating recipes with AI: $e');
      throw Exception('Failed to generate recipes with AI: $e');
    }
  }
  
  Future<List<Recipe>> getSavedRecipes() async {
    try {
      // Simple implementation that returns all recipes
      // In a real app, you'd filter by user's saved recipes
      QuerySnapshot snapshot = await _firestore
          .collection('recipes')
          .limit(10)
          .get();
          
      return snapshot.docs
          .map((doc) => Recipe.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting saved recipes: $e');
      throw Exception('Failed to retrieve saved recipes');
    }
  }
  
  Future<List<Recipe>> getFavoriteRecipes() async {
    try {
      // In a real app, you'd get user's favorite recipes from their profile
      QuerySnapshot snapshot = await _firestore
          .collection('recipes')
          .where('isFavorite', isEqualTo: true)
          .limit(10)
          .get();
          
      return snapshot.docs
          .map((doc) => Recipe.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting favorite recipes: $e');
      throw Exception('Failed to retrieve favorite recipes');
    }
  }
  
  Future<List<Recipe>> getRecentRecipes() async {
    try {
      // In a real app, you'd get user's recently viewed recipes
      QuerySnapshot snapshot = await _firestore
          .collection('recipes')
          .orderBy('createdAt', descending: true)
          .limit(10)
          .get();
          
      return snapshot.docs
          .map((doc) => Recipe.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting recent recipes: $e');
      throw Exception('Failed to retrieve recent recipes');
    }
  }
}