// lib/services/recipe_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/recipe_model.dart';
import '../models/ingredient_model.dart';
import '../config/env.dart';

class RecipeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Cache for AI generated recipes to reduce API calls
  static final Map<String, List<Recipe>> _recipeCache = {};
  static const Duration _cacheDuration = Duration(hours: 1);
  static final Map<String, DateTime> _cacheTimestamps = {};
  
  // Get API Key from environment
  String get _apiKey => EnvConfig.openAiApiKey;
  String get _apiUrl => EnvConfig.openAiApiUrl;
  
  /// Generates recipes based on provided ingredients and filters
  Future<List<Recipe>> generateRecipes({
    required List<Ingredient> ingredients,
    String? cuisine,
    String? mealType,
    String? difficulty,
    List<String>? dietaryRestrictions,
    int limit = 5,
  }) async {
    try {
      // Generate cache key from parameters
      final String cacheKey = _generateCacheKey(
        ingredients, cuisine, mealType, difficulty, dietaryRestrictions
      );
      
      // Check cache first
      if (_isValidCacheEntry(cacheKey)) {
        return _recipeCache[cacheKey]!;
      }
      
      // For larger number of ingredients, use AI generation
      if (ingredients.length >= 3) {
        final recipes = await generateRecipesWithAI(
          ingredients: ingredients,
          cuisine: cuisine,
          mealType: mealType,
          dietaryRestrictions: dietaryRestrictions,
        );
        
        // Cache results
        _cacheRecipes(cacheKey, recipes);
        return recipes;
      }
      
      // Fall back to database for simpler queries
      List<String> ingredientNames = ingredients.map((i) => i.name.toLowerCase()).toList();
      
      // Create a query to find recipes containing the ingredients
      Query query = _firestore.collection('recipes');
      
      // Apply filters
      if (cuisine != null && cuisine != 'Any') {
        query = query.where('cuisineTypes', arrayContains: cuisine);
      }
      
      if (mealType != null && mealType != 'Any') {
        query = query.where('mealType', isEqualTo: mealType);
      }
      
      if (difficulty != null && difficulty != 'Any') {
        query = query.where('difficulty', isEqualTo: difficulty);
      }
      
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
      List<Recipe> matchedRecipes = _calculateRecipeMatches(recipes, ingredientNames);
      
      // Cache results
      _cacheRecipes(cacheKey, matchedRecipes);
      
      return matchedRecipes;
    } catch (e) {
      print('Error generating recipes: $e');
      throw Exception('Failed to generate recipes: $e');
    }
  }
  
  /// Calculates recipe matches based on available ingredients
  List<Recipe> _calculateRecipeMatches(List<Recipe> recipes, List<String> ingredientNames) {
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
  }
  
  /// Generate recipes using AI (OpenAI API)
  Future<List<Recipe>> generateRecipesWithAI({
    required List<Ingredient> ingredients,
    String? cuisine,
    String? mealType, 
    List<String>? dietaryRestrictions,
  }) async {
    try {
      // If API key is not set, throw an error
      if (_apiKey.isEmpty) {
        throw Exception('OpenAI API key not configured. Please set up your environment.');
      }
      
      // Format the ingredients
      final ingredientNames = ingredients.map((i) => i.name).join(', ');
      
      // Build an enhanced prompt for better recipe generation
      String prompt = _buildAiPrompt(
        ingredients: ingredientNames,
        cuisine: cuisine,
        mealType: mealType,
        dietaryRestrictions: dietaryRestrictions,
      );
      
      // Call AI API with retry mechanism
      var response = await _callOpenAiApiWithRetry(prompt);
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        String recipeContent = data['choices'][0]['message']['content'];
        
        // Extract JSON from the content
        recipeContent = _extractJsonFromResponse(recipeContent);
        
        // Parse the JSON response into Recipe objects
        List<dynamic> recipeList;
        try {
          recipeList = jsonDecode(recipeContent);
        } catch (e) {
          print('Error parsing JSON: $e');
          print('Response content: $recipeContent');
          throw Exception('Failed to parse AI response as JSON');
        }
        
        List<Recipe> recipes = [];
        
        for (var recipeJson in recipeList) {
          try {
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
            
            // Parse nutrition info
            Map<String, double> nutritionInfo = {};
            if (recipeJson['nutritionInfo'] != null) {
              recipeJson['nutritionInfo'].forEach((key, value) {
                nutritionInfo[key] = value is int ? value.toDouble() : value;
              });
            }
            
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
              prepTimeMinutes: recipeJson['prepTimeMinutes'] ?? 15,
              cookTimeMinutes: recipeJson['cookTimeMinutes'] ?? 30,
              servings: recipeJson['servings'] ?? 4,
              nutritionInfo: nutritionInfo,
              matchPercentage: matchPercentage,
              availableIngredients: availableCount,
              missingIngredients: missingIngredients,
              tags: List<String>.from(recipeJson['tags'] ?? []),
              calories: recipeJson['nutritionInfo']?['calories']?.toInt() ?? 0,
            );
            
            recipes.add(recipe);
          } catch (e) {
            print('Error processing recipe: $e');
            // Continue with next recipe
          }
        }
        
        // Save the generated recipes to Firestore for future reference
        _saveGeneratedRecipesToFirestore(recipes);
        
        return recipes;
      } else {
        print('AI API Error: ${response.statusCode}, ${response.body}');
        throw Exception('Failed to call AI service: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error generating recipes with AI: $e');
      throw Exception('Failed to generate recipes with AI: $e');
    }
  }

  /// Clean and extract JSON from AI response
  String _extractJsonFromResponse(String content) {
    content = content.trim();
    
    // Handle markdown code blocks
    if (content.startsWith('```json')) {
      content = content.substring(7);
    } else if (content.startsWith('```')) {
      content = content.substring(3);
    }
    
    if (content.endsWith('```')) {
      content = content.substring(0, content.length - 3);
    }
    
    content = content.trim();
    
    // If content is not a JSON array, try to find JSON array in the content
    if (!content.startsWith('[') && content.contains('[') && content.contains(']')) {
      final start = content.indexOf('[');
      final end = content.lastIndexOf(']') + 1;
      if (start < end) {
        content = content.substring(start, end);
      }
    }
    
    return content;
  }
  
  /// Build optimized AI prompt for recipe generation
  String _buildAiPrompt({
    required String ingredients,
    String? cuisine,
    String? mealType,
    List<String>? dietaryRestrictions,
  }) {
    return """
    Act as a professional chef. Generate 3 detailed, creative recipes using these ingredients: $ingredients.
    
    ${cuisine != null && cuisine != 'Any' ? "The cuisine should be $cuisine." : ""}
    ${mealType != null && mealType != 'Any' ? "Recipe should be suitable for $mealType." : ""}
    ${dietaryRestrictions != null && dietaryRestrictions.isNotEmpty ? "Recipes MUST meet these dietary restrictions: ${dietaryRestrictions.join(', ')}." : ""}
    
    Each recipe should be practical, delicious, and realistic. Focus on good flavor combinations.
    
    For each recipe, provide the following in JSON format:
    {
      "title": "Recipe Title",
      "description": "Brief appetizing description of the dish and its flavors",
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
    
    Return only the JSON array of recipes without any additional text. Ensure the JSON is correctly formatted and valid.
    """;
  }
  
  /// Call OpenAI API with retry mechanism
  Future<http.Response> _callOpenAiApiWithRetry(String prompt, {int maxRetries = 3}) async {
    int retries = 0;
    while (retries < maxRetries) {
      try {
        final response = await http.post(
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
            'max_tokens': 2500
          }),
        );
        
        // If successful or error that won't be fixed by retrying
        if (response.statusCode == 200 || response.statusCode >= 400 && response.statusCode != 429) {
          return response;
        }
        
        // If rate limited, wait longer before retrying
        if (response.statusCode == 429) {
          await Future.delayed(Duration(seconds: 5 * (retries + 1)));
        } else {
          await Future.delayed(Duration(seconds: 2));
        }
        
      } catch (e) {
        print('API call failed: $e');
        if (e is SocketException) {
          // Network error, wait before retry
          await Future.delayed(Duration(seconds: 2));
        } else {
          // Other errors, may not be fixable with retry
          rethrow;
        }
      }
      
      retries++;
    }
    
    throw Exception('Failed to call OpenAI API after $maxRetries attempts');
  }
  
  /// Save generated recipes to Firestore for future use
  Future<void> _saveGeneratedRecipesToFirestore(List<Recipe> recipes) async {
    try {
      WriteBatch batch = _firestore.batch();
      
      for (var recipe in recipes) {
        DocumentReference docRef = _firestore.collection('ai_generated_recipes').doc(recipe.id);
        batch.set(docRef, recipe.toJson());
      }
      
      await batch.commit();
    } catch (e) {
      print('Error saving recipes to Firestore: $e');
      // Don't throw here, this is a background operation
    }
  }
  
  /// Generate a cache key from parameters
  String _generateCacheKey(
    List<Ingredient> ingredients,
    String? cuisine,
    String? mealType,
    String? difficulty,
    List<String>? dietaryRestrictions,
  ) {
    // Sort ingredients to ensure consistent cache keys
    final sortedIngredients = ingredients.map((i) => i.name.toLowerCase()).toList()..sort();
    
    // Create key parts
    final parts = [
      sortedIngredients.join('|'),
      cuisine ?? 'any',
      mealType ?? 'any',
      difficulty ?? 'any',
      dietaryRestrictions?.join('|') ?? 'none',
    ];
    
    return parts.join('::');
  }
  
  /// Check if cache entry is valid (not expired)
  bool _isValidCacheEntry(String cacheKey) {
    if (!_recipeCache.containsKey(cacheKey) || !_cacheTimestamps.containsKey(cacheKey)) {
      return false;
    }
    
    final timestamp = _cacheTimestamps[cacheKey]!;
    final now = DateTime.now();
    
    return now.difference(timestamp) < _cacheDuration;
  }
  
  /// Cache recipes with timestamp
  void _cacheRecipes(String cacheKey, List<Recipe> recipes) {
    _recipeCache[cacheKey] = recipes;
    _cacheTimestamps[cacheKey] = DateTime.now();
    
    // Cleanup old cache entries if cache is getting too large
    if (_recipeCache.length > 100) {
      _cleanupCache();
    }
  }
  
  /// Clean up old cache entries
  void _cleanupCache() {
    final now = DateTime.now();
    final keysToRemove = <String>[];
    
    _cacheTimestamps.forEach((key, timestamp) {
      if (now.difference(timestamp) > _cacheDuration) {
        keysToRemove.add(key);
      }
    });
    
    for (var key in keysToRemove) {
      _recipeCache.remove(key);
      _cacheTimestamps.remove(key);
    }
  }
  
  // Methods for retrieving saved, favorite, and recent recipes
  Future<List<Recipe>> getSavedRecipes() async {
    try {
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