# Just The Crumbs 🥐

A Flutter mobile app for saving, organizing, importing, and sharing recipes —
backed entirely by Firebase (Auth + Cloud Firestore). This is a serverless
rewrite of the original Rails app; it does not connect to any backend of its own.

## Features

- **Guest or Google** — browse and cook immediately as a guest (anonymous auth);
  sign in with Google to save recipes to your account. Guest recipes carry over
  when you link a Google account.
- **Recipes** — create, edit, delete; ingredients + step-by-step instructions;
  search by title; drag to reorder; tag with colored categories.
- **Import from a URL** — paste a recipe link (or TikTok) and the app parses the
  ingredients and steps client-side (Schema.org JSON-LD first, then HTML
  heuristics), then opens a pre-filled form to review and save. For TikTok it
  reads the video description, falls back to the caption/subtitle transcript,
  and — when those come up short — can optionally ask Gemini (Firebase AI Logic,
  fallback-only, free-tier friendly) to untangle the recipe.
- **Categories** — colored, per-user; filter your collection by category.
- **Discover** — public feed of others' recipes with search and a "surprise me"
  random pick.
- **Comments** — on public recipes, as a signed-in user or a guest (anonymous).
- **Share** — domain-free: shares a short code + a `justthecrumbs://share/<code>`
  link that opens the app straight to the recipe (recipient pastes the code or
  taps the link). Works for private recipes too; copy any shared recipe into your
  own collection.

## Tech

Flutter · Riverpod · go_router · Firebase Auth (Anonymous + Google) ·
Cloud Firestore · `http`/`html` for import · `firebase_ai` (Gemini import
fallback) · `share_plus` · `app_links` · `google_mobile_ads` (AdMob).

`lib/` is organized into `models/`, `services/` (repositories + import + share +
auth + ads), `providers/`, `router/`, `screens/`, `widgets/`, and `theme/`.

## Ads (AdMob)

A persistent banner sits above the bottom nav on the three main tabs
(`widgets/banner_ad_widget.dart`), and an interstitial ("popup") shows when
opening a recipe — frequency-capped so it isn't intrusive
(`services/ad_service.dart`, tuned in `config.dart`).

Everything ships with Google's official **test** ad units and app IDs, so ads
render in development without an AdMob account and without risking a policy
strike. Before release, swap in your real IDs:

- App ID: `AndroidManifest.xml` (`com.google.android.gms.ads.APPLICATION_ID`)
  and `ios/Runner/Info.plist` (`GADApplicationIdentifier`).
- Ad unit IDs: pass via `--dart-define` (see `AdConfig` in `lib/config.dart`),
  e.g. `--dart-define=ADMOB_BANNER_ANDROID=... --dart-define=ADMOB_INTERSTITIAL_ANDROID=...`.

## Getting started

The app is built and compiles (`flutter analyze`, `flutter test`, and
`flutter build apk --debug` all pass). A few one-time Firebase console steps
(create the Firestore database, enable the Anonymous + Google auth providers,
deploy the security rules) are required before running — see **[SETUP.md](SETUP.md)**.

Then:

```bash
flutter run
```

## Tests

```bash
flutter test
```

Covers the recipe import parser (JSON-LD, `@graph`, `HowToSection`, HTML
fallback, and error handling) and the TikTok parser (description sections,
single-line/inline segmentation, subtitle-transcript fallback, and the AI
fallback — used only when heuristics come up short, verified with an injected
fake so tests stay offline).
