// services/storage_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../models/user_model.dart';
import '../models/recipe_model.dart';
import '../models/ingredient_model.dart';

class StorageService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // User Profile Methods
  Future<UserModel?> getUserProfile() async {
    try {
      String uid = _auth.currentUser?.uid ?? '';
      if (uid.isEmpty) return null;

      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromJson(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  Future<void> saveUserProfile(UserModel profile) async {
    try {
      String uid = _auth.currentUser?.uid ?? '';
      if (uid.isEmpty) throw Exception('User not authenticated');

      await _firestore.collection('users').doc(uid).set(profile.toJson());
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
      
      await ref.putFile(imageFile);
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

      DocumentSnapshot userDoc = await _firestore.collection('users').doc(uid).get();
      if (!userDoc.exists) return [];
      
      UserModel user = UserModel.fromJson(userDoc.data() as Map<String, dynamic>);
      List<String> savedRecipeIds = user.savedRecipes;
      
      List<Recipe> recipes = [];
      for (String recipeId in savedRecipeIds) {
        DocumentSnapshot recipeDoc = await _firestore.collection('recipes').doc(recipeId).get();
        if (recipeDoc.exists) {
          recipes.add(Recipe.fromJson(recipeDoc.data() as Map<String, dynamic>));
        }
      }
      
      return recipes;
    } catch (e) {
      print('Error getting saved recipes: $e');
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

      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('pantry')
          .orderBy('name')
          .get();

      return snapshot.docs
          .map((doc) => Ingredient.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting pantry ingredients: $e');
      return [];
    }
  }

  Future<void> savePantryIngredient(Ingredient ingredient) async {
    try {
      String uid = _auth.currentUser?.uid ?? '';
      if (uid.isEmpty) throw Exception('User not authenticated');

      await _firestore
          .collection('users')
          .doc(uid)
          .collection('pantry')
          .doc(ingredient.id)
          .set(ingredient.toJson());
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

      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(uid)
          .collection('preferences')
          .doc('dietary')
          .get();

      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return Map<String, bool>.from(data);
      }
      return {};
    } catch (e) {
      print('Error getting user preferences: $e');
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
          
      List<Recipe> recipes = [];
      for (String id in recipeIds) {
        DocumentSnapshot recipeDoc = await _firestore
            .collection('recipes')
            .doc(id)
            .get();
            
        if (recipeDoc.exists) {
          recipes.add(Recipe.fromJson(recipeDoc.data() as Map<String, dynamic>));
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
}