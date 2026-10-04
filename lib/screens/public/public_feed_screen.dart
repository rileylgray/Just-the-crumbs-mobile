import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/gen/app_localizations.dart';
import '../../models/recipe.dart';
import '../../providers/locale_provider.dart';
import '../../providers/providers.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/recipe_card.dart';
import '../../widgets/recipe_moderation.dart';
import '../../widgets/search_field.dart';

class PublicFeedScreen extends ConsumerStatefulWidget {
  const PublicFeedScreen({super.key});

  @override
  ConsumerState<PublicFeedScreen> createState() => _PublicFeedScreenState();
}

class _PublicFeedScreenState extends ConsumerState<PublicFeedScreen> {
  final _searchController = TextEditingController();
  String _search = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// The language actually applied: the viewer's persisted choice once made
  /// (see [contentLanguageProvider]), otherwise the viewer's UI language when
  /// the feed has recipes in it, else "all" — so the feed is never empty just
  /// because nobody posted in the viewer's language yet.
  String? _effectiveLanguage(
    ContentLanguagePref pref,
    List<String> available,
  ) {
    if (pref.chosen) return pref.language;
    final viewerLang = ref.read(localeControllerProvider).languageCode;
    return available.contains(viewerLang) ? viewerLang : null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final recipesAsync = ref.watch(visiblePublicRecipesProvider);
    final allRecipes = recipesAsync.value ?? const <Recipe>[];
    final languagePref = ref.watch(contentLanguageProvider);

    // Distinct languages present in the feed, for the filter chips.
    final availableLanguages = allRecipes.map((r) => r.language).toSet().toList()
      ..sort();
    final effectiveLanguage =
        _effectiveLanguage(languagePref, availableLanguages);

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
              HapticFeedback.lightImpact();
              final r = shown[Random().nextInt(shown.length)];
              context.push('/public/${r.id}');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          SearchField(
            controller: _searchController,
            hintText: l10n.discoverSearch,
            onChanged: (v) => setState(() => _search = v),
          ),
          if (availableLanguages.isNotEmpty)
            _LanguageFilterBar(
              languages: availableLanguages,
              selected: effectiveLanguage,
              onSelected: (code) =>
                  ref.read(contentLanguageProvider.notifier).setLanguage(code),
            ),
          Expanded(
            child: recipesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => EmptyState(
                icon: Icons.error_outline,
                title: l10n.errorWithMessage(e.toString()),
              ),
              data: (recipes) {
                final filtered = _applyFilters(recipes, effectiveLanguage);
                if (filtered.isEmpty) {
                  return _emptyState(l10n, recipes.isEmpty, effectiveLanguage);
                }
                return ListView.builder(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                  itemCount: filtered.length,
                  itemBuilder: (context, i) => RecipeCard(
                    recipe: filtered[i],
                    showAuthor: true,
                    showLanguage: true,
                    showLikes: true,
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
      return matchesLanguage && r.matchesSearch(_search);
    }).toList();
  }

  /// Nothing to show. When the feed has recipes and only the filters hide
  /// them, offer a one-tap way back to a full feed instead of a dead end.
  Widget _emptyState(
    AppLocalizations l10n,
    bool feedEmpty,
    String? language,
  ) {
    if (feedEmpty) {
      return EmptyState.fromText(l10n.discoverEmpty, icon: Icons.public);
    }
    final searching = _search.trim().isNotEmpty;
    return EmptyState(
      icon: Icons.search_off,
      title: l10n.recipesEmptyNoMatchTitle,
      action: OutlinedButton.icon(
        onPressed: () {
          _searchController.clear();
          setState(() => _search = '');
          if (language != null) {
            ref.read(contentLanguageProvider.notifier).setLanguage(null);
          }
        },
        icon: Icon(searching ? Icons.filter_alt_off_outlined : Icons.translate),
        label: Text(searching ? l10n.clearFilters : l10n.filterAllLanguages),
      ),
    );
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
