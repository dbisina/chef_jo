// screens/recipe_generator_screen.dart
import 'dart:async';
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
  bool _isSearching = false;
  
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
  
  // Add debounce timer
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadPantryIngredients();
    _loadUserPreferences();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadPantryIngredients() async {
    setState(() {
      _isLoadingPantry = true;
    });

    try {
      final ingredients = await _storageService.getPantryIngredients();
      if (mounted) {
        setState(() {
          _pantryIngredients = ingredients;
          _filteredIngredients = ingredients;
          _isLoadingPantry = false;
        });
      }
    } catch (e) {
      print('Error loading pantry: $e');
      if (mounted) {
        setState(() {
          _isLoadingPantry = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load ingredients: ${e.toString().substring(0, 50)}...')),
        );
      }
    }
  }

  Future<void> _loadUserPreferences() async {
    try {
      final preferences = await _storageService.getUserPreferences();
      if (preferences.isNotEmpty && mounted) {
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
      // Don't show error for preferences, not critical
    }
  }
  
  // Add debounce to prevent excessive filtering
  void _filterIngredients(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    
    setState(() {
      _isSearching = query.isNotEmpty;
    });
    
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          if (query.isEmpty) {
            _filteredIngredients = _pantryIngredients;
          } else {
            // Optimize filtering with indexing and case insensitivity
            final lowercaseQuery = query.toLowerCase();
            _filteredIngredients = _pantryIngredients
                .where((ingredient) => 
                    ingredient.name.toLowerCase().contains(lowercaseQuery))
                .toList();
          }
          _isSearching = false;
        });
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
      _generatedRecipes = []; // Clear previous results
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

      if (mounted) {
        setState(() {
          _generatedRecipes = recipes;
          _isGenerating = false;
        });
        
        if (recipes.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No recipes found for these ingredients. Try adding more ingredients or changing filters.')),
          );
        }
      }
    } catch (e) {
      print('Error generating recipes: $e');
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate recipes: ${e.toString().substring(0, 100)}...')),
        );
      }
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
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: _isLoadingPantry
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Search bar
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: 'Search Ingredients',
                      prefixIcon: Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                _filterIngredients('');
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: _filterIngredients,
                  ),
                ),
                
                // Selected ingredients
                if (_selectedIngredients.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Selected Ingredients:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _selectedIngredients.map((ingredient) {
                            return Chip(
                              label: Text(ingredient.name),
                              onDeleted: () => _toggleIngredientSelection(ingredient),
                              backgroundColor: ChefJoTheme.primaryColor.withOpacity(0.1),
                              deleteIconColor: ChefJoTheme.primaryColor,
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                
                // Ingredient list or results
                Expanded(
                  child: _isSearching
                      ? Center(child: CircularProgressIndicator())
                      : _generatedRecipes.isEmpty
                          ? _buildIngredientList()
                          : _buildRecipeResults(),
                ),
                
                // Generate button
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: CustomButton(
                    text: _generatedRecipes.isEmpty
                        ? 'Generate Recipes'
                        : 'Generate New Recipes',
                    icon: Icons.auto_awesome,
                    onPressed: _generateRecipes,
                    isLoading: _isGenerating,
                    fullWidth: true,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildIngredientList() {
    if (_filteredIngredients.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.no_food,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No ingredients found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/pantry_management');
              },
              child: Text('Add ingredients to your pantry'),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _filteredIngredients.length,
      itemBuilder: (context, index) {
        final ingredient = _filteredIngredients[index];
        return Card(
          margin: EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text(ingredient.name),
            subtitle: ingredient.category != null ? Text(ingredient.category!) : null,
            trailing: IconButton(
              icon: Icon(
                _selectedIngredients.any((item) => item.id == ingredient.id)
                    ? Icons.check_circle
                    : Icons.add_circle_outline,
                color: _selectedIngredients.any((item) => item.id == ingredient.id)
                    ? ChefJoTheme.primaryColor
                    : null,
              ),
              onPressed: () => _toggleIngredientSelection(ingredient),
            ),
            onTap: () => _toggleIngredientSelection(ingredient),
          ),
        );
      },
    );
  }

  Widget _buildRecipeResults() {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _generatedRecipes.length,
      itemBuilder: (context, index) {
        final recipe = _generatedRecipes[index];
        return RecipeCard(
          recipe: recipe,
          onTap: () => _navigateToRecipeDetail(recipe),
        );
      },
    );
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.all(24),
              child: ListView(
                shrinkWrap: true,
                children: [
                  // Title
                  Center(
                    child: Text(
                      'Recipe Filters',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(height: 24),
                  
                  // Cuisine filter
                  Text(
                    'Cuisine',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _cuisineOptions.map((cuisine) {
                      return ChoiceChip(
                        label: Text(cuisine),
                        selected: _cuisine == cuisine,
                        onSelected: (selected) {
                          setModalState(() {
                            _cuisine = selected ? cuisine : 'Any';
                          });
                        },
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 16),
                  
                  // Meal type filter
                  Text(
                    'Meal Type',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _mealTypeOptions.map((type) {
                      return ChoiceChip(
                        label: Text(type),
                        selected: _mealType == type,
                        onSelected: (selected) {
                          setModalState(() {
                            _mealType = selected ? type : 'Any';
                          });
                        },
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 16),
                  
                  // Difficulty filter
                  Text(
                    'Difficulty',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _difficultyOptions.map((difficulty) {
                      return ChoiceChip(
                        label: Text(difficulty),
                        selected: _difficulty == difficulty,
                        onSelected: (selected) {
                          setModalState(() {
                            _difficulty = selected ? difficulty : 'Any';
                          });
                        },
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 16),
                  
                  // Dietary preferences
                  Text(
                    'Dietary Preferences',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _dietaryPreferences.entries.map((entry) {
                      return FilterChip(
                        label: Text(entry.key),
                        selected: entry.value,
                        onSelected: (selected) {
                          setModalState(() {
                            _dietaryPreferences[entry.key] = selected;
                          });
                        },
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 24),
                  
                  // Apply button
                  CustomButton(
                    text: 'Apply Filters',
                    icon: Icons.check,
                    onPressed: () {
                      Navigator.pop(context);
                      setState(() {
                        // Filters are updated inside the modal state
                        // Clear results to prevent confusion
                        _generatedRecipes = [];
                      });
                    },
                    fullWidth: true,
                  ),
                  SizedBox(height: 8),
                  
                  // Reset button
                  TextButton(
                    onPressed: () {
                      setModalState(() {
                        _cuisine = 'Any';
                        _mealType = 'Any';
                        _difficulty = 'Any';
                        _dietaryPreferences.forEach((key, value) {
                          _dietaryPreferences[key] = false;
                        });
                      });
                    },
                    child: Text('Reset Filters'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}