import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/gen/app_localizations.dart';
import '../../models/recipe.dart';
import '../../providers/locale_provider.dart';
import '../../providers/providers.dart';
import '../../services/import/recipe_import_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/offline_banner.dart';

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

/// The editable state of one ingredient group: a name (only meaningful for
/// multi-part recipes) and its individual ingredient rows.
class _GroupEditor {
  _GroupEditor({String name = '', List<String> items = const []})
      : name = TextEditingController(text: name),
        items = items.isEmpty
            ? [TextEditingController()]
            : items.map((e) => TextEditingController(text: e)).toList();

  final TextEditingController name;
  final List<TextEditingController> items;

  void dispose() {
    name.dispose();
    for (final c in items) {
      c.dispose();
    }
  }
}

class _RecipeFormScreenState extends ConsumerState<RecipeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _sourceUrl = TextEditingController();

  // Structured ingredient/step editors. Start with one (unnamed) group and a
  // single blank step so a brand-new recipe opens with something to type into.
  final List<_GroupEditor> _groups = [_GroupEditor()];
  final List<TextEditingController> _steps = [TextEditingController()];

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
      _sourceUrl.text = initial.sourceUrl;
      _setGroups(initial.ingredientGroups);
      _setSteps(initial.steps);
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _sourceUrl.dispose();
    for (final g in _groups) {
      g.dispose();
    }
    for (final s in _steps) {
      s.dispose();
    }
    super.dispose();
  }

  void _setGroups(List<IngredientGroup> groups) {
    for (final g in _groups) {
      g.dispose();
    }
    _groups
      ..clear()
      ..addAll(groups.isEmpty
          ? [_GroupEditor()]
          : groups.map(
              (g) => _GroupEditor(name: g.title, items: g.items),
            ));
  }

  void _setSteps(List<String> steps) {
    for (final s in _steps) {
      s.dispose();
    }
    _steps
      ..clear()
      ..addAll(steps.isEmpty
          ? [TextEditingController()]
          : steps.map((e) => TextEditingController(text: e)));
  }

  Future<void> _loadExisting() async {
    if (_loadedExisting || !widget.isEditing) return;
    _loadedExisting = true;
    final recipe = await ref
        .read(recipeRepositoryProvider)
        .getRecipe(widget.recipeId!);
    if (recipe == null || !mounted) return;
    setState(() {
      _title.text = recipe.title;
      _description.text = recipe.description;
      _setGroups(recipe.ingredientGroups);
      _setSteps(recipe.steps);
      _sourceUrl.text = recipe.sourceUrl;
      _isPublic = recipe.isPublic;
      _language = recipe.language;
      _categoryIds
        ..clear()
        ..addAll(recipe.categoryIds);
    });
  }

  /// Collects the non-empty ingredient groups from the editors. A group's items
  /// are trimmed and blanks dropped; groups left entirely empty are discarded.
  List<IngredientGroup> _collectGroups() {
    final result = <IngredientGroup>[];
    final single = _groups.length == 1;
    for (final g in _groups) {
      final items = g.items
          .map((c) => c.text.trim())
          .where((t) => t.isNotEmpty)
          .toList();
      if (items.isEmpty) continue;
      // A lone group keeps no title (renders as a plain list); named parts keep
      // theirs so the view and future edits show the headings.
      result.add(IngredientGroup(
        title: single ? '' : g.name.text.trim(),
        items: items,
      ));
    }
    return result;
  }

  List<String> _collectSteps() =>
      _steps.map((c) => c.text.trim()).where((t) => t.isNotEmpty).toList();

  // Fail-safe cap on a save. Both create and update persist to Firestore's
  // local cache without awaiting server acknowledgement, so this should never
  // fire in practice — it exists purely so an unforeseen stall can never trap
  // the user on an endless spinner.
  static const _saveTimeout = Duration(seconds: 8);

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final groups = _collectGroups();
    final steps = _collectSteps();
    // The validators already guarantee these, but guard so a save never writes
    // an empty recipe if validation is ever bypassed.
    if (groups.isEmpty || steps.isEmpty) return;

    final l10n = AppLocalizations.of(context);
    setState(() => _loading = true);
    final repo = ref.read(recipeRepositoryProvider);
    try {
      if (widget.isEditing) {
        await repo
            .updateRecipe(
              widget.recipeId!,
              title: _title.text.trim(),
              description: _description.text.trim(),
              ingredientGroups: groups,
              steps: steps,
              sourceUrl: _sourceUrl.text.trim(),
              isPublic: _isPublic,
              categoryIds: _categoryIds.toList(),
              language: _language,
            )
            .timeout(_saveTimeout);
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
        // Cap the wait so a slow/flaky read can't hang creation on the spinner.
        final profile = await ref
            .read(currentAppUserProvider.future)
            .timeout(const Duration(seconds: 3), onTimeout: () => null);
        final authorName = profile?.name ?? 'Guest';
        final id = await repo
            .createRecipe(
              uid: uid,
              authorName: authorName,
              title: _title.text.trim(),
              description: _description.text.trim(),
              ingredientGroups: groups,
              steps: steps,
              sourceUrl: _sourceUrl.text.trim(),
              isPublic: _isPublic,
              categoryIds: _categoryIds.toList(),
              language: _language,
            )
            .timeout(_saveTimeout);
        if (mounted) {
          context.pushReplacement('/recipes/$id');
          _toast(l10n.recipeCreated);
        }
      }
    } on TimeoutException {
      // The write is durably queued in Firestore's local cache regardless of
      // server acknowledgement, so treat the timeout as a save and let it sync
      // in the background rather than stranding the user on the spinner. Fall
      // back to the previous screen; the change shows via the recipe streams.
      if (mounted) {
        context.pop();
        _toast(widget.isEditing ? l10n.recipeUpdated : l10n.recipeCreated);
      }
    } catch (e) {
      if (mounted) _toast(l10n.errorWithMessage(e.toString()));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _toast(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  // ---- Ingredient/step mutations -------------------------------------------

  void _addIngredient(_GroupEditor g) =>
      setState(() => g.items.add(TextEditingController()));

  void _removeIngredient(_GroupEditor g, int i) => setState(() {
        g.items.removeAt(i).dispose();
        if (g.items.isEmpty) g.items.add(TextEditingController());
      });

  void _addGroup() => setState(() => _groups.add(_GroupEditor()));

  void _removeGroup(int index) => setState(() {
        _groups.removeAt(index).dispose();
        if (_groups.isEmpty) _groups.add(_GroupEditor());
      });

  void _addStep() => setState(() => _steps.add(TextEditingController()));

  void _removeStep(int i) => setState(() {
        _steps.removeAt(i).dispose();
        if (_steps.isEmpty) _steps.add(TextEditingController());
      });

  @override
  Widget build(BuildContext context) {
    // Lazily populate fields for edit mode.
    if (widget.isEditing && !_loadedExisting) _loadExisting();

    final l10n = AppLocalizations.of(context);
    final online = ref.watch(isOnlineProvider).value ?? true;
    final categories = ref.watch(userCategoriesProvider).value ?? const [];
    // Offer every content language (sorted by name), plus the recipe's own
    // language if it's some other code, so an existing value is never dropped.
    final languageCodes = contentLanguageCodes(extra: _language);
    final multiGroup = _groups.length > 1;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isEditing ? l10n.editRecipeTitle : l10n.newRecipeTitle,
        ),
        backgroundColor: AppColors.surface,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            if (!online) OfflineBanner(message: l10n.offlineBannerEditing),
            Expanded(
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
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? l10n.titleRequired
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _description,
                    textCapitalization: TextCapitalization.sentences,
                    minLines: 1,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: l10n.fieldDescriptionOptional,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ---- Ingredients (grouped) ----
                  _fieldHeader(l10n.fieldIngredients),
                  const SizedBox(height: 8),
                  for (var gi = 0; gi < _groups.length; gi++)
                    _groupCard(l10n, _groups[gi], gi, multiGroup),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: _addGroup,
                      icon: const Icon(Icons.create_new_folder_outlined,
                          size: 18),
                      label: Text(l10n.addIngredientGroup),
                    ),
                  ),
                  // A hidden field carries validation for the whole ingredient
                  // section, so the error shows even though each row is its own
                  // widget.
                  FormField<bool>(
                    validator: (_) => _collectGroups().isEmpty
                        ? l10n.addAtLeastOneIngredient
                        : null,
                    builder: (state) => state.hasError
                        ? Padding(
                            padding: const EdgeInsets.only(left: 12, top: 4),
                            child: Text(
                              state.errorText!,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                                fontSize: 12,
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 24),

                  // ---- Steps ----
                  _fieldHeader(l10n.fieldSteps),
                  const SizedBox(height: 8),
                  for (var si = 0; si < _steps.length; si++)
                    _stepRow(l10n, si),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: _addStep,
                      icon: const Icon(Icons.add, size: 18),
                      label: Text(l10n.addStep),
                    ),
                  ),
                  FormField<bool>(
                    validator: (_) => _collectSteps().isEmpty
                        ? l10n.addAtLeastOneStep
                        : null,
                    builder: (state) => state.hasError
                        ? Padding(
                            padding: const EdgeInsets.only(left: 12, top: 4),
                            child: Text(
                              state.errorText!,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                                fontSize: 12,
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 24),

                  TextFormField(
                    controller: _sourceUrl,
                    keyboardType: TextInputType.url,
                    decoration: InputDecoration(
                      labelText: l10n.fieldSourceUrlOptional,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (categories.isNotEmpty) ...[
                    Text(
                      l10n.categoriesLabel,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
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
                              sel
                                  ? _categoryIds.add(c.id)
                                  : _categoryIds.remove(c.id);
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
                  // Content language only matters for public recipes (it drives the
                  // Discover feed's language filter), so it's shown only when public.
                  if (_isPublic) ...[
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      // Key on the value so an async edit-mode load (which updates
                      // _language after first build) refreshes the shown selection.
                      key: ValueKey(_language),
                      initialValue: _language,
                      decoration: InputDecoration(
                        labelText: l10n.recipeLanguageLabel,
                      ),
                      items: [
                        for (final code in languageCodes)
                          DropdownMenuItem(
                            value: code,
                            child: Text(languageDisplayName(code)),
                          ),
                      ],
                      onChanged: (v) =>
                          setState(() => _language = v ?? _language),
                    ),
                  ],
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loading ? null : _save,
                    child: _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            widget.isEditing
                                ? l10n.saveChanges
                                : l10n.createRecipe,
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fieldHeader(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppColors.primaryDark,
        ),
      );

  /// One ingredient group: an optional name (shown only for multi-part
  /// recipes), its ingredient rows, and an "add ingredient" action.
  Widget _groupCard(
    AppLocalizations l10n,
    _GroupEditor g,
    int index,
    bool multiGroup,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.fromLTRB(12, multiGroup ? 8 : 0, 12, 8),
      decoration: multiGroup
          ? BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black12),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (multiGroup)
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: g.name,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: l10n.ingredientGroupNameHint,
                      border: InputBorder.none,
                    ),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: l10n.removeIngredientGroup,
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.delete_outline,
                      size: 20, color: AppColors.textMuted),
                  onPressed: () => _removeGroup(index),
                ),
              ],
            ),
          for (var i = 0; i < g.items.length; i++)
            _ingredientRow(l10n, g, i),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => _addIngredient(g),
              icon: const Icon(Icons.add, size: 18),
              label: Text(l10n.addIngredient),
            ),
          ),
        ],
      ),
    );
  }

  Widget _ingredientRow(AppLocalizations l10n, _GroupEditor g, int i) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsets.only(right: 8),
            child: Icon(Icons.circle, size: 6, color: AppColors.textMuted),
          ),
          Expanded(
            child: TextFormField(
              controller: g.items[i],
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                isDense: true,
                hintText: l10n.ingredientHint,
              ),
              onFieldSubmitted: (_) {
                if (i == g.items.length - 1) _addIngredient(g);
              },
            ),
          ),
          IconButton(
            tooltip: l10n.actionDelete,
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.close, size: 18, color: AppColors.textMuted),
            onPressed: () => _removeIngredient(g, i),
          ),
        ],
      ),
    );
  }

  Widget _stepRow(AppLocalizations l10n, int i) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 10, right: 10),
            child: Container(
              width: 24,
              height: 24,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: Text(
                '${i + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          Expanded(
            child: TextFormField(
              controller: _steps[i],
              textCapitalization: TextCapitalization.sentences,
              minLines: 1,
              maxLines: 5,
              textInputAction: TextInputAction.newline,
              decoration: InputDecoration(
                isDense: true,
                hintText: l10n.stepHint,
              ),
            ),
          ),
          IconButton(
            tooltip: l10n.actionDelete,
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.close, size: 18, color: AppColors.textMuted),
            onPressed: () => _removeStep(i),
          ),
        ],
      ),
    );
  }
}
