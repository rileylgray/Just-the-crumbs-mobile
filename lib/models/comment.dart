import 'package:cloud_firestore/cloud_firestore.dart';

/// A comment on a public recipe. Mirrors the Rails `Comment` model.
class Comment {
  final String id;
  final String? userId; // null for guests
  final String authorName;
  final String content;
  final bool anonymous;
  final DateTime? createdAt;

  const Comment({
    required this.id,
    required this.userId,
    required this.authorName,
    required this.content,
    required this.anonymous,
    this.createdAt,
  });

  factory Comment.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const {};
    return Comment(
      id: doc.id,
      userId: data['userId'] as String?,
      authorName: data['authorName'] as String? ?? 'Anonymous',
      content: data['content'] as String? ?? '',
      anonymous: data['anonymous'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'authorName': authorName,
        'content': content,
        'anonymous': anonymous,
      };

  /// Name to show, matching Rails `Comment#display_name`.
  String get displayName => (anonymous || userId == null) ? 'Anonymous' : authorName;
}
