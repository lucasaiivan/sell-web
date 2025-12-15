import 'package:cloud_firestore/cloud_firestore.dart';

class Mark {
  final String id;
  final String name;
  final String country;
  final String description;
  final String image;
  final bool verified;
  final DateTime? creation;
  final DateTime? upgrade;

  Mark({
    required this.id,
    required this.name,
    required this.country,
    this.description = '',
    this.image = '',
    this.verified = false,
    this.creation,
    this.upgrade,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'country': country,
      'description': description,
      'image': image,
      'verified': verified,
      'creation': creation != null ? Timestamp.fromDate(creation!) : null,
      'upgrade': upgrade != null ? Timestamp.fromDate(upgrade!) : null,
    };
  }

  factory Mark.fromMap(Map<String, dynamic> map) {
    return Mark(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      country: map['country'] ?? '',
      description: map['description'] ?? '',
      image: map['image'] ?? '',
      verified: map['verified'] ?? false,
      creation: map['creation'] is Timestamp
          ? (map['creation'] as Timestamp).toDate()
          : null,
      upgrade: map['upgrade'] is Timestamp
          ? (map['upgrade'] as Timestamp).toDate()
          : null,
    );
  }

  Mark copyWith({
    String? id,
    String? name,
    String? country,
    String? description,
    String? image,
    bool? verified,
    DateTime? creation,
    DateTime? upgrade,
  }) {
    return Mark(
      id: id ?? this.id,
      name: name ?? this.name,
      country: country ?? this.country,
      description: description ?? this.description,
      image: image ?? this.image,
      verified: verified ?? this.verified,
      creation: creation ?? this.creation,
      upgrade: upgrade ?? this.upgrade,
    );
  }
}
