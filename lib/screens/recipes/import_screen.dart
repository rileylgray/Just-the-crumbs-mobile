import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/gen/app_localizations.dart';
import '../../services/import/recipe_import_service.dart';
import '../../theme/app_theme.dart';

/// Paste a recipe URL, fetch + parse it client-side, then hand off to the form
/// pre-filled for review. Mirrors the Rails import flow.
class ImportScreen extends ConsumerStatefulWidget {
  const ImportScreen({super.key});

  @override
  ConsumerState<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends ConsumerState<ImportScreen> {
  final _url = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _url.dispose();
    super.dispose();
  }

  Future<void> _import() async {
    final url = _url.text.trim();
    if (url.isEmpty) {
      setState(() => _error = AppLocalizations.of(context).importPasteUrlError);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final imported = await RecipeImportService(url).call();
      if (!mounted) return;
      // Hand off to the form for review & save.
      context.pushReplacement('/recipes/new', extra: imported);
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString());
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.importTitle),
        backgroundColor: AppColors.surface,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            l10n.importIntro,
            style: const TextStyle(color: AppColors.textMuted, height: 1.4),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _url,
            keyboardType: TextInputType.url,
            autofocus: true,
            decoration: InputDecoration(
              labelText: l10n.importUrlLabel,
              hintText: l10n.importUrlHint,
              prefixIcon: const Icon(Icons.link),
              errorText: _error,
            ),
            onSubmitted: (_) => _import(),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _loading ? null : _import,
            icon: _loading
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.download),
            label: Text(_loading ? l10n.importingButton : l10n.importButton),
          ),
          if (_loading) ...[
            const SizedBox(height: 16),
            Center(
              child: Text(l10n.importProgress,
                  style: const TextStyle(color: AppColors.textMuted)),
            ),
          ],
        ],
      ),
    );
  }
}
