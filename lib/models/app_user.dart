import 'package:cloud_firestore/cloud_firestore.dart';

/// Application-level user profile stored in Firestore, keyed by the Firebase
/// Auth uid. Guests (anonymous auth) get a placeholder name until they link a
/// Google account.
class AppUser {
  final String uid;
  final String name;
  final String? email;
  final String? photoUrl;
  final bool isGuest;

  /// Public recipe ids this user has blocked (hidden from their feed).
  final List<String> blockedRecipeIds;

  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.photoUrl,
    required this.isGuest,
    this.blockedRecipeIds = const [],
  });

  factory AppUser.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const {};
    return AppUser(
      uid: doc.id,
      name: data['name'] as String? ?? 'Guest',
      email: data['email'] as String?,
      photoUrl: data['photoUrl'] as String?,
      isGuest: data['isGuest'] as bool? ?? true,
      blockedRecipeIds: (data['blockedRecipeIds'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'email': email,
        'photoUrl': photoUrl,
        'isGuest': isGuest,
        'blockedRecipeIds': blockedRecipeIds,
      };
}
