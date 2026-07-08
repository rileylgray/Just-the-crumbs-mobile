import 'package:cloud_firestore/cloud_firestore.dart';

/// A recipe owned by a user. Mirrors the Rails `Recipe` model.
class Recipe {
  final String id;
  final String userId;
  final String authorName; // denormalized for the public feed
  final String title;
  final String description;
  final List<String> ingredients;
  final List<String> steps;
  final String sourceUrl;
  final int position;
  final bool isPublic;
  final List<String> categoryIds;

  /// BCP-47 language code of the recipe's content (e.g. `en`, `es`). Used to
  /// filter and badge recipes in the public Discover feed. Legacy recipes with
  /// no stored value default to English, which the app used before this field.
  final String language;
  final String? shareCode;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Recipe({
    required this.id,
    required this.userId,
    required this.authorName,
    required this.title,
    required this.description,
    required this.ingredients,
    required this.steps,
    required this.sourceUrl,
    required this.position,
    required this.isPublic,
    required this.categoryIds,
    this.language = 'en',
    this.shareCode,
    this.createdAt,
    this.updatedAt,
  });

  factory Recipe.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) =>
      Recipe.fromMap(doc.id, doc.data() ?? const {});

  /// Build from a raw map. Used for both recipe docs and share snapshots
  /// (a share snapshot passes the original `recipeId` as [id]).
  factory Recipe.fromMap(String id, Map<String, dynamic> data) {
    return Recipe(
      id: id,
      userId: data['userId'] as String? ?? '',
      authorName: data['authorName'] as String? ?? 'Anonymous',
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      ingredients: _stringList(data['ingredients']),
      steps: _stringList(data['steps']),
      sourceUrl: data['sourceUrl'] as String? ?? '',
      position: (data['position'] as num?)?.toInt() ?? 0,
      isPublic: data['public'] as bool? ?? false,
      categoryIds: _stringList(data['categoryIds']),
      language: (data['language'] as String?)?.trim().isNotEmpty == true
          ? (data['language'] as String)
          : 'en',
      shareCode: data['shareCode'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
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
      };

  Recipe copyWith({
    String? title,
    String? description,
    List<String>? ingredients,
    List<String>? steps,
    String? sourceUrl,
    int? position,
    bool? isPublic,
    List<String>? categoryIds,
    String? language,
  }) {
    return Recipe(
      id: id,
      userId: userId,
      authorName: authorName,
      title: title ?? this.title,
      description: description ?? this.description,
      ingredients: ingredients ?? this.ingredients,
      steps: steps ?? this.steps,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      position: position ?? this.position,
      isPublic: isPublic ?? this.isPublic,
      categoryIds: categoryIds ?? this.categoryIds,
      language: language ?? this.language,
      shareCode: shareCode,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  static List<String> _stringList(dynamic value) {
    if (value is List) {
      return value.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
    }
    if (value is String) {
      // Tolerate legacy newline-delimited text.
      return value
          .split('\n')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return const [];
  }
}
