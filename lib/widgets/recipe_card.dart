import 'package:flutter/material.dart';

import '../models/category.dart';
import '../models/recipe.dart';
import '../theme/app_theme.dart';

/// Summary card for a recipe in a list.
class RecipeCard extends StatelessWidget {
  const RecipeCard({
    super.key,
    required this.recipe,
    required this.onTap,
    this.categoriesById = const {},
    this.showAuthor = false,
    this.trailing,
  });

  final Recipe recipe;
  final VoidCallback onTap;
  final Map<String, Category> categoriesById;
  final bool showAuthor;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final chips = recipe.categoryIds
        .map((id) => categoriesById[id])
        .whereType<Category>()
        .toList();

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            recipe.title,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: AppColors.text,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (recipe.isPublic)
                          const Padding(
                            padding: EdgeInsets.only(left: 6),
                            child: Icon(Icons.public,
                                size: 16, color: AppColors.primary),
                          ),
                      ],
                    ),
                    if (recipe.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        recipe.description,
                        style: const TextStyle(color: AppColors.textMuted),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.restaurant_menu,
                            size: 14, color: Colors.grey.shade400),
                        const SizedBox(width: 4),
                        Text(
                          '${recipe.ingredients.length} ingredients · ${recipe.steps.length} steps',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                    if (showAuthor) ...[
                      const SizedBox(height: 4),
                      Text('by ${recipe.authorName}',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade500)),
                    ],
                    if (chips.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final c in chips)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: c.colorValue.withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                c.name,
                                style: TextStyle(
                                  color: c.colorValue,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
        ),
      ),
    );
  }
}
