import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/comment.dart';

/// Firestore access for comments, stored as a subcollection of each recipe.
/// Mirrors the Rails `CommentsController`.
class CommentRepository {
  CommentRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _commentsOf(String recipeId) =>
      _db.collection('recipes').doc(recipeId).collection('comments');

  Stream<List<Comment>> watchComments(String recipeId) {
    return _commentsOf(recipeId).snapshots().map((snap) {
      final list = snap.docs.map(Comment.fromDoc).toList();
      list.sort((a, b) {
        final at = a.createdAt ?? DateTime(0);
        final bt = b.createdAt ?? DateTime(0);
        return bt.compareTo(at); // newest first
      });
      return list;
    });
  }

  Future<void> addComment({
    required String recipeId,
    required String content,
    String? userId,
    required String authorName,
    required bool anonymous,
  }) {
    return _commentsOf(recipeId).add({
      'userId': userId,
      'authorName': authorName,
      'content': content,
      'anonymous': anonymous,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteComment(String recipeId, String commentId) {
    return _commentsOf(recipeId).doc(commentId).delete();
  }
}
