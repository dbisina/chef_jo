// lib/screens/shopping_list_screen.dart
import 'package:flutter/material.dart';
import '../models/ingredient_model.dart';
import '../services/storage_service.dart';
import '../config/theme.dart';

class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({Key? key}) : super(key: key);

  @override
  _ShoppingListScreenState createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  final StorageService _storageService = StorageService();
  final TextEditingController _itemController = TextEditingController();
  
  List<Ingredient> _shoppingItems = [];
  List<Ingredient> _purchasedItems = [];
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadShoppingList();
  }
  
  @override
  void dispose() {
    _itemController.dispose();
    super.dispose();
  }
  
  Future<void> _loadShoppingList() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // For now, just simulate data
      // In a real app, you would load from storage service
      await Future.delayed(Duration(milliseconds: 500));
      
      setState(() {
        _shoppingItems = [
          Ingredient(id: '1', name: 'Milk', quantity: '1 gallon'),
          Ingredient(id: '2', name: 'Eggs', quantity: '1 dozen'),
          Ingredient(id: '3', name: 'Bread', quantity: '1 loaf'),
          Ingredient(id: '4', name: 'Butter', quantity: '1 stick'),
        ];
        _purchasedItems = [];
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading shopping list: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load shopping list')),
        );
      }
    }
  }
  
  void _addItem() {
    final itemName = _itemController.text.trim();
    if (itemName.isEmpty) return;
    
    setState(() {
      _shoppingItems.add(
        Ingredient(
          id: 'item_${DateTime.now().millisecondsSinceEpoch}',
          name: itemName,
        ),
      );
      _itemController.clear();
    });
  }
  
  void _toggleItemPurchased(Ingredient item) {
    setState(() {
      if (_shoppingItems.contains(item)) {
        _shoppingItems.remove(item);
        _purchasedItems.add(item);
      } else {
        _purchasedItems.remove(item);
        _shoppingItems.add(item);
      }
    });
  }
  
  void _deleteItem(Ingredient item) {
    setState(() {
      _shoppingItems.remove(item);
      _purchasedItems.remove(item);
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Shopping List'),
        actions: [
          IconButton(
            icon: Icon(Icons.delete_sweep),
            onPressed: () {
              setState(() {
                _purchasedItems.clear();
              });
            },
            tooltip: 'Clear purchased items',
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Add new item
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _itemController,
                          decoration: InputDecoration(
                            hintText: 'Add item',
                            border: OutlineInputBorder(),
                          ),
                          onSubmitted: (_) => _addItem(),
                        ),
                      ),
                      SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _addItem,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ChefJoTheme.primaryColor,
                          padding: EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Icon(Icons.add),
                      ),
                    ],
                  ),
                ),
                
                // Shopping Items
                Expanded(
                  child: _shoppingItems.isEmpty && _purchasedItems.isEmpty
                      ? _buildEmptyState()
                      : ListView(
                          children: [
                            if (_shoppingItems.isNotEmpty) ...[
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                  vertical: 8.0,
                                ),
                                child: Text(
                                  'TO BUY',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ),
                              ..._shoppingItems.map((item) => _buildShoppingItem(item, false)),
                            ],
                            
                            if (_purchasedItems.isNotEmpty) ...[
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                  vertical: 8.0,
                                ),
                                child: Text(
                                  'PURCHASED',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ),
                              ..._purchasedItems.map((item) => _buildShoppingItem(item, true)),
                            ],
                          ],
                        ),
                ),
              ],
            ),
    );
  }
  
  Widget _buildShoppingItem(Ingredient item, bool isPurchased) {
    return Dismissible(
      key: Key(item.id),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 16),
        child: Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => _deleteItem(item),
      child: Card(
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: ListTile(
          leading: Checkbox(
            value: isPurchased,
            activeColor: ChefJoTheme.primaryColor,
            onChanged: (_) => _toggleItemPurchased(item),
          ),
          title: Text(
            item.name,
            style: TextStyle(
              decoration: isPurchased ? TextDecoration.lineThrough : null,
            ),
          ),
          subtitle: item.quantity != null ? Text(item.quantity!) : null,
          trailing: IconButton(
            icon: Icon(Icons.delete, color: Colors.grey),
            onPressed: () => _deleteItem(item),
          ),
          onTap: () => _toggleItemPurchased(item),
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
            Icons.shopping_cart,
            size: 64,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'Your shopping list is empty',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Add items using the field above',
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}