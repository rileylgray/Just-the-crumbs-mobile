import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/gen/app_localizations.dart';
import '../../providers/providers.dart';
import '../../widgets/copy_recipe_bar.dart';
import '../../widgets/empty_state.dart';
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
    final recipe = recipeAsync.value;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.sharedRecipeTitle)),
      body: recipeAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EmptyState(
          icon: Icons.error_outline,
          title: l10n.errorWithMessage(e.toString()),
        ),
        data: (recipe) => recipe == null
            ? EmptyState.fromText(
                l10n.shareCodeNotFound,
                icon: Icons.link_off,
              )
            : RecipeView(recipe: recipe),
      ),
      bottomNavigationBar:
          recipe == null ? null : CopyRecipeBar(recipe: recipe, replace: true),
    );
  }
}
