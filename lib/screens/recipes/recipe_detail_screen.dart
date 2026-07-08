import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/gen/app_localizations.dart';
import '../../models/recipe.dart';
import '../../providers/providers.dart';
import '../../theme/app_theme.dart';
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

    return recipeAsync.when(
      loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(l10n.errorWithMessage(e.toString()))),
      ),
      data: (recipe) {
        if (recipe == null) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(child: Text(l10n.recipeNotFound)),
          );
        }
        final isOwner = recipe.userId == uid;
        return Scaffold(
          appBar: AppBar(
            title: const Text(''),
            actions: [
              IconButton(
                tooltip: l10n.tooltipShare,
                icon: const Icon(Icons.share_outlined),
                onPressed: () => _share(context, ref, recipe),
              ),
              if (isOwner)
                PopupMenuButton<String>(
                  onSelected: (v) => _onMenu(context, ref, recipe, v),
                  itemBuilder: (context) => [
                    PopupMenuItem(value: 'edit', child: Text(l10n.menuEdit)),
                    PopupMenuItem(
                      value: 'public',
                      child: Text(recipe.isPublic
                          ? l10n.menuMakePrivate
                          : l10n.menuMakePublic),
                    ),
                    PopupMenuItem(value: 'delete', child: Text(l10n.menuDelete)),
                  ],
                ),
            ],
          ),
          body: RecipeView(recipe: recipe, categoriesById: categoriesById),
        );
      },
    );
  }

  Future<void> _share(BuildContext context, WidgetRef ref, Recipe recipe) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final code = await ref.read(recipeRepositoryProvider).ensureShareCode(recipe);
      await ref.read(shareServiceProvider).shareRecipe(recipe, code);
    } catch (e) {
      messenger.showSnackBar(
          SnackBar(content: Text(l10n.couldNotShare(e.toString()))));
    }
  }

  Future<void> _onMenu(
      BuildContext context, WidgetRef ref, Recipe recipe, String value) async {
    final l10n = AppLocalizations.of(context);
    final repo = ref.read(recipeRepositoryProvider);
    switch (value) {
      case 'edit':
        context.push('/recipes/${recipe.id}/edit');
      case 'public':
        await repo.setPublic(recipe.id, !recipe.isPublic);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(recipe.isPublic
                ? l10n.recipeNowPrivate
                : l10n.recipeNowPublic),
          ));
        }
      case 'delete':
        final confirm = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(l10n.deleteRecipeTitle),
            content: Text(l10n.deleteRecipeBody),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(l10n.actionCancel),
              ),
              TextButton(
                style: TextButton.styleFrom(foregroundColor: AppColors.danger),
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(l10n.actionDelete),
              ),
            ],
          ),
        );
        if (confirm == true) {
          await repo.deleteRecipe(recipe.id);
          if (context.mounted) context.pop();
        }
    }
  }
}
