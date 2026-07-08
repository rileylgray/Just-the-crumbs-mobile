import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/gen/app_localizations.dart';
import '../../models/recipe.dart';
import '../../providers/locale_provider.dart';
import '../../providers/providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/recipe_card.dart';
import '../../widgets/recipe_moderation.dart';

class PublicFeedScreen extends ConsumerStatefulWidget {
  const PublicFeedScreen({super.key});

  @override
  ConsumerState<PublicFeedScreen> createState() => _PublicFeedScreenState();
}

class _PublicFeedScreenState extends ConsumerState<PublicFeedScreen> {
  String _search = '';

  // Language filter. Null means "all languages". Until the user picks a chip,
  // the feed defaults to the viewer's UI language (see [_effectiveLanguage]).
  String? _languageFilter;
  bool _userChoseLanguage = false;

  /// The language actually applied: the user's explicit choice once made,
  /// otherwise the viewer's UI language when the feed has recipes in it, else
  /// "all" — so the feed is never empty just because nobody posted in the
  /// viewer's language yet.
  String? _effectiveLanguage(List<String> available) {
    if (_userChoseLanguage) return _languageFilter;
    final viewerLang = ref.read(localeControllerProvider).languageCode;
    return available.contains(viewerLang) ? viewerLang : null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final recipesAsync = ref.watch(visiblePublicRecipesProvider);
    final allRecipes = recipesAsync.value ?? const <Recipe>[];

    // Distinct languages present in the feed, for the filter chips.
    final availableLanguages = allRecipes.map((r) => r.language).toSet().toList()
      ..sort();
    final effectiveLanguage = _effectiveLanguage(availableLanguages);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.discoverTitle),
        actions: [
          IconButton(
            tooltip: l10n.surpriseMe,
            icon: const Icon(Icons.casino_outlined),
            onPressed: () {
              // Surprise from what's actually shown (respects the filters).
              final shown = _applyFilters(allRecipes, effectiveLanguage);
              if (shown.isEmpty) return;
              final r = shown[Random().nextInt(shown.length)];
              context.push('/public/${r.id}');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              decoration: InputDecoration(
                hintText: l10n.discoverSearch,
                prefixIcon: const Icon(Icons.search),
                isDense: true,
              ),
            ),
          ),
          if (availableLanguages.length > 1)
            _LanguageFilterBar(
              languages: availableLanguages,
              selected: effectiveLanguage,
              onSelected: (code) => setState(() {
                _userChoseLanguage = true;
                _languageFilter = code;
              }),
            ),
          Expanded(
            child: recipesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) =>
                  Center(child: Text(l10n.errorWithMessage(e.toString()))),
              data: (recipes) {
                final filtered = _applyFilters(recipes, effectiveLanguage);
                if (filtered.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        l10n.discoverEmpty,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.textMuted),
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                  itemCount: filtered.length,
                  itemBuilder: (context, i) => RecipeCard(
                    recipe: filtered[i],
                    showAuthor: true,
                    showLanguage: true,
                    onTap: () => context.push('/public/${filtered[i].id}'),
                    trailing: RecipeModerationMenu(recipe: filtered[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<Recipe> _applyFilters(List<Recipe> recipes, String? language) {
    return recipes.where((r) {
      final matchesLanguage = language == null || r.language == language;
      final matchesSearch = _search.isEmpty ||
          r.title.toLowerCase().contains(_search.toLowerCase());
      return matchesLanguage && matchesSearch;
    }).toList();
  }
}

/// Horizontal chip bar to filter the Discover feed by content language.
/// Mirrors the category filter bar on the personal recipe list.
class _LanguageFilterBar extends StatelessWidget {
  const _LanguageFilterBar({
    required this.languages,
    required this.selected,
    required this.onSelected,
  });

  final List<String> languages;
  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8, top: 6, bottom: 6),
            child: ChoiceChip(
              label: Text(l10n.filterAllLanguages),
              selected: selected == null,
              onSelected: (_) => onSelected(null),
            ),
          ),
          for (final code in languages)
            Padding(
              padding: const EdgeInsets.only(right: 8, top: 6, bottom: 6),
              child: ChoiceChip(
                label: Text(languageDisplayName(code)),
                selected: selected == code,
                onSelected: (_) => onSelected(code),
              ),
            ),
        ],
      ),
    );
  }
}
