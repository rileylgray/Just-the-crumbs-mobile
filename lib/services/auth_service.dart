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
