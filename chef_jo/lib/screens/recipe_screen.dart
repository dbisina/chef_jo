// screens/recipe_generator_screen.dart
import 'package:flutter/material.dart';
import '../models/recipe_model.dart';
import '../models/ingredient_model.dart';
import '../services/recipe_service.dart';
import '../services/storage_service.dart';
import '../widgets/custom_button.dart';
import '../widgets/ingredient_chip.dart';
import '../widgets/recipe_card.dart';
import '../config/theme.dart';

class RecipeGeneratorScreen extends StatefulWidget {
  const RecipeGeneratorScreen({Key? key}) : super(key: key);

  @override
  _RecipeGeneratorScreenState createState() => _RecipeGeneratorScreenState();
}

class _RecipeGeneratorScreenState extends State<RecipeGeneratorScreen> {
  final RecipeService _recipeService = RecipeService();
  final StorageService _storageService = StorageService();
  final TextEditingController _searchController = TextEditingController();

  List<Ingredient> _pantryIngredients = [];
  List<Ingredient> _selectedIngredients = [];
  List<Ingredient> _filteredIngredients = [];
  List<Recipe> _generatedRecipes = [];
  
  bool _isLoadingPantry = true;
  bool _isGenerating = false;
  
  String _cuisine = 'Any';
  String _mealType = 'Any';
  String _difficulty = 'Any';
  
  List<String> _cuisineOptions = ['Any', 'Italian', 'American', 'Asian', 'Mexican', 'Mediterranean', 'Indian'];
  List<String> _mealTypeOptions = ['Any', 'Breakfast', 'Lunch', 'Dinner', 'Snack', 'Dessert'];
  List<String> _difficultyOptions = ['Any', 'Easy', 'Medium', 'Hard'];
  
  Map<String, bool> _dietaryPreferences = {
    'Vegetarian': false,
    'Vegan': false,
    'Gluten-Free': false,
    'Dairy-Free': false,
    'Low-Carb': false,
    'Keto': false,
  };

  @override
  void initState() {
    super.initState();
    _loadPantryIngredients();
    _loadUserPreferences();
  }

  Future<void> _loadPantryIngredients() async {
    setState(() {
      _isLoadingPantry = true;
    });

    try {
      final ingredients = await _storageService.getPantryIngredients();
      setState(() {
        _pantryIngredients = ingredients;
        _filteredIngredients = ingredients;
        _isLoadingPantry = false;
      });
    } catch (e) {
      print('Error loading pantry: $e');
      setState(() {
        _isLoadingPantry = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load ingredients')),
      );
    }
  }

  Future<void> _loadUserPreferences() async {
    try {
      final preferences = await _storageService.getUserPreferences();
      if (preferences.isNotEmpty) {
        setState(() {
          preferences.forEach((key, value) {
            if (_dietaryPreferences.containsKey(key)) {
              _dietaryPreferences[key] = value;
            }
          });
        });
      }
    } catch (e) {
      print('Error loading preferences: $e');
    }
  }
  
  void _filterIngredients(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredIngredients = _pantryIngredients;
      } else {
        _filteredIngredients = _pantryIngredients
            .where((ingredient) => 
                ingredient.name.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  void _toggleIngredientSelection(Ingredient ingredient) {
    setState(() {
      if (_selectedIngredients.any((item) => item.id == ingredient.id)) {
        _selectedIngredients.removeWhere((item) => item.id == ingredient.id);
      } else {
        _selectedIngredients.add(ingredient);
      }
    });
  }

  Future<void> _generateRecipes() async {
    if (_selectedIngredients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select at least one ingredient')),
      );
      return;
    }

    setState(() {
      _isGenerating = true;
    });

    try {
      // Prepare dietary restrictions
      List<String> dietaryRestrictions = _dietaryPreferences.entries
          .where((entry) => entry.value)
          .map((entry) => entry.key)
          .toList();

      // Generate recipes
      List<Recipe> recipes = await _recipeService.generateRecipes(
        ingredients: _selectedIngredients,
        cuisine: _cuisine == 'Any' ? null : _cuisine,
        mealType: _mealType == 'Any' ? null : _mealType,
        difficulty: _difficulty == 'Any' ? null : _difficulty,
        dietaryRestrictions: dietaryRestrictions.isEmpty ? null : dietaryRestrictions,
        limit: 10,
      );

      setState(() {
        _generatedRecipes = recipes;
        _isGenerating = false;
      });
    } catch (e) {
      print('Error generating recipes: $e');
      setState(() {
        _isGenerating = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to generate recipes. Please try again.')),
      );
    }
  }

  void _navigateToRecipeDetail(Recipe recipe) {
    Navigator.pushNamed(
      context,
      '/recipe_detail',
      arguments: recipe,
    );
    
    // Save to view history
    _storageService.saveRecipeHistory(recipe);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Recipe Generator'),
      ),
      body: _isLoadingPantry
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: 'Search Ingredients',
                      suffixIcon: IconButton(
                        icon: Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _filterIngredients('');
                        },
                      ),
                    ),
                    onChanged: _filterIngredients,
                  ),
                  SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _filteredIngredients.length,
                      itemBuilder: (context, index) {
                        final ingredient = _filteredIngredients[index];
                        return IngredientChip(
                          ingredient: ingredient,
                          isSelected: _selectedIngredients
                              .any((item) => item.id == ingredient.id),
                          onSelected: () => _toggleIngredientSelection(ingredient),
                        );
                      },
                    ),
                  ),
                  SizedBox(height: 16),
                  CustomButton(
                    text: 'Generate Recipes',
                    onPressed: _generateRecipes,
                    isLoading: _isGenerating,
                  ),
                  SizedBox(height: 16),
                  if (_generatedRecipes.isNotEmpty)
                    Expanded(
                      child: ListView.builder(
                        itemCount: _generatedRecipes.length,
                        itemBuilder: (context, index) {
                          final recipe = _generatedRecipes[index];
                          return RecipeCard(
                            recipe: recipe,
                            onTap: () => _navigateToRecipeDetail(recipe),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}