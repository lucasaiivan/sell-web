
import 'combo_item.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sellweb/core/constants/unit_constants.dart';

class ProductCatalogue {
  // Información básica del producto
  final String id;
  final String idMark;
  final String nameMark;
  final String imageMark;
  final String image;
  final String description;
  final String code;
  final DateTime documentCreation;
  final DateTime documentUpgrade;
  final String documentIdCreation;
  final String documentIdUpgrade;

  // Variables del producto global
  final bool reviewed;
  final bool outstanding;
  final int followers;
  final Map<String, dynamic> variants;
  final String status;
  
  // Variables de Combo
  final List<ComboItem> comboItems;
  final DateTime? comboExpiration;

  // Variables del catálogo de la cuenta
  final DateTime creation; // Fecha de creación
  final DateTime upgrade; // Fecha de última actualización
  final bool favorite;
  final String category;
  final String provider;
  final String nameProvider;
  final String nameCategory;
  final double quantityStock; // Stock actual (double para soportar fraccionales)
  final bool stock; // indica si el seguimiento del stock está activado
  final double alertStock; // Alerta de stock bajo (double)
  final double sales; // cantidad de ventas
  final double salePrice; // Precio de venta
  final double purchasePrice; // Precio de coste
  final String unit; // Unidad de venta (unidad, kilogramo, litro, metro)
  final String currencySign; // Símbolo de la moneda
  final int iva; // Porcentaje de IVA (0 = sin IVA o exento)
  final double revenuePercentage; // Porcentaje de ganancia

  // Variables en tiempo de ejecución (no se guardan en la base de datos)
  final double quantity; // Cantidad en el ticket (soporta fraccionarios: 0.025 = 25g, 2.5 = 2.5kg)
  final double revenueTotal; // Ganancia total del productos
  final double priceTotal; // precio total del producto considerando la cantidades

  // Variables en desuso
  final String subcategory;
  final String nameSubcategory;

  ProductCatalogue({
    this.id = "",
    this.reviewed = false,
    this.followers = 0,
    this.favorite = false,
    this.outstanding = false,
    this.image = "",
    this.description = "",
    this.code = "",
    this.provider = "",
    this.nameProvider = "",
    this.category = "",
    this.nameCategory = '',
    this.subcategory = "",
    this.nameSubcategory = '',
    this.stock = false,
    this.quantityStock = 0.0,
    this.alertStock = 5.0,
    this.revenueTotal = 0.0,
    this.revenuePercentage = 0.0,
    required this.creation,
    required this.upgrade,
    required this.documentCreation,
    required this.documentUpgrade,
    this.documentIdCreation = "",
    this.documentIdUpgrade = "",
    this.sales = 0.0,
    this.salePrice = 0.0,
    this.purchasePrice = 0.0,
    this.unit = UnitConstants.unit,
    this.currencySign = "\$",
    this.iva = 0,
    this.idMark = '',
    this.nameMark = '',
    this.imageMark = '',
    this.quantity = 1.0,
    this.priceTotal = 0.0,
    this.variants = const {},
    this.status = 'pending',
    this.comboItems = const [],
    this.comboExpiration,
  });

