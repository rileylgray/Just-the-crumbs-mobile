import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../models/category.dart';
import '../models/recipe.dart';
import '../providers/locale_provider.dart';
import '../theme/app_theme.dart';
import 'category_chip.dart';

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
    const metaStyle = TextStyle(fontSize: 12, color: AppColors.textMuted);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.fromLTRB(14, 14, trailing == null ? 14 : 4, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Monogram(
                title: recipe.title,
                color: chips.isEmpty ? AppColors.primary : chips.first.colorValue,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            recipe.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.text,
                              height: 1.25,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (recipe.isPublic)
                          const Padding(
                            padding: EdgeInsets.only(left: 6, top: 2),
                            child: Icon(Icons.public,
                                size: 16, color: AppColors.primaryDeep),
                          ),
                      ],
                    ),
                    if (recipe.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        recipe.description,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.restaurant_menu,
                            size: 14, color: AppColors.textMuted),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            l10n.ingredientsStepsSeparator(
                              l10n.ingredientsCount(recipe.ingredients.length),
                              l10n.stepsCount(recipe.steps.length),
                            ),
                            style: metaStyle,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (showLikes) ...[
                          const SizedBox(width: 10),
                          const Icon(Icons.favorite,
                              size: 13, color: AppColors.primaryDeep),
                          const SizedBox(width: 3),
                          Text('${recipe.likeCount}', style: metaStyle),
                        ],
                      ],
                    ),
                    if (showAuthor || showLanguage) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          if (showAuthor)
                            Flexible(
                              child: Text(
                                l10n.recipeByAuthor(recipe.authorName),
                                style: metaStyle,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          if (showAuthor && showLanguage)
                            const SizedBox(width: 8),
                          if (showLanguage)
                            _LanguageBadge(code: recipe.language),
                        ],
                      ),
                    ],
                    if (chips.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final c in chips)
                            CategoryChip(category: c, dense: true),
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

/// A rounded tile with the recipe's first letter, tinted with its first
/// category's color — a visual anchor for each row, since recipes have no
/// photos.
class _Monogram extends StatelessWidget {
  const _Monogram({required this.title, required this.color});

  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final trimmed = title.trim();
    final letter =
        trimmed.isEmpty ? '🥐' : trimmed.characters.first.toUpperCase();
    return Container(
      width: 46,
      height: 46,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        letter,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: AppColors.ink(color),
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
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.translate, size: 11, color: AppColors.primaryDeep),
          const SizedBox(width: 4),
          Text(
            languageDisplayName(code),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryDeep,
            ),
          ),
        ],
      ),
    );
  }
}
