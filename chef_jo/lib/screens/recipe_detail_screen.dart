// screens/recipe_detail_screen.dart
import 'package:flutter/material.dart';
import '../models/recipe_model.dart';
import '../services/storage_service.dart';
import '../widgets/custom_button.dart';
import '../config/theme.dart';

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

  @override
  void initState() {
    super.initState();
    _checkIfRecipeIsSaved();
  }

  Future<void> _checkIfRecipeIsSaved() async {
    final savedRecipes = await _storageService.getSavedRecipes();
    setState(() {
      _isSaved = savedRecipes.any((recipe) => recipe.id == widget.recipe.id);
    });
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
          content: Text('Error: ${e.toString()}'),
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
                  ? Image.network(
                      widget.recipe.imageUrl!,
                      fit: BoxFit.cover,
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
                color: Colors.black.withOpacity(0.3),
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
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Cooking mode coming soon!')),
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
    return Container(
      height: 100,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildInfoCard(
            icon: Icons.access_time,
            title: 'Prep Time',
            value: '${widget.recipe.prepTimeMinutes} min',
          ),
          _buildInfoCard(
            icon: Icons.whatshot,
            title: 'Cook Time',
            value: '${widget.recipe.cookTimeMinutes} min',
          ),
          _buildInfoCard(
            icon: Icons.people,
            title: 'Servings',
            value: '${widget.recipe.servings}',
          ),
          _buildInfoCard(
            icon: Icons.local_fire_department,
            title: 'Calories',
            value: '${widget.recipe.calories} cal',
          ),
          _buildInfoCard(
            icon: Icons.fitness_center,
            title: 'Protein',
            value: '${widget.recipe.nutritionInfo['protein']}g',
          ),
          _buildInfoCard(
            icon: Icons.bakery_dining,
            title: 'Carbs',
            value: '${widget.recipe.nutritionInfo['carbs']}g',
          ),
          _buildInfoCard(
            icon: Icons.opacity,
            title: 'Fat',
            value: '${widget.recipe.nutritionInfo['fat']}g',
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
    return Column(
      children: widget.recipe.ingredients.asMap().entries.map((entry) {
        final index = entry.key;
        final ingredient = entry.value;
        
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
                      ingredient.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    if (ingredient.amount.isNotEmpty)
                      Text(
                        '${ingredient.amount} ${ingredient.unit}',
                        style: TextStyle(
                          color: Colors.grey[600],
                        ),
                      ),
                  ],
                ),
              ),
              if (ingredient.inPantry != null && ingredient.inPantry!)
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