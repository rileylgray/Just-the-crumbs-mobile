import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../models/category.dart';
import '../models/recipe.dart';
import '../providers/locale_provider.dart';
import '../theme/app_theme.dart';

/// Summary card for a recipe in a list.
class RecipeCard extends StatelessWidget {
  const RecipeCard({
    super.key,
    required this.recipe,
    required this.onTap,
    this.categoriesById = const {},
    this.showAuthor = false,
    this.showLanguage = false,
    this.showLikes = false,
    this.trailing,
  });

  final Recipe recipe;
  final VoidCallback onTap;
  final Map<String, Category> categoriesById;
  final bool showAuthor;

  /// Show a small badge with the recipe's content language (used in the
  /// public Discover feed, where recipes span many languages).
  final bool showLanguage;

  /// Show the recipe's like count (used in the public Discover feed, which is
  /// sorted by likes).
  final bool showLikes;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
                        Flexible(
                          child: Text(
                            l10n.ingredientsStepsSeparator(
                              l10n.ingredientsCount(recipe.ingredients.length),
                              l10n.stepsCount(recipe.steps.length),
                            ),
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade500),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (showLanguage) ...[
                          const SizedBox(width: 8),
                          _LanguageBadge(code: recipe.language),
                        ],
                        if (showLikes) ...[
                          const SizedBox(width: 8),
                          Icon(Icons.favorite,
                              size: 13, color: AppColors.primary),
                          const SizedBox(width: 3),
                          Text(
                            '${recipe.likeCount}',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ],
                      ],
                    ),
                    if (showAuthor) ...[
                      const SizedBox(height: 4),
                      Text(l10n.recipeByAuthor(recipe.authorName),
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

/// A small pill showing a recipe's content language (e.g. "Español", "JA").
class _LanguageBadge extends StatelessWidget {
  const _LanguageBadge({required this.code});
  final String code;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.translate, size: 11, color: AppColors.primaryDark),
          const SizedBox(width: 4),
          Text(
            languageDisplayName(code),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryDark,
            ),
          ),
        ],
      ),
    );
  }
}
