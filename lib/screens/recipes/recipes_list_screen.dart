import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/gen/app_localizations.dart';
import '../../models/category.dart';
import '../../models/recipe.dart';
import '../../providers/providers.dart';
import '../../services/import/shared_link.dart';
import '../../theme/app_theme.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/offline_banner.dart';
import '../../widgets/recipe_card.dart';
import '../../widgets/search_field.dart';

class RecipesListScreen extends ConsumerStatefulWidget {
  const RecipesListScreen({super.key});

  @override
  ConsumerState<RecipesListScreen> createState() => _RecipesListScreenState();
}

class _RecipesListScreenState extends ConsumerState<RecipesListScreen> {
  final _searchController = TextEditingController();
  String _search = '';
  String? _selectedCategoryId;

  bool get _filtering =>
      _search.trim().isNotEmpty || _selectedCategoryId != null;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearFilters() {
    _searchController.clear();
    setState(() {
      _search = '';
      _selectedCategoryId = null;
    });
  }

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
          if (!online) const OfflineBanner(),
          SearchField(
            controller: _searchController,
            hintText: l10n.recipesSearch,
            onChanged: (v) => setState(() => _search = v),
          ),
          if (categories.isNotEmpty)
            _CategoryFilterBar(
              categories: categories,
              selectedId: _selectedCategoryId,
              onSelected: (id) => setState(() => _selectedCategoryId = id),
            ),
          Expanded(
            child: recipesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => EmptyState(
                icon: Icons.error_outline,
                title: l10n.errorWithMessage(e.toString()),
              ),
              data: (recipes) {
                final filtered = _applyFilters(recipes);
                if (filtered.isEmpty) return _emptyState(l10n, online);
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
      final matchesCategory =
          _selectedCategoryId == null ||
          r.categoryIds.contains(_selectedCategoryId);
      return matchesCategory && r.matchesSearch(_search);
    }).toList();
  }

  /// Nothing to show: either no recipes at all (offer to add one) or none that
  /// match the search/category (offer to reset those).
  Widget _emptyState(AppLocalizations l10n, bool online) {
    if (_filtering) {
      return EmptyState(
        icon: Icons.search_off,
        title: l10n.recipesEmptyNoMatchTitle,
        message: l10n.recipesEmptyNoMatchBody,
        action: OutlinedButton.icon(
          onPressed: _clearFilters,
          icon: const Icon(Icons.filter_alt_off_outlined),
          label: Text(l10n.clearFilters),
        ),
      );
    }
    return EmptyState(
      emoji: '🥐',
      title: l10n.recipesEmptyTitle,
      message: online ? l10n.recipesEmptyBody : null,
      action: online
          ? FilledButton.icon(
              onPressed: _showAddSheet,
              icon: const Icon(Icons.add),
              label: Text(l10n.recipesAddRecipe),
            )
          : null,
    );
  }

  Widget _plainList(List<Recipe> recipes, Map<String, Category> cats) {
    return ListView.builder(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 96),
      itemCount: recipes.length,
      onReorderStart: (_) => HapticFeedback.mediumImpact(),
      // Lift the dragged card with a soft shadow that follows its rounded
      // corners, rather than the default square-cornered elevation.
      proxyDecorator: (child, index, animation) => AnimatedBuilder(
        animation: animation,
        builder: (context, child) => Material(
          color: Colors.transparent,
          elevation: Tween<double>(begin: 0, end: 8).evaluate(
            CurvedAnimation(parent: animation, curve: Curves.easeOut),
          ),
          shadowColor: Colors.black38,
          borderRadius: BorderRadius.circular(16),
          child: child,
        ),
        child: child,
      ),
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
            child: const Padding(
              padding: EdgeInsets.fromLTRB(8, 10, 10, 10),
              child: Icon(Icons.drag_indicator, color: AppColors.inputBorder),
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Text(
                l10n.addSheetTitle,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                ),
              ),
            ),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 24),
              leading: const _SheetIcon(Icons.edit_note),
              title: Text(l10n.addSheetCreateTitle),
              subtitle: Text(l10n.addSheetCreateSubtitle),
              onTap: () {
                Navigator.pop(sheetContext);
                context.push('/recipes/new');
              },
            ),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 24),
              leading: const _SheetIcon(Icons.link),
              title: Text(l10n.addSheetImportTitle),
              subtitle: Text(l10n.addSheetImportSubtitle),
              onTap: () {
                Navigator.pop(sheetContext);
                context.push('/recipes/import');
              },
            ),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 24),
              leading: const _SheetIcon(Icons.tag),
              title: Text(l10n.addSheetCodeTitle),
              subtitle: Text(l10n.addSheetCodeSubtitle),
              onTap: () {
                Navigator.pop(sheetContext);
                _showCodeDialog();
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Future<void> _showCodeDialog() async {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController();
    final input = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.shareCodeDialogTitle),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          autocorrect: false,
          decoration: InputDecoration(
            hintText: l10n.shareCodeHint,
            prefixIcon: const Icon(Icons.tag),
            // Pasting the whole share message (or the link) works too: the
            // code is picked out of it.
            suffixIcon: IconButton(
              tooltip: l10n.actionPaste,
              icon: const Icon(Icons.content_paste),
              onPressed: () async {
                final data = await Clipboard.getData(Clipboard.kTextPlain);
                final text = data?.text;
                if (text == null || text.trim().isEmpty) return;
                controller.text = shareCodeIn(text) ?? text.trim();
              },
            ),
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
    if (input == null || input.isEmpty || !mounted) return;
    final code = shareCodeIn(input) ?? input.toUpperCase();
    context.push('/share/${Uri.encodeComponent(code)}');
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
                avatar: CircleAvatar(backgroundColor: c.colorValue, radius: 5),
                label: Text(c.name),
                selected: selectedId == c.id,
                selectedColor: c.colorValue.withValues(alpha: 0.25),
                onSelected: (_) => onSelected(selectedId == c.id ? null : c.id),
              ),
            ),
        ],
      ),
    );
  }
}

/// A brand-tinted circular badge for an option in the add-recipe sheet.
class _SheetIcon extends StatelessWidget {
  const _SheetIcon(this.icon);
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: const BoxDecoration(
        color: AppColors.primarySoft,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: AppColors.primaryDeep, size: 22),
    );
  }
}
