import 'package:cloud_firestore/cloud_firestore.dart';

class Mark {
  final String id;
  final String name;
  final String description;
  final String image;
  final bool verified;
  final DateTime? creation;
  final DateTime? upgrade;

  Mark({
    required this.id,
    required this.name,
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
      'description': description,
      'image': image,
      'verified': verified,
      'creation': creation != null ? Timestamp.fromDate(creation!) : null,
      'upgrade': upgrade != null ? Timestamp.fromDate(upgrade!) : null,
    };
  }

  factory Mark.fromMap(Map<String, dynamic> map) {
    // Soporte para campos antiguos y nuevos
    String getName() {
      if (map.containsKey('name') && map['name'] != null && map['name'].toString().isNotEmpty) {
        return map['name'].toString();
      }
      // Compatibilidad con campo antiguo 'titulo'
      if (map.containsKey('titulo') && map['titulo'] != null && map['titulo'].toString().isNotEmpty) {
        return map['titulo'].toString();
      }
      return '';
    }

    String getDescription() {
      if (map.containsKey('description') && map['description'] != null) {
        return map['description'].toString();
      }
      // Compatibilidad con campo antiguo 'descripcion'
      if (map.containsKey('descripcion') && map['descripcion'] != null) {
        return map['descripcion'].toString();
      }
      return '';
    }

    String getImage() {
      if (map.containsKey('image') && map['image'] != null && map['image'].toString().isNotEmpty) {
        return map['image'].toString();
      }
      // Compatibilidad con campo antiguo 'url_imagen'
      if (map.containsKey('url_imagen') && map['url_imagen'] != null && map['url_imagen'].toString().isNotEmpty) {
        return map['url_imagen'].toString();
      }
      return '';
    }

    bool getVerified() {
      if (map.containsKey('verified')) {
        return map['verified'] ?? false;
      }
      // Compatibilidad con campo antiguo 'verificado'
      if (map.containsKey('verificado')) {
        return map['verificado'] ?? false;
      }
      return false;
    }

    return Mark(
      id: map['id'] ?? '',
      name: getName(),
      description: getDescription(),
      image: getImage(),
      verified: getVerified(),
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
      description: description ?? this.description,
      image: image ?? this.image,
      verified: verified ?? this.verified,
      creation: creation ?? this.creation,
      upgrade: upgrade ?? this.upgrade,
    );
  }
}
