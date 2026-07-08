import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../config.dart';

/// Wraps Firebase Auth + Google Sign-In and keeps a Firestore `users/{uid}`
/// profile in sync.
///
/// Model: the app signs in **anonymously** at startup so guests can browse and
/// comment immediately. Tapping "Sign in with Google" **links** the Google
/// credential onto the anonymous account, preserving any recipes made as a
/// guest. If that Google account already exists, we sign into it instead.
class AuthService {
  AuthService(this._auth, this._db);

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;
  bool _googleInitialized = false;

  User? get currentUser => _auth.currentUser;
  Stream<User?> authStateChanges() => _auth.authStateChanges();

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

  Future<void> _initGoogle() async {
    if (_googleInitialized) return;
    await GoogleSignIn.instance.initialize(
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
    await _writeGoogleProfile(user, googleUser);
    return user;
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
  /// the auth user requires a recent sign-in; for Google accounts we transparently
  /// re-authenticate when Firebase asks. A fresh guest session is started
  /// afterwards so the app stays usable.
  ///
  /// Two things are intentionally left behind: abuse *reports* (retained for
  /// moderation integrity — the rules forbid client deletion) and comments the
  /// user left on *other* people's recipes (a collection-group delete is blocked
  /// by the comment read rule). Removing those requires a server-side sweep.
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _deleteUserData(user.uid);

    try {
      await user.delete();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login' && !user.isAnonymous) {
        await _reauthenticateGoogle(user);
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

  /// Re-signs in with Google to satisfy Firebase's recent-login requirement
  /// before a sensitive operation like account deletion.
  Future<void> _reauthenticateGoogle(User user) async {
    await _initGoogle();
    final googleUser = await GoogleSignIn.instance.authenticate();
    final credential = GoogleAuthProvider.credential(
      idToken: googleUser.authentication.idToken,
    );
    await user.reauthenticateWithCredential(credential);
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

  Future<void> _writeGoogleProfile(User user, GoogleSignInAccount account) async {
    await _users.doc(user.uid).set({
      'name': account.displayName ?? user.displayName ?? 'Cook',
      'email': account.email,
      'photoUrl': user.photoURL,
      'isGuest': false,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
