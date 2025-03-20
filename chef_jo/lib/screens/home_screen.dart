// screens/home_screen.dart
import 'package:flutter/material.dart';
import '../models/recipe_model.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../widgets/recipe_card.dart';
import '../config/theme.dart';
import '../config/routes.dart';
class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();
  final StorageService _storageService = StorageService();
  
  List<Recipe> _recentRecipes = [];
  List<Recipe> _favoriteRecipes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final recentRecipes = await _storageService.getRecentRecipes();
      final favoriteRecipes = await _storageService.getFavoriteRecipes();
      
      if (mounted) {
        setState(() {
          _recentRecipes = recentRecipes;
          _favoriteRecipes = favoriteRecipes;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
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

  void _navigateToGenerateRecipe() {
    Navigator.pushNamed(context, Routes.recipeGenerator);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chef Jo'),
        actions: [
          IconButton(
            icon: Icon(Icons.person),
            onPressed: () => Navigator.pushNamed(context, '/profile'),
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Quick Actions
                    _buildQuickActions(),
                    
                    SizedBox(height: 24),
                    
                    // Recent Recipes
                    _buildSectionTitle('Recently Viewed', onSeeAll: () {
                      Navigator.pushNamed(context, Routes.recipes, arguments: 'recent');
                    }),
                    SizedBox(height: 12),
                    _buildHorizontalRecipeList(_recentRecipes),
                    
                    SizedBox(height: 24),
                    
                    // Favorite Recipes
                    _buildSectionTitle('Your Favorites', onSeeAll: () {
                      Navigator.pushNamed(context, Routes.recipes, arguments: 'favorites');
                    }),
                    SizedBox(height: 12),
                    _favoriteRecipes.isEmpty
                        ? _buildEmptyState(
                            icon: Icons.favorite,
                            message: 'No favorite recipes yet',
                            actionText: 'Browse Recipes',
                            onAction: () => Navigator.pushNamed(context, '/recipes'),
                          )
                        : _buildHorizontalRecipeList(_favoriteRecipes),
                    
                    SizedBox(height: 24),
                    
                    // Recipe Suggestions
                    _buildSectionTitle('Ideas For You'),
                    SizedBox(height: 12),
                    _buildSuggestionsList(),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToGenerateRecipe,
        label: Text('Generate Recipe'),
        icon: Icon(Icons.auto_awesome),
        backgroundColor: ChefJoTheme.primaryColor,
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ChefJoTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildActionButton(
                icon: Icons.kitchen,
                label: 'My Pantry',
                onTap: () => Navigator.pushNamed(context, '/pantry'),
              ),
              _buildActionButton(
                icon: Icons.auto_awesome,
                label: 'Generate',
                onTap: _navigateToGenerateRecipe,
              ),
              _buildActionButton(
                icon: Icons.bookmark,
                label: 'Saved',
                onTap: () => Navigator.pushNamed(
                  context,
                  '/recipes',
                  arguments: 'saved',
                ),
              ),
              _buildActionButton(
                icon: Icons.shopping_cart,
                label: 'Shopping',
                onTap: () => Navigator.pushNamed(context, '/shopping_list'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 70,
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: ChefJoTheme.primaryColor,
              ),
            ),
            SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, {VoidCallback? onSeeAll}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (onSeeAll != null)
          TextButton(
            onPressed: onSeeAll,
            child: Text('See All'),
          ),
      ],
    );
  }

  Widget _buildHorizontalRecipeList(List<Recipe> recipes) {
    if (recipes.isEmpty) {
      return _buildEmptyState(
        icon: Icons.restaurant,
        message: 'No recipes available',
        actionText: 'Browse Recipes',
        onAction: () => Navigator.pushNamed(context, '/recipes'),
      );
    }

    return Container(
      height: 230,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: recipes.length,
        itemBuilder: (context, index) {
          return Container(
            width: 160,
            margin: EdgeInsets.only(right: 16),
            child: RecipeCard(
              recipe: recipes[index],
              onTap: () => _navigateToRecipeDetail(recipes[index]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSuggestionsList() {
    // This would typically be populated with AI-generated suggestions
    // For now, using placeholder data
    List<Map<String, String>> suggestions = [
      {'title': 'Quick Breakfasts', 'subtitle': 'Start your day right'},
      {'title': 'Vegetarian Dinner', 'subtitle': 'Plant-based goodness'},
      {'title': 'Weekend Baking', 'subtitle': 'Sweet treats to try'},
      {'title': 'Healthy Lunches', 'subtitle': 'Nutritious and delicious'},
    ];

    return Column(
      children: suggestions.map((suggestion) {
        return Container(
          margin: EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: ChefJoTheme.primaryColor.withOpacity(0.2),
              child: Icon(
                Icons.lightbulb_outline,
                color: ChefJoTheme.primaryColor,
              ),
            ),
            title: Text(suggestion['title']!),
            subtitle: Text(suggestion['subtitle']!),
            trailing: Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.pushNamed(
                context,
                '/recipe_generator',
                arguments: {'suggestion': suggestion['title']},
              );
            },
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String message,
    required String actionText,
    required VoidCallback onAction,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: onAction,
              child: Text(actionText),
            ),
          ],
        ),
      ),
    );
  }
}