import 'package:flutter/material.dart';

import '../models/category.dart';
import '../models/recipe.dart';
import '../theme/app_theme.dart';

/// Read-only rendering of a recipe's contents (title, meta, ingredients,
/// steps). Shared by the owner and public detail screens.
class RecipeView extends StatelessWidget {
  const RecipeView({
    super.key,
    required this.recipe,
    this.categoriesById = const {},
    this.footer,
  });

  final Recipe recipe;
  final Map<String, Category> categoriesById;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final chips = recipe.categoryIds
        .map((id) => categoriesById[id])
        .whereType<Category>()
        .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
      children: [
        Text(
          recipe.title,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'by ${recipe.authorName}',
          style: const TextStyle(color: AppColors.textMuted),
        ),
        if (chips.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final c in chips)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: c.colorValue.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(c.name,
                      style: TextStyle(
                          color: c.colorValue, fontWeight: FontWeight.w600)),
                ),
            ],
          ),
        ],
        if (recipe.description.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(recipe.description,
              style: const TextStyle(fontSize: 16, height: 1.4)),
        ],
        const SizedBox(height: 24),
        _sectionTitle('Ingredients'),
        const SizedBox(height: 8),
        ...recipe.ingredients.map(_ingredientRow),
        const SizedBox(height: 24),
        _sectionTitle('Steps'),
        const SizedBox(height: 8),
        ...List.generate(
          recipe.steps.length,
          (i) => _stepRow(i + 1, recipe.steps[i]),
        ),
        if (recipe.sourceUrl.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text('Source: ${recipe.sourceUrl}',
              style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
        ],
        ?footer,
      ],
    );
  }

  Widget _sectionTitle(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppColors.primaryDark,
        ),
      );

  Widget _ingredientRow(String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 6, right: 10),
              child: Icon(Icons.circle, size: 7, color: AppColors.primary),
            ),
            Expanded(
              child: Text(text, style: const TextStyle(fontSize: 16, height: 1.35)),
            ),
          ],
        ),
      );

  Widget _stepRow(int number, String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 26,
              height: 26,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: Text('$number',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 2),
                child:
                    Text(text, style: const TextStyle(fontSize: 16, height: 1.4)),
              ),
            ),
          ],
        ),
      );
}
