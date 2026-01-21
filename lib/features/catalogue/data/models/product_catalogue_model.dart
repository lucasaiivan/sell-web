import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/utils/formatters/currency_formatter.dart';
import '../../domain/entities/product_catalogue.dart';
import 'product_model.dart';

/// Modelo de datos para ProductCatalogue con lógica de serialización.
///
/// Maneja la conversión desde/hacia Firestore, incluyendo compatibilidad
/// con nombres de campos legacy y conversión de tipos primitivos.
class ProductCatalogueModel extends ProductCatalogue {
  ProductCatalogueModel({
    super.id,
    super.reviewed,
    super.followers,
    super.favorite,
    super.outstanding,
    super.image,
    super.description,
    super.code,
    super.provider,
    super.nameProvider,
    super.category,
    super.nameCategory,
    super.subcategory,
    super.nameSubcategory,
    super.stock,
    super.quantityStock,
    super.alertStock,
    super.revenue,
    required super.creation,
    required super.upgrade,
    required super.documentCreation,
    required super.documentUpgrade,
    super.documentIdCreation,
    super.documentIdUpgrade,
    super.sales,
    super.salePrice,
    super.purchasePrice,
    super.unit,
    super.currencySign,
    super.idMark,
    super.nameMark,
    super.imageMark,
    super.quantity,
    super.variants,
    super.status,
    super.iva,
  });

  /// Crea una instancia desde un Map con soporte para nombres legacy
  factory ProductCatalogueModel.fromMap(Map<String, dynamic> data) {
    // Helper para parsear doubles de forma segura
    double _parseDouble(dynamic value, double defaultValue) {
      if (value == null) return defaultValue;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? defaultValue;
      return defaultValue;
    }

    return ProductCatalogueModel(
      id: data.containsKey('id') ? data['id'] : '',
      reviewed: data.containsKey('reviewed')
          ? data['reviewed']
          : data['revisado'] ?? false,
      followers: data.containsKey('followers')
          ? data['followers']
          : data['seguidores'] ?? 0,
      outstanding: data.containsKey('outstanding')
          ? data['outstanding']
          : data['destacado'] ?? false,
      favorite: data.containsKey('favorite')
          ? data['favorite']
          : data['favorito'] ?? false,
      idMark:
          data.containsKey('idMark') ? data['idMark'] : data['id_marca'] ?? '',
      nameMark: data.containsKey('nameMark')
          ? data['nameMark']
          : data['nombre_marca'] ?? '',
      imageMark: data.containsKey('imageMark') ? data['imageMark'] : '',
      image: data.containsKey('image')
          ? data['image']
          : data['urlimagen'] ?? 'https://default',
      description: data.containsKey('description')
          ? data['description']
          : data['descripcion'] ?? '',
      code: data.containsKey('code') ? data['code'] : data['codigo'] ?? '',
      provider: data.containsKey('provider')
          ? data['provider']
          : data['proveedor'] ?? '',
      nameProvider: data.containsKey('nameProvider')
          ? data['nameProvider']
          : data['proveedorName'] ?? '',
      category: data.containsKey('category')
          ? data['category']
          : data['categoria'] ?? '',
      nameCategory: data.containsKey('nameCategory')
          ? data['nameCategory']
          : data['categoriaName'] ?? '',
      subcategory: data.containsKey('subcategory')
          ? data['subcategory']
          : data['subcategoria'] ?? '',
      nameSubcategory: data.containsKey('nameSubcategory')
          ? data['nameSubcategory']
          : data['subcategoriaName'] ?? '',
      upgrade:
          _parseTimestamp(data['upgrade'] ?? data['timestamp_actualizacion']),
      creation: _parseTimestamp(data['creation'] ?? data['timestamp_creation']),
      documentCreation: _parseTimestamp(data['documentCreation']),
      documentUpgrade: _parseTimestamp(data['documentUpgrade']),
      documentIdCreation: data.containsKey('documentIdCreation')
          ? data['documentIdCreation']
          : data['documentIdCreation'] ?? '',
      documentIdUpgrade: data.containsKey('documentIdUpgrade')
          ? data['documentIdUpgrade']
          : data['documentIdUpgrade'] ?? '',
      salePrice: data.containsKey('salePrice')
          ? _parseDouble(data['salePrice'], 0.0)
          : 0.0,
      purchasePrice: data.containsKey('purchasePrice')
          ? _parseDouble(data['purchasePrice'], 0.0)
          : 0.0,
      unit: data.containsKey('unit') ? data['unit'] : 'unidad',
      currencySign: data.containsKey('currencySign')
          ? data['currencySign']
          : data['signo_moneda'] ?? '',
      quantityStock:
          data.containsKey('quantityStock') ? _parseDouble(data['quantityStock'], 0.0) : 0.0,
      sales: _parseDouble(data['sales'], 0.0),
      stock: data.containsKey('stock') ? data['stock'] : false,
      alertStock: data.containsKey('alertStock') ? _parseDouble(data['alertStock'], 5.0) : 5.0,
      revenue: data.containsKey('revenue') ? _parseDouble(data['revenue'], 0.0) : 0.0,
      quantity: data.containsKey('quantity') ? _parseDouble(data['quantity'], 1.0) : 1.0,
      variants: data.containsKey('variants') && data['variants'] != null
          ? Map<String, dynamic>.from(data['variants'])
          : data.containsKey('attributes') && data['attributes'] != null
              ? Map<String, dynamic>.from(data['attributes'])
              : {},
      status: data.containsKey('status')
          ? data['status']
          : (data.containsKey('verified') && data['verified'] == true)
              ? 'verified'
              : 'pending',
      iva: data['iva'] ?? 0,
    );
  }

