import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/gen/app_localizations.dart';
import '../models/recipe.dart';
import '../providers/providers.dart';
import '../services/moderation_repository.dart';

/// Localized label for a report reason, shown in the report dialog.
String reportReasonLabel(AppLocalizations l10n, ReportReason reason) {
  switch (reason) {
    case ReportReason.spam:
      return l10n.reportReasonSpam;
    case ReportReason.inappropriate:
      return l10n.reportReasonInappropriate;
    case ReportReason.offensive:
      return l10n.reportReasonOffensive;
    case ReportReason.copyright:
      return l10n.reportReasonCopyright;
    case ReportReason.other:
      return l10n.reportReasonOther;
  }
}

/// Overflow menu of moderation actions ("Report", "Block") for a public recipe.
/// Reused by the public feed cards and the public recipe detail screen.
class RecipeModerationMenu extends ConsumerWidget {
  const RecipeModerationMenu({super.key, required this.recipe, this.iconColor});

  final Recipe recipe;
  final Color? iconColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return PopupMenuButton<String>(
      tooltip: l10n.tooltipMore,
      icon: Icon(Icons.more_vert, color: iconColor),
      onSelected: (value) {
        switch (value) {
          case 'report':
            reportRecipe(context, ref, recipe);
          case 'block':
            blockRecipe(context, ref, recipe);
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
    );
  }
}

/// Hides [recipe] from the current user's feed and offers an Undo.
Future<void> blockRecipe(
  BuildContext context,
  WidgetRef ref,
  Recipe recipe,
) async {
  final uid = ref.read(currentUidProvider);
  if (uid == null) return;
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final repo = ref.read(moderationRepositoryProvider);
  try {
    await repo.blockRecipe(uid, recipe.id);
    messenger.showSnackBar(
      SnackBar(
        content: Text(l10n.moderationHidRecipe(recipe.title)),
        action: SnackBarAction(
          label: l10n.actionUndo,
          onPressed: () => repo.unblockRecipe(uid, recipe.id),
        ),
      ),
    );
  } catch (e) {
    messenger
        .showSnackBar(SnackBar(content: Text(l10n.couldNotBlock(e.toString()))));
  }
}

/// Prompts for a reason and files a report against [recipe].
Future<void> reportRecipe(
  BuildContext context,
  WidgetRef ref,
  Recipe recipe,
) async {
  final uid = ref.read(currentUidProvider);
  if (uid == null) return;
  final l10n = AppLocalizations.of(context);
  final result = await showDialog<_ReportResult>(
    context: context,
    builder: (_) => _ReportDialog(recipeTitle: recipe.title),
  );
  if (result == null || !context.mounted) return;

  final messenger = ScaffoldMessenger.of(context);
  try {
    await ref.read(moderationRepositoryProvider).reportRecipe(
          recipe: recipe,
          reporterUid: uid,
          reason: result.reason,
          details: result.details,
        );
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.reportSubmitted)),
    );
  } catch (e) {
    messenger.showSnackBar(
        SnackBar(content: Text(l10n.couldNotReport(e.toString()))));
  }
}

class _ReportResult {
  const _ReportResult(this.reason, this.details);
  final ReportReason reason;
  final String details;
}

class _ReportDialog extends StatefulWidget {
  const _ReportDialog({required this.recipeTitle});
  final String recipeTitle;

  @override
  State<_ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<_ReportDialog> {
  ReportReason _reason = ReportReason.spam;
  final _details = TextEditingController();

  @override
  void dispose() {
    _details.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.reportRecipeTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.reportWhy(widget.recipeTitle),
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 8),
            RadioGroup<ReportReason>(
              groupValue: _reason,
              onChanged: (v) => setState(() => _reason = v!),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final reason in ReportReason.values)
                    RadioListTile<ReportReason>(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      value: reason,
                      title: Text(reportReasonLabel(l10n, reason)),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _details,
              minLines: 1,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: l10n.reportDetailsOptional,
                isDense: true,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.actionCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(
            _ReportResult(_reason, _details.text),
          ),
          child: Text(l10n.actionSubmit),
        ),
      ],
    );
  }
}
