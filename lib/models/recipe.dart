import 'package:cloud_firestore/cloud_firestore.dart';

/// A named group of ingredients within a recipe (e.g. "Crust", "Filling").
///
/// Most recipes have a single group with an empty [title], which renders as a
/// plain ingredient list. Multi-part recipes use one group per part so the
/// editor and the recipe view can show a heading above each set of ingredients.
class IngredientGroup {
  const IngredientGroup({this.title = '', this.items = const []});

  /// Heading for this group (e.g. "Crust"). Empty for the default/ungrouped set.
  final String title;
  final List<String> items;

  bool get isDefault => title.trim().isEmpty;

  Map<String, dynamic> toMap() => {'title': title, 'items': items};

  factory IngredientGroup.fromMap(Map<String, dynamic> data) => IngredientGroup(
        title: (data['title'] as String? ?? '').trim(),
        items: Recipe._stringList(data['items']),
      );

}

/// A recipe owned by a user. Mirrors the Rails `Recipe` model.
class Recipe {
  final String id;
  final String userId;
  final String authorName; // denormalized for the public feed
  final String title;
  final String description;

  /// Ingredients grouped into (optionally named) parts. Legacy recipes with a
  /// flat `ingredients` array read back as a single untitled group.
  final List<IngredientGroup> ingredientGroups;
  final List<String> steps;
  final String sourceUrl;
  final int position;
  final bool isPublic;
  final List<String> categoryIds;

  /// How many users have liked this (public) recipe. Maintained by the like
  /// toggle; absent on legacy recipes, which read back as 0.
  final int likeCount;

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
    required this.ingredientGroups,
    required this.steps,
    required this.sourceUrl,
    required this.position,
    required this.isPublic,
    required this.categoryIds,
    this.likeCount = 0,
    this.language = 'en',
    this.shareCode,
    this.createdAt,
    this.updatedAt,
  });

  /// A flat list of every ingredient across all groups. Kept for callers that
  /// only need counts, search or the legacy flat representation.
  List<String> get ingredients =>
      [for (final g in ingredientGroups) ...g.items];

  /// Whether [query] appears (case-insensitively) in the title, description
  /// or any ingredient — so searching "chicken" also finds recipes that only
  /// list it as an ingredient. An empty query matches everything.
  bool matchesSearch(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return title.toLowerCase().contains(q) ||
        description.toLowerCase().contains(q) ||
        ingredients.any((i) => i.toLowerCase().contains(q));
  }

  /// Whether this recipe splits its ingredients into named parts.
  bool get hasIngredientGroups =>
      ingredientGroups.length > 1 ||
      (ingredientGroups.length == 1 && !ingredientGroups.first.isDefault);

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
      ingredientGroups: _readIngredientGroups(data),
      steps: _stringList(data['steps']),
      sourceUrl: data['sourceUrl'] as String? ?? '',
      position: (data['position'] as num?)?.toInt() ?? 0,
      isPublic: data['public'] as bool? ?? false,
      categoryIds: _stringList(data['categoryIds']),
      likeCount: (data['likeCount'] as num?)?.toInt() ?? 0,
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
        // Write the flat list too, so older clients and count-only readers keep
        // working regardless of the structured groups.
        'ingredients': ingredients,
        'ingredientGroups': [for (final g in ingredientGroups) g.toMap()],
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
    List<IngredientGroup>? ingredientGroups,
    List<String>? steps,
    String? sourceUrl,
    int? position,
    bool? isPublic,
    List<String>? categoryIds,
    int? likeCount,
    String? language,
  }) {
    return Recipe(
      id: id,
      userId: userId,
      authorName: authorName,
      title: title ?? this.title,
      description: description ?? this.description,
      ingredientGroups: ingredientGroups ?? this.ingredientGroups,
      steps: steps ?? this.steps,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      position: position ?? this.position,
      isPublic: isPublic ?? this.isPublic,
      categoryIds: categoryIds ?? this.categoryIds,
      likeCount: likeCount ?? this.likeCount,
      language: language ?? this.language,
      shareCode: shareCode,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Reads structured [ingredientGroups] when present, otherwise falls back to
  /// the flat `ingredients` array as a single untitled group. Legacy recipes
  /// (flat only) therefore keep displaying exactly as before.
  static List<IngredientGroup> _readIngredientGroups(Map<String, dynamic> data) {
    final raw = data['ingredientGroups'];
    if (raw is List) {
      final groups = raw
          .whereType<Map>()
          .map((m) => IngredientGroup.fromMap(Map<String, dynamic>.from(m)))
          .where((g) => g.items.isNotEmpty)
          .toList();
      if (groups.isNotEmpty) return groups;
    }
    return [IngredientGroup(items: _stringList(data['ingredients']))];
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
