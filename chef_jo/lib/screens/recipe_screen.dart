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
          : Column(
              children: [
                // Filter Section
                _buildFilterSection(),
                
                // Selected Ingredients
                if (_selectedIngredients.isNotEmpty)
                  _buildSelectedIngredientsSection(),
                
                // Generate Button
                Padding(
                  padding: EdgeInsets.all(16),
                  child: CustomButton(
                    text: 'Generate Recipes',
                    icon: Icons.auto_awesome,
                    onPressed: _generateRecipes,
                    isLoading: _isGenerating,
                    fullWidth: true,
                  ),
                ),
                
                // Generated Recipes
                if (_generatedRecipes.isNotEmpty)
                  Expanded(
                    child: _buildGeneratedRecipesSection(),
                  )
                else
                  Expanded(
                    child: _buildIngredientsSection(),
                  ),
              ],
            ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ingredient Search
          TextFormField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search ingredients',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            ),
            onChanged: _filterIngredients,
          ),
          
          SizedBox(height: 16),
          
          // Filter Dropdowns
          Row(
            children: [
              Expanded(
                child: _buildDropdown(
                  label: 'Cuisine',
                  value: _cuisine,
                  items: _cuisineOptions,
                  onChanged: (value) {
                    setState(() {
                      _cuisine = value ?? 'Any';
                    });
                  },
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _buildDropdown(
                  label: 'Meal',
                  value: _mealType,
                  items: _mealTypeOptions,
                  onChanged: (value) {
                    setState(() {
                      _mealType = value ?? 'Any';
                    });
                  },
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _buildDropdown(
                  label: 'Difficulty',
                  value: _difficulty,
                  items: _difficultyOptions,
                  onChanged: (value) {
                    setState(() {
                      _difficulty = value ?? 'Any';
                    });
                  },
                ),
              ),
            ],
          ),
          
          SizedBox(height: 16),
          
          // Dietary Preferences
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
                selectedColor: ChefJoTheme.primaryColor.withOpacity(0.2),
                checkmarkColor: ChefJoTheme.primaryColor,
                onSelected: (selected) {
                  setState(() {
                    _dietaryPreferences[entry.key] = selected;
                  });
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 4),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            underline: SizedBox(),
            icon: Icon(Icons.arrow_drop_down),
            items: items.map((String item) {
              return DropdownMenuItem<String>(
                value: item,
                child: Text(item),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedIngredientsSection() {
    return Container(
      padding: EdgeInsets.all(16),
      color: ChefJoTheme.primaryColor.withOpacity(0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Selected Ingredients (${_selectedIngredients.length})',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedIngredients.clear();
                  });
                },
                child: Text('Clear All'),
              ),
            ],
          ),
          SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _selectedIngredients.map((ingredient) {
              return IngredientChip(
                ingredient: ingredient,
                onTap: () => _toggleIngredientSelection(ingredient),
                removable: true,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildIngredientsSection() {
  return Padding(
    padding: EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Ingredients',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 16),
        if (_filteredIngredients.isEmpty)
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.search_off,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No ingredients found',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/pantry'),
                    child: Text('Add ingredients to your pantry'),
                  ),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 2.5,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: _filteredIngredients.length,
              itemBuilder: (context, index) {
                final ingredient = _filteredIngredients[index];
                final isSelected = _selectedIngredients
                    .any((item) => item.id == ingredient.id);
                
                return InkWell(
                  onTap: () => _toggleIngredientSelection(ingredient),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? ChefJoTheme.primaryColor
                          : ChefJoTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Center(
                      child: Text(
                        ingredient.name,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    ),
  );
}

// Implement _buildGeneratedRecipesSection
Widget _buildGeneratedRecipesSection() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Text(
          'Generated Recipes (${_generatedRecipes.length})',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      Expanded(
        child: ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: _generatedRecipes.length,
          itemBuilder: (context, index) {
            final recipe = _generatedRecipes[index];
            return Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: RecipeCard(
                recipe: recipe,
                onTap: () => _navigateToRecipeDetail(recipe),
              ),
            );
          },
        ),
      ),
    ],
  );
}

@override
void dispose() {
  _searchController.dispose();
  super.dispose();
}