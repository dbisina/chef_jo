// lib/screens/recipe_list_screen.dart
import 'package:flutter/material.dart';
import '../models/recipe_model.dart';
import '../services/storage_service.dart';
import '../widgets/recipe_card.dart';
import '../config/theme.dart';

class RecipeListScreen extends StatefulWidget {
  const RecipeListScreen({Key? key}) : super(key: key);

  @override
  _RecipeListScreenState createState() => _RecipeListScreenState();
}

class _RecipeListScreenState extends State<RecipeListScreen> {
  final StorageService _storageService = StorageService();
  List<Recipe> _recipes = [];
  bool _isLoading = true;
  String _listType = 'all';

  @override
  void initState() {
    super.initState();
    // Wait for the widget to be fully initialized before processing arguments
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _processArguments();
    });
  }

  void _processArguments() {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args != null) {
      setState(() {
        _listType = args.toString();
      });
    }
    _loadRecipes();
  }

  Future<void> _loadRecipes() async {
    setState(() {
      _isLoading = true;
    });

    try {
      List<Recipe> recipes;
      
      switch (_listType) {
        case 'recent':
          recipes = await _storageService.getRecentRecipes();
          break;
        case 'favorites':
          recipes = await _storageService.getFavoriteRecipes();
          break;
        case 'saved':
          recipes = await _storageService.getSavedRecipes();
          break;
        default:
          // Default to all recipes
          recipes = await _storageService.getSavedRecipes();
          break;
      }
      
      if (mounted) {
        setState(() {
          _recipes = recipes;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading recipes: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading recipes: $e')),
        );
      }
    }
  }

  void _navigateToRecipeDetail(Recipe recipe) {
    Navigator.pushNamed(
      context,
      '/detail',
      arguments: recipe,
    );
  }

  String _getPageTitle() {
    switch (_listType) {
      case 'recent':
        return 'Recently Viewed';
      case 'favorites':
        return 'Your Favorites';
      case 'saved':
        return 'Saved Recipes';
      default:
        return 'All Recipes';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getPageTitle()),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _recipes.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadRecipes,
                  child: ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: _recipes.length,
                    itemBuilder: (context, index) {
                      return RecipeCard(
                        recipe: _recipes[index],
                        onTap: () => _navigateToRecipeDetail(_recipes[index]),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.restaurant,
            size: 64,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'No recipes found',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, '/recipe_generator');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ChefJoTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: Text('Generate New Recipe'),
          ),
        ],
      ),
    );
  }
}