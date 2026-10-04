import 'package:flutter/material.dart';

import '../models/category.dart';
import '../theme/app_theme.dart';

/// A small colored pill representing a category.
class CategoryChip extends StatelessWidget {
  const CategoryChip({
    super.key,
    required this.category,
    this.selected = false,
    this.dense = false,
    this.onTap,
  });

  final Category category;
  final bool selected;

  /// Smaller text and padding, for recipe cards.
  final bool dense;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = category.colorValue;
    return Material(
      color: selected ? color : color.withValues(alpha: 0.16),
      shape: const StadiumBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: dense ? 10 : 12,
            vertical: dense ? 4 : 6,
          ),
          child: Text(
            category.name,
            style: TextStyle(
              color: selected ? AppColors.onColor(color) : AppColors.ink(color),
              fontWeight: FontWeight.w600,
              fontSize: dense ? 12 : 13,
            ),
          ),
        ),
      ),
    );
  }
}
