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

  /// Atributos dinámicos del producto (peso, color, talle, etc.)
  final Map<String, dynamic> attributes;

  /// Estado del producto
  /// 
  /// Valores posibles:
  /// - 'verified': Producto verificado por la comunidad (inmutable)
  /// - 'pending': Producto pendiente de verificación
  /// - 'sku': Producto interno del comercio (solo catálogo privado)
  final String status;

  // Getters de lógica de negocio

  /// Indica si el producto está verificado por la comunidad
  bool get isVerified => status == 'verified';

  /// Indica si el producto está pendiente de verificación
  bool get isPending => status == 'pending';

  /// Indica si el producto es un SKU interno del comercio
  /// 
  /// Los productos con status 'sku' son códigos generados internamente
  /// para productos sin código de barras estándar (carnicería, granel, etc.)
  /// Estos productos SOLO existen en el catálogo privado del comercio.
  bool get isSku => status == 'sku';

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
      attributes: attributes,
      status: status,
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
    this.reviewed = false,
    required this.creation,
    required this.upgrade,
    this.idUserCreation = '',
    this.idUserUpgrade = '',
    this.attributes = const {},
    this.status = 'pending',
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
      reviewed: map['reviewed'] ?? false,
      creation: map['creation'] is Timestamp
          ? (map['creation'] as Timestamp).toDate()
          : DateTime.now(),
      upgrade: map['upgrade'] is Timestamp
          ? (map['upgrade'] as Timestamp).toDate()
          : DateTime.now(),
      idUserCreation: map['idUserCreation'] ?? '',
      idUserUpgrade: map['idUserUpgrade'] ?? '',
      attributes: map.containsKey('attributes') && map['attributes'] != null
          ? Map<String, dynamic>.from(map['attributes'])
          : {},
      // Migración: Lee 'status' si existe, sino convierte desde 'verified'
      status: map.containsKey('status')
          ? map['status']
          : (map.containsKey('verified') && map['verified'] == true)
              ? 'verified'
              : 'pending',
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
      'reviewed': reviewed,
      'creation': Timestamp.fromDate(creation),
      'upgrade': Timestamp.fromDate(upgrade),
      'idUserCreation': idUserCreation,
      'idUserUpgrade': idUserUpgrade,
      'attributes': attributes,
      'status': status,
    };
  }
}
