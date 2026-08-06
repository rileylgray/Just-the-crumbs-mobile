/// App-wide configuration constants.
class AppConfig {
  /// OAuth **web** client ID from Firebase (Project settings → your apps, or the
  /// `client_type: 3` entry in `google-services.json`). Required by
  /// google_sign_in on Android to return an idToken usable by Firebase Auth.
  ///
  /// The web client (`client_type: 3`) from this project's google-services.json,
  /// used so google_sign_in returns a Firebase-usable idToken. Overridable with
  /// `--dart-define=GOOGLE_SERVER_CLIENT_ID=...` (e.g. for a different project).
  static const String googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue:
        '1029709252983-iaocta8ugt19fbrqlko9a7jftopvlmur.apps.googleusercontent.com',
  );

  /// OAuth **iOS** client ID (`CLIENT_ID` in `GoogleService-Info.plist`, the
  /// `client_type: 2` entry in google-services.json). Passed explicitly to
  /// google_sign_in on iOS/macOS: without a client id the Google SDK has no
  /// configuration and fails the moment the sign-in button is tapped, so we
  /// don't rely on the plist being bundled. Overridable with
  /// `--dart-define=GOOGLE_IOS_CLIENT_ID=...`.
  static const String googleIosClientId = String.fromEnvironment(
    'GOOGLE_IOS_CLIENT_ID',
    defaultValue:
        '1029709252983-7gm8kvrhl3f9usrq2j8mp3klomgmmj2e.apps.googleusercontent.com',
  );

  /// Custom URI scheme for share/deep links. Domain-free: sharing works via a
  /// short code + a `justthecrumbs://share/<code>` link that opens the app.
  static const String deepLinkScheme = 'justthecrumbs';
}

/// AI-assisted recipe import (Firebase AI Logic → Gemini).
///
/// This is a *fallback only*: the rule-based parser runs first, and the model
/// is invoked solely when the heuristics come up short (no ingredients or no
/// steps) — which keeps call volume low and well inside the Gemini free tier.
/// On any error or quota limit the import silently degrades to the heuristic
/// result, so this can never break an import.
class AiConfig {
  const AiConfig._();

  /// Master switch for the AI fallback. Disable instantly with
  /// `--dart-define=AI_IMPORT_ASSIST=false` (e.g. to stay 100% offline/free).
  static const bool importAssistEnabled = bool.fromEnvironment(
    'AI_IMPORT_ASSIST',
    defaultValue: true,
  );

  /// Gemini model id. Flash-Lite is the cheapest and has the most generous
  /// free-tier daily quota — the right pick for a fallback. Override with
  /// `--dart-define=AI_IMPORT_MODEL=...` if you upgrade to a paid tier.
  static const String model = String.fromEnvironment(
    'AI_IMPORT_MODEL',
    defaultValue: 'gemini-2.5-flash-lite',
  );

  /// Trim the text sent to the model so token use (and cost) stays tiny.
  static const int maxInputChars = 4000;
}

/// AdMob ad unit IDs.
///
/// Defaults are Google's official **test** unit IDs, so ads render immediately
/// in development without a real AdMob account (and without risking a policy
/// strike from tapping live ads). For a release build, pass your real unit IDs:
///
/// ```
/// flutter build apk \
///   --dart-define=ADMOB_BANNER_ANDROID=ca-app-pub-XXXX/YYYY \
///   --dart-define=ADMOB_INTERSTITIAL_ANDROID=ca-app-pub-XXXX/ZZZZ
/// ```
///
/// The app-level AdMob application ID lives in the native manifests
/// (AndroidManifest.xml / Info.plist) and must also be swapped for release.
class AdConfig {
  const AdConfig._();

  static const String _bannerAndroid = String.fromEnvironment(
    'ADMOB_BANNER_ANDROID',
    defaultValue: 'ca-app-pub-7855071425983459/8980245276',
  );
  static const String _bannerIos = String.fromEnvironment(
    'ADMOB_BANNER_IOS',
    defaultValue: 'ca-app-pub-7855071425983459/5312463002',
  );
  static const String _interstitialAndroid = String.fromEnvironment(
    'ADMOB_INTERSTITIAL_ANDROID',
    defaultValue: 'ca-app-pub-7855071425983459/9293024907',
  );
  static const String _interstitialIos = String.fromEnvironment(
    'ADMOB_INTERSTITIAL_IOS',
    defaultValue: 'ca-app-pub-7855071425983459/7667163604',
  );

  /// Banner unit for the current platform.
  static String bannerUnitId(bool isIOS) =>
      isIOS ? _bannerIos : _bannerAndroid;

  /// Interstitial unit for the current platform.
  static String interstitialUnitId(bool isIOS) =>
      isIOS ? _interstitialIos : _interstitialAndroid;

  /// Show an interstitial on every Nth qualifying event (recipe opened).
  static const int interstitialFrequency = 3;

  /// Minimum gap between interstitials, so they never feel back-to-back.
  static const Duration interstitialMinInterval = Duration(seconds: 45);
}
