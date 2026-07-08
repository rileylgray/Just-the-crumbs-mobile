import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/category.dart';

/// Firestore access for user-owned categories. Mirrors `CategoriesController`.
class CategoryRepository {
  CategoryRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _categories =>
      _db.collection('categories');

  Stream<List<Category>> watchUserCategories(String uid) {
    return _categories.where('userId', isEqualTo: uid).snapshots().map((snap) {
      final list = snap.docs.map(Category.fromDoc).toList();
      list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return list;
    });
  }

  Future<void> createCategory({
    required String uid,
    required String name,
    required String color,
  }) {
    return _categories.add({
      'userId': uid,
      'name': name,
      'color': color,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateCategory(
    String id, {
    required String name,
    required String color,
  }) {
    return _categories.doc(id).update({'name': name, 'color': color});
  }

  Future<void> deleteCategory(String id) => _categories.doc(id).delete();
}
