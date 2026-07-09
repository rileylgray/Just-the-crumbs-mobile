import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/gen/app_localizations.dart';
import '../../models/category.dart';
import '../../models/recipe.dart';
import '../../providers/providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/recipe_card.dart';

class RecipesListScreen extends ConsumerStatefulWidget {
  const RecipesListScreen({super.key});

  @override
  ConsumerState<RecipesListScreen> createState() => _RecipesListScreenState();
}

class _RecipesListScreenState extends ConsumerState<RecipesListScreen> {
  String _search = '';
  String? _selectedCategoryId;

  bool get _filtering => _search.isNotEmpty || _selectedCategoryId != null;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final recipesAsync = ref.watch(userRecipesProvider);
    final categories = ref.watch(userCategoriesProvider).value ?? const [];
    final categoriesById = {for (final c in categories) c.id: c};
    // Offline: recipes stay viewable from Firestore's cache, but adding,
    // importing and reordering all need the network — so drop those affordances.
    final online = ref.watch(isOnlineProvider).value ?? true;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: [
          IconButton(
            tooltip: l10n.categoriesTitle,
            icon: const Icon(Icons.label_outline),
            onPressed: () => context.push('/categories'),
          ),
        ],
      ),
      floatingActionButton: online
          ? FloatingActionButton.extended(
              onPressed: _showAddSheet,
              icon: const Icon(Icons.add),
              label: Text(l10n.recipesAddRecipe),
            )
          : null,
      body: Column(
        children: [
          if (!online) const _OfflineBanner(),
          _SearchBar(onChanged: (v) => setState(() => _search = v)),
          if (categories.isNotEmpty)
            _CategoryFilterBar(
              categories: categories,
              selectedId: _selectedCategoryId,
              onSelected: (id) => setState(() => _selectedCategoryId = id),
            ),
          Expanded(
            child: recipesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) =>
                  Center(child: Text(l10n.errorWithMessage(e.toString()))),
              data: (recipes) {
                final filtered = _applyFilters(recipes);
                if (filtered.isEmpty) {
                  return _EmptyState(filtering: _filtering);
                }
                return (_filtering || !online)
                    ? _plainList(filtered, categoriesById)
                    : _reorderableList(filtered, categoriesById);
              },
            ),
          ),
        ],
      ),
    );
  }

  List<Recipe> _applyFilters(List<Recipe> recipes) {
    return recipes.where((r) {
      final matchesSearch = _search.isEmpty ||
          r.title.toLowerCase().contains(_search.toLowerCase());
      final matchesCategory = _selectedCategoryId == null ||
          r.categoryIds.contains(_selectedCategoryId);
      return matchesSearch && matchesCategory;
    }).toList();
  }

  Widget _plainList(List<Recipe> recipes, Map<String, Category> cats) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 96),
      itemCount: recipes.length,
      itemBuilder: (context, i) => RecipeCard(
        recipe: recipes[i],
        categoriesById: cats,
        onTap: () => context.push('/recipes/${recipes[i].id}'),
      ),
    );
  }

  Widget _reorderableList(List<Recipe> recipes, Map<String, Category> cats) {
    return ReorderableListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 96),
      itemCount: recipes.length,
      onReorder: (oldIndex, newIndex) async {
        final reordered = List<Recipe>.of(recipes);
        if (newIndex > oldIndex) newIndex -= 1;
        final item = reordered.removeAt(oldIndex);
        reordered.insert(newIndex, item);
        await ref.read(recipeRepositoryProvider).persistOrder(reordered);
      },
      itemBuilder: (context, i) => Padding(
        key: ValueKey(recipes[i].id),
        padding: EdgeInsets.zero,
        child: RecipeCard(
          recipe: recipes[i],
          categoriesById: cats,
          onTap: () => context.push('/recipes/${recipes[i].id}'),
          trailing: ReorderableDragStartListener(
            index: i,
            child: Padding(
              padding: const EdgeInsets.only(left: 8, top: 4),
              child: Icon(Icons.drag_handle, color: Colors.grey.shade400),
            ),
          ),
        ),
      ),
    );
  }

  void _showAddSheet() {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_note, color: AppColors.primary),
              title: Text(l10n.addSheetCreateTitle),
              subtitle: Text(l10n.addSheetCreateSubtitle),
              onTap: () {
                Navigator.pop(sheetContext);
                context.push('/recipes/new');
              },
            ),
            ListTile(
              leading: const Icon(Icons.link, color: AppColors.primary),
              title: Text(l10n.addSheetImportTitle),
              subtitle: Text(l10n.addSheetImportSubtitle),
              onTap: () {
                Navigator.pop(sheetContext);
                context.push('/recipes/import');
              },
            ),
            ListTile(
              leading: const Icon(Icons.qr_code, color: AppColors.primary),
              title: Text(l10n.addSheetCodeTitle),
              subtitle: Text(l10n.addSheetCodeSubtitle),
              onTap: () {
                Navigator.pop(sheetContext);
                _showCodeDialog();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showCodeDialog() async {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController();
    final code = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.shareCodeDialogTitle),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          decoration: InputDecoration(
            hintText: l10n.shareCodeHint,
            prefixIcon: const Icon(Icons.tag),
          ),
          onSubmitted: (v) => Navigator.pop(dialogContext, v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.actionCancel),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            child: Text(l10n.actionOpen),
          ),
        ],
      ),
    );
    if (code != null && code.isNotEmpty && mounted) {
      context.push('/share/${code.toUpperCase()}');
    }
  }
}

/// A slim bar shown above the recipe list while the device is offline, making
/// it clear the list is cached and that adding/editing is paused.
class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Material(
      color: AppColors.primary.withValues(alpha: 0.12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            const Icon(Icons.cloud_off, size: 18, color: AppColors.textMuted),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l10n.offlineBanner,
                style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.onChanged});
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: TextField(
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: AppLocalizations.of(context).recipesSearch,
          prefixIcon: const Icon(Icons.search),
          isDense: true,
        ),
      ),
    );
  }
}

class _CategoryFilterBar extends StatelessWidget {
  const _CategoryFilterBar({
    required this.categories,
    required this.selectedId,
    required this.onSelected,
  });

  final List<Category> categories;
  final String? selectedId;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8, top: 6, bottom: 6),
            child: ChoiceChip(
              label: Text(AppLocalizations.of(context).filterAll),
              selected: selectedId == null,
              onSelected: (_) => onSelected(null),
            ),
          ),
          for (final c in categories)
            Padding(
              padding: const EdgeInsets.only(right: 8, top: 6, bottom: 6),
              child: ChoiceChip(
                label: Text(c.name),
                selected: selectedId == c.id,
                selectedColor: c.colorValue.withValues(alpha: 0.3),
                onSelected: (_) =>
                    onSelected(selectedId == c.id ? null : c.id),
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.filtering});
  final bool filtering;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🥐', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            Text(
              filtering ? l10n.recipesEmptyNoMatchTitle : l10n.recipesEmptyTitle,
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              filtering ? l10n.recipesEmptyNoMatchBody : l10n.recipesEmptyBody,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
