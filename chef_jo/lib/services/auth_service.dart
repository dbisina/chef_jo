// services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  
  Future<UserModel?> getUserData() async {
    if (currentUser == null) return null;
    
    try {
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .get();
      
      if (doc.exists) {
        return UserModel.fromJson(doc.data() as Map<String, dynamic>);
      } else {
        // Create new user document if it doesn't exist
        UserModel newUser = UserModel(
          uid: currentUser!.uid,
          email: currentUser!.email ?? '',
          name: currentUser!.displayName ?? 'Chef',
        );
        
        await _firestore
            .collection('users')
            .doc(currentUser!.uid)
            .set(newUser.toJson());
            
        return newUser;
      }
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  Future<UserCredential> signIn({
    required String email, 
    required String password,
  }) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      notifyListeners();
      return result;
    } catch (e) {
      print('Error signing in: $e');
      rethrow;
    }
  }

  Future<UserCredential> signUp({
    required String email, 
    required String password, 
    required String name,
  }) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Create user in Firestore
      UserModel newUser = UserModel(
        uid: result.user!.uid,
        email: email,
        name: name,
      );
      
      await _firestore
          .collection('users')
          .doc(result.user!.uid)
          .set(newUser.toJson());
      
      // Update display name
      await result.user!.updateDisplayName(name);
      
      notifyListeners();
      return result;
    } catch (e) {
      print('Error signing up: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      notifyListeners();
    } catch (e) {
      print('Error signing out: $e');
      rethrow;
    }
  }
  
  Future<void> updateUserProfile(UserModel updatedUser) async {
    try {
      if (currentUser == null) throw Exception('User not authenticated');
      
      await _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .update(updatedUser.toJson());
          
      // Update display name if it changed
      if (currentUser!.displayName != updatedUser.name) {
        await currentUser!.updateDisplayName(updatedUser.name);
      }
      
      notifyListeners();
    } catch (e) {
      print('Error updating user profile: $e');
      rethrow;
    }
  }
  
  Future<void> updatePassword(String newPassword) async {
    try {
      if (currentUser == null) throw Exception('User not authenticated');
      
      await currentUser!.updatePassword(newPassword);
      notifyListeners();
    } catch (e) {
      print('Error updating password: $e');
      rethrow;
    }
  }
  
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      print('Error sending password reset email: $e');
      rethrow;
    }
  }
  
  Future<void> deleteAccount() async {
    try {
      if (currentUser == null) throw Exception('User not authenticated');
      
      // Delete user data from Firestore
      await _firestore.collection('users').doc(currentUser!.uid).delete();
      
      // Delete user authentication account
      await currentUser!.delete();
      
      notifyListeners();
    } catch (e) {
      print('Error deleting account: $e');
      rethrow;
    }
  }
}