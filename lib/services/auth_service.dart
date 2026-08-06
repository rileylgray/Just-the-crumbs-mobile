import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../config.dart';

/// Wraps Firebase Auth (Google and Apple sign-in) and keeps a Firestore
/// `users/{uid}` profile in sync.
///
/// Model: the app signs in **anonymously** at startup so guests can browse and
/// comment immediately. Tapping a sign-in button **links** the provider
/// credential onto the anonymous account, preserving any recipes made as a
/// guest. If that provider account already exists, we sign into it instead.
///
/// Apple's guideline 4.8 requires Sign in with Apple wherever a third-party
/// login (here, Google) is offered, so [signInWithApple] is surfaced alongside
/// [signInWithGoogle] on Apple platforms — see [supportsAppleSignIn].
class AuthService {
  AuthService(this._auth, this._db);

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;
  bool _googleInitialized = false;

  /// Whether Sign in with Apple can be offered on this platform. Firebase's
  /// native Apple flow exists on iOS/macOS; elsewhere it would need a web
  /// redirect, so the button is hidden instead.
  static bool get supportsAppleSignIn =>
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS;

  /// Requests only the name and email — the minimum Apple's guideline 4.8 asks
  /// a login option to collect, and all the app needs for a profile.
  AppleAuthProvider get _appleProvider => AppleAuthProvider()
    ..addScope('email')
    ..addScope('name');

  User? get currentUser => _auth.currentUser;

  /// User-state stream. Uses [User.userChanges] rather than
  /// [FirebaseAuth.authStateChanges] so it also fires when a credential is
  /// **linked** onto the current (anonymous) user — linking keeps the same uid,
  /// so `authStateChanges` would not emit and `isAnonymous` would stay stale.
  Stream<User?> userChanges() => _auth.userChanges();

  CollectionReference<Map<String, dynamic>> get _users => _db.collection('users');

  /// Ensures there is always an authenticated user. Called at startup.
  Future<User> ensureSignedIn() async {
    final existing = _auth.currentUser;
    if (existing != null) {
      await _ensureUserDoc(existing);
      return existing;
    }
    final cred = await _auth.signInAnonymously();
    await _ensureUserDoc(cred.user!);
    return cred.user!;
  }

  /// Configures Google Sign-In.
  ///
  /// On iOS/macOS the **iOS OAuth client id must be passed explicitly**: the
  /// plugin otherwise looks for it in a bundled `GoogleService-Info.plist`, and
  /// without a client id the Google SDK has no configuration and throws as soon
  /// as the sign-in button is tapped. Android ignores `clientId` and uses the
  /// web (`client_type: 3`) id supplied as `serverClientId`.
  Future<void> _initGoogle() async {
    if (_googleInitialized) return;
    final isApplePlatform = defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;
    await GoogleSignIn.instance.initialize(
      clientId: (isApplePlatform && AppConfig.googleIosClientId.isNotEmpty)
          ? AppConfig.googleIosClientId
          : null,
      serverClientId: AppConfig.googleServerClientId.isEmpty
          ? null
          : AppConfig.googleServerClientId,
    );
    _googleInitialized = true;
  }

  /// Signs in with Google, linking to the current anonymous account when
  /// possible so guest-created data carries over.
  Future<User> signInWithGoogle() async {
    await _initGoogle();

    final googleUser = await GoogleSignIn.instance.authenticate();
    final idToken = googleUser.authentication.idToken;
    final credential = GoogleAuthProvider.credential(idToken: idToken);

    final current = _auth.currentUser;
    UserCredential result;
    if (current != null && current.isAnonymous) {
      try {
        result = await current.linkWithCredential(credential);
      } on FirebaseAuthException catch (e) {
        // Google account already exists — sign into it instead of linking.
        if (e.code == 'credential-already-in-use' ||
            e.code == 'email-already-in-use') {
          result = await _auth.signInWithCredential(credential);
        } else {
          rethrow;
        }
      }
    } else {
      result = await _auth.signInWithCredential(credential);
    }

    final user = result.user!;
    final name = await _writeGoogleProfile(user, googleUser);
    // A guest's recipes were denormalized with the placeholder 'Guest' name;
    // now that they've a real identity, refresh those to the real name.
    await _backfillAuthorName(user.uid, name);
    return user;
  }

