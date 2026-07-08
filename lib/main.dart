import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'firebase_options.dart';
import 'providers/providers.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Fire-and-forget: ads aren't needed for first paint, so don't block launch.
  unawaited(MobileAds.instance.initialize());
  runApp(const ProviderScope(child: CrumbsApp()));
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

  Future<void> _initDeepLinks() async {
    _appLinks.uriLinkStream.listen(_handleUri);
    final initial = await _appLinks.getInitialLink();
    if (initial != null) _handleUri(initial);
  }

  void _handleUri(Uri uri) {
    final code = _shareCodeFromUri(uri);
    if (code != null) appRouter.push('/share/$code');
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
    return MaterialApp.router(
      title: 'Just The Crumbs',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: appRouter,
    );
  }
}