  ProductCatalogue copyWith({
    String? id,
    bool? reviewed,
    int? followers,
    bool? favorite,
    bool? outstanding,
    String? image,
    String? description,
    String? code,
    String? provider,
    String? nameProvider,
    String? category,
    String? nameCategory,
    String? subcategory,
    String? nameSubcategory,
    bool? stock,
    double? quantityStock,
    double? alertStock,
    double? revenueTotal,
    double? revenuePercentage,
    DateTime? creation,
    DateTime? upgrade,
    DateTime? documentCreation,
    DateTime? documentUpgrade,
    String? documentIdCreation,
    String? documentIdUpgrade,
    double? sales,
    double? salePrice,
    double? purchasePrice,
    String? unit,
    String? currencySign,
    int? iva,
    String? idMark,
    String? nameMark,
    String? imageMark,
    double? quantity,
    Map<String, dynamic>? variants,
    String? status,
    List<ComboItem>? comboItems,
    DateTime? comboExpiration,
  }) {
    return ProductCatalogue(
      id: id ?? this.id,
      reviewed: reviewed ?? this.reviewed,
      followers: followers ?? this.followers,
      favorite: favorite ?? this.favorite,
      outstanding: outstanding ?? this.outstanding,
      image: image ?? this.image,
      description: description ?? this.description,
      code: code ?? this.code,
      provider: provider ?? this.provider,
      nameProvider: nameProvider ?? this.nameProvider,
      category: category ?? this.category,
      nameCategory: nameCategory ?? this.nameCategory,
      subcategory: subcategory ?? this.subcategory,
      nameSubcategory: nameSubcategory ?? this.nameSubcategory,
      stock: stock ?? this.stock,
      quantityStock: quantityStock ?? this.quantityStock,
      alertStock: alertStock ?? this.alertStock,
      revenueTotal: revenueTotal ?? this.revenueTotal,
      revenuePercentage: revenuePercentage ?? this.revenuePercentage,
      creation: creation ?? this.creation,
      upgrade: upgrade ?? this.upgrade,
      documentCreation: documentCreation ?? this.documentCreation,
      documentUpgrade: documentUpgrade ?? this.documentUpgrade,
      documentIdCreation: documentIdCreation ?? this.documentIdCreation,
      documentIdUpgrade: documentIdUpgrade ?? this.documentIdUpgrade,
      sales: sales ?? this.sales,
      salePrice: salePrice ?? this.salePrice,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      unit: unit ?? this.unit,
      currencySign: currencySign ?? this.currencySign,
      iva: iva ?? this.iva,
      idMark: idMark ?? this.idMark,
      nameMark: nameMark ?? this.nameMark,
      imageMark: imageMark ?? this.imageMark,
      quantity: quantity ?? this.quantity,
      variants: variants ?? this.variants,
      status: status ?? this.status,
      comboItems: comboItems ?? this.comboItems,
      comboExpiration: comboExpiration ?? this.comboExpiration,
    );
  }

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
  ///
  /// Nota: También incluye status 'local_only' por compatibilidad con datos antiguos.
  bool get isSku => status == 'sku' || status == 'local_only';

  /// Indica si el producto es un combo
  bool get isCombo => comboItems.isNotEmpty;

  /// Indica si el stock está bajo (menor o igual a la alerta)
  bool get isLowStock => stock && quantityStock <= alertStock;

  /// Indica si el producto está sin stock
  bool get isOutOfStock => stock && quantityStock <= 0;

  /// Indica si tiene margen de beneficio positivo
  bool get hasProfitMargin => revenuePercentage > 0;

  /// Retorna la fecha de última actualización del producto
  ///
  /// Valida si existe una actualización real comparando `upgrade` con `creation`.
  /// Si `upgrade` es posterior a `creation`, significa que hubo una modificación.
  /// De lo contrario, retorna `creation` (producto nunca actualizado).
  DateTime get lastUpdateDate {
    // Validar si upgrade es posterior a creation (actualización real)
    if (upgrade.isAfter(creation)) {
      return upgrade;
    }
    // Si no hay actualización válida, retornar fecha de creación
    return creation;
  }

  String get getPorcentageFormat {
    // Si es entero, mostrar sin decimales
    if (revenuePercentage % 1 == 0) {
      return '${revenuePercentage.toInt()}%';
    }
    return '${revenuePercentage.toStringAsFixed(2)}%';
  }

  double get getPorcentageValue => revenuePercentage;

  double get getBenefitsValue {
    if (purchasePrice <= 0) return 0.0;
    return purchasePrice * (revenuePercentage / 100);
  }

  String get getBenefits {
    if (purchasePrice <= 0) return '';
    if (revenuePercentage % 1 == 0) {
      return '${revenuePercentage.toInt()}%';
    }
    return '${revenuePercentage.toStringAsFixed(2)}%';
  }

  bool get isComplete => description.isNotEmpty && nameMark.isNotEmpty;

  /// Indica si el producto fue creado de manera rápida (sin ID base o generado al vuelo)
  bool get isQuickSale => id.isEmpty || id.startsWith('quick_') || code.isEmpty || description.isEmpty;

  // ==========================================
  // GETTERS DE UNIDAD DE MEDIDA Y CÁLCULOS
  // ==========================================

  /// Indica si el producto tiene una unidad fraccionaria (kg, L, m)
  bool get isFractionalUnit => UnitConstants.fractionalUnits.contains(unit);

  /// Indica si el producto tiene una unidad discreta (unit, box, package)
  bool get isDiscreteUnit => UnitConstants.discreteUnits.contains(unit);

  /// Obtiene el símbolo abreviado de la unidad (kg, g, L, ml, m, cm, u)
  String get unitSymbol {
    // Si es fraccionario y menor a 1, mostrar subunidad
    if (unit == UnitConstants.kilogram && quantity < 1.0) return 'g';
    if (unit == UnitConstants.liter && quantity < 1.0) return 'ml';
    if (unit == UnitConstants.meter && quantity < 1.0) return 'cm';

    return UnitConstants.getSymbol(unit);
  }

