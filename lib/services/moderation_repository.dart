import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/recipe.dart';

/// The reasons a user can pick when reporting a public recipe.
enum ReportReason {
  spam('Spam or misleading'),
  inappropriate('Inappropriate content'),
  offensive('Offensive or hateful'),
  copyright('Copyright violation'),
  other('Something else');

  const ReportReason(this.label);

  /// Human-readable label shown in the report dialog.
  final String label;
}

/// Firestore access for content moderation: reporting public recipes (stored as
/// standalone records for review) and blocking/hiding recipes from your own feed
/// (stored on your user profile).
class ModerationRepository {
  ModerationRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _reports =>
      _db.collection('reports');

  DocumentReference<Map<String, dynamic>> _user(String uid) =>
      _db.collection('users').doc(uid);

  /// Files a report against [recipe] as a standalone document in `reports`.
  ///
  /// Recipe title/author are denormalized so a reviewer can triage from the
  /// document alone (e.g. in the Firebase console) without extra lookups.
  Future<void> reportRecipe({
    required Recipe recipe,
    required String reporterUid,
    required ReportReason reason,
    String details = '',
  }) {
    return _reports.add({
      'recipeId': recipe.id,
      'recipeTitle': recipe.title,
      'recipeAuthorId': recipe.userId,
      'recipeAuthorName': recipe.authorName,
      'reporterUid': reporterUid,
      'reason': reason.name,
      'reasonLabel': reason.label,
      'details': details.trim(),
      'status': 'open',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Hides [recipeId] from [uid]'s public feed by recording it on their profile.
  Future<void> blockRecipe(String uid, String recipeId) {
    return _user(uid).set(
      {
        'blockedRecipeIds': FieldValue.arrayUnion([recipeId]),
      },
      SetOptions(merge: true),
    );
  }

  /// Reverses [blockRecipe].
  Future<void> unblockRecipe(String uid, String recipeId) {
    return _user(uid).update({
      'blockedRecipeIds': FieldValue.arrayRemove([recipeId]),
    });
  }
}