  /// Crea una instancia desde ProductModel (conversión de producto global)
  factory ProductCatalogueModel.fromProductModel(ProductModel product) {
    return ProductCatalogueModel(
      id: product.id,
      followers: product.followers,
      image: product.image,
      reviewed: product.reviewed,
      outstanding: product.favorite,
      idMark: product.idMark,
      nameMark: product.nameMark,
      imageMark: product.imageMark,
      description: product.description,
      code: product.code,
      documentUpgrade: product.upgrade,
      documentCreation: product.creation,
      documentIdCreation: product.idUserCreation,
      documentIdUpgrade: product.idUserUpgrade,
      creation: product.creation,
      upgrade: product.upgrade,
      variants: product.variants,
      unit: product.unit,
      status: product.status,
    );
  }

  /// Convierte a Map para Firestore
  Map<String, dynamic> toMap() => {
        "id": id,
        'reviewed': reviewed,
        'followers': followers,
        'outstanding': outstanding,
        "favorite": favorite,
        "idMark": idMark,
        "nameMark": nameMark,
        'imageMark': imageMark,
        "image": image,
        "description": description,
        "code": code,
        "provider": provider,
        "nameProvider": nameProvider,
        "category": category,
        "nameCategory": nameCategory,
        "subcategory": subcategory,
        "nameSubcategory": nameSubcategory,
        "salePrice": salePrice,
        "purchasePrice": purchasePrice,
        "unit": unit,
        "creation": Timestamp.fromDate(creation),
        "upgrade": Timestamp.fromDate(upgrade),
        "documentCreation": Timestamp.fromDate(documentCreation),
        "documentUpgrade": Timestamp.fromDate(documentUpgrade),
        'documentIdCreation': documentIdCreation,
        'documentIdUpgrade': documentIdUpgrade,
        "currencySign": currencySign,
        "quantity": quantity,
        "stock": stock,
        "quantityStock": quantityStock,
        "sales": sales,
        "alertStock": alertStock,
        "revenue": revenue,
        "variants": variants,
        "status": status,
        "iva": iva,
      };

  /// Convierte a entidad de dominio pura
  ProductCatalogue toEntity() {
    return ProductCatalogue(
      id: id,
      reviewed: reviewed,
      followers: followers,
      favorite: favorite,
      outstanding: outstanding,
      image: image,
      description: description,
      code: code,
      provider: provider,
      nameProvider: nameProvider,
      category: category,
      nameCategory: nameCategory,
      subcategory: subcategory,
      nameSubcategory: nameSubcategory,
      stock: stock,
      quantityStock: quantityStock,
      alertStock: alertStock,
      revenue: revenue,
      creation: creation,
      upgrade: upgrade,
      documentCreation: documentCreation,
      documentUpgrade: documentUpgrade,
      documentIdCreation: documentIdCreation,
      documentIdUpgrade: documentIdUpgrade,
      sales: sales,
      salePrice: salePrice,
      purchasePrice: purchasePrice,
      unit: unit,
      currencySign: currencySign,
      idMark: idMark,
      nameMark: nameMark,
      imageMark: imageMark,
      quantity: quantity,
      variants: variants,
      status: status,
      iva: iva,
    );
  }

  /// Convierte a ProductModel (producto global)
  ProductModel toProductModel() {
    return ProductModel(
      id: id,
      followers: followers,
      image: image,
      reviewed: reviewed,
      favorite: outstanding,
      idMark: idMark,
      nameMark: nameMark,
      imageMark: imageMark,
      description: description,
      code: code,
      upgrade: documentUpgrade,
      creation: documentCreation,
      idUserCreation: documentIdCreation,
      idUserUpgrade: documentIdUpgrade,
      variants: variants,
      unit: unit,
      status: status,
    );
  }

  /// Obtiene el beneficio formateado con el signo de moneda
  String getBenefitsFormatted() {
    final double ganancia = getBenefitsValue;
    if (ganancia > 0) {
      return CurrencyFormatter.formatPrice(
        value: ganancia,
        moneda: currencySign,
      );
    }
    return '';
  }

  /// Helper para parsear Timestamp a DateTime
  static DateTime _parseTimestamp(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    return DateTime.now();
  }
}
