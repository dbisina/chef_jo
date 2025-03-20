// services/storage_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'dart:async';
import '../models/user_model.dart';
import '../models/recipe_model.dart';
import '../models/ingredient_model.dart';

class StorageService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Cache for frequently accessed data
  UserModel? _cachedUserProfile;
  List<Recipe>? _cachedSavedRecipes;
  List<Ingredient>? _cachedPantryIngredients;
  Map<String, bool>? _cachedUserPreferences;
  DateTime? _cachedUserProfileTime;
  DateTime? _cachedSavedRecipesTime;
  DateTime? _cachedPantryIngredientsTime;
  DateTime? _cachedUserPreferencesTime;
  
  // Cache validity duration
  final Duration _cacheValidityDuration = Duration(minutes: 15);
  
  // Check if cache is still valid
  bool _isCacheValid(DateTime? cacheTime) {
    if (cacheTime == null) return false;
    return DateTime.now().difference(cacheTime) < _cacheValidityDuration;
  }

  // User Profile Methods
  Future<UserModel?> getUserProfile() async {
    try {
      String uid = _auth.currentUser?.uid ?? '';
      if (uid.isEmpty) return null;
      
      // Return from cache if valid
      if (_cachedUserProfile != null && _isCacheValid(_cachedUserProfileTime)) {
        return _cachedUserProfile;
      }

      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        UserModel userProfile = UserModel.fromJson(doc.data() as Map<String, dynamic>);
        
        // Update cache
        _cachedUserProfile = userProfile;
        _cachedUserProfileTime = DateTime.now();
        
        return userProfile;
      }
      return null;
    } catch (e) {
      print('Error getting user profile: $e');
      // Return cached version as fallback if available
      if (_cachedUserProfile != null) {
        return _cachedUserProfile;
      }
      return null;
    }
  }

  Future<void> saveUserProfile(UserModel profile) async {
    try {
      String uid = _auth.currentUser?.uid ?? '';
      if (uid.isEmpty) throw Exception('User not authenticated');

      await _firestore.collection('users').doc(uid).set(profile.toJson());
      
      // Update cache
      _cachedUserProfile = profile;
      _cachedUserProfileTime = DateTime.now();
    } catch (e) {
      print('Error saving user profile: $e');
      throw e;
    }
  }

  Future<String?> uploadProfileImage(File imageFile) async {
    try {
      String uid = _auth.currentUser?.uid ?? '';
      if (uid.isEmpty) return null;

      String fileName = 'profile_images/$uid.jpg';
      Reference ref = _storage.ref().child(fileName);
      
      // Add metadata for image optimization
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {'resizable': 'true', 'userId': uid},
      );
      
      await ref.putFile(imageFile, metadata);
      return await ref.getDownloadURL();
    } catch (e) {
      print('Error uploading profile image: $e');
      return null;
    }
  }

  // Recipe Methods
  Future<List<Recipe>> getSavedRecipes() async {
    try {
      String uid = _auth.currentUser?.uid ?? '';
      if (uid.isEmpty) return [];
      
      // Return from cache if valid
      if (_cachedSavedRecipes != null && _isCacheValid(_cachedSavedRecipesTime)) {
        return _cachedSavedRecipes!;
      }

      DocumentSnapshot userDoc = await _firestore.collection('users').doc(uid).get();
      if (!userDoc.exists) return [];
      
      UserModel user = UserModel.fromJson(userDoc.data() as Map<String, dynamic>);
      List<String> savedRecipeIds = user.savedRecipes;
      
      if (savedRecipeIds.isEmpty) return [];
      
      // Use a batch get for efficiency
      List<Recipe> recipes = [];
      
      // Process in batches of 10 to avoid Firestore limits
      for (int i = 0; i < savedRecipeIds.length; i += 10) {
        int end = (i + 10 < savedRecipeIds.length) ? i + 10 : savedRecipeIds.length;
        List<String> batch = savedRecipeIds.sublist(i, end);
        
        // Get recipes in this batch
        QuerySnapshot recipeSnapshot = await _firestore
            .collection('recipes')
            .where(FieldPath.documentId, whereIn: batch)
            .get();
            
        for (var doc in recipeSnapshot.docs) {
          recipes.add(Recipe.fromJson(doc.data() as Map<String, dynamic>));
        }
      }
      
      // Update cache
      _cachedSavedRecipes = recipes;
      _cachedSavedRecipesTime = DateTime.now();
      
      return recipes;
    } catch (e) {
      print('Error getting saved recipes: $e');
      // Return cached version as fallback if available
      if (_cachedSavedRecipes != null) {
        return _cachedSavedRecipes!;
      }
      return [];
    }
  }

  Future<void> saveRecipe(Recipe recipe) async {
    try {
      String uid = _auth.currentUser?.uid ?? '';
      if (uid.isEmpty) throw Exception('User not authenticated');

      // Update user's saved recipes list
      await _firestore.collection('users').doc(uid).update({
        'savedRecipes': FieldValue.arrayUnion([recipe.id])
      });
      
      // Update cache
      if (_cachedSavedRecipes != null) {
        if (!_cachedSavedRecipes!.any((r) => r.id == recipe.id)) {
          _cachedSavedRecipes!.add(recipe);
          _cachedSavedRecipesTime = DateTime.now();
        }
      } else {
        // Initialize cache if it doesn't exist
        _cachedSavedRecipes = [recipe];
        _cachedSavedRecipesTime = DateTime.now();
      }
    } catch (e) {
      print('Error saving recipe: $e');
      throw e;
    }
  }

  Future<void> deleteRecipe(String recipeId) async {
    try {
      String uid = _auth.currentUser?.uid ?? '';
      if (uid.isEmpty) throw Exception('User not authenticated');

      // Remove from user's saved recipes list
      await _firestore.collection('users').doc(uid).update({
        'savedRecipes': FieldValue.arrayRemove([recipeId])
      });
      
      // Update cache
      if (_cachedSavedRecipes != null) {
        _cachedSavedRecipes!.removeWhere((recipe) => recipe.id == recipeId);
        _cachedSavedRecipesTime = DateTime.now();
      }
    } catch (e) {
      print('Error deleting recipe: $e');
      throw e;
    }
  }

  // Ingredient Pantry Methods
  Future<List<Ingredient>> getPantryIngredients() async {
    try {
      String uid = _auth.currentUser?.uid ?? '';
      if (uid.isEmpty) return [];
      
      // Return from cache if valid
      if (_cachedPantryIngredients != null && _isCacheValid(_cachedPantryIngredientsTime)) {
        return _cachedPantryIngredients!;
      }

      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('pantry')
          .orderBy('name')
          .get();

      List<Ingredient> ingredients = snapshot.docs
          .map((doc) => Ingredient.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
          
      // Update cache
      _cachedPantryIngredients = ingredients;
      _cachedPantryIngredientsTime = DateTime.now();
      
      return ingredients;
    } catch (e) {
      print('Error getting pantry ingredients: $e');
      // Return cached version as fallback if available
      if (_cachedPantryIngredients != null) {
        return _cachedPantryIngredients!;
      }
      return [];
    }
  }

  Future<void> savePantryIngredient(Ingredient ingredient) async {
    try {
      String uid = _auth.currentUser?.uid ?? '';
      if (uid.isEmpty) throw Exception('User not authenticated');

      // Ensure ingredient has an ID
      String ingredientId = ingredient.id.isNotEmpty 
          ? ingredient.id 
          : 'ingredient_${DateTime.now().millisecondsSinceEpoch}';
          
      Ingredient updatedIngredient = ingredient.id.isNotEmpty
          ? ingredient
          : ingredient.copyWith(id: ingredientId);

      await _firestore
          .collection('users')
          .doc(uid)
          .collection('pantry')
          .doc(updatedIngredient.id)
          .set(updatedIngredient.toJson());
          
      // Update cache
      if (_cachedPantryIngredients != null) {
        // Replace or add ingredient
        int index = _cachedPantryIngredients!.indexWhere((i) => i.id == updatedIngredient.id);
        if (index >= 0) {
          _cachedPantryIngredients![index] = updatedIngredient;
        } else {
          _cachedPantryIngredients!.add(updatedIngredient);
        }
        _cachedPantryIngredientsTime = DateTime.now();
      }
    } catch (e) {
      print('Error saving pantry ingredient: $e');
      throw e;
    }
  }

  Future<void> deleteIngredient(String ingredientId) async {
    try {
      String uid = _auth.currentUser?.uid ?? '';
      if (uid.isEmpty) throw Exception('User not authenticated');

      await _firestore
          .collection('users')
          .doc(uid)
          .collection('pantry')
          .doc(ingredientId)
          .delete();
          
      // Update cache
      if (_cachedPantryIngredients != null) {
        _cachedPantryIngredients!.removeWhere((ingredient) => ingredient.id == ingredientId);
        _cachedPantryIngredientsTime = DateTime.now();
      }
    } catch (e) {
      print('Error deleting ingredient: $e');
      throw e;
    }
  }

  // User Preferences
  Future<Map<String, bool>> getUserPreferences() async {
    try {
      String uid = _auth.currentUser?.uid ?? '';
      if (uid.isEmpty) return {};
      
      // Return from cache if valid
      if (_cachedUserPreferences != null && _isCacheValid(_cachedUserPreferencesTime)) {
        return _cachedUserPreferences!;
      }

      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(uid)
          .collection('preferences')
          .doc('dietary')
          .get();

      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        Map<String, bool> preferences = Map<String, bool>.from(data);
        
        // Update cache
        _cachedUserPreferences = preferences;
        _cachedUserPreferencesTime = DateTime.now();
        
        return preferences;
      }
      return {};
    } catch (e) {
      print('Error getting user preferences: $e');
      // Return cached version as fallback if available
      if (_cachedUserPreferences != null) {
        return _cachedUserPreferences!;
      }
      return {};
    }
  }

  Future<void> saveUserPreferences(Map<String, bool> preferences) async {
    try {
      String uid = _auth.currentUser?.uid ?? '';
      if (uid.isEmpty) throw Exception('User not authenticated');

      await _firestore
          .collection('users')
          .doc(uid)
          .collection('preferences')
          .doc('dietary')
          .set(preferences);
          
      // Update cache
      _cachedUserPreferences = Map<String, bool>.from(preferences);
      _cachedUserPreferencesTime = DateTime.now();
    } catch (e) {
      print('Error saving user preferences: $e');
      throw e;
    }
  }

  // User Allergies
  Future<List<String>> getUserAllergies() async {
    try {
      String uid = _auth.currentUser?.uid ?? '';
      if (uid.isEmpty) return [];

      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(uid)
          .get();

      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        if (data.containsKey('allergies')) {
          return List<String>.from(data['allergies']);
        }
      }
      return [];
    } catch (e) {
      print('Error getting user allergies: $e');
      return [];
    }
  }

  Future<void> saveUserAllergies(List<String> allergies) async {
    try {
      String uid = _auth.currentUser?.uid ?? '';
      if (uid.isEmpty) throw Exception('User not authenticated');

      await _firestore
          .collection('users')
          .doc(uid)
          .update({'allergies': allergies});
    } catch (e) {
      print('Error saving user allergies: $e');
      throw e;
    }
  }

  // Recipe History
  Future<void> saveRecipeHistory(Recipe recipe) async {
    try {
      String uid = _auth.currentUser?.uid ?? '';
      if (uid.isEmpty) return;
      
      Map<String, dynamic> historyData = {
        'recipeId': recipe.id,
        'title': recipe.title,
        'imageUrl': recipe.imageUrl,
        'viewedAt': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection('users')
          .doc(uid)
          .collection('recipe_history')
          .doc(recipe.id)
          .set(historyData);
    } catch (e) {
      print('Error saving recipe history: $e');
      // Don't throw, this is not critical
    }
  }
  
  Future<List<Recipe>> getRecentRecipes() async {
    try {
      String uid = _auth.currentUser?.uid ?? '';
      if (uid.isEmpty) return [];

      QuerySnapshot historySnapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('recipe_history')
          .orderBy('viewedAt', descending: true)
          .limit(10)
          .get();
          
      List<String> recipeIds = historySnapshot.docs
          .map((doc) => doc['recipeId'] as String)
          .toList();
          
      if (recipeIds.isEmpty) return [];
      
      List<Recipe> recipes = [];
      
      // Process in batches of 10 to avoid Firestore limits
      for (int i = 0; i < recipeIds.length; i += 10) {
        int end = (i + 10 < recipeIds.length) ? i + 10 : recipeIds.length;
        List<String> batch = recipeIds.sublist(i, end);
        
        // Get recipes in this batch
        QuerySnapshot recipeSnapshot = await _firestore
            .collection('recipes')
            .where(FieldPath.documentId, whereIn: batch)
            .get();
            
        for (var doc in recipeSnapshot.docs) {
          recipes.add(Recipe.fromJson(doc.data() as Map<String, dynamic>));
        }
      }
      
      return recipes;
    } catch (e) {
      print('Error getting recent recipes: $e');
      return [];
    }
  }
  
  Future<List<Recipe>> getFavoriteRecipes() async {
    try {
      return await getSavedRecipes();
    } catch (e) {
      print('Error getting favorite recipes: $e');
      return [];
    }
  }
  
  // Clear cache method for logout
  void clearCache() {
    _cachedUserProfile = null;
    _cachedSavedRecipes = null;
    _cachedPantryIngredients = null;
    _cachedUserPreferences = null;
    _cachedUserProfileTime = null;
    _cachedSavedRecipesTime = null;
    _cachedPantryIngredientsTime = null;
    _cachedUserPreferencesTime = null;
  }
}