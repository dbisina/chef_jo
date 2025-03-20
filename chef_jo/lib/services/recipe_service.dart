// services/recipe_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/recipe_model.dart';
import '../models/ingredient_model.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class RecipeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Get AI API key from environment variables
  // Add flutter_dotenv package to pubspec.yaml first
  final String _apiKey = dotenv.env['AI_API_KEY'] ?? '';
  final String _apiUrl = dotenv.env['AI_API_URL'] ?? 'https://api.openai.com/v1/chat/completions';
  
  Future<List<Recipe>> generateRecipes({
    required List<Ingredient> ingredients,
    String? cuisine,
    String? mealType,
    String? difficulty,
    List<String>? dietaryRestrictions,
    int limit = 5,
  }) async {
    try {
      // For larger number of ingredients, use AI generation
      if (ingredients.length >= 3) {
        return await generateRecipesWithAI(
          ingredients: ingredients,
          cuisine: cuisine,
          mealType: mealType,
          dietaryRestrictions: dietaryRestrictions,
        );
      }
      
      // Fall back to database for simpler queries
      List<String> ingredientNames = ingredients.map((i) => i.name.toLowerCase()).toList();
      
      // Create a query to find recipes containing the ingredients
      Query query = _firestore.collection('recipes');
      
      // Apply filters for cuisine if specified
      if (cuisine != null && cuisine != 'Any') {
        query = query.where('cuisineTypes', arrayContains: cuisine);
      }
      
      // Apply filter for meal type if specified
      if (mealType != null && mealType != 'Any') {
        query = query.where('mealType', isEqualTo: mealType);
      }
      
      // Apply filter for difficulty if specified
      if (difficulty != null && difficulty != 'Any') {
        query = query.where('difficulty', isEqualTo: difficulty);
      }
      
      // Apply dietary restrictions filter if specified
      if (dietaryRestrictions != null && dietaryRestrictions.isNotEmpty) {
        for (String restriction in dietaryRestrictions) {
          query = query.where('tags', arrayContains: restriction);
        }
      }
      
      // Execute the query
      QuerySnapshot snapshot = await query.limit(limit).get();
      
      List<Recipe> recipes = snapshot.docs
          .map((doc) => Recipe.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
      
      // Calculate match percentage and available ingredients
      List<Recipe> matchedRecipes = [];
      for (var recipe in recipes) {
        int matchedIngredients = 0;
        int availableIngredients = 0;
        List<Ingredient> missingIngredientsList = [];
        
        for (var recipeIngredient in recipe.ingredients) {
          bool found = ingredientNames.contains(recipeIngredient.name.toLowerCase());
          
          if (found) {
            matchedIngredients++;
            availableIngredients++;
          } else {
            missingIngredientsList.add(recipeIngredient);
          }
        }
        
        double matchPercentage = recipe.ingredients.isNotEmpty
            ? (matchedIngredients / recipe.ingredients.length) * 100
            : 0;
        
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
        
        matchedRecipes.add(matchedRecipe);
      }
      
      // Sort by match percentage
      matchedRecipes.sort((a, b) => b.matchPercentage.compareTo(a.matchPercentage));
      
      return matchedRecipes;
    } catch (e) {
      print('Error generating recipes: $e');
      throw Exception('Failed to generate recipes: $e');
    }
  }
  
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
      String prompt = """
      Generate 3 detailed recipes using these ingredients: $ingredientNames.
      
      ${cuisine != null && cuisine != 'Any' ? "The cuisine should be $cuisine." : ""}
      ${mealType != null && mealType != 'Any' ? "It should be suitable for $mealType." : ""}
      ${dietaryRestrictions != null && dietaryRestrictions.isNotEmpty ? "It must meet these dietary restrictions: ${dietaryRestrictions.join(', ')}." : ""}
      
      For each recipe, provide the following in JSON format:
      {
        "title": "Recipe Title",
        "description": "Brief description",
        "ingredients": [
          {"name": "Ingredient Name", "amount": "Amount", "unit": "Unit"}
        ],
        "instructions": ["Step 1 instruction", "Step 2 instruction"],
        "prepTimeMinutes": 15,
        "cookTimeMinutes": 30,
        "servings": 4,
        "nutritionInfo": {
          "calories": 350,
          "protein": 20,
          "carbs": 30,
          "fat": 15
        },
        "tags": ["Tag1", "Tag2"]
      }
      
      Return only the JSON array of recipes without any additional text.
      """;
      
      // 3. Call AI API
      var response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey'
        },
        body: jsonEncode({
          'model': 'gpt-4-turbo',  // Use appropriate model
          'messages': [
            {"role": "system", "content": "You are a professional chef specialized in creating recipes from available ingredients."},
            {"role": "user", "content": prompt}
          ],
          'temperature': 0.7,
          'max_tokens': 2000
        }),
      );
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        String recipeContent = data['choices'][0]['message']['content'];
        
        // Extract JSON from the content (in case API returns text around it)
        recipeContent = recipeContent.trim();
        if (recipeContent.startsWith('```json')) {
          recipeContent = recipeContent.substring(7);
        }
        if (recipeContent.endsWith('```')) {
          recipeContent = recipeContent.substring(0, recipeContent.length - 3);
        }
        recipeContent = recipeContent.trim();
        
        // Parse the JSON response into Recipe objects
        List<dynamic> recipeList = jsonDecode(recipeContent);
        List<Recipe> recipes = [];
        
        for (var recipeJson in recipeList) {
          // Create a unique ID for the recipe
          String recipeId = DateTime.now().millisecondsSinceEpoch.toString() + 
                            '_${recipeJson['title'].toString().toLowerCase().replaceAll(' ', '_')}';
          
          // Process ingredients
          List<Ingredient> recipeIngredients = [];
          for (var ing in recipeJson['ingredients']) {
            recipeIngredients.add(Ingredient(
              id: '${ing['name']}_${DateTime.now().millisecondsSinceEpoch}',
              name: ing['name'],
              amount: ing['amount'],
              unit: ing['unit'],
            ));
          }
          
          // Determine which ingredients are already available
          List<String> availableIngredientNames = ingredients.map((i) => i.name.toLowerCase()).toList();
          List<Ingredient> missingIngredients = [];
          int availableCount = 0;
          
          for (var ing in recipeIngredients) {
            if (availableIngredientNames.contains(ing.name.toLowerCase())) {
              availableCount++;
            } else {
              missingIngredients.add(ing);
            }
          }
          
          // Calculate match percentage
          double matchPercentage = recipeIngredients.isNotEmpty
              ? (availableCount / recipeIngredients.length) * 100
              : 0;
          
          // Create the recipe object
          Recipe recipe = Recipe(
            id: recipeId,
            title: recipeJson['title'],
            description: recipeJson['description'],
            cuisineTypes: cuisine != null && cuisine != 'Any' 
                ? [cuisine] 
                : ['General'],
            ingredients: recipeIngredients,
            instructions: List<String>.from(recipeJson['instructions']),
            prepTimeMinutes: recipeJson['prepTimeMinutes'],
            cookTimeMinutes: recipeJson['cookTimeMinutes'],
            servings: recipeJson['servings'],
            nutritionInfo: Map<String, double>.from(recipeJson['nutritionInfo']),
            matchPercentage: matchPercentage,
            availableIngredients: availableCount,
            missingIngredients: missingIngredients,
            tags: List<String>.from(recipeJson['tags']),
            calories: recipeJson['nutritionInfo']['calories'].toInt(),
          );
          
          recipes.add(recipe);
        }
        
        // Save the generated recipes to Firestore for future reference
        for (var recipe in recipes) {
          await _firestore.collection('ai_generated_recipes').doc(recipe.id).set(recipe.toJson());
        }
        
        return recipes;
      } else {
        print('AI API Error: ${response.statusCode}, ${response.body}');
        throw Exception('Failed to call AI service: ${response.statusCode}');
      }
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