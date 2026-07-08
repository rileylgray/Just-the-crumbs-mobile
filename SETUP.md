# Just The Crumbs — Setup & Firebase configuration

The Flutter app is fully built. A few Firebase steps must be done in the console
(they can't be scripted without a gcloud token). Do these once, then
`flutter run`.

Project: **just-the-crumbs-app**
Console: https://console.firebase.google.com/project/just-the-crumbs-app

---

## 1. Create the Firestore database

Console → **Firestore Database** → **Create database** → Standard edition →
**Production mode** → location **nam5 (US)** → Enable.

(This also enables the Cloud Firestore API for the project.)

## 2. Deploy the security rules

From this project directory:

```bash
firebase deploy --only firestore:rules
```

The rules live in [`firestore.rules`](firestore.rules): owners-only writes,
public recipes readable by anyone, comments allowed only on public recipes.

## 3. Enable the auth providers

Console → **Authentication** → **Get started** → **Sign-in method**, then enable:

- **Anonymous** — powers guest sessions (the app signs in anonymously at launch).
- **Google** — set a project support email and save.

## 4. Wire up Google Sign-In (after step 3)

Enabling Google creates an OAuth **web client**. The Android app needs its ID to
get a Firebase-usable idToken.

1. Refresh the config so `google-services.json` contains the new OAuth client:
   ```bash
   flutterfire configure --project=just-the-crumbs-app --platforms=android,ios --yes
   ```
2. Find the **web** client ID (Firebase console → Project settings → your apps,
   or the `"client_type": 3` entry in `android/app/google-services.json`).
3. Run the app passing it as the server client ID:
   ```bash
   flutter run --dart-define=GOOGLE_SERVER_CLIENT_ID=<WEB_CLIENT_ID>.apps.googleusercontent.com
   ```
   (Or paste it as the `defaultValue` in [`lib/config.dart`](lib/config.dart).)

**App identifier:** Android `applicationId` / iOS bundle id is
**`com.realgamesrealfun.justthecrumbs`** (Firebase Android app
`1:1029709252983:android:2db3d059c171610597b972`).

**SHA fingerprints:** the debug keystore's SHA-1 and SHA-256 are already
registered with this Android app. For a release build, add the release keystore's
fingerprints:
```bash
firebase apps:android:sha:create 1:1029709252983:android:2db3d059c171610597b972 <SHA1>
```

## 5. (Optional) Enable AI-assisted import

The import screen can call **Gemini** (via Firebase AI Logic) to untangle messy
TikTok captions/transcripts — but only as a *fallback* when the rule-based parser
comes up short. It's optional: if you skip this, imports still work, they just
won't get the AI assist (the call fails and the app silently keeps the heuristic
result).

To turn it on:

1. Console → **AI Logic** → **Get started**, and choose the **Gemini Developer
   API** (this is the one with a free tier). This enables the required API for
   the project.
2. Set up **App Check** so the client can call the API without shipping a raw
   key: Console → **App Check** → register the Android app (Play Integrity) and
   iOS app (App Attest / DeviceCheck). In debug, register a debug token.
3. That's it — the app already picks a free-tier-friendly model
   (`gemini-2.5-flash-lite`). Verify the current free-tier rate/daily limits at
   <https://ai.google.dev/pricing> before you ship.

Toggle or retarget it with dart-defines (no code change):

```bash
flutter run --dart-define=AI_IMPORT_ASSIST=false          # disable entirely
flutter run --dart-define=AI_IMPORT_MODEL=gemini-2.5-flash # e.g. after upgrading
```

> Free-tier note: the free Gemini Developer API may use prompts/responses to
> improve Google's products, and the quota is **per-project** (shared across all
> users). Because the model is fallback-only, cached by input, and capped in
> input size, call volume stays low. Moving to the paid tier both raises the
> quota and stops the data being used for training.

## 6. Run

```bash
flutter run
```

Guest browsing, recipes, categories, import, public feed, comments, sharing, and
deep links all work immediately. Google sign-in works after steps 3–4; AI-assisted
import works after step 5.

---

## iOS (needs a Mac)

The iOS app (bundle id `com.realgamesrealfun.justthecrumbs`) is registered and
its config is in place:
- `ios/Runner/GoogleService-Info.plist` matches the new bundle id.
- The Google reversed-client-id URL scheme in `ios/Runner/Info.plist` matches the
  plist's `REVERSED_CLIENT_ID`.

Building still requires macOS/Xcode:

```bash
cd ios && pod install
flutter run
```

## Sharing (domain-free)

Sharing needs no hosted domain. When a user shares a recipe, the app writes a
self-contained snapshot to `shares/{code}` in Firestore under a short,
unguessable code and shares text containing:

- a tappable `justthecrumbs://share/<code>` link that opens the app straight to
  the recipe, and
- the raw code, which the recipient can paste via **Add recipe → Enter a share
  code**.

Both resolve the same snapshot, so even **private** recipes can be shared without
making them public. The recipient needs the app installed (there's no web
fallback by design). The custom URL scheme is already registered for Android
(`AndroidManifest.xml`) and iOS (`Info.plist`) — nothing else to configure.
