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
  
  // Common error messages for better user feedback
  static const Map<String, String> _errorMessages = {
    'user-not-found': 'No user found with this email address.',
    'wrong-password': 'Incorrect password. Please try again.',
    'email-already-in-use': 'An account already exists with this email.',
    'weak-password': 'Password is too weak. Please use a stronger password.',
    'invalid-email': 'Please enter a valid email address.',
    'network-request-failed': 'Network error. Please check your connection.',
    'too-many-requests': 'Too many attempts. Please try again later.',
    'operation-not-allowed': 'This operation is not allowed.',
  };
  
  // Helper method to format Firebase error messages
  String _getReadableErrorMessage(FirebaseException e) {
    return _errorMessages[e.code] ?? 'An error occurred: ${e.message}';
  }
  
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
    } on FirebaseException catch (e) {
      print('Error getting user data: $e');
      throw _getReadableErrorMessage(e);
    } catch (e) {
      print('Error getting user data: $e');
      throw 'Failed to retrieve user data. Please try again.';
    }
  }

  Future<UserCredential> signIn({
    required String email, 
    required String password,
  }) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      notifyListeners();
      return result;
    } on FirebaseAuthException catch (e) {
      print('Error signing in: $e');
      throw _getReadableErrorMessage(e);
    } catch (e) {
      print('Error signing in: $e');
      throw 'An unexpected error occurred. Please try again later.';
    }
  }

  Future<UserCredential> signUp({
    required String email, 
    required String password, 
    required String name,
  }) async {
    try {
      // Validate email format
      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
        throw FirebaseAuthException(
          code: 'invalid-email',
          message: 'Please enter a valid email address.',
        );
      }
      
      // Validate password strength
      if (password.length < 6) {
        throw FirebaseAuthException(
          code: 'weak-password',
          message: 'Password is too weak. Please use a stronger password.',
        );
      }
      
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      
      // Create user in Firestore
      UserModel newUser = UserModel(
        uid: result.user!.uid,
        email: email.trim(),
        name: name.trim(),
      );
      
      await _firestore
          .collection('users')
          .doc(result.user!.uid)
          .set(newUser.toJson());
      
      // Update display name
      await result.user!.updateDisplayName(name);
      
      notifyListeners();
      return result;
    } on FirebaseAuthException catch (e) {
      print('Error signing up: $e');
      throw _getReadableErrorMessage(e);
    } catch (e) {
      print('Error signing up: $e');
      throw 'Failed to create account. Please try again later.';
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      notifyListeners();
    } on FirebaseAuthException catch (e) {
      print('Error signing out: $e');
      throw _getReadableErrorMessage(e);
    } catch (e) {
      print('Error signing out: $e');
      throw 'Failed to sign out. Please try again.';
    }
  }
  
  Future<void> updateUserProfile(UserModel updatedUser) async {
    try {
      if (currentUser == null) throw Exception('User not authenticated');
      
      // Transaction to ensure atomicity
      await _firestore.runTransaction((transaction) async {
        DocumentReference userRef = _firestore.collection('users').doc(currentUser!.uid);
        
        // Get the current user data
        DocumentSnapshot userSnapshot = await transaction.get(userRef);
        
        if (!userSnapshot.exists) {
          throw Exception('User document not found');
        }
        
        // Update user document
        transaction.update(userRef, updatedUser.toJson());
      });
      
      // Update display name if it changed
      if (currentUser!.displayName != updatedUser.name) {
        await currentUser!.updateDisplayName(updatedUser.name);
      }
      
      notifyListeners();
    } on FirebaseException catch (e) {
      print('Error updating user profile: $e');
      throw _getReadableErrorMessage(e);
    } catch (e) {
      print('Error updating user profile: $e');
      throw 'Failed to update profile. Please try again.';
    }
  }
  
  Future<void> updatePassword(String newPassword) async {
    try {
      if (currentUser == null) throw Exception('User not authenticated');
      
      // Validate password strength
      if (newPassword.length < 6) {
        throw FirebaseAuthException(
          code: 'weak-password',
          message: 'Password is too weak. Please use a stronger password.',
        );
      }
      
      await currentUser!.updatePassword(newPassword);
      notifyListeners();
    } on FirebaseAuthException catch (e) {
      print('Error updating password: $e');
      throw _getReadableErrorMessage(e);
    } catch (e) {
      print('Error updating password: $e');
      throw 'Failed to update password. Please try again.';
    }
  }
  
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      print('Error sending password reset email: $e');
      throw _getReadableErrorMessage(e);
    } catch (e) {
      print('Error sending password reset email: $e');
      throw 'Failed to send password reset email. Please try again.';
    }
  }
  
  Future<void> deleteAccount() async {
    try {
      if (currentUser == null) throw Exception('User not authenticated');
      
      // Delete user data from Firestore with transaction
      await _firestore.runTransaction((transaction) async {
        // Delete user document
        transaction.delete(_firestore.collection('users').doc(currentUser!.uid));
        
        // Delete user's saved recipes
        QuerySnapshot savedRecipes = await _firestore
            .collection('users')
            .doc(currentUser!.uid)
            .collection('recipe_history')
            .get();
            
        for (DocumentSnapshot doc in savedRecipes.docs) {
          transaction.delete(doc.reference);
        }
        
        // Delete user's pantry
        QuerySnapshot pantry = await _firestore
            .collection('users')
            .doc(currentUser!.uid)
            .collection('pantry')
            .get();
            
        for (DocumentSnapshot doc in pantry.docs) {
          transaction.delete(doc.reference);
        }
        
        // Delete user's preferences
        QuerySnapshot preferences = await _firestore
            .collection('users')
            .doc(currentUser!.uid)
            .collection('preferences')
            .get();
            
        for (DocumentSnapshot doc in preferences.docs) {
          transaction.delete(doc.reference);
        }
      });
      
      // Delete user authentication account
      await currentUser!.delete();
      
      notifyListeners();
    } on FirebaseAuthException catch (e) {
      print('Error deleting account: $e');
      
      // For this specific error, provide a helpful message about re-authentication
      if (e.code == 'requires-recent-login') {
        throw 'For security reasons, please sign out and sign in again before deleting your account.';
      }
      
      throw _getReadableErrorMessage(e);
    } catch (e) {
      print('Error deleting account: $e');
      throw 'Failed to delete account. Please try again.';
    }
  }
  
  // Add method for re-authentication
  Future<void> reauthenticate(String password) async {
    try {
      if (currentUser == null || currentUser!.email == null) {
        throw Exception('User not authenticated');
      }
      
      // Create credential
      AuthCredential credential = EmailAuthProvider.credential(
        email: currentUser!.email!, 
        password: password
      );
      
      // Re-authenticate
      await currentUser!.reauthenticateWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      print('Error reauthenticating: $e');
      throw _getReadableErrorMessage(e);
    } catch (e) {
      print('Error reauthenticating: $e');
      throw 'Failed to reauthenticate. Please check your password and try again.';
    }
  }
}