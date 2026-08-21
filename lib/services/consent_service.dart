import 'dart:async';
import 'dart:io' show Platform;

import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Owns the Google UMP (User Messaging Platform) consent flow and the iOS ATT
/// prompt, and gates every ad load behind them.
///
/// Consent comes first, always. In the EEA, UK and Switzerland AdMob requires a
/// TCF-registered CMP to have collected a choice before any ad is requested; a
/// request sent beforehand carries no TC string, which Google's Policy center
/// flags as "Consent requirement: No CMP" and which throttles serving in those
/// regions. The message itself is configured in the AdMob console under
/// Privacy & messaging → European regulations and must be *published* and
/// applied to this app — this class only fetches and shows whatever is there.
///
/// [adsStarted] is the gate, and it stays false until the SDK confirms ads may
/// be requested. That is deliberately fail-closed: a launch with no network
/// yields no ads rather than a TC-string-less request. Nothing here throws —
/// ads are optional and the app must never be blocked behind an ad SDK.
class ConsentService {
  ConsentService._();
  static final ConsentService instance = ConsentService._();

  bool _canRequestAds = false;

  /// True once consent cleared ads and the Mobile Ads SDK started — nothing may
  /// be requested before then.
  ///
  /// A notifier rather than a plain flag because consent resolves *after* first
  /// paint: a banner built during startup would otherwise ask once, get false,
  /// and sit empty for the rest of the session. Listeners load when it flips,
  /// which also covers a user granting consent later from the privacy options
  /// form.
  final ValueNotifier<bool> adsStarted = ValueNotifier<bool>(false);

  /// True when this user must be offered a way to change their ad-consent
  /// choice. Google requires the entry point wherever the configured message
  /// offers privacy options and requires it to be absent elsewhere, so the
  /// profile screen hides the row when this is false. A notifier for the same
  /// reason as [adsStarted].
  final ValueNotifier<bool> privacyOptionsRequired = ValueNotifier<bool>(false);

  bool get _supported => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  /// Runs consent, the ATT prompt and SDK start-up, in that order. Started
  /// during launch so the first ad request already carries the user's choices.
  Future<void> initialize() async {
    if (!_supported) return;

    await _gatherConsent();

    // iOS wants the ATT prompt after the UMP form, and only with the app
    // actually in the foreground. Without it iOS withholds the advertising
    // identifier, so ads still serve — just with less to target on.
    if (Platform.isIOS) {
      try {
        final status = await AppTrackingTransparency.trackingAuthorizationStatus;
        if (status == TrackingStatus.notDetermined) {
          await Future<void>.delayed(const Duration(milliseconds: 400));
          await AppTrackingTransparency.requestTrackingAuthorization();
        }
      } catch (e) {
        debugPrint('ATT prompt failed: $e');
      }
    }

    await startAdsIfAllowed();
  }

  /// Starts the Mobile Ads SDK, but only once consent has cleared ads.
  ///
  /// Called from [initialize] at launch and again after the user changes their
  /// choice in the privacy options form, so granting consent later starts ads
  /// without a restart. A no-op once ads are already running.
  Future<void> startAdsIfAllowed() async {
    if (adsStarted.value || !_canRequestAds) return;
    try {
      await MobileAds.instance.initialize();
      // Set last: it's what releases every waiting ad slot, so it must not flip
      // until the SDK is genuinely up.
      adsStarted.value = true;
    } catch (e) {
      debugPrint('MobileAds initialization failed: $e');
    }
  }

  /// Reopens the consent form so the user can change their mind. Backs the
  /// "Ad privacy choices" row in the profile screen.
  Future<void> showPrivacyOptions() async {
    if (!_supported) return;

    try {
      FormError? formError;
      await ConsentForm.showPrivacyOptionsForm((error) => formError = error);
      if (formError != null) {
        debugPrint('Privacy options form failed: ${formError!.message}');
        return;
      }
    } catch (e) {
      debugPrint('Privacy options form failed: $e');
      return;
    }

    // The user may have just granted consent for the first time — or withdrawn
    // it, in which case the re-read below closes the gate for future loads.
    await _refreshCanRequestAds();
    await startAdsIfAllowed();
  }

  Future<void> _gatherConsent() async {
    try {
      await _requestConsentInfoUpdate();
      // Runs whatever the console serves; a no-op when consent isn't required
      // or was already collected. Deliberately not time-limited — it completes
      // only once the form is dismissed, because starting ads while the form is
      // still on screen is what produces requests with no TC string.
      FormError? formError;
      await ConsentForm.loadAndShowConsentFormIfRequired(
        (error) => formError = error,
      );
      if (formError != null) {
        debugPrint('Consent form failed: ${formError!.message}');
      }
    } catch (e) {
      debugPrint('Consent gathering failed: $e');
    }

    // Read even when the steps above failed: UMP persists a previous session's
    // choice, so a user who already answered isn't punished for a transient
    // error here.
    await _refreshCanRequestAds();
    try {
      privacyOptionsRequired.value =
          await ConsentInformation.instance
                  .getPrivacyOptionsRequirementStatus() ==
              PrivacyOptionsRequirementStatus.required;
    } catch (e) {
      debugPrint('Privacy options requirement check failed: $e');
    }
  }

  Future<void> _refreshCanRequestAds() async {
    try {
      _canRequestAds = await ConsentInformation.instance.canRequestAds();
    } catch (e) {
      debugPrint('canRequestAds check failed: $e');
      _canRequestAds = false;
    }
  }

  /// Wraps the SDK's callback-style update in a Future, capped so a network
  /// stall inside UMP can't hold up the app's first paint.
  Future<void> _requestConsentInfoUpdate() {
    final completer = Completer<void>();

    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () {
        if (!completer.isCompleted) completer.complete();
      },
      (FormError error) {
        debugPrint('Consent info update failed: ${error.message}');
        if (!completer.isCompleted) completer.complete();
      },
    );

    return completer.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () => debugPrint('Consent info update timed out'),
    );
  }
}
