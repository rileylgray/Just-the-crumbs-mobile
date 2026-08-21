import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../config.dart';
import 'consent_service.dart';

/// The single ad request used for every ad in the app.
///
/// Personalized: the default request lets AdMob target on whatever signals the
/// user has actually agreed to. What's permitted is decided by consent, not by
/// this request — [ConsentService] runs the UMP form (which supplies the TC
/// string that limits targeting for EEA/UK users who decline) and the iOS ATT
/// prompt (which gates the advertising identifier) before any ad loads.
///
/// Personalized ads use the advertising identifier to link this app's data with
/// third-party data, which is what App Store guideline 5.1.2(i) calls
/// "tracking". That is why ios/Runner/Info.plist now carries
/// `NSUserTrackingUsageDescription`, why [ConsentService] requests ATT, and why
/// the App Store Connect privacy labels must declare data used to track —
/// leave any of the three out and the next submission gets rejected again.
const adRequest = AdRequest();

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

  /// Ads only run on Android/iOS, and only once the consent flow has cleared
  /// them; skip on web/desktop where the plugin has no implementation.
  bool get _supported =>
      !kIsWeb &&
      (Platform.isAndroid || Platform.isIOS) &&
      ConsentService.instance.adsStarted.value;

  /// Preload an interstitial so it's ready the moment we want to show one.
  /// A no-op until consent resolves — `providers.dart` calls it again then.
  void preload() {
    if (!_supported || _ad != null || _loading) return;
    _loading = true;
    InterstitialAd.load(
      adUnitId: AdConfig.interstitialUnitId(_isIOS),
      request: adRequest,
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
