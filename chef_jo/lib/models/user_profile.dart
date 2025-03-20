// models/user_profile.dart
class UserProfile {
  final String uid;
  final String email;
  final String name;
  final String? photoUrl;
  final List<String> dietaryPreferences;
  final List<String> allergies;
  final bool notificationsEnabled;
  final bool darkMode;

  UserProfile({
    required this.uid,
    required this.email,
    required this.name,
    this.photoUrl,
    this.dietaryPreferences = const [],
    this.allergies = const [],
    this.notificationsEnabled = true,
    this.darkMode = false,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      photoUrl: map['photoUrl'],
      dietaryPreferences: List<String>.from(map['dietaryPreferences'] ?? []),
      allergies: List<String>.from(map['allergies'] ?? []),
      notificationsEnabled: map['notificationsEnabled'] ?? true,
      darkMode: map['darkMode'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'photoUrl': photoUrl,
      'dietaryPreferences': dietaryPreferences,
      'allergies': allergies,
      'notificationsEnabled': notificationsEnabled,
      'darkMode': darkMode,
    };
  }

  UserProfile copyWith({
    String? name,
    String? photoUrl,
    List<String>? dietaryPreferences,
    List<String>? allergies,
    bool? notificationsEnabled,
    bool? darkMode,
  }) {
    return UserProfile(
      uid: this.uid,
      email: this.email,
      name: name ?? this.name,
      photoUrl: photoUrl ?? this.photoUrl,
      dietaryPreferences: dietaryPreferences ?? this.dietaryPreferences,
      allergies: allergies ?? this.allergies,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      darkMode: darkMode ?? this.darkMode,
    );
  }
}