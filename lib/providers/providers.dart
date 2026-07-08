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
final shareServiceProvider = Provider<ShareService>((_) => ShareService());

/// Manages interstitial ("popup") ads. Kept alive for the app's lifetime so a
/// single ad stays preloaded and the frequency cap persists across screens.
final interstitialAdManagerProvider = Provider<InterstitialAdManager>((ref) {
  final manager = InterstitialAdManager();
  manager.preload();
  return manager;
});

// ---- Auth ------------------------------------------------------------------

/// Firebase auth-state stream (fires on anonymous sign-in, Google link, etc.).
final authStateProvider = StreamProvider<User?>(
  (ref) => ref.watch(authServiceProvider).authStateChanges(),
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

/// Display name used to denormalize recipe authorship.
final currentAuthorNameProvider = Provider<String>(
  (ref) => ref.watch(currentAppUserProvider).value?.name ?? 'Guest',
);

// ---- Recipes ---------------------------------------------------------------

final userRecipesProvider = StreamProvider<List<Recipe>>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return Stream.value(const []);
  return ref.watch(recipeRepositoryProvider).watchUserRecipes(uid);
});

final publicRecipesProvider = StreamProvider<List<Recipe>>(
  (ref) => ref.watch(recipeRepositoryProvider).watchPublicRecipes(),
);

final recipeProvider = StreamProvider.family<Recipe?, String>(
  (ref, id) => ref.watch(recipeRepositoryProvider).watchRecipe(id),
);

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
