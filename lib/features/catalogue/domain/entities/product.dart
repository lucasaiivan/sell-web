import 'package:cloud_firestore/cloud_firestore.dart';
import 'product_catalogue.dart';

/// Entidad que representa un producto en su forma más pura.
/// No contiene dependencias externas (Firebase, JSON, etc.)
class Product {
  /// ID único del producto
  final String id;

  /// ID de la marca asociada
  final String idMark;

  /// Nombre de la marca
  final String nameMark;

  /// URL de la imagen de la marca
  final String imageMark;

  /// Descripción del producto
  final String description;

  /// URL de la imagen del producto
  final String image;

  /// Código del producto
  final String code;

  /// Número de seguidores del producto
  final int followers;

  /// Indica si el producto está marcado como favorito
  final bool favorite;

  /// Indica si el producto ha sido verificado por un moderador
  final bool verified;

  /// Indica si el producto ha sido revisado por un moderador
  final bool reviewed;

  /// Fecha y hora de creación del producto
  final DateTime creation;

  /// Fecha y hora de la última actualización
  final DateTime upgrade;

  /// ID del usuario que creó el producto
  final String idUserCreation;

  /// ID del usuario que actualizó el producto
  final String idUserUpgrade;

  /// Convierte este producto global a un producto de catálogo
  ProductCatalogue convertProductCatalogue() {
    return ProductCatalogue(
      id: id,
      idMark: idMark,
      nameMark: nameMark,
      imageMark: imageMark,
      image: image,
      description: description,
      code: code,
      verified: verified,
      reviewed: reviewed,
      followers: followers,
      favorite: favorite,
      creation: creation,
      upgrade: upgrade,
      documentCreation: DateTime.now(),
      documentUpgrade: DateTime.now(),
      // Valores por defecto para campos específicos del catálogo
      stock: false,
      quantityStock: 0,
      alertStock: 5,
      sales: 0,
      salePrice: 0.0,
      purchasePrice: 0.0,
      currencySign: '\$',
      local: false,
    );
  }

  Product({
    this.id = "",
    this.idMark = "",
    this.nameMark = '',
    this.imageMark = '',
    this.description = "",
    this.image = "",
    this.code = "",
    this.followers = 0,
    this.favorite = false,
    this.verified = false,
    this.reviewed = false,
    required this.creation,
    required this.upgrade,
    this.idUserCreation = '',
    this.idUserUpgrade = '',
  });

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] ?? '',
      idMark: map['idMark'] ?? '',
      nameMark: map['nameMark'] ?? '',
      imageMark: map['imageMark'] ?? '',
      description: map['description'] ?? '',
      image: map['image'] ?? '',
      code: map['code'] ?? '',
      followers: map['followers'] ?? 0,
      favorite: map['favorite'] ?? false,
      verified: map['verified'] ?? false,
      reviewed: map['reviewed'] ?? false,
      creation: map['creation'] is Timestamp
          ? (map['creation'] as Timestamp).toDate()
          : DateTime.now(),
      upgrade: map['upgrade'] is Timestamp
          ? (map['upgrade'] as Timestamp).toDate()
          : DateTime.now(),
      idUserCreation: map['idUserCreation'] ?? '',
      idUserUpgrade: map['idUserUpgrade'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'idMark': idMark,
      'nameMark': nameMark,
      'imageMark': imageMark,
      'description': description,
      'image': image,
      'code': code,
      'followers': followers,
      'favorite': favorite,
      'verified': verified,
      'reviewed': reviewed,
      'creation': Timestamp.fromDate(creation),
      'upgrade': Timestamp.fromDate(upgrade),
      'idUserCreation': idUserCreation,
      'idUserUpgrade': idUserUpgrade,
    };
  }
}
