// models/ingredient_model.dart
class Ingredient {
  final String id; // Added id field
  final String name;
  final String? quantity;
  final String? unit;
  final String? category;
  final String? amount; // Added amount field
  final bool? inPantry; // Added inPantry field

  Ingredient({
    this.id = '', // Default empty string
    required this.name,
    this.quantity,
    this.unit,
    this.category,
    this.amount = '', // Default empty string
    this.inPantry, // Default null
  });

  factory Ingredient.fromJson(Map<String, dynamic> json) {
    return Ingredient(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      quantity: json['quantity'],
      unit: json['unit'],
      category: json['category'],
      amount: json['amount'] ?? '',
      inPantry: json['inPantry'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'quantity': quantity,
      'unit': unit,
      'category': category,
      'amount': amount,
      'inPantry': inPantry,
    };
  }
  
  // Added this method to create a copy with modified fields
  Ingredient copyWith({
    String? id,
    String? name,
    String? quantity,
    String? unit,
    String? category,
    String? amount,
    bool? inPantry,
  }) {
    return Ingredient(
      id: id ?? this.id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      inPantry: inPantry ?? this.inPantry,
    );
  }
}