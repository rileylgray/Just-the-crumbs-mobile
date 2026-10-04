import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/gen/app_localizations.dart';
import '../../models/category.dart';
import '../../providers/providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/category_chip.dart';

class CategoryFormScreen extends ConsumerStatefulWidget {
  const CategoryFormScreen({super.key, this.categoryId});

  final String? categoryId;
  bool get isEditing => categoryId != null;

  @override
  ConsumerState<CategoryFormScreen> createState() => _CategoryFormScreenState();
}

class _CategoryFormScreenState extends ConsumerState<CategoryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  String _color = AppColors.categorySwatches.first;
  bool _loading = false;
  bool _loaded = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _loadExisting() {
    if (_loaded || !widget.isEditing) return;
    _loaded = true;
    final categories = ref.read(userCategoriesProvider).value ?? const [];
    final existing =
        categories.where((c) => c.id == widget.categoryId).firstOrNull;
    if (existing != null) {
      _name.text = existing.name;
      _color = existing.color;
    }
  }

  Future<void> _save() async {
    if (_loading || !_formKey.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context);
    setState(() => _loading = true);
    final repo = ref.read(categoryRepositoryProvider);
    try {
      if (widget.isEditing) {
        await repo.updateCategory(widget.categoryId!,
            name: _name.text.trim(), color: _color);
      } else {
        final uid = ref.read(currentUidProvider);
        if (uid == null) return;
        await repo.createCategory(uid: uid, name: _name.text.trim(), color: _color);
      }
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.errorWithMessage(e.toString()))));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    _loadExisting();
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
            widget.isEditing ? l10n.editCategoryTitle : l10n.newCategoryTitle),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _name,
              autofocus: !widget.isEditing,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(labelText: l10n.fieldName),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? l10n.nameRequired : null,
              onFieldSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 16),
            // Live preview of the chip as it will appear on recipes.
            Center(
              child: ValueListenableBuilder<TextEditingValue>(
                valueListenable: _name,
                builder: (context, value, _) => CategoryChip(
                  category: Category(
                    id: '',
                    userId: '',
                    name: value.text.trim().isEmpty
                        ? l10n.fieldName
                        : value.text.trim(),
                    color: _color,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(l10n.fieldColor,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 14,
              runSpacing: 14,
              children: [
                for (final hex in AppColors.categorySwatches)
                  _Swatch(
                    hex: hex,
                    selected: hex.toLowerCase() == _color.toLowerCase(),
                    onTap: () => setState(() => _color = hex),
                  ),
              ],
            ),
            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: _loading ? null : _save,
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text(widget.isEditing ? l10n.actionSave : l10n.createCategory),
            ),
          ],
        ),
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.hex, required this.selected, required this.onTap});
  final String hex;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
    return Semantics(
      button: true,
      selected: selected,
      label: hex,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 46,
          height: 46,
          // A gap between the swatch and its selection ring keeps the ring
          // visible against dark swatches.
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? AppColors.text : Colors.transparent,
              width: 2,
            ),
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: selected
                ? Icon(Icons.check, color: AppColors.onColor(color), size: 20)
                : null,
          ),
        ),
      ),
    );
  }
}
