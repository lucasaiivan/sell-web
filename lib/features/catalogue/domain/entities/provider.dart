import 'package:cloud_firestore/cloud_firestore.dart';

class Provider {
  final String id;
  final String name;
  final String? phone;
  final String? email;

  Provider({
    required this.id,
    required this.name,
    this.phone,
    this.email,
  });

  factory Provider.fromDocumentSnapshot(
      {required DocumentSnapshot documentSnapshot}) {
    final rawData = documentSnapshot.data();
    final data =
        rawData != null ? Map<String, dynamic>.from(rawData as dynamic) : {};

    return Provider(
      id: documentSnapshot.id,
      name: data['name'] ?? '',
      phone: data['phone'],
      email: data['email'],
    );
  }
}
