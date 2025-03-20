// lib/screens/pantry_screen.dart
import 'package:flutter/material.dart';
import '../models/ingredient_model.dart';
import '../services/storage_service.dart';
import '../config/theme.dart';
import '../widgets/custom_button.dart';

class PantryScreen extends StatefulWidget {
  const PantryScreen({Key? key}) : super(key: key);

  @override
  _PantryScreenState createState() => _PantryScreenState();
}

class _PantryScreenState extends State<PantryScreen> {
  final StorageService _storageService = StorageService();
  final TextEditingController _ingredientController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  List<Ingredient> _ingredients = [];
  bool _isLoading = true;
  String _selectedCategory = 'General';
  List<String> _categories = [
    'General', 'Vegetables', 'Fruits', 'Meat', 'Dairy', 'Grains', 'Spices', 'Baking'
  ];
  
  @override
  void initState() {
    super.initState();
    _loadIngredients();
  }
  
  @override
  void dispose() {
    _ingredientController.dispose();
    _quantityController.dispose();
    super.dispose();
  }
  
  Future<void> _loadIngredients() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final ingredients = await _storageService.getPantryIngredients();
      if (mounted) {
        setState(() {
          _ingredients = ingredients;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading ingredients: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load pantry ingredients')),
        );
      }
    }
  }
  
  void _showAddIngredientDialog() {
    _ingredientController.clear();
    _quantityController.clear();
    _selectedCategory = 'General';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Ingredient'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _ingredientController,
                decoration: InputDecoration(
                  labelText: 'Ingredient Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an ingredient name';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _quantityController,
                decoration: InputDecoration(
                  labelText: 'Quantity (e.g., 2 cups)',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: _categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value ?? 'General';
                  });
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _addIngredient,
            child: Text('Add'),
          ),
        ],
      ),
    );
  }
  
  void _addIngredient() async {
    if (_formKey.currentState != null && _formKey.currentState!.validate()) {
      final name = _ingredientController.text.trim();
      final quantity = _quantityController.text.trim();
      
      final ingredient = Ingredient(
        id: 'ingredient_${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        quantity: quantity.isNotEmpty ? quantity : null,
        category: _selectedCategory,
        inPantry: true,
      );
      
      try {
        await _storageService.savePantryIngredient(ingredient);
        
        Navigator.pop(context);
        
        setState(() {
          _ingredients.add(ingredient);
          _ingredients.sort((a, b) => a.name.compareTo(b.name));
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ingredient added to pantry')),
        );
      } catch (e) {
        print('Error adding ingredient: $e');
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add ingredient')),
        );
      }
    }
  }
  
  Future<void> _deleteIngredient(Ingredient ingredient) async {
    try {
      await _storageService.deleteIngredient(ingredient.id);
      
      setState(() {
        _ingredients.removeWhere((item) => item.id == ingredient.id);
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ingredient removed from pantry')),
      );
    } catch (e) {
      print('Error deleting ingredient: $e');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to remove ingredient')),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Pantry'),
        actions: [
          IconButton(
            icon: Icon(Icons.sort),
            onPressed: () {
              _showSortOptions();
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _ingredients.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadIngredients,
                  child: ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: _ingredients.length,
                    itemBuilder: (context, index) {
                      final ingredient = _ingredients[index];
                      return Card(
                        margin: EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(ingredient.name),
                          subtitle: Text(
                            ingredient.quantity != null
                                ? '${ingredient.quantity} • ${ingredient.category ?? 'General'}'
                                : ingredient.category ?? 'General',
                          ),
                          trailing: IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteIngredient(ingredient),
                          ),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddIngredientDialog,
        backgroundColor: ChefJoTheme.primaryColor,
        child: Icon(Icons.add),
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.kitchen,
            size: 64,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'Your pantry is empty',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Add ingredients to get started',
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 24),
          CustomButton(
            text: 'Add Ingredient',
            icon: Icons.add,
            onPressed: _showAddIngredientDialog,
          ),
        ],
      ),
    );
  }
  
  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text('Sort by Name (A-Z)'),
              onTap: () {
                setState(() {
                  _ingredients.sort((a, b) => a.name.compareTo(b.name));
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text('Sort by Name (Z-A)'),
              onTap: () {
                setState(() {
                  _ingredients.sort((a, b) => b.name.compareTo(a.name));
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text('Sort by Category'),
              onTap: () {
                setState(() {
                  _ingredients.sort((a, b) => 
                    (a.category ?? '').compareTo(b.category ?? ''));
                });
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }
}