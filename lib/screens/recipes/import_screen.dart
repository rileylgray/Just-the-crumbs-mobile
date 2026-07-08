import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
      setState(() => _error = 'Please paste a URL');
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Import recipe'),
        backgroundColor: AppColors.surface,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Paste a link from a recipe website or TikTok. We’ll pull out the '
            'ingredients and steps so you can review and save.',
            style: TextStyle(color: AppColors.textMuted, height: 1.4),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _url,
            keyboardType: TextInputType.url,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Recipe URL',
              hintText: 'https://…',
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
            label: Text(_loading ? 'Importing…' : 'Import'),
          ),
          if (_loading) ...[
            const SizedBox(height: 16),
            const Center(
              child: Text('Fetching and parsing the page…',
                  style: TextStyle(color: AppColors.textMuted)),
            ),
          ],
        ],
      ),
    );
  }
}
