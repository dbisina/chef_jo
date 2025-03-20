// screens/profile_screen.dart
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../widgets/custom_button.dart';
import '../config/theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final StorageService _storageService = StorageService();
  
  late User _user;
  bool _isLoading = true;
  bool _isSaving = false;
  
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  
  Map<String, bool> _dietaryPreferences = {
    'Vegetarian': false,
    'Vegan': false,
    'Gluten-Free': false,
    'Dairy-Free': false,
    'Low-Carb': false,
    'Keto': false,
  };
  
  List<String> _allergies = [];
  final TextEditingController _allergyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _allergyController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load user profile
      final user = await _authService.getCurrentUser();
      if (user != null) {
        _nameController.text = user.name;
        _user = user;
      }
      
      // Load preferences
      final preferences = await _storageService.getUserPreferences();
      
      // Load allergies
      final allergies = await _storageService.getUserAllergies();
      
      if (mounted) {
        setState(() {
          if (preferences.isNotEmpty) {
            preferences.forEach((key, value) {
              if (_dietaryPreferences.containsKey(key)) {
                _dietaryPreferences[key] = value;
              }
            });
          }
          
          _allergies = allergies;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load user data')),
        );
      }
    }
  }

  Future<void> _saveUserData() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // Update user profile
      await _authService.updateUserProfile(
        name: _nameController.text.trim(),
      );
      
      // Save preferences
      await _storageService.saveUserPreferences(_dietaryPreferences);
      
      // Save allergies
      await _storageService.saveUserAllergies(_allergies);
      
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profile updated successfully')),
        );
      }
    } catch (e) {
      print('Error saving user data: $e');
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile')),
        );
      }
    }
  }

  void _addAllergy() {
    final allergy = _allergyController.text.trim();
    if (allergy.isNotEmpty && !_allergies.contains(allergy)) {
      setState(() {
        _allergies.add(allergy);
        _allergyController.clear();
      });
    }
  }

  void _removeAllergy(String allergy) {
    setState(() {
      _allergies.remove(allergy);
    });
  }

  Future<void> _signOut() async {
    try {
      await _authService.signOut();
      Navigator.of(context).pushReplacementNamed('/auth');
    } catch (e) {
      print('Error signing out: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to sign out')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _signOut,
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Header
                    Center(
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: ChefJoTheme.primaryColor.withOpacity(0.2),
                            child: Icon(
                              Icons.person,
                              size: 50,
                              color: ChefJoTheme.primaryColor,
                            ),
                          ),
                          SizedBox(height: 16),
                          Text(
                            _user.name,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            _user.email,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    SizedBox(height: 32),
                    
                    // Personal Information
                    _buildSectionTitle('Personal Information'),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your name';
                        }
                        return null;
                      },
                    ),
                    
                    SizedBox(height: 32),
                    
                    // Dietary Preferences
                    _buildSectionTitle('Dietary Preferences'),
                    SizedBox(height: 16),
                    _buildDietaryPreferences(),
                    
                    SizedBox(height: 32),
                    
                    // Allergies
                    _buildSectionTitle('Allergies & Intolerances'),
                    SizedBox(height: 16),
                    _buildAllergiesSection(),
                    
                    SizedBox(height: 32),
                    
                    // App Settings
                    _buildSectionTitle('App Settings'),
                    SizedBox(height: 16),
                    _buildAppSettings(),
                    
                    SizedBox(height: 32),
                    
                    // Save Button
                    CustomButton(
                      text: 'Save Changes',
                      icon: Icons.save,
                      onPressed: _saveUserData,
                      isLoading: _isSaving,
                      fullWidth: true,
                    ),
                    
                    SizedBox(height: 16),
                    
                    // Delete Account
                    Center(
                      child: TextButton(
                        onPressed: () {
                          // Show confirmation dialog before deleting
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text('Delete Account'),
                              content: Text(
                                'Are you sure you want to delete your account? '
                                'This action cannot be undone.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    // Implement delete account functionality
                                  },
                                  child: Text(
                                    'Delete',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                        child: Text(
                          'Delete Account',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        Divider(),
      ],
    );
  }

  Widget _buildDietaryPreferences() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _dietaryPreferences.entries.map((entry) {
        return FilterChip(
          label: Text(entry.key),
          selected: entry.value,
          selectedColor: ChefJoTheme.primaryColor.withOpacity(0.2),
          checkmarkColor: ChefJoTheme.primaryColor,
          onSelected: (selected) {
            setState(() {
              _dietaryPreferences[entry.key] = selected;
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildAllergiesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _allergyController,
                decoration: InputDecoration(
                  hintText: 'Add allergy or intolerance',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            SizedBox(width: 8),
            IconButton(
              icon: Icon(Icons.add),
              onPressed: _addAllergy,
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all(ChefJoTheme.primaryColor),
                foregroundColor: MaterialStateProperty.all(Colors.white),
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        if (_allergies.isEmpty)
          Text(
            'No allergies added',
            style: TextStyle(
              color: Colors.grey,
              fontStyle: FontStyle.italic,
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _allergies.map((allergy) {
              return Chip(
                label: Text(allergy),
                deleteIcon: Icon(Icons.close, size: 16),
                onDeleted: () => _removeAllergy(allergy),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildAppSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          title: Text('Enable Notifications'),
          value: _user.notificationsEnabled,
          onChanged: (value) {
            setState(() {
              _user.notificationsEnabled = value;
            });
          },
        ),
        SwitchListTile(
          title: Text('Dark Mode'),
          value: _user.darkMode,
          onChanged: (value) {
            setState(() {
              _user.darkMode = value;
            });
          },
        ),
      ],
    ); 
  }
}
