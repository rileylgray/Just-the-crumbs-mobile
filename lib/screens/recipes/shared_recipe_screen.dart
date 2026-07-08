import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
    final recipeAsync = ref.watch(sharedRecipeProvider(code));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shared recipe'),
        backgroundColor: AppColors.surface,
      ),
      body: recipeAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (recipe) {
          if (recipe == null) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'That share code doesn’t exist.\nDouble-check it and try again.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textMuted),
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
                  label: const Text('Copy to my recipes'),
                ),
              ),
            ),
    );
  }

  Future<void> _copy(BuildContext context, WidgetRef ref, Recipe recipe) async {
    final uid = ref.read(currentUidProvider);
    if (uid == null) return;
    final authorName = ref.read(currentAuthorNameProvider);
    final id = await ref
        .read(recipeRepositoryProvider)
        .copyRecipe(source: recipe, uid: uid, authorName: authorName);
    if (context.mounted) {
      context.pushReplacement('/recipes/$id');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Copied to your recipes')),
      );
    }
  }
}
