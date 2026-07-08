import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
        );
        if (mounted) {
          context.pop();
          _toast('Recipe updated');
        }
      } else {
        final uid = ref.read(currentUidProvider);
        final authorName = ref.read(currentAuthorNameProvider);
        if (uid == null) return;
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
        );
        if (mounted) {
          context.pushReplacement('/recipes/$id');
          _toast('Recipe created');
        }
      }
    } catch (e) {
      if (mounted) _toast('Error: $e');
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

    final categories = ref.watch(userCategoriesProvider).value ?? const [];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit recipe' : 'New recipe'),
        backgroundColor: AppColors.surface,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _title,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Title'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Title is required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _description,
              textCapitalization: TextCapitalization.sentences,
              minLines: 1,
              maxLines: 3,
              decoration:
                  const InputDecoration(labelText: 'Description (optional)'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _ingredients,
              minLines: 4,
              maxLines: 12,
              decoration: const InputDecoration(
                labelText: 'Ingredients',
                helperText: 'One per line',
                alignLabelWithHint: true,
              ),
              validator: (v) => _lines(v ?? '').isEmpty
                  ? 'Add at least one ingredient'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _steps,
              minLines: 4,
              maxLines: 16,
              decoration: const InputDecoration(
                labelText: 'Steps',
                helperText: 'One per line',
                alignLabelWithHint: true,
              ),
              validator: (v) =>
                  _lines(v ?? '').isEmpty ? 'Add at least one step' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _sourceUrl,
              keyboardType: TextInputType.url,
              decoration:
                  const InputDecoration(labelText: 'Source URL (optional)'),
            ),
            const SizedBox(height: 20),
            if (categories.isNotEmpty) ...[
              const Text('Categories',
                  style: TextStyle(fontWeight: FontWeight.w600)),
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
              title: const Text('Public'),
              subtitle: const Text('Share in the Discover feed'),
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
                  : Text(widget.isEditing ? 'Save changes' : 'Create recipe'),
            ),
          ],
        ),
      ),
    );
  }
}
