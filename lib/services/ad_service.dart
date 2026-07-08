import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../config.dart';

/// Loads and shows interstitial ("popup") ads at natural transition points.
///
/// One instance is created at app start (see `providers.dart`). It keeps a
/// single interstitial preloaded and shows it from [maybeShowOnRecipeOpen],
/// which is frequency-capped so users are never interrupted too often.
class InterstitialAdManager {
  InterstitialAdManager();

  InterstitialAd? _ad;
  bool _loading = false;
  int _eventCount = 0;
  DateTime _lastShown = DateTime.fromMillisecondsSinceEpoch(0);

  bool get _isIOS => !kIsWeb && Platform.isIOS;

  /// Ads only run on Android/iOS; skip on web/desktop where the plugin has no
  /// implementation.
  bool get _supported => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  /// Preload an interstitial so it's ready the moment we want to show one.
  void preload() {
    if (!_supported || _ad != null || _loading) return;
    _loading = true;
    InterstitialAd.load(
      adUnitId: AdConfig.interstitialUnitId(_isIOS),
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _ad = ad;
          _loading = false;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _ad = null;
              preload(); // Get the next one ready.
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _ad = null;
              preload();
            },
          );
        },
        onAdFailedToLoad: (error) {
          _ad = null;
          _loading = false;
        },
      ),
    );
  }

  /// Called when the user opens a recipe. Shows an interstitial on every Nth
  /// open, and never more than once per [AdConfig.interstitialMinInterval].
  void maybeShowOnRecipeOpen() {
    if (!_supported) return;
    _eventCount++;
    if (_ad == null) {
      preload();
      return;
    }
    if (_eventCount % AdConfig.interstitialFrequency != 0) return;
    if (DateTime.now().difference(_lastShown) <
        AdConfig.interstitialMinInterval) {
      return;
    }
    _lastShown = DateTime.now();
    _ad!.show();
    _ad = null; // Ownership passes to the SDK; dismissal callback reloads.
  }
}