  /// Signs in with Apple, linking to the current anonymous account when
  /// possible so guest-created data carries over.
  ///
  /// Apple only returns the user's name on the *first* authorization and lets
  /// users hide their email behind a private relay address, so
  /// [_writeAppleProfile] keeps whatever name is already on file rather than
  /// overwriting it with a placeholder on later sign-ins.
  Future<User> signInWithApple() async {
    final current = _auth.currentUser;
    UserCredential result;
    if (current != null && current.isAnonymous) {
      try {
        result = await current.linkWithProvider(_appleProvider);
      } on FirebaseAuthException catch (e) {
        // Apple account already exists — sign into it instead of linking. The
        // exception carries the credential, so no second Apple prompt is needed.
        if (e.code == 'credential-already-in-use' ||
            e.code == 'email-already-in-use') {
          final credential = e.credential;
          result = credential != null
              ? await _auth.signInWithCredential(credential)
              : await _auth.signInWithProvider(_appleProvider);
        } else {
          rethrow;
        }
      }
    } else {
      result = await _auth.signInWithProvider(_appleProvider);
    }

    final user = result.user!;
    final name = await _writeAppleProfile(user);
    await _backfillAuthorName(user.uid, name);
    return user;
  }

  /// Updates the current user's display name — the name shown on the public
  /// feed and denormalized onto recipes and shares they've authored. The new
  /// name is propagated onto everything they've already created so their
  /// authorship stays consistent (see [_backfillAuthorName]).
  Future<void> updateDisplayName(String name) async {
    final user = _auth.currentUser;
    if (user == null) return;
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    await _users.doc(user.uid).set({'name': trimmed}, SetOptions(merge: true));
    await user.updateDisplayName(trimmed);
    await _backfillAuthorName(user.uid, trimmed);
  }

  Future<void> signOut() async {
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {
      // Not signed into Google — ignore.
    }
    await _auth.signOut();
    // Immediately re-establish a guest session so the app stays usable.
    await ensureSignedIn();
  }

