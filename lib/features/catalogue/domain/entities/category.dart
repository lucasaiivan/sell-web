import 'package:cloud_firestore/cloud_firestore.dart';

class Category {
  final String id;
  final String name;
  final Map<String, dynamic> subcategories;

  Category({
    this.id = "",
    this.name = "",
    this.subcategories = const {},
  });

  factory Category.fromDocumentSnapshot(
      {required DocumentSnapshot documentSnapshot}) {
    final rawData = documentSnapshot.data();
    final data =
        rawData != null ? Map<String, dynamic>.from(rawData as dynamic) : {};

    return Category(
      id: documentSnapshot.id,
      name: data['name'] ?? '',
      subcategories: data['subcategories'] ?? {},
    );
  }
}
