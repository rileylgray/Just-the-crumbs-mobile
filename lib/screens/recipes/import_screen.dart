import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;

import '../../l10n/gen/app_localizations.dart';
import '../../providers/providers.dart';
import '../../services/import/recipe_import_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/offline_banner.dart';

/// Paste a recipe URL, fetch + parse it client-side, then hand off to the form
/// pre-filled for review. Mirrors the Rails import flow.
class ImportScreen extends ConsumerStatefulWidget {
  const ImportScreen({super.key, this.initialUrl});

  /// A link the screen was opened with, from another app's share sheet
  /// ("Share → Just The Crumbs" on a TikTok video). Importing starts on its
  /// own in that case — the user already picked the recipe.
  final String? initialUrl;

  @override
  ConsumerState<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends ConsumerState<ImportScreen> {
  final _url = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final shared = widget.initialUrl?.trim();
    if (shared == null || shared.isEmpty) return;
    _url.text = shared;
    // After the first frame: _import() needs a context that can reach the
    // localizations and the router.
    WidgetsBinding.instance.addPostFrameCallback((_) => _import());
  }

  @override
  void dispose() {
    _url.dispose();
    super.dispose();
  }

  Future<void> _import() async {
    final l10n = AppLocalizations.of(context);
    final url = _url.text.trim();
    if (url.isEmpty) {
      setState(() => _error = l10n.importPasteUrlError);
      return;
    }
    // Pre-flight connectivity check. Unlike creating a recipe (which works
    // offline and syncs later), importing needs the network to fetch the source
    // page — so fail fast with a clear message instead of making the user wait
    // out a ~12s timeout.
    if (!(ref.read(isOnlineProvider).value ?? true)) {
      setState(() => _error = l10n.importOfflineError);
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
      if (mounted) setState(() => _error = _friendlyError(l10n, e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Maps a raw import failure to a friendly, localized message. Network/timeout
  /// problems (including the service's `'Error importing recipe: …'` wrapper) get
  /// a "check your connection" message; anything else means we reached the page
  /// but couldn't find a recipe on it.
  String _friendlyError(AppLocalizations l10n, Object error) {
    final isNetwork =
        error is TimeoutException ||
        error is SocketException ||
        error is http.ClientException ||
        error is HandshakeException ||
        (error is String && error.startsWith('Error importing recipe'));
    return isNetwork ? l10n.importNetworkError : l10n.importReadError;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final online = ref.watch(isOnlineProvider).value ?? true;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.importTitle),
        backgroundColor: AppColors.surface,
      ),
      body: Column(
        children: [
          if (!online) OfflineBanner(message: l10n.importOfflineError),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  l10n.importIntro,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _url,
                  keyboardType: TextInputType.url,
                  // A shared link is already in the field, so don't throw the
                  // keyboard up over the import that's already running.
                  autofocus: widget.initialUrl == null,
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
                  onPressed: (_loading || !online) ? null : _import,
                  icon: _loading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.download),
                  label: Text(
                    _loading ? l10n.importingButton : l10n.importButton,
                  ),
                ),
                if (_loading) ...[
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      l10n.importProgress,
                      style: const TextStyle(color: AppColors.textMuted),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
