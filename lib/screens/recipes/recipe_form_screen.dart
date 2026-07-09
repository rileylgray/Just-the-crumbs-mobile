import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/gen/app_localizations.dart';
import '../../providers/locale_provider.dart';
import '../../providers/providers.dart';
import '../../services/import/recipe_import_service.dart';
import '../../theme/app_theme.dart';

/// Create or edit a recipe. Also used as the "review & save" screen after an
/// import (pass [initial]).
class RecipeFormScreen extends ConsumerStatefulWidget {
  const RecipeFormScreen({super.key, this.recipeId, this.initial});

  final String? recipeId;
  final ImportedRecipe? initial;

  bool get isEditing => recipeId != null;

  @override
  ConsumerState<RecipeFormScreen> createState() => _RecipeFormScreenState();
}

class _RecipeFormScreenState extends ConsumerState<RecipeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _ingredients = TextEditingController();
  final _steps = TextEditingController();
  final _sourceUrl = TextEditingController();
  bool _isPublic = false;
  final Set<String> _categoryIds = {};
  // Content language. Defaults to the author's current UI language (a good
  // proxy for what they're writing in); overridable via the dropdown, and
  // replaced with the recipe's stored value when editing.
  late String _language = ref.read(localeControllerProvider).languageCode;

  bool _loading = false;
  bool _loadedExisting = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    if (initial != null) {
      _title.text = initial.title;
      _ingredients.text = initial.ingredients.join('\n');
      _steps.text = initial.steps.join('\n');
      _sourceUrl.text = initial.sourceUrl;
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _ingredients.dispose();
    _steps.dispose();
    _sourceUrl.dispose();
    super.dispose();
  }

  Future<void> _loadExisting() async {
    if (_loadedExisting || !widget.isEditing) return;
    _loadedExisting = true;
    final recipe = await ref.read(recipeRepositoryProvider).getRecipe(widget.recipeId!);
    if (recipe == null || !mounted) return;
    setState(() {
      _title.text = recipe.title;
      _description.text = recipe.description;
      _ingredients.text = recipe.ingredients.join('\n');
      _steps.text = recipe.steps.join('\n');
      _sourceUrl.text = recipe.sourceUrl;
      _isPublic = recipe.isPublic;
      _language = recipe.language;
      _categoryIds
        ..clear()
        ..addAll(recipe.categoryIds);
    });
  }

  List<String> _lines(String text) => text
      .split('\n')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context);
    setState(() => _loading = true);
    final repo = ref.read(recipeRepositoryProvider);
    try {
      if (widget.isEditing) {
        await repo.updateRecipe(
          widget.recipeId!,
          title: _title.text.trim(),
          description: _description.text.trim(),
          ingredients: _lines(_ingredients.text),
          steps: _lines(_steps.text),
          sourceUrl: _sourceUrl.text.trim(),
          isPublic: _isPublic,
          categoryIds: _categoryIds.toList(),
          language: _language,
        );
        if (mounted) {
          context.pop();
          _toast(l10n.recipeUpdated);
        }
      } else {
        final uid = ref.read(currentUidProvider);
        if (uid == null) return;
        // Await the profile so a cold read of the Firestore stream doesn't
        // fall back to 'Guest' for a signed-in user (e.g. straight after an
        // import, where no earlier screen has warmed the profile provider).
        final profile = await ref.read(currentAppUserProvider.future);
        final authorName = profile?.name ?? 'Guest';
        final id = await repo.createRecipe(
          uid: uid,
          authorName: authorName,
          title: _title.text.trim(),
          description: _description.text.trim(),
          ingredients: _lines(_ingredients.text),
          steps: _lines(_steps.text),
          sourceUrl: _sourceUrl.text.trim(),
          isPublic: _isPublic,
          categoryIds: _categoryIds.toList(),
          language: _language,
        );
        if (mounted) {
          context.pushReplacement('/recipes/$id');
          _toast(l10n.recipeCreated);
        }
      }
    } catch (e) {
      if (mounted) _toast(l10n.errorWithMessage(e.toString()));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _toast(String msg) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    // Lazily populate fields for edit mode.
    if (widget.isEditing && !_loadedExisting) _loadExisting();

    final l10n = AppLocalizations.of(context);
    final categories = ref.watch(userCategoriesProvider).value ?? const [];
    // Offer the six UI languages, plus the recipe's own language if it's some
    // other code (so an existing value is never dropped from the dropdown).
    final languageCodes = <String>{
      for (final lang in supportedLanguages) lang.locale.languageCode,
      _language,
    }.toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? l10n.editRecipeTitle : l10n.newRecipeTitle),
        backgroundColor: AppColors.surface,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            16 + MediaQuery.of(context).viewPadding.bottom,
          ),
          children: [
            TextFormField(
              controller: _title,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(labelText: l10n.fieldTitle),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? l10n.titleRequired : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _description,
              textCapitalization: TextCapitalization.sentences,
              minLines: 1,
              maxLines: 3,
              decoration:
                  InputDecoration(labelText: l10n.fieldDescriptionOptional),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _ingredients,
              minLines: 4,
              maxLines: 12,
              decoration: InputDecoration(
                labelText: l10n.fieldIngredients,
                helperText: l10n.helperOnePerLine,
                alignLabelWithHint: true,
              ),
              validator: (v) => _lines(v ?? '').isEmpty
                  ? l10n.addAtLeastOneIngredient
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _steps,
              minLines: 4,
              maxLines: 16,
              decoration: InputDecoration(
                labelText: l10n.fieldSteps,
                helperText: l10n.helperOnePerLine,
                alignLabelWithHint: true,
              ),
              validator: (v) =>
                  _lines(v ?? '').isEmpty ? l10n.addAtLeastOneStep : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _sourceUrl,
              keyboardType: TextInputType.url,
              decoration:
                  InputDecoration(labelText: l10n.fieldSourceUrlOptional),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              // Key on the value so an async edit-mode load (which updates
              // _language after first build) refreshes the shown selection.
              key: ValueKey(_language),
              initialValue: _language,
              decoration: InputDecoration(labelText: l10n.recipeLanguageLabel),
              items: [
                for (final code in languageCodes)
                  DropdownMenuItem(
                    value: code,
                    child: Text(languageDisplayName(code)),
                  ),
              ],
              onChanged: (v) => setState(() => _language = v ?? _language),
            ),
            const SizedBox(height: 20),
            if (categories.isNotEmpty) ...[
              Text(l10n.categoriesLabel,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final c in categories)
                    FilterChip(
                      label: Text(c.name),
                      selected: _categoryIds.contains(c.id),
                      selectedColor: c.colorValue.withValues(alpha: 0.3),
                      onSelected: (sel) => setState(() {
                        sel ? _categoryIds.add(c.id) : _categoryIds.remove(c.id);
                      }),
                    ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.fieldPublic),
              subtitle: Text(l10n.fieldPublicSubtitle),
              value: _isPublic,
              activeThumbColor: AppColors.primary,
              onChanged: (v) => setState(() => _isPublic = v),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loading ? null : _save,
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text(widget.isEditing ? l10n.saveChanges : l10n.createRecipe),
            ),
          ],
        ),
      ),
    );
  }
}
