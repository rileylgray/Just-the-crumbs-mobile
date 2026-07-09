import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/gen/app_localizations.dart';
import '../../models/recipe.dart';
import '../../providers/providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/recipe_view.dart';

/// Opens a recipe shared via a code (pasted in-app or from a
/// `justthecrumbs://share/<code>` deep link). Reads a self-contained snapshot,
/// so it works even for recipes that aren't public.
class SharedRecipeScreen extends ConsumerWidget {
  const SharedRecipeScreen({super.key, required this.code});

  final String code;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final recipeAsync = ref.watch(sharedRecipeProvider(code));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.sharedRecipeTitle),
        backgroundColor: AppColors.surface,
      ),
      body: recipeAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) =>
            Center(child: Text(l10n.errorWithMessage(e.toString()))),
        data: (recipe) {
          if (recipe == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  l10n.shareCodeNotFound,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textMuted),
                ),
              ),
            );
          }
          return RecipeView(recipe: recipe);
        },
      ),
      bottomNavigationBar: recipeAsync.value == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: ElevatedButton.icon(
                  onPressed: () => _copy(context, ref, recipeAsync.value!),
                  icon: const Icon(Icons.bookmark_add_outlined),
                  label: Text(l10n.copyToMyRecipes),
                ),
              ),
            ),
    );
  }

  Future<void> _copy(BuildContext context, WidgetRef ref, Recipe recipe) async {
    final l10n = AppLocalizations.of(context);
    final uid = ref.read(currentUidProvider);
    if (uid == null) return;
    // Await the profile so a cold read doesn't fall back to 'Guest' for a
    // signed-in user.
    final profile = await ref.read(currentAppUserProvider.future);
    final authorName = profile?.name ?? 'Guest';
    final id = await ref
        .read(recipeRepositoryProvider)
        .copyRecipe(source: recipe, uid: uid, authorName: authorName);
    if (context.mounted) {
      context.pushReplacement('/recipes/$id');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.copiedToRecipes)),
      );
    }
  }
}
