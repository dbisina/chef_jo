// screens/recipe_detail_screen.dart
import 'package:flutter/material.dart';
import '../models/recipe_model.dart';
import '../services/storage_service.dart';
import '../widgets/custom_button.dart';
import '../config/theme.dart';
import 'package:cached_network_image/cached_network_image.dart';

class RecipeDetailScreen extends StatefulWidget {
  final Recipe recipe;

  const RecipeDetailScreen({
    Key? key,
    required this.recipe,
  }) : super(key: key);

  @override
  _RecipeDetailScreenState createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  final StorageService _storageService = StorageService();
  bool _isSaved = false;
  bool _isSaving = false;
  bool _isImageLoading = true;
  bool _imageError = false;

  @override
  void initState() {
    super.initState();
    _checkIfRecipeIsSaved();
  }

  Future<void> _checkIfRecipeIsSaved() async {
    try {
      final savedRecipes = await _storageService.getSavedRecipes();
      if (mounted) {
        setState(() {
          _isSaved = savedRecipes.any((recipe) => recipe.id == widget.recipe.id);
        });
      }
    } catch (e) {
      print('Error checking if recipe is saved: $e');
      // Don't update state if there's an error
    }
  }

  Future<void> _toggleSaveRecipe() async {
    setState(() {
      _isSaving = true;
    });

    try {
      if (_isSaved) {
        await _storageService.deleteRecipe(widget.recipe.id);
      } else {
        await _storageService.saveRecipe(widget.recipe);
      }

      setState(() {
        _isSaved = !_isSaved;
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isSaved ? 'Recipe saved' : 'Recipe removed from saved',
          ),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString().substring(0, 50)}...'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar with Image
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: widget.recipe.imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: widget.recipe.imageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: ChefJoTheme.primaryColor.withOpacity(0.1),
                        child: Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      errorWidget: (context, url, error) {
                        return Container(
                          color: ChefJoTheme.primaryColor.withOpacity(0.1),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.restaurant,
                                  size: 64,
                                  color: ChefJoTheme.primaryColor,
                                ),
                                SizedBox(height: 8),
                                Text(
                                  widget.recipe.title,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: ChefJoTheme.primaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    )
                  : Container(
                      color: ChefJoTheme.primaryColor.withOpacity(0.1),
                      child: Center(
                        child: Icon(
                          Icons.restaurant,
                          size: 80,
                          color: ChefJoTheme.primaryColor,
                        ),
                      ),
                    ),
              title: Container(
                width: double.infinity,
                color: Colors.black.withOpacity(0.5),
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  widget.recipe.title,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              titlePadding: EdgeInsets.only(left: 0, bottom: 0),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  _isSaved ? Icons.bookmark : Icons.bookmark_border,
                  color: Colors.white,
                ),
                onPressed: _isSaving ? null : _toggleSaveRecipe,
              ),
              IconButton(
                icon: Icon(Icons.share, color: Colors.white),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Sharing feature coming soon!')),
                  );
                },
              ),
            ],
          ),
          // Recipe Content
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Recipe Info Cards
                  _buildInfoCards(),
                  
                  SizedBox(height: 24),
                  
                  // Description
                  Text(
                    'Description',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  SizedBox(height: 8),
                  Text(
                    widget.recipe.description,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  
                  SizedBox(height: 24),
                  
                  // Ingredients
                  Text(
                    'Ingredients',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  SizedBox(height: 16),
                  _buildIngredientsList(),
                  
                  SizedBox(height: 24),
                  
                  // Instructions
                  Text(
                    'Instructions',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  SizedBox(height: 16),
                  _buildInstructionsList(),
                  
                  SizedBox(height: 24),
                  
                  // Match Information
                  if (widget.recipe.matchPercentage > 0)
                    _buildMatchInfo(),
                  
                  SizedBox(height: 24),
                  
                  // Nutrition Information
                  _buildNutritionInfo(),
                  
                  SizedBox(height: 24),
                  
                  // Tags
                  if (widget.recipe.tags.isNotEmpty) _buildTags(),
                  
                  SizedBox(height: 32),
                  
                  // Actions
                  Row(
                    children: [
                      Expanded(
                        child: CustomButton(
                          text: 'Cook Now',
                          icon: Icons.restaurant,
                          onPressed: () {
                            // Navigate to cooking mode or timer
                            Navigator.pushNamed(
                              context, 
                              '/cooking_mode',
                              arguments: widget.recipe,
                            );
                          },
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: CustomButton(
                          text: _isSaved ? 'Unsave' : 'Save',
                          icon: _isSaved ? Icons.bookmark : Icons.bookmark_border,
                          type: ButtonType.outline,
                          isLoading: _isSaving,
                          onPressed: _toggleSaveRecipe,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCards() {
    // Values to display with fallbacks
    final prepTime = widget.recipe.prepTimeMinutes > 0 
        ? widget.recipe.prepTimeMinutes 
        : 15; // Default to 15 if missing
    final cookTime = widget.recipe.cookTimeMinutes > 0 
        ? widget.recipe.cookTimeMinutes 
        : 30; // Default to 30 if missing
    final servings = widget.recipe.servings > 0 
        ? widget.recipe.servings 
        : 4; // Default to 4 if missing
    final calories = widget.recipe.calories > 0 
        ? widget.recipe.calories 
        : 0; // 0 if missing
        
    // Nutritional values with fallbacks  
    final protein = widget.recipe.nutritionInfo.containsKey('protein') 
        ? widget.recipe.nutritionInfo['protein']?.toStringAsFixed(1)
        : "N/A";
    final carbs = widget.recipe.nutritionInfo.containsKey('carbs') 
        ? widget.recipe.nutritionInfo['carbs']?.toStringAsFixed(1)
        : "N/A";
    final fat = widget.recipe.nutritionInfo.containsKey('fat') 
        ? widget.recipe.nutritionInfo['fat']?.toStringAsFixed(1)
        : "N/A";

    return Container(
      height: 100,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildInfoCard(
            icon: Icons.access_time,
            title: 'Prep Time',
            value: '$prepTime min',
          ),
          _buildInfoCard(
            icon: Icons.whatshot,
            title: 'Cook Time',
            value: '$cookTime min',
          ),
          _buildInfoCard(
            icon: Icons.people,
            title: 'Servings',
            value: '$servings',
          ),
          if (calories > 0) _buildInfoCard(
            icon: Icons.local_fire_department,
            title: 'Calories',
            value: '$calories cal',
          ),
          if (protein != "N/A") _buildInfoCard(
            icon: Icons.fitness_center,
            title: 'Protein',
            value: '${protein}g',
          ),
          if (carbs != "N/A") _buildInfoCard(
            icon: Icons.bakery_dining,
            title: 'Carbs',
            value: '${carbs}g',
          ),
          if (fat != "N/A") _buildInfoCard(
            icon: Icons.opacity,
            title: 'Fat',
            value: '${fat}g',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      width: 120,
      margin: EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: ChefJoTheme.primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: ChefJoTheme.primaryColor,
          ),
          SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIngredientsList() {
    if (widget.recipe.ingredients.isEmpty) {
      return Text(
        'No ingredients available. This recipe might be incomplete.',
        style: TextStyle(fontStyle: FontStyle.italic),
      );
    }
    
    return Column(
      children: widget.recipe.ingredients.asMap().entries.map((entry) {
        final index = entry.key;
        final ingredient = entry.value;
        
        // Handle missing ingredient properties safely
        final name = ingredient.name.isNotEmpty 
            ? ingredient.name 
            : 'Ingredient ${index + 1}';
        final amount = ingredient.amount?.isNotEmpty == true
            ? ingredient.amount
            : '';
        final unit = ingredient.unit?.isNotEmpty == true
            ? ingredient.unit
            : '';
        
        return Container(
          padding: EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: index < widget.recipe.ingredients.length - 1
                    ? Colors.grey.withOpacity(0.2)
                    : Colors.transparent,
              ),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 24,
                height: 24,
                margin: EdgeInsets.only(right: 16, top: 2),
                decoration: BoxDecoration(
                  color: ChefJoTheme.primaryColor,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    if (amount.isNotEmpty)
                      Text(
                        '$amount ${unit ?? ''}',
                        style: TextStyle(
                          color: Colors.grey[600],
                        ),
                      ),
                  ],
                ),
              ),
              if (ingredient.inPantry == true)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'In Pantry',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildInstructionsList() {
    if (widget.recipe.instructions.isEmpty) {
      return Text(
        'No instructions available. This recipe might be incomplete.',
        style: TextStyle(fontStyle: FontStyle.italic),
      );
    }
    
    return Column(
      children: widget.recipe.instructions.asMap().entries.map((entry) {
        final index = entry.key;
        final instruction = entry.value;
        
        return Container(
          padding: EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: index < widget.recipe.instructions.length - 1
                    ? Colors.grey.withOpacity(0.2)
                    : Colors.transparent,
              ),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                margin: EdgeInsets.only(right: 16),
                decoration: BoxDecoration(
                  color: ChefJoTheme.primaryColor,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  instruction,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMatchInfo() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ChefJoTheme.accentColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ChefJoTheme.accentColor.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.check_circle,
                color: ChefJoTheme.accentColor,
              ),
              SizedBox(width: 8),
              Text(
                'Match Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: ChefJoTheme.accentColor,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            'This recipe matches ${widget.recipe.matchPercentage.toStringAsFixed(0)}% of your available ingredients.',
          ),
          SizedBox(height: 8),
          Text(
            'You have ${widget.recipe.availableIngredients} out of ${widget.recipe.ingredients.length} ingredients in your pantry.',
          ),
          if (widget.recipe.missingIngredients.isNotEmpty) ...[
            SizedBox(height: 12),
            Text(
              'Missing ingredients:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.recipe.missingIngredients.map((ingredient) {
                return Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(ingredient.name),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNutritionInfo() {
    // Skip if no nutrition info available
    if (widget.recipe.nutritionInfo.isEmpty) {
      return SizedBox.shrink();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nutrition Information',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        SizedBox(height: 16),
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              _buildNutritionRow('Calories', '${widget.recipe.calories} cal'),
              if (widget.recipe.nutritionInfo.containsKey('protein'))
                _buildNutritionRow('Protein', '${widget.recipe.nutritionInfo['protein']?.toStringAsFixed(1)}g'),
              if (widget.recipe.nutritionInfo.containsKey('carbs'))
                _buildNutritionRow('Carbohydrates', '${widget.recipe.nutritionInfo['carbs']?.toStringAsFixed(1)}g'),
              if (widget.recipe.nutritionInfo.containsKey('fat'))
                _buildNutritionRow('Fat', '${widget.recipe.nutritionInfo['fat']?.toStringAsFixed(1)}g'),
              if (widget.recipe.nutritionInfo.containsKey('fiber'))
                _buildNutritionRow('Fiber', '${widget.recipe.nutritionInfo['fiber']?.toStringAsFixed(1)}g'),
              if (widget.recipe.nutritionInfo.containsKey('sugar'))
                _buildNutritionRow('Sugar', '${widget.recipe.nutritionInfo['sugar']?.toStringAsFixed(1)}g'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNutritionRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTags() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tags',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: widget.recipe.tags.map((tag) {
            return Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: ChefJoTheme.accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                tag,
                style: TextStyle(
                  color: ChefJoTheme.accentColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
