import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_user.dart';
import '../models/category.dart';
import '../models/comment.dart';
import '../models/recipe.dart';
import '../services/ad_service.dart';
import '../services/auth_service.dart';
import '../services/category_repository.dart';
import '../services/comment_repository.dart';
import '../services/moderation_repository.dart';
import '../services/recipe_repository.dart';
import '../services/share_service.dart';

// ---- Infrastructure --------------------------------------------------------

final firebaseAuthProvider = Provider<FirebaseAuth>((_) => FirebaseAuth.instance);
final firestoreProvider =
    Provider<FirebaseFirestore>((_) => FirebaseFirestore.instance);

final authServiceProvider = Provider<AuthService>(
  (ref) => AuthService(
    ref.watch(firebaseAuthProvider),
    ref.watch(firestoreProvider),
  ),
);

final recipeRepositoryProvider = Provider<RecipeRepository>(
  (ref) => RecipeRepository(ref.watch(firestoreProvider)),
);
final categoryRepositoryProvider = Provider<CategoryRepository>(
  (ref) => CategoryRepository(ref.watch(firestoreProvider)),
);
final commentRepositoryProvider = Provider<CommentRepository>(
  (ref) => CommentRepository(ref.watch(firestoreProvider)),
);
final moderationRepositoryProvider = Provider<ModerationRepository>(
  (ref) => ModerationRepository(ref.watch(firestoreProvider)),
);
final shareServiceProvider = Provider<ShareService>((_) => ShareService());

/// Manages interstitial ("popup") ads. Kept alive for the app's lifetime so a
/// single ad stays preloaded and the frequency cap persists across screens.
final interstitialAdManagerProvider = Provider<InterstitialAdManager>((ref) {
  final manager = InterstitialAdManager();
  manager.preload();
  return manager;
});

// ---- Auth ------------------------------------------------------------------

/// Firebase user-state stream (fires on anonymous sign-in, Google link, etc.).
final authStateProvider = StreamProvider<User?>(
  (ref) => ref.watch(authServiceProvider).userChanges(),
);

/// The current uid, or null before startup sign-in completes.
final currentUidProvider = Provider<String?>(
  (ref) => ref.watch(authStateProvider).value?.uid,
);

/// True when the signed-in user is a guest (anonymous auth).
final isGuestProvider = Provider<bool>(
  (ref) => ref.watch(authStateProvider).value?.isAnonymous ?? true,
);

/// The current user's Firestore profile.
final currentAppUserProvider = StreamProvider<AppUser?>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return Stream.value(null);
  return ref
      .watch(firestoreProvider)
      .collection('users')
      .doc(uid)
      .snapshots()
      .map((doc) => doc.exists ? AppUser.fromDoc(doc) : null);
});

// ---- Recipes ---------------------------------------------------------------

final userRecipesProvider = StreamProvider<List<Recipe>>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return Stream.value(const []);
  return ref.watch(recipeRepositoryProvider).watchUserRecipes(uid);
});

final publicRecipesProvider = StreamProvider<List<Recipe>>(
  (ref) => ref.watch(recipeRepositoryProvider).watchPublicRecipes(),
);

/// Whether the app can currently reach Firestore's backend.
///
/// Derived from snapshot metadata on a tiny listener over the user's own
/// recipes: while offline, Firestore serves from its local cache and flags the
/// snapshot `isFromCache`; once it syncs with the server that flag clears. This
/// gives us a real backend-reachability signal (recipes stay viewable offline
/// but writes are gated) without pulling in a separate connectivity package.
/// Defaults to online (`true`) while unknown so actions aren't hidden on launch.
final isOnlineProvider = StreamProvider<bool>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return Stream.value(true);
  return ref
      .watch(firestoreProvider)
      .collection('recipes')
      .where('userId', isEqualTo: uid)
      .limit(1)
      .snapshots(includeMetadataChanges: true)
      .map((snap) => !snap.metadata.isFromCache);
});

/// Recipe ids the current user has blocked (hidden from their public feed).
final blockedRecipeIdsProvider = Provider<Set<String>>(
  (ref) =>
      ref.watch(currentAppUserProvider).value?.blockedRecipeIds.toSet() ??
      const {},
);

/// Public feed with the current user's blocked recipes filtered out.
final visiblePublicRecipesProvider = Provider<AsyncValue<List<Recipe>>>((ref) {
  final blocked = ref.watch(blockedRecipeIdsProvider);
  return ref.watch(publicRecipesProvider).whenData(
        (recipes) =>
            recipes.where((r) => !blocked.contains(r.id)).toList(),
      );
});

final recipeProvider = StreamProvider.family<Recipe?, String>(
  (ref, id) => ref.watch(recipeRepositoryProvider).watchRecipe(id),
);

/// Whether the current user has liked recipe [id] (live). Defaults to false
/// while the uid is still resolving.
final userLikedProvider = StreamProvider.family<bool, String>((ref, id) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return Stream.value(false);
  return ref.watch(recipeRepositoryProvider).watchUserLike(id, uid);
});

// ---- Categories ------------------------------------------------------------

final userCategoriesProvider = StreamProvider<List<Category>>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return Stream.value(const []);
  return ref.watch(categoryRepositoryProvider).watchUserCategories(uid);
});

/// Fetches a shared recipe snapshot by its code (null if the code is invalid).
final sharedRecipeProvider = FutureProvider.family<Recipe?, String>(
  (ref, code) => ref.watch(recipeRepositoryProvider).getSharedRecipe(code),
);

// ---- Comments --------------------------------------------------------------

final commentsProvider = StreamProvider.family<List<Comment>, String>(
  (ref, recipeId) =>
      ref.watch(commentRepositoryProvider).watchComments(recipeId),
);
