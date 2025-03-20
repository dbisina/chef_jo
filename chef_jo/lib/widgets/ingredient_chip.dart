// widgets/ingredient_chip.dart
import 'package:flutter/material.dart';
import '../config/theme.dart';

class IngredientChip extends StatelessWidget {
  final String name;
  final VoidCallback? onDelete;
  final bool isSelected;
  final VoidCallback? onTap;

  const IngredientChip({
    Key? key,
    required this.name,
    this.onDelete,
    this.isSelected = false,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(right: 8, bottom: 8),
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? ChefJoTheme.primaryColor 
              : ChefJoTheme.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected 
                ? ChefJoTheme.primaryColor 
                : ChefJoTheme.primaryColor.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              name,
              style: TextStyle(
                color: isSelected 
                    ? Colors.white 
                    : ChefJoTheme.primaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (onDelete != null)
              SizedBox(width: 4),
            if (onDelete != null)
              InkWell(
                onTap: onDelete,
                child: Icon(
                  Icons.close,
                  size: 16,
                  color: isSelected 
                      ? Colors.white 
                      : ChefJoTheme.primaryColor,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
