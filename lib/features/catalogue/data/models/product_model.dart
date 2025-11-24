import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/product.dart';

/// Modelo de datos que extiende [Product] y maneja la serialización
/// desde/hacia Firestore y JSON.
/// 
/// Esta clase pertenece a la capa de datos y contiene toda la lógica
/// de conversión y mapeo de datos externos.
class ProductModel extends Product {
  ProductModel({
    super.id,
    super.idMark,
    super.nameMark,
    super.imageMark,
    super.description,
    super.image,
    super.code,
    super.followers,
    super.favorite,
    super.verified,
    super.reviewed,
    required super.creation,
    required super.upgrade,
    super.idUserCreation,
    super.idUserUpgrade,
  });

  /// Crea una instancia desde un Map de datos
  factory ProductModel.fromMap(Map<String, dynamic> data) {
    return ProductModel(
      id: data.containsKey('id') ? data['id'] : '',
      followers: data.containsKey('followers') ? data['followers'] : 0,
      idUserCreation: data.containsKey('idUserCreation') ? data['idUserCreation'] : '',
      idUserUpgrade: data.containsKey('idUserUpgrade') ? data['idUserUpgrade'] : '',
      verified: data.containsKey('verified') ? data['verified'] : false,
      reviewed: data.containsKey('reviewed') ? data['reviewed'] : false,
      favorite: data.containsKey('favorite') ? data['favorite'] : false,
      idMark: data.containsKey('idMark')
          ? data['idMark']
          : data.containsKey('id_marca')
              ? data['id_marca']
              : '',
      nameMark: data.containsKey('nameMark') ? data['nameMark'] : '',
      imageMark: data.containsKey('imageMark') ? data['imageMark'] : '',
      image: data.containsKey('image')
          ? data['image']
          : data.containsKey('urlimagen')
              ? data['urlimagen']
              : '',
      description: data.containsKey('description')
          ? data['description']
          : data.containsKey('descripcion')
              ? data['descripcion']
              : '',
      code: data.containsKey('code')
          ? data['code']
          : data.containsKey('codigo')
              ? data['codigo']
              : '',
      upgrade: _parseTimestamp(data['upgrade']),
      creation: _parseTimestamp(data['creation']),
    );
  }

  /// Crea una instancia desde un DocumentSnapshot de Firestore
  factory ProductModel.fromDocumentSnapshot(DocumentSnapshot documentSnapshot) {
    Map<String, dynamic> data = documentSnapshot.data() as Map<String, dynamic>;
    return ProductModel.fromMap(data);
  }

  /// Convierte la instancia a un Map para guardar en Firestore
  Map<String, dynamic> toJson() => {
        "id": id,
        'followers': followers,
        'idUserCreation': idUserCreation,
        'idUserUpgrade': idUserUpgrade,
        "verified": verified,
        'reviewed': reviewed,
        "favorite": favorite,
        "idMark": idMark,
        'nameMark': nameMark,
        'imageMark': imageMark,
        "image": image,
        "description": description,
        "code": code,
        "creation": Timestamp.fromDate(creation),
        "upgrade": Timestamp.fromDate(upgrade),
      };

  /// Convierte a JSON para actualizaciones (omitiendo campos inmutables)
  Map<String, dynamic> toJsonUpdate() => {
        "id": id,
        'followers': followers,
        'idUserUpgrade': idUserUpgrade,
        "verified": verified,
        'reviewed': reviewed,
        "favorite": favorite,
        "idMark": idMark,
        'nameMark': nameMark,
        'imageMark': imageMark,
        "image": image,
        "description": description,
        "upgrade": Timestamp.fromDate(upgrade),
      };

  /// Convierte a la entidad de dominio pura
  Product toEntity() {
    return Product(
      id: id,
      idMark: idMark,
      nameMark: nameMark,
      imageMark: imageMark,
      description: description,
      image: image,
      code: code,
      followers: followers,
      favorite: favorite,
      verified: verified,
      reviewed: reviewed,
      creation: creation,
      upgrade: upgrade,
      idUserCreation: idUserCreation,
      idUserUpgrade: idUserUpgrade,
    );
  }

  /// Helper para parsear Timestamp a DateTime
  static DateTime _parseTimestamp(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    return DateTime.now();
  }
}