  /// Obtiene el nombre completo de la unidad (traducido)
  String get unitName {
     // Si es fraccionario y menor a 1, mostrar nombre de subunidad
    if (unit == UnitConstants.kilogram && quantity < 1.0) return 'gramos';
    if (unit == UnitConstants.liter && quantity < 1.0) return 'mililitros';
    if (unit == UnitConstants.meter && quantity < 1.0) return 'centímetros';

    return UnitConstants.getDisplayName(unit);
  }

  /// Obtiene el precio total del producto (precio × cantidad)
  double get totalPrice => salePrice * quantity;

  /// Obtiene la ganancia total del producto (ganancia unitaria × cantidad)
  double get totalProfit => (purchasePrice * (revenuePercentage / 100)) * quantity;

  /// Formatea la cantidad según el tipo de unidad
  /// - Discretas: "1", "5", "10"
  /// - Fraccionarias: "0.5", "1.25", "2.5"
  String get formattedQuantity {
    if (isDiscreteUnit) {
      return quantity.toInt().toString();
    }

    double displayQuantity = quantity;
    
    // Lógica de conversión para visualización de subunidades
    if (unit == UnitConstants.kilogram && quantity < 1.0) {
      displayQuantity = quantity * 1000;
    } else if (unit == UnitConstants.liter && quantity < 1.0) {
      displayQuantity = quantity * 1000;
    } else if (unit == UnitConstants.meter && quantity < 1.0) {
      displayQuantity = quantity * 100;
    }

    // Para fraccionarias: eliminar ceros innecesarios
    if (displayQuantity == displayQuantity.roundToDouble()) {
      return displayQuantity.toInt().toString();
    }
    return displayQuantity.toStringAsFixed(3).replaceAll(RegExp(r'\.?0+$'), '');
  }

  /// Formatea la cantidad con el símbolo de unidad (corto)
  /// Ejemplos: "2.5 kg", "1 u", "500 g"
  String get formattedQuantityWithUnit => '$formattedQuantity $unitSymbol';

  /// Formatea la cantidad con el nombre completo de unidad
  /// Ejemplos: "2.5 kilogramo", "1 unidad", "500 gramo"
  String get formattedQuantityWithUnitName => '$formattedQuantity $unitName';