  /// Permanently deletes the current user's account and their data.
  ///
  /// Removes everything the client is allowed to delete under the Firestore
  /// rules — the profile doc, the user's recipes and their comments, categories,
  /// and share snapshots — then deletes the Firebase Auth user itself. Deleting
  /// the auth user requires a recent sign-in; we transparently re-authenticate
  /// with whichever provider the account uses when Firebase asks. A fresh guest
  /// session is started afterwards so the app stays usable.
  ///
  /// Apple additionally requires apps to **revoke** the Sign in with Apple token
  /// when an account is deleted. The authorization code that revokes it only
  /// comes back from a fresh authorization, so Apple accounts re-authorize up
  /// front rather than waiting for Firebase to demand it.
  ///
  /// Two things are intentionally left behind: abuse *reports* (retained for
  /// moderation integrity — the rules forbid client deletion) and comments the
  /// user left on *other* people's recipes (a collection-group delete is blocked
  /// by the comment read rule). Removing those requires a server-side sweep.
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) return;

    String? appleAuthorizationCode;
    if (_isAppleAccount(user)) {
      final reauth = await _reauthenticate(user);
      appleAuthorizationCode = reauth?.additionalUserInfo?.authorizationCode;
    }

    await _deleteUserData(user.uid);

    if (appleAuthorizationCode != null) {
      try {
        await _auth.revokeTokenWithAuthorizationCode(appleAuthorizationCode);
      } catch (_) {
        // Revocation is best-effort: never block the deletion the user asked for.
      }
    }

    try {
      await user.delete();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login' && !user.isAnonymous) {
        await _reauthenticate(user);
        await user.delete();
      } else {
        rethrow;
      }
    }

    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {
      // Not signed into Google — ignore.
    }
    // Start a clean guest session so the app remains usable after deletion.
    await ensureSignedIn();
  }

  /// Whether [user] signed in with Apple.
  bool _isAppleAccount(User user) => user.providerData
      .any((p) => p.providerId == AppleAuthProvider.PROVIDER_ID);

  /// Re-signs in with whichever provider the account uses, to satisfy
  /// Firebase's recent-login requirement before a sensitive operation like
  /// account deletion. Returns the fresh credential, whose
  /// `additionalUserInfo.authorizationCode` is what revokes an Apple token.
  Future<UserCredential?> _reauthenticate(User user) async {
    if (_isAppleAccount(user)) {
      return user.reauthenticateWithProvider(_appleProvider);
    }
    await _initGoogle();
    final googleUser = await GoogleSignIn.instance.authenticate();
    final credential = GoogleAuthProvider.credential(
      idToken: googleUser.authentication.idToken,
    );
    return user.reauthenticateWithCredential(credential);
  }

  /// Collects and deletes all Firestore documents owned by [uid].
  Future<void> _deleteUserData(String uid) async {
    final refs = <DocumentReference<Map<String, dynamic>>>[];

    // The user's recipes, plus every comment stored under each of them.
    final recipes =
        await _recipes.where('userId', isEqualTo: uid).get();
    for (final recipe in recipes.docs) {
      final comments = await recipe.reference.collection('comments').get();
      refs.addAll(comments.docs.map((d) => d.reference));
      refs.add(recipe.reference);
    }

    // Categories owned by the user.
    final categories =
        await _db.collection('categories').where('userId', isEqualTo: uid).get();
    refs.addAll(categories.docs.map((d) => d.reference));

    // Share snapshots the user created.
    final shares =
        await _db.collection('shares').where('userId', isEqualTo: uid).get();
    refs.addAll(shares.docs.map((d) => d.reference));

    // The profile document itself.
    refs.add(_users.doc(uid));

    await _deleteInChunks(refs);
  }

  CollectionReference<Map<String, dynamic>> get _recipes =>
      _db.collection('recipes');

  /// Deletes [refs] in batches, respecting Firestore's 500-writes-per-batch cap.
  Future<void> _deleteInChunks(
    List<DocumentReference<Map<String, dynamic>>> refs,
  ) async {
    const chunkSize = 400;
    for (var i = 0; i < refs.length; i += chunkSize) {
      final end = (i + chunkSize < refs.length) ? i + chunkSize : refs.length;
      final batch = _db.batch();
      for (final ref in refs.sublist(i, end)) {
        batch.delete(ref);
      }
      await batch.commit();
    }
  }

  /// Creates the profile doc on first sight of a user (idempotent, merge).
  Future<void> _ensureUserDoc(User user) async {
    final ref = _users.doc(user.uid);
    final snap = await ref.get();
    if (!snap.exists) {
      await ref.set({
        'name': user.displayName ?? (user.isAnonymous ? 'Guest' : 'Cook'),
        'email': user.email,
        'photoUrl': user.photoURL,
        'isGuest': user.isAnonymous,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  /// Writes the Google profile and returns the display name it stored.
  Future<String> _writeGoogleProfile(User user, GoogleSignInAccount account) async {
    final name = account.displayName ?? user.displayName ?? 'Cook';
    await _users.doc(user.uid).set({
      'name': name,
      'email': account.email,
      'photoUrl': user.photoURL,
      'isGuest': false,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    return name;
  }

  /// Writes the Apple profile and returns the display name it stored.
  ///
  /// Apple hands over the full name only the first time a user authorizes the
  /// app (and never when they've chosen to hide their email), so the name is
  /// resolved in order of preference: what Firebase now holds → the name
  /// already on the profile → a neutral fallback. Only [name] is written back
  /// when the account has no other source, which keeps a user's edited name
  /// intact across sign-ins.
  Future<String> _writeAppleProfile(User user) async {
    final ref = _users.doc(user.uid);
    final existing = (await ref.get()).data()?['name'] as String?;
    final fromApple = user.displayName?.trim();
    final name = (fromApple != null && fromApple.isNotEmpty)
        ? fromApple
        : (existing != null && existing.isNotEmpty && existing != 'Guest')
            ? existing
            : 'Cook';
    await ref.set({
      'name': name,
      // May be an Apple private-relay address when the user hid their email.
      'email': user.email,
      'isGuest': false,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    if (fromApple == null || fromApple.isEmpty) {
      await user.updateDisplayName(name);
    }
    return name;
  }

  /// Propagates a display-name change onto the denormalized `authorName` field
  /// of everything [uid] has authored: their recipes and their share snapshots.
  ///
  /// Called when a guest links a real account (so recipes stamped with the
  /// placeholder 'Guest' pick up the real name) and when a user renames
  /// themselves. Only documents whose stored name actually differs are written.
  ///
  /// Comments are intentionally left untouched: guest and anonymous comments
  /// always render as "Anonymous" regardless of the stored name, and the
  /// Firestore rules don't permit updating comment documents from the client.
  Future<void> _backfillAuthorName(String uid, String name) async {
    final refs = <DocumentReference<Map<String, dynamic>>>[];

    final recipes = await _recipes.where('userId', isEqualTo: uid).get();
    refs.addAll(recipes.docs
        .where((d) => d.data()['authorName'] != name)
        .map((d) => d.reference));

    final shares =
        await _db.collection('shares').where('userId', isEqualTo: uid).get();
    refs.addAll(shares.docs
        .where((d) => d.data()['authorName'] != name)
        .map((d) => d.reference));

    const chunkSize = 400;
    for (var i = 0; i < refs.length; i += chunkSize) {
      final end = (i + chunkSize < refs.length) ? i + chunkSize : refs.length;
      final batch = _db.batch();
      for (final ref in refs.sublist(i, end)) {
        batch.update(ref, {'authorName': name});
      }
      await batch.commit();
    }
  }
}
