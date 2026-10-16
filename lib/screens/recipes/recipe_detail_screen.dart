import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/gen/app_localizations.dart';
import '../../models/recipe.dart';
import '../../providers/providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/feedback.dart';
import '../../widgets/recipe_view.dart';

/// View a recipe the current user owns, with edit/delete/share/publish actions.
class RecipeDetailScreen extends ConsumerStatefulWidget {
  const RecipeDetailScreen({super.key, required this.recipeId});

  final String recipeId;

  @override
  ConsumerState<RecipeDetailScreen> createState() =>
      _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends ConsumerState<RecipeDetailScreen> {
  @override
  void initState() {
    super.initState();
    // Opening a recipe is a natural full-screen transition — a good moment for
    // an interstitial. The manager caps how often one actually shows.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(interstitialAdManagerProvider).maybeShowOnRecipeOpen();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final recipeId = widget.recipeId;
    final recipeAsync = ref.watch(recipeProvider(recipeId));
    final categories = ref.watch(userCategoriesProvider).value ?? const [];
    final categoriesById = {for (final c in categories) c.id: c};
    final uid = ref.watch(currentUidProvider);
    // Offline the recipe is still readable from cache, and edits save locally
    // and sync later — but sharing, deleting and publishing reach the network,
    // so those actions are hidden.
    final online = ref.watch(isOnlineProvider).value ?? true;

    return recipeAsync.when(
      // An app bar even while loading, so there's always a way back.
      loading: () => Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: ErrorState(
          error: e,
          onRetry: () => ref.invalidate(recipeProvider(recipeId)),
        ),
      ),
      data: (recipe) {
        if (recipe == null) {
          return Scaffold(
            appBar: AppBar(),
            body: EmptyState(
              icon: Icons.no_food_outlined,
              title: l10n.recipeNotFound,
            ),
          );
        }
        final isOwner = recipe.userId == uid;
        return Scaffold(
          appBar: AppBar(
            title: const Text(''),
            actions: [
              // Editing is the thing owners do most, so it isn't tucked away
              // in the overflow menu.
              if (isOwner)
                IconButton(
                  tooltip: l10n.menuEdit,
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => context.push('/recipes/${recipe.id}/edit'),
                ),
              if (online)
                IconButton(
                  tooltip: l10n.tooltipShare,
                  icon: const Icon(Icons.share_outlined),
                  onPressed: () => _share(recipe),
                ),
              if (isOwner && online)
                PopupMenuButton<String>(
                  tooltip: l10n.tooltipMore,
                  onSelected: (v) => _onMenu(recipe, v),
                  itemBuilder: (context) => [
                    recipe.isPublic
                        ? _menuItem(
                            'public', Icons.lock_outline, l10n.menuMakePrivate)
                        : _menuItem(
                            'public', Icons.public, l10n.menuMakePublic),
                    _menuItem('delete', Icons.delete_outline, l10n.menuDelete,
                        color: AppColors.danger),
                  ],
                ),
            ],
          ),
          body: RecipeView(recipe: recipe, categoriesById: categoriesById),
        );
      },
    );
  }

  PopupMenuItem<String> _menuItem(
    String value,
    IconData icon,
    String label, {
    Color? color,
  }) {
    return PopupMenuItem(
      value: value,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(icon, color: color ?? AppColors.textMuted),
        title: Text(label, style: TextStyle(color: color)),
      ),
    );
  }

  Future<void> _share(Recipe recipe) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final code =
          await ref.read(recipeRepositoryProvider).ensureShareCode(recipe);
      await ref.read(shareServiceProvider).shareRecipe(recipe, code);
    } catch (e) {
      messenger.showSnackBar(
          SnackBar(content: Text(l10n.couldNotShare(friendlyError(l10n, e)))));
    }
  }

  Future<void> _onMenu(Recipe recipe, String value) async {
    switch (value) {
      case 'public':
        await _togglePublic(recipe);
      case 'delete':
        await _delete(recipe);
    }
  }

  Future<void> _togglePublic(Recipe recipe) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(recipeRepositoryProvider)
          .setPublic(recipe.id, !recipe.isPublic);
      messenger.showSnackBar(SnackBar(
        content: Text(
            recipe.isPublic ? l10n.recipeNowPrivate : l10n.recipeNowPublic),
      ));
    } catch (e) {
      messenger
          .showSnackBar(SnackBar(content: Text(friendlyError(l10n, e))));
    }
  }

  /// Deletes straight away and offers Undo, rather than asking first: the
  /// recipe can be put back exactly as it was (see
  /// [RecipeRepository.restoreRecipe]), so a confirmation would only slow
  /// down every deliberate delete.
  Future<void> _delete(Recipe recipe) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final repo = ref.read(recipeRepositoryProvider);
    // Leave first, so this screen doesn't flash "Recipe not found" as the
    // deletion lands.
    context.canPop() ? context.pop() : context.go('/recipes');
    try {
      await repo.deleteRecipe(recipe.id);
      showUndoSnackBar(
        messenger,
        message: l10n.recipeDeleted(recipe.title),
        onUndo: () async {
          try {
            await repo.restoreRecipe(recipe);
          } catch (e) {
            messenger
                .showSnackBar(SnackBar(content: Text(friendlyError(l10n, e))));
          }
        },
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(friendlyError(l10n, e))));
    }
  }
}
