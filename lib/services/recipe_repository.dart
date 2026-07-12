import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/recipe.dart';

/// Firestore access for recipes. Mirrors the Rails `RecipesController` +
/// `Recipe` model behavior (ordering, reordering, public feed, copy).
class RecipeRepository {
  RecipeRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _recipes =>
      _db.collection('recipes');

  /// Current user's recipes, ordered by position then creation (Rails `ordered`).
  Stream<List<Recipe>> watchUserRecipes(String uid) {
    return _recipes.where('userId', isEqualTo: uid).snapshots().map((snap) {
      final list = snap.docs.map(Recipe.fromDoc).toList();
      list.sort((a, b) {
        final byPos = a.position.compareTo(b.position);
        if (byPos != 0) return byPos;
        final at = a.createdAt ?? DateTime(0);
        final bt = b.createdAt ?? DateTime(0);
        return at.compareTo(bt);
      });
      return list;
    });
  }

  /// Public recipes for the community feed, newest first.
  Stream<List<Recipe>> watchPublicRecipes() {
    return _recipes.where('public', isEqualTo: true).snapshots().map((snap) {
      final list = snap.docs.map(Recipe.fromDoc).toList();
      list.sort((a, b) {
        final at = a.createdAt ?? DateTime(0);
        final bt = b.createdAt ?? DateTime(0);
        return bt.compareTo(at); // desc
      });
      return list;
    });
  }

  Stream<Recipe?> watchRecipe(String id) {
    return _recipes
        .doc(id)
        .snapshots()
        .map((doc) => doc.exists ? Recipe.fromDoc(doc) : null);
  }

  Future<Recipe?> getRecipe(String id) async {
    final doc = await _recipes.doc(id).get();
    return doc.exists ? Recipe.fromDoc(doc) : null;
  }

  Future<String> createRecipe({
    required String uid,
    required String authorName,
    required String title,
    required String description,
    required List<String> ingredients,
    required List<String> steps,
    required String sourceUrl,
    required bool isPublic,
    required List<String> categoryIds,
    required String language,
  }) async {
    final position = await _nextPosition(uid);
    // Use a locally-generated id and DON'T await the write. The Firestore SDK
    // persists the write to its local cache immediately and syncs to the server
    // when connectivity allows. The future returned by set() only completes on
    // server acknowledgement, so awaiting it hangs indefinitely while offline
    // (or on a flaky connection) even though the recipe is already saved locally
    // and shows up in streams. See: the "create shows an endless spinner but the
    // recipe was actually created" bug.
    final ref = _recipes.doc();
    unawaited(
      ref
          .set({
            'userId': uid,
            'authorName': authorName,
            'title': title,
            'description': description,
            'ingredients': ingredients,
            'steps': steps,
            'sourceUrl': sourceUrl,
            'position': position,
            'public': isPublic,
            'categoryIds': categoryIds,
            'language': language,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          })
          .catchError((Object _) {
            // The write is already durably queued in the local cache; the SDK retries
            // transient server errors on its own, so there is nothing to surface here.
          }),
    );
    return ref.id;
  }

  Future<void> updateRecipe(
    String id, {
    required String title,
    required String description,
    required List<String> ingredients,
    required List<String> steps,
    required String sourceUrl,
    required bool isPublic,
    required List<String> categoryIds,
    required String language,
  }) async {
    // Don't await the write (see createRecipe). The Firestore SDK applies the
    // update to its local cache immediately — so streams reflect the edit right
    // away — and syncs to the server when connectivity allows. Awaiting instead
    // waits on server acknowledgement, which never arrives while offline or on a
    // flaky connection, leaving the editor stuck on a spinner.
    unawaited(
      _recipes
          .doc(id)
          .update({
            'title': title,
            'description': description,
            'ingredients': ingredients,
            'steps': steps,
            'sourceUrl': sourceUrl,
            'public': isPublic,
            'categoryIds': categoryIds,
            'language': language,
            'updatedAt': FieldValue.serverTimestamp(),
          })
          .catchError((Object _) {
            // Already durably queued in the local cache; the SDK retries on its own.
          }),
    );
  }

