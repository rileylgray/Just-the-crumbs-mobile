import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/gen/app_localizations.dart';
import '../../models/category.dart';
import '../../providers/providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/empty_state.dart';

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final categoriesAsync = ref.watch(userCategoriesProvider);
    final recipes = ref.watch(userRecipesProvider).value ?? const [];
    return Scaffold(
      appBar: AppBar(title: Text(l10n.categoriesTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/categories/new'),
        icon: const Icon(Icons.add),
        label: Text(l10n.newCategoryButton),
      ),
      body: categoriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EmptyState(
          icon: Icons.error_outline,
          title: l10n.errorWithMessage(e.toString()),
        ),
        data: (categories) {
          if (categories.isEmpty) {
            return EmptyState.fromText(
              l10n.categoriesEmpty,
              icon: Icons.label_outline,
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 90),
            itemCount: categories.length,
            separatorBuilder: (_, _) => const SizedBox(height: 4),
            itemBuilder: (context, i) => _CategoryTile(
              category: categories[i],
              recipeCount: recipes
                  .where((r) => r.categoryIds.contains(categories[i].id))
                  .length,
            ),
          );
        },
      ),
    );
  }
}

class _CategoryTile extends ConsumerWidget {
  const _CategoryTile({required this.category, required this.recipeCount});
  final Category category;
  final int recipeCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final color = category.colorValue;
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        contentPadding: const EdgeInsets.only(left: 16, right: 4),
        onTap: () => context.push('/categories/${category.id}/edit'),
        leading: CircleAvatar(
          backgroundColor: color,
          radius: 18,
          child: Icon(Icons.label, size: 18, color: AppColors.onColor(color)),
        ),
        title: Text(category.name,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          l10n.profileRecipeCount(recipeCount),
          style: const TextStyle(color: AppColors.textMuted),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: l10n.menuEdit,
              icon: const Icon(Icons.edit_outlined, color: AppColors.textMuted),
              onPressed: () => context.push('/categories/${category.id}/edit'),
            ),
            IconButton(
              tooltip: l10n.actionDelete,
              icon:
                  const Icon(Icons.delete_outline, color: AppColors.textMuted),
              onPressed: () => _confirmDelete(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.deleteCategoryTitle(category.name)),
        content: Text(l10n.deleteCategoryBody),
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
      await ref.read(categoryRepositoryProvider).deleteCategory(category.id);
    }
  }
}
