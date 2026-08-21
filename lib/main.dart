import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';
import 'l10n/gen/app_localizations.dart';
import 'providers/locale_provider.dart';
import 'providers/providers.dart';
import 'router/app_router.dart';
import 'services/consent_service.dart';
import 'services/import/shared_link.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Keep recipes readable offline: Firestore caches every document it syncs, so
  // "My Recipes" (and any recipe already opened) stays viewable with no network.
  // Persistence is on by default on mobile; we set it explicitly — with an
  // unbounded cache — so the whole collection survives offline rather than being
  // evicted under the default size cap.
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );
  // Load persisted settings (e.g. the chosen language) before first paint so the
  // saved locale applies immediately, with no flash of the default language.
  final prefs = await SharedPreferences.getInstance();
  // Runs the UMP consent form and the iOS ATT prompt, then starts the ad SDK —
  // nothing is requested until a consent choice exists. Fire-and-forget: ads
  // aren't needed for first paint, so don't block launch. Ad slots stay empty
  // until this resolves and then fill themselves in.
  unawaited(ConsentService.instance.initialize());
  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const CrumbsApp(),
    ),
  );
}

class CrumbsApp extends ConsumerStatefulWidget {
  const CrumbsApp({super.key});

  @override
  ConsumerState<CrumbsApp> createState() => _CrumbsAppState();
}

class _CrumbsAppState extends ConsumerState<CrumbsApp> {
  final _appLinks = AppLinks();

  @override
  void initState() {
    super.initState();
    // Establish a guest session immediately so the app is usable at launch.
    ref.read(authServiceProvider).ensureSignedIn();
    _initDeepLinks();
  }

  void _initDeepLinks() {
    // The stream covers a cold start too: app_links holds the launch link and
    // replays it to the first listener on both platforms. Also asking for
    // getInitialLink() would deliver it a second time, which for a shared
    // recipe means two import screens and two imports of the same link.
    _appLinks.uriLinkStream.listen(_handleUri);
  }

  void _handleUri(Uri uri) {
    final code = _shareCodeFromUri(uri);
    if (code != null) {
      appRouter.push('/share/$code');
      return;
    }
    if (!_isImportUri(uri)) return;
    // Open the import screen either way: if the shared text held no link there
    // is nothing to prefill, but a share that silently did nothing looks like
    // the app is broken.
    final link = _sharedLinkFromUri(uri);
    appRouter.push(
      link == null
          ? '/recipes/import'
          : '/recipes/import?url=${Uri.encodeQueryComponent(link)}',
    );
  }

  /// `justthecrumbs://import?text=<shared text>` is what the share-sheet
  /// hand-off turns into on both platforms — the Android activity rewrites the
  /// SEND intent into this URL, and the iOS share extension opens it.
  bool _isImportUri(Uri uri) =>
      uri.scheme == 'justthecrumbs' && uri.host == 'import';

  /// The recipe link inside a share. The payload is whatever the sharing app
  /// handed over — usually a caption with the link buried in it — so the link
  /// has to be picked out of it.
  String? _sharedLinkFromUri(Uri uri) {
    final shared = uri.queryParameters['text'] ?? uri.queryParameters['url'];
    return shared == null ? null : firstLinkIn(shared);
  }

  /// Extract a share code from `justthecrumbs://share/<code>` (code in the
  /// first path segment; "share" is the URI host) or a `.../share/<code>` path.
  String? _shareCodeFromUri(Uri uri) {
    if (uri.host == 'share' && uri.pathSegments.isNotEmpty) {
      return uri.pathSegments.first;
    }
    final segments = uri.pathSegments;
    for (var i = 0; i < segments.length - 1; i++) {
      if (segments[i] == 'share') return segments[i + 1];
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeControllerProvider);
    return MaterialApp.router(
      title: 'Just The Crumbs',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: appRouter,
    );
  }
}
