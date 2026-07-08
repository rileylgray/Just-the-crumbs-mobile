import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// A user-owned recipe category with a color. Mirrors the Rails `Category` model.
class Category {
  final String id;
  final String userId;
  final String name;
  final String color; // hex string, e.g. "#D4A574"
  final DateTime? createdAt;

  const Category({
    required this.id,
    required this.userId,
    required this.name,
    required this.color,
    this.createdAt,
  });

  factory Category.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const {};
    return Category(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      name: data['name'] as String? ?? '',
      color: data['color'] as String? ?? '#D4A574',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'name': name,
        'color': color,
      };

  /// Parse the stored hex string into a [Color].
  Color get colorValue {
    final hex = color.replaceAll('#', '');
    if (hex.length == 6) {
      return Color(int.parse('FF$hex', radix: 16));
    }
    return const Color(0xFFD4A574);
  }
}
