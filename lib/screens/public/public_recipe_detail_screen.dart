import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../l10n/gen/app_localizations.dart';
import '../../models/comment.dart';
import '../../models/recipe.dart';
import '../../providers/providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/recipe_moderation.dart';
import '../../widgets/recipe_view.dart';

/// Public recipe detail: read the recipe, copy it to your collection, and read
/// or add comments (including as a guest). Also the deep-link landing screen.
class PublicRecipeDetailScreen extends ConsumerWidget {
  const PublicRecipeDetailScreen({super.key, required this.recipeId});

  final String recipeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final recipeAsync = ref.watch(recipeProvider(recipeId));

    return recipeAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(l10n.errorWithMessage(e.toString()))),
      ),
      data: (recipe) {
        if (recipe == null || !recipe.isPublic) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(child: Text(l10n.recipeNotAvailable)),
          );
        }
        return Scaffold(
          appBar: AppBar(
            title: const Text(''),
            actions: [
              IconButton(
                tooltip: l10n.tooltipShare,
                icon: const Icon(Icons.share_outlined),
                onPressed: () => _share(context, ref, recipe),
              ),
              PopupMenuButton<String>(
                tooltip: l10n.tooltipMore,
                onSelected: (value) {
                  switch (value) {
                    case 'report':
                      reportRecipe(context, ref, recipe);
                    case 'block':
                      _blockAndLeave(context, ref, recipe);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'report',
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.flag_outlined),
                      title: Text(l10n.menuReport),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'block',
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.block),
                      title: Text(l10n.menuBlock),
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: RecipeView(
            recipe: recipe,
            footer: _CommentsSection(recipeId: recipe.id),
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: ElevatedButton.icon(
                onPressed: () => _copy(context, ref, recipe),
                icon: const Icon(Icons.bookmark_add_outlined),
                label: Text(l10n.copyToMyRecipes),
              ),
            ),
          ),
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

  Future<void> _blockAndLeave(
      BuildContext context, WidgetRef ref, Recipe recipe) async {
    await blockRecipe(context, ref, recipe);
    // The recipe is now hidden; leave the detail screen.
    if (context.mounted && context.canPop()) context.pop();
  }

  Future<void> _copy(BuildContext context, WidgetRef ref, Recipe recipe) async {
    final l10n = AppLocalizations.of(context);
    final uid = ref.read(currentUidProvider);
    if (uid == null) return;
    final authorName = ref.read(currentAuthorNameProvider);
    final id = await ref
        .read(recipeRepositoryProvider)
        .copyRecipe(source: recipe, uid: uid, authorName: authorName);
    if (context.mounted) {
      context.push('/recipes/$id');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.copiedToRecipes)),
      );
    }
  }
}

class _CommentsSection extends ConsumerStatefulWidget {
  const _CommentsSection({required this.recipeId});
  final String recipeId;

  @override
  ConsumerState<_CommentsSection> createState() => _CommentsSectionState();
}

class _CommentsSectionState extends ConsumerState<_CommentsSection> {
  final _content = TextEditingController();
  final _authorName = TextEditingController();
  bool _anonymous = false;
  bool _sending = false;

  @override
  void dispose() {
    _content.dispose();
    _authorName.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _content.text.trim();
    if (text.isEmpty) return;
    final l10n = AppLocalizations.of(context);
    setState(() => _sending = true);

    final isGuest = ref.read(isGuestProvider);
    final uid = ref.read(currentUidProvider);
    final profileName = ref.read(currentAuthorNameProvider);

    String authorName;
    bool anonymous;
    if (isGuest) {
      authorName = _authorName.text.trim().isEmpty
          ? 'Anonymous'
          : _authorName.text.trim();
      anonymous = false; // guests use the name field
    } else {
      anonymous = _anonymous;
      authorName = _anonymous ? 'Anonymous' : profileName;
    }

    try {
      await ref.read(commentRepositoryProvider).addComment(
            recipeId: widget.recipeId,
            content: text,
            userId: isGuest ? null : uid,
            authorName: authorName,
            anonymous: anonymous,
          );
      _content.clear();
      if (mounted) FocusScope.of(context).unfocus();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.couldNotPost(e.toString()))));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final commentsAsync = ref.watch(commentsProvider(widget.recipeId));
    final isGuest = ref.watch(isGuestProvider);
    final uid = ref.watch(currentUidProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 32),
        const Divider(),
        const SizedBox(height: 8),
        Text(l10n.commentsTitle,
            style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryDark)),
        const SizedBox(height: 12),
        if (isGuest)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: TextField(
              controller: _authorName,
              decoration: InputDecoration(
                labelText: l10n.commentYourNameOptional,
                isDense: true,
              ),
            ),
          ),
        TextField(
          controller: _content,
          minLines: 1,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: l10n.commentAddHint,
            isDense: true,
          ),
        ),
        Row(
          children: [
            if (!isGuest)
              Expanded(
                child: CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  dense: true,
                  title: Text(l10n.commentPostAnonymously),
                  value: _anonymous,
                  onChanged: (v) => setState(() => _anonymous = v ?? false),
                ),
              )
            else
              const Spacer(),
            TextButton(
              onPressed: _sending ? null : _send,
              child: Text(_sending ? l10n.commentPosting : l10n.commentPost),
            ),
          ],
        ),
        const SizedBox(height: 8),
        commentsAsync.when(
          loading: () =>
              const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator())),
          error: (e, _) => Text(l10n.errorWithMessage(e.toString())),
          data: (comments) {
            if (comments.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(l10n.commentsEmpty,
                    style: const TextStyle(color: AppColors.textMuted)),
              );
            }
            return Column(
              children: [
                for (final c in comments)
                  _CommentTile(
                    comment: c,
                    canDelete: c.userId != null && c.userId == uid,
                    onDelete: () => ref
                        .read(commentRepositoryProvider)
                        .deleteComment(widget.recipeId, c.id),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({
    required this.comment,
    required this.canDelete,
    required this.onDelete,
  });

  final Comment comment;
  final bool canDelete;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final date = comment.createdAt;
    final dateStr = date == null ? '' : DateFormat.yMMMd().add_jm().format(date);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.primary,
            child: Icon(Icons.person, size: 18, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(comment.displayName,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(width: 8),
                    Text(dateStr,
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade500)),
                  ],
                ),
                const SizedBox(height: 2),
                Text(comment.content, style: const TextStyle(height: 1.35)),
              ],
            ),
          ),
          if (canDelete)
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.delete_outline,
                  size: 18, color: AppColors.textMuted),
              onPressed: onDelete,
            ),
        ],
      ),
    );
  }
}
