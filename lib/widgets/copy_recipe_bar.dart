import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../l10n/gen/app_localizations.dart';
import '../models/recipe.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';

/// Bottom bar with a "Copy to my recipes" button, shared by the public recipe
/// and shared-code screens.
///
/// The button disables itself while a copy is in flight: each tap writes a new
/// recipe, so a quick double tap would otherwise leave duplicate copies.
class CopyRecipeBar extends ConsumerStatefulWidget {
  const CopyRecipeBar({super.key, required this.recipe, this.replace = false});

  final Recipe recipe;

  /// Open the copy in place of the current screen rather than on top of it.
  final bool replace;

  @override
  ConsumerState<CopyRecipeBar> createState() => _CopyRecipeBarState();
}

class _CopyRecipeBarState extends ConsumerState<CopyRecipeBar> {
  bool _busy = false;

  Future<void> _copy() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final uid = ref.read(currentUidProvider);
    if (uid == null) return;
    setState(() => _busy = true);
    try {
      // Await the profile so a cold read doesn't fall back to 'Guest' for a
      // signed-in user.
      final profile = await ref.read(currentAppUserProvider.future);
      final authorName = profile?.name ?? 'Guest';
      final id = await ref
          .read(recipeRepositoryProvider)
          .copyRecipe(source: widget.recipe, uid: uid, authorName: authorName);
      if (!mounted) return;
      widget.replace
          ? context.pushReplacement('/recipes/$id')
          : context.push('/recipes/$id');
      messenger.showSnackBar(SnackBar(content: Text(l10n.copiedToRecipes)));
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.errorWithMessage(e.toString()))),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: ElevatedButton.icon(
            onPressed: _busy ? null : _copy,
            icon: _busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.bookmark_add_outlined),
            label: Text(AppLocalizations.of(context).copyToMyRecipes),
          ),
        ),
      ),
    );
  }
}
