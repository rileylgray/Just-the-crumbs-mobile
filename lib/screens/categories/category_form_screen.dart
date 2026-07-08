import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/gen/app_localizations.dart';
import '../../providers/providers.dart';
import '../../theme/app_theme.dart';

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
    if (!_formKey.currentState!.validate()) return;
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
        backgroundColor: AppColors.surface,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(labelText: l10n.fieldName),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? l10n.nameRequired : null,
            ),
            const SizedBox(height: 24),
            Text(l10n.fieldColor,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? AppColors.text : Colors.transparent,
            width: 3,
          ),
        ),
        child: selected
            ? const Icon(Icons.check, color: Colors.white, size: 20)
            : null,
      ),
    );
  }
}
