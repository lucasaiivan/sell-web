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
}
