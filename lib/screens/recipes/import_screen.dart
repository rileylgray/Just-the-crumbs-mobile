import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;

import '../../l10n/gen/app_localizations.dart';
import '../../providers/providers.dart';
import '../../services/import/recipe_import_service.dart';
import '../../services/import/shared_link.dart';
import '../../theme/app_theme.dart';
import '../../widgets/offline_banner.dart';

/// Paste a recipe URL, fetch + parse it client-side, then hand off to the form
/// pre-filled for review. Mirrors the Rails import flow.
class ImportScreen extends ConsumerStatefulWidget {
  const ImportScreen({super.key, this.initialUrl});

  /// A link the screen was opened with, from another app's share sheet
  /// ("Share -> Just The Crumbs" on a TikTok video). The link is pre-filled so
  /// the user can start the import explicitly.
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
  }

  @override
  void dispose() {
    _url.dispose();
    super.dispose();
  }

  /// Fills the field from the clipboard, picking the link out of whatever was
  /// copied — usually a caption with the link buried in it.
  Future<void> _paste() async {
    final l10n = AppLocalizations.of(context);
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final link = firstLinkIn(data?.text ?? '');
    if (!mounted) return;
    setState(() {
      if (link == null) {
        _error = l10n.clipboardNoLink;
      } else {
        _url.text = link;
        _error = null;
      }
    });
  }

  Future<void> _import() async {
    if (_loading) return;
    final l10n = AppLocalizations.of(context);
    // Accept a whole pasted caption, not only a bare link.
    final url = firstLinkIn(_url.text) ?? _url.text.trim();
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
      await _waitForSession();
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

  /// Waits, briefly, for the startup guest sign-in to land.
  ///
  /// A share opens this screen while the app is still booting, and the import's
  /// AI step sends the signed-in user's ID token — so a cold start would
  /// otherwise run the import unauthenticated while a warm one doesn't, which
  /// is the difference between a parsed recipe and "watch the video".
  ///
  /// Waits on the auth user rather than the app's whole startup sign-in, which
  /// also syncs a Firestore profile document and can stall offline. Only the AI
  /// step benefits from any of this, so failure or slowness is not fatal.
  Future<void> _waitForSession() async {
    final auth = ref.read(firebaseAuthProvider);
    if (auth.currentUser != null) return;
    try {
      await auth
          .authStateChanges()
          .firstWhere((user) => user != null)
          .timeout(const Duration(seconds: 5));
    } catch (_) {
      // Still no session: import anyway, heuristics-only if it comes to that.
    }
  }

  /// Maps a raw import failure to a friendly, localized message. Network/timeout
  /// problems get a "check your connection" message; anything else means we
  /// reached the page but couldn't find a recipe on it.
  ///
  /// The services wrap a failed fetch in a string rather than rethrowing, so
  /// those are matched on their shared `'Error importing …'` prefix — both
  /// `'Error importing recipe: …'` and TikTok's `'Error importing TikTok
  /// recipe: …'`. Matching only the former is what made every failed TikTok
  /// fetch report itself as "no recipe on that page".
  String _friendlyError(AppLocalizations l10n, Object error) {
    final isNetwork =
        error is TimeoutException ||
        error is SocketException ||
        error is http.ClientException ||
        error is HandshakeException ||
        (error is String && error.startsWith('Error importing'));
    return isNetwork ? l10n.importNetworkError : l10n.importReadError;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final online = ref.watch(isOnlineProvider).value ?? true;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.importTitle),
      ),
      body: Column(
        children: [
          if (!online) OfflineBanner(message: l10n.importOfflineError),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: AppColors.primarySoft,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.auto_awesome,
                          color: AppColors.primaryDeep, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        l10n.importIntro,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _url,
                  keyboardType: TextInputType.url,
                  autocorrect: false,
                  textInputAction: TextInputAction.go,
                  autofocus: widget.initialUrl == null,
                  decoration: InputDecoration(
                    labelText: l10n.importUrlLabel,
                    hintText: l10n.importUrlHint,
                    prefixIcon: const Icon(Icons.link),
                    suffixIcon: IconButton(
                      tooltip: l10n.actionPaste,
                      icon: const Icon(Icons.content_paste),
                      onPressed: _loading ? null : _paste,
                    ),
                    errorText: _error,
                    errorMaxLines: 3,
                  ),
                  // A stale error shouldn't linger while the link is fixed.
                  onChanged: (_) {
                    if (_error != null) setState(() => _error = null);
                  },
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
                  const SizedBox(height: 20),
                  const LinearProgressIndicator(minHeight: 3),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      l10n.importProgress,
                      textAlign: TextAlign.center,
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