  Future<void> setPublic(String id, bool isPublic) {
    return _recipes.doc(id).update({
      'public': isPublic,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteRecipe(String id) => _recipes.doc(id).delete();

  /// Persist a new manual ordering (from drag-and-drop) as `position` = index.
  Future<void> persistOrder(List<Recipe> ordered) async {
    final batch = _db.batch();
    for (var i = 0; i < ordered.length; i++) {
      if (ordered[i].position != i) {
        batch.update(_recipes.doc(ordered[i].id), {'position': i});
      }
    }
    await batch.commit();
  }

  /// Copy a (shared/public) recipe into [uid]'s collection. Rails `copy` action.
  Future<String> copyRecipe({
    required Recipe source,
    required String uid,
    required String authorName,
  }) {
    return createRecipe(
      uid: uid,
      authorName: authorName,
      title: source.title,
      description: source.description,
      ingredients: source.ingredients,
      steps: source.steps,
      sourceUrl: source.sourceUrl,
      isPublic: false,
      categoryIds: const [],
      language: source.language, // preserve the original recipe's language
    );
  }

  // ---- Sharing via unguessable code -----------------------------------------

  CollectionReference<Map<String, dynamic>> get _shares =>
      _db.collection('shares');

  /// Ensures a shareable snapshot exists for [recipe] and returns its code.
  ///
  /// The snapshot in `shares/{code}` is self-contained, so a recipient can read
  /// it via the (unguessable) code alone — the recipe itself can stay private.
  /// Reusing the recipe's existing code keeps shared links stable while
  /// refreshing the snapshot to the current content.
  Future<String> ensureShareCode(Recipe recipe) async {
    final code = (recipe.shareCode != null && recipe.shareCode!.isNotEmpty)
        ? recipe.shareCode!
        : await _uniqueCode();

    await _shares.doc(code).set({
      'recipeId': recipe.id,
      'userId': recipe.userId,
      'authorName': recipe.authorName,
      'title': recipe.title,
      'description': recipe.description,
      'ingredients': recipe.ingredients,
      'steps': recipe.steps,
      'sourceUrl': recipe.sourceUrl,
      'createdAt': FieldValue.serverTimestamp(),
    });

    if (recipe.shareCode != code) {
      await _recipes.doc(recipe.id).update({'shareCode': code});
    }
    return code;
  }

  /// Reads a shared recipe snapshot by its code, or null if the code is invalid.
  Future<Recipe?> getSharedRecipe(String code) async {
    final doc = await _shares.doc(code.trim()).get();
    if (!doc.exists) return null;
    final data = doc.data()!;
    return Recipe.fromMap(data['recipeId'] as String? ?? doc.id, data);
  }

  // Unambiguous alphabet (no 0/O/1/I) for hand-typed codes.
  static const _codeAlphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  final _rand = Random.secure();

  String _generateCode([int length = 8]) => List.generate(
    length,
    (_) => _codeAlphabet[_rand.nextInt(_codeAlphabet.length)],
  ).join();

  Future<String> _uniqueCode() async {
    for (var attempt = 0; attempt < 5; attempt++) {
      final code = _generateCode();
      final existing = await _shares.doc(code).get();
      if (!existing.exists) return code;
    }
    // Extremely unlikely; widen the space.
    return _generateCode(10);
  }

  Future<int> _nextPosition(String uid) async {
    // Compute max client-side to avoid a composite (userId + position) index.
    //
    // Read cache-first. A query .get() with the default (serverAndCache) source
    // WAITS for the server on a flaky connection instead of falling back to the
    // cache promptly, which would stall recipe creation before the write is even
    // queued — the user sees an endless spinner, backs out, and finds the recipe
    // was created anyway (once the stalled read finally resolved) but was never
    // redirected. The user's recipe-list stream keeps this cache warm, so the
    // cache is the correct source here.
    final query = _recipes.where('userId', isEqualTo: uid);
    QuerySnapshot<Map<String, dynamic>> snap;
    try {
      snap = await query.get(const GetOptions(source: Source.cache));
    } catch (_) {
      snap = await _emptyOrServer(query);
    }
    if (snap.docs.isEmpty) {
      // Cold cache (e.g. first launch on a new device). Try the server, but
      // never let it block creation for long — end-of-list is a safe default.
      snap = await _emptyOrServer(query);
    }
    if (snap.docs.isEmpty) return 0;
    final maxPos = snap.docs
        .map((d) => (d.data()['position'] as num?)?.toInt() ?? 0)
        .fold<int>(-1, (a, b) => a > b ? a : b);
    return maxPos + 1;
  }

  /// A best-effort server read that resolves to an empty snapshot rather than
  /// hanging when the backend is slow or unreachable.
  Future<QuerySnapshot<Map<String, dynamic>>> _emptyOrServer(
    Query<Map<String, dynamic>> query,
  ) async {
    try {
      return await query
          .get(const GetOptions(source: Source.server))
          .timeout(const Duration(seconds: 4));
    } catch (_) {
      return query.get(const GetOptions(source: Source.cache));
    }
  }
}
