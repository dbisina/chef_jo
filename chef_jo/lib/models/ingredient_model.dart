// models/ingredient_model.dart
class Ingredient {
  final String name;
  final String? quantity;
  final String? unit;
  final String? category;

  Ingredient({
    required this.name,
    this.quantity,
    this.unit,
    this.category,
  });

  factory Ingredient.fromJson(Map<String, dynamic> json) {
    return Ingredient(
      name: json['name'] ?? '',
      quantity: json['quantity'],
      unit: json['unit'],
      category: json['category'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'quantity': quantity,
      'unit': unit,
      'category': category,
    };
  }
}