import 'package:flutter/material.dart';

import '../models/category.dart';

/// A small colored chip representing a category.
class CategoryChip extends StatelessWidget {
  const CategoryChip({
    super.key,
    required this.category,
    this.selected = false,
    this.onTap,
  });

  final Category category;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = category.colorValue;
    final luminance = color.computeLuminance();
    final fg = luminance > 0.55 ? Colors.black87 : Colors.white;
    return Material(
      color: selected ? color : color.withValues(alpha: 0.16),
      shape: StadiumBorder(
        side: BorderSide(color: color, width: selected ? 0 : 1),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Text(
            category.name,
            style: TextStyle(
              color: selected ? fg : color,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
