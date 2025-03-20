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
  Future<UserProfile?> getUserProfile() async {
    try {
      String uid = _auth.currentUser?.uid ?? '';
      if (uid.isEmpty) return null;

      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserProfile.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  Future<void> saveUserProfile(UserProfile profile) async {
    try {
      String uid = _auth.currentUser?.uid ?? '';
      if (uid.isEmpty) throw Exception('User not authenticated');

      await _firestore.collection('users').doc(uid).set(profile.toMap());
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

      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('saved_recipes')
          .orderBy('savedAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Recipe.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting saved recipes: $e');
      return [];
    }
  }

  Future<void> saveRecipe(Recipe recipe) async {
    try {
      String uid = _auth.currentUser?.uid ?? '';
      if (uid.isEmpty) throw Exception('User not authenticated');

      // Add current timestamp when saving
      Map<String, dynamic> recipeData = recipe.toMap();
      recipeData['savedAt'] = FieldValue.serverTimestamp();

      await _firestore
          .collection('users')
          .doc(uid)
          .collection('saved_recipes')
          .doc(recipe.id)
          .set(recipeData);
    } catch (e) {
      print('Error saving recipe: $e');
      throw e;
    }
  }

  Future<void> deleteRecipe(String recipeId) async {
    try {
      String uid = _auth.currentUser?.uid ?? '';
      if (uid.isEmpty) throw Exception('User not authenticated');

      await _firestore
          .collection('users')
          .doc(uid)
          .collection('saved_recipes')
          .doc(recipeId)
          .delete();
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
          .map((doc) => Ingredient.fromMap(doc.data() as Map<String, dynamic>))
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
          .set(ingredient.toMap());
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
  Future<Map<String, dynamic>> getUserPreferences() async {
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
        return doc.data() as Map<String, dynamic>;
      }
      return {};
    } catch (e) {
      print('Error getting user preferences: $e');
      return {};
    }
  }

  Future<void> saveUserPreferences(Map<String, dynamic> preferences) async {
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

  // Recipe History
  Future<void> saveRecipeHistory(Recipe recipe) async {
    try {
      String uid = _auth.currentUser?.uid ?? '';
      if (uid.isEmpty) throw Exception('User not authenticated');
      
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
          .add(historyData);
    } catch (e) {
      print('Error saving recipe history: $e');
    }
  }
}