  /// Formatea la cantidad de forma compacta para badges pequeños
  /// Limita decimales a 2 para evitar overflow en UI
  /// Ejemplos: "2.5", "0.75", "10"
  String get formattedQuantityCompact {
    if (isDiscreteUnit) {
      return quantity.toInt().toString();
    }

    double displayQuantity = quantity;

    // Lógica de conversión para visualización
    if (unit == UnitConstants.kilogram && quantity < 1.0) {
      displayQuantity = quantity * 1000;
    } else if (unit == UnitConstants.liter && quantity < 1.0) {
      displayQuantity = quantity * 1000;
    } else if (unit == UnitConstants.meter && quantity < 1.0) {
      displayQuantity = quantity * 100;
    }

    // Para fraccionarias: máximo 2 decimales, sin ceros finales
    if (displayQuantity == displayQuantity.roundToDouble()) {
      return displayQuantity.toInt().toString();
    }
    return displayQuantity.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '');
  }

  /// Formatea el precio por unidad con el símbolo de unidad
  /// Ejemplo: "$100/kg", "$50/u"
  String get formattedPricePerUnit => '\$$salePrice/$unitSymbol';
 
  /// Obtiene la cantidad máxima permitida según el tipo de unidad
  double get maxQuantity {
    return isFractionalUnit ? 1000.0 : 10000.0;
  }

  /// Cantidad mínima permitida
  static const double minQuantity = 0.001;

  // Serialization methods
  /// Convierte el producto a un mapa para persistencia
  ///
  /// ## Campos de estado:
  /// - **status**: Estado del producto ('sku', 'pending', 'verified')
  ///   - 'sku': Producto interno sin código estándar (solo catálogo privado)
  ///   - 'pending': Producto con código válido pendiente de verificación
  ///   - 'verified': Producto verificado por la comunidad (inmutable)
  /// - **variants**: Variantes dinámicas del producto
  Map<String, dynamic> toMap() {
    final map = {
      "id": id,
      'reviewed': reviewed,
      'followers': followers,
      'outstanding': outstanding,
      'status': status,
      'variants': variants,
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
      "creation": creation.millisecondsSinceEpoch,
      "upgrade": upgrade.millisecondsSinceEpoch,
      "documentCreation": documentCreation.millisecondsSinceEpoch,
      "documentUpgrade": documentUpgrade.millisecondsSinceEpoch,
      'documentIdCreation': documentIdCreation,
      'documentIdUpgrade': documentIdUpgrade,
      "currencySign": currencySign,
      "quantity": quantity,
      "stock": stock,
      "quantityStock": quantityStock,
      "sales": sales,
      "alertStock": alertStock,
      "revenueTotal": revenueTotal,
      "unit": unit,
      "iva": iva,
      "revenuePercentage": revenuePercentage,
      'comboItems': comboItems.map((e) => e.toMap()).toList(),
      'comboExpiration':  comboExpiration?.millisecondsSinceEpoch,
    };


    return map;
  }

  Map<String, dynamic> toJson() => toMap();

  factory ProductCatalogue.fromMap(Map data) {
    DateTime parseDateTime(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is DateTime) return value;
      if (value is int) {
        return DateTime.fromMillisecondsSinceEpoch(value);
      }
      // Handle Firestore Timestamp
      if (value is Timestamp) {
        return value.toDate();
      }
      return DateTime.now();
    }

    // Parsea quantity como double, compatible con int y double
    double parseQuantity(dynamic value) {
      if (value == null) return 1.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) {
        final parsed = double.tryParse(value);
        return parsed ?? 1.0;
      }
      return 1.0;
    }

    // Helper para parsear stocks
     double parseStock(dynamic value, double defaultValue) {
      if (value == null) return defaultValue;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? defaultValue;
      return defaultValue;
    }

    final product = ProductCatalogue(
      id: data['id'] ?? '',
      reviewed: data['reviewed'] ?? data['revisado'] ?? false,
      followers: data['followers'] ?? data['seguidores'] ?? 0,
      favorite: data['favorite'] ?? data['favorito'] ?? false,
      outstanding: data['outstanding'] ?? data['destacado'] ?? false,
      idMark: data['idMark'] ?? data['id_marca'] ?? '',
      nameMark: data['nameMark'] ?? data['nombre_marca'] ?? '',
      imageMark: data['imageMark'] ?? '',
      image: data['image'] ?? data['urlimagen'] ?? '',
      description: data['description'] ?? data['descripcion'] ?? '',
      code: data['code'] ?? data['codigo'] ?? '',
      provider: data['provider'] ?? data['proveedor'] ?? '',
      nameProvider: data['nameProvider'] ?? data['proveedorName'] ?? '',
      category: data['category'] ?? data['categoria'] ?? '',
      nameCategory: data['nameCategory'] ?? data['categoriaName'] ?? '',
      subcategory: data['subcategory'] ?? data['subcategoria'] ?? '',
      nameSubcategory:
          data['nameSubcategory'] ?? data['subcategoriaName'] ?? '',
      upgrade:
          parseDateTime(data['upgrade'] ?? data['timestamp_actualizacion']),
      creation: parseDateTime(data['creation'] ?? data['timestamp_creation']),
      documentCreation: parseDateTime(
          data['documentCreation'] ?? data['timestamp_creation_document']),
      documentUpgrade: parseDateTime(
          data['documentUpgrade'] ?? data['timestamp_upgrade_document']),
      documentIdCreation: data['documentIdCreation'] ?? '',
      documentIdUpgrade: data['documentIdUpgrade'] ?? '',
      currencySign: data['currencySign'] ?? '\$',
      quantity: parseQuantity(data['quantity']),
      stock: data['stock'] ?? false,
      quantityStock: parseStock(data['quantityStock'], 0.0),
      sales: parseStock(data['sales'], 0.0),
      alertStock: parseStock(data['alertStock'], 5.0),
      revenueTotal: (data['revenueTotal'] ?? 0.0).toDouble(),
      salePrice: (data['salePrice'] ?? 0.0).toDouble(),
      purchasePrice: (data['purchasePrice'] ?? 0.0).toDouble(),
      unit: UnitConstants.normalizeId(data['unit'] ?? UnitConstants.unit),
      iva: data['iva'] ?? 0,
      revenuePercentage: data['revenuePercentage'] ?? 0,
      variants: data.containsKey('variants') && data['variants'] != null
          ? Map<String, dynamic>.from(data['variants'])
          : data.containsKey('attributes') && data['attributes'] != null
              ? Map<String, dynamic>.from(data['attributes'])
              : {},
      // Migración: Lee 'status' si existe, sino convierte desde 'verified'
      status: data.containsKey('status')
          ? data['status']
          : (data.containsKey('verified') && data['verified'] == true)
              ? 'verified'
              : 'pending',
      comboItems: data.containsKey('comboItems') && data['comboItems'] != null
          ? (data['comboItems'] as List)
              .map((item) => ComboItem.fromMap(item))
              .toList()
          : [],
      comboExpiration: parseDateTime(data['comboExpiration']),
    );

    return product;
  }
}
