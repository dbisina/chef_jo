// models/user_model.dart
class UserModel {
  final String uid;
  final String email;
  final String name;
  final List<String> dietaryPreferences;
  final List<String> allergies;
  final List<String> savedRecipes;
  bool notificationsEnabled; // Added property
  bool darkMode; // Added property

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    this.dietaryPreferences = const [],
    this.allergies = const [],
    this.savedRecipes = const [],
    this.notificationsEnabled = true, // Default to true
    this.darkMode = false, // Default to false
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      dietaryPreferences: List<String>.from(json['dietaryPreferences'] ?? []),
      allergies: List<String>.from(json['allergies'] ?? []),
      savedRecipes: List<String>.from(json['savedRecipes'] ?? []),
      notificationsEnabled: json['notificationsEnabled'] ?? true,
      darkMode: json['darkMode'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'dietaryPreferences': dietaryPreferences,
      'allergies': allergies,
      'savedRecipes': savedRecipes,
      'notificationsEnabled': notificationsEnabled,
      'darkMode': darkMode,
    };
  }

  UserModel copyWith({
    String? name,
    List<String>? dietaryPreferences,
    List<String>? allergies,
    List<String>? savedRecipes,
    bool? notificationsEnabled,
    bool? darkMode,
  }) {
    return UserModel(
      uid: this.uid,
      email: this.email,
      name: name ?? this.name,
      dietaryPreferences: dietaryPreferences ?? this.dietaryPreferences,
      allergies: allergies ?? this.allergies,
      savedRecipes: savedRecipes ?? this.savedRecipes,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      darkMode: darkMode ?? this.darkMode,
    );
  }
}