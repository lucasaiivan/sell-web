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
  final Map<String, dynamic> attributes;
  final String status;

  // Variables del catálogo de la cuenta
  final bool local;
  final DateTime creation;
  final DateTime upgrade;
  final bool favorite;
  final String category;
  final String provider;
  final String nameProvider;
  final String nameCategory;
  final int quantityStock;
  final bool stock;
  final int alertStock;
  final int sales;
  final double salePrice; // Precio de venta
  final double purchasePrice; // Precio de compra
  final String currencySign;

  // Variables en tiempo de ejecución
  final int quantity;
  final double revenue;
  final double priceTotal;

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
    this.quantityStock = 0,
    this.alertStock = 5,
    this.revenue = 0.0,
    required this.creation,
    required this.upgrade,
    required this.documentCreation,
    required this.documentUpgrade,
    this.documentIdCreation = "",
    this.documentIdUpgrade = "",
    this.sales = 0,
    this.salePrice = 0.0,
    this.purchasePrice = 0.0,
    this.currencySign = "\$",
    this.idMark = '',
    this.nameMark = '',
    this.imageMark = '',
    this.quantity = 1,
    this.local = false,
    this.priceTotal = 0,
    this.attributes = const {},
    this.status = 'pending',
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
    int? quantityStock,
    int? alertStock,
    double? revenue,
    DateTime? creation,
    DateTime? upgrade,
    DateTime? documentCreation,
    DateTime? documentUpgrade,
    String? documentIdCreation,
    String? documentIdUpgrade,
    int? sales,
    double? salePrice,
    double? purchasePrice,
    String? currencySign,
    String? idMark,
    String? nameMark,
    String? imageMark,
    int? quantity,
    bool? local,
    Map<String, dynamic>? attributes,
    String? status,
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
      revenue: revenue ?? this.revenue,
      creation: creation ?? this.creation,
      upgrade: upgrade ?? this.upgrade,
      documentCreation: documentCreation ?? this.documentCreation,
      documentUpgrade: documentUpgrade ?? this.documentUpgrade,
      documentIdCreation: documentIdCreation ?? this.documentIdCreation,
      documentIdUpgrade: documentIdUpgrade ?? this.documentIdUpgrade,
      sales: sales ?? this.sales,
      salePrice: salePrice ?? this.salePrice,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      currencySign: currencySign ?? this.currencySign,
      idMark: idMark ?? this.idMark,
      nameMark: nameMark ?? this.nameMark,
      imageMark: imageMark ?? this.imageMark,
      quantity: quantity ?? this.quantity,
      local: local ?? this.local,
      attributes: attributes ?? this.attributes,
      status: status ?? this.status,
    );
  }

  // Getters de lógica de negocio

  /// Indica si el producto está verificado por la comunidad
  bool get isVerified => status == 'verified';

  /// Indica si el producto está pendiente de verificación
  bool get isPending => status == 'pending';

  /// Indica si el producto es solo local (no se guarda en BD global)
  bool get isLocalOnly => status == 'local_only';

  /// Indica si el stock está bajo (menor o igual a la alerta)
  bool get isLowStock => stock && quantityStock <= alertStock;

  /// Indica si el producto está sin stock
  bool get isOutOfStock => stock && quantityStock <= 0;

  /// Indica si tiene margen de beneficio positivo
  bool get hasProfitMargin => salePrice > purchasePrice;

  String get getPorcentageFormat {
    if (purchasePrice == 0 || salePrice == 0) return '';
    double ganancia = salePrice - purchasePrice;
    double porcentajeDeGanancia = (ganancia / purchasePrice) * 100;
    return '${porcentajeDeGanancia.toInt()}%';
  }

  int get getPorcentageValue {
    if (purchasePrice == 0 || salePrice == 0) return 0;
    double ganancia = salePrice - purchasePrice;
    double porcentajeDeGanancia = (ganancia / purchasePrice) * 100;
    return porcentajeDeGanancia.toInt();
  }

  double get getBenefitsValue {
    if (purchasePrice <= 0 || salePrice <= 0) return 0.0;
    return salePrice - purchasePrice;
  }

  String get getBenefits {
    if (purchasePrice <= 0 || salePrice <= 0) return '';
    final profit = salePrice - purchasePrice;
    final percentage = (profit / purchasePrice) * 100;
    return '${percentage.toStringAsFixed(0)}%';
  }

  bool get isComplete => description.isNotEmpty && nameMark.isNotEmpty;

  // Serialization methods
  Map<String, dynamic> toMap() => {
        "id": id,
        'local': local,
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
        "revenue": revenue,
      };

  Map<String, dynamic> toJson() => toMap();

  factory ProductCatalogue.fromMap(Map data) {
    DateTime parseDateTime(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is DateTime) return value;
      if (value is int) {
        return DateTime.fromMillisecondsSinceEpoch(value);
      }
      // Handle Firestore Timestamp
      if (value.runtimeType.toString() == 'Timestamp') {
        return (value as dynamic).toDate();
      }
      return DateTime.now();
    }

    return ProductCatalogue(
      id: data['id'] ?? '',
      local: data['local'] ?? false,
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
      quantity: data['quantity'] ?? 1,
      stock: data['stock'] ?? false,
      quantityStock: data['quantityStock'] ?? 0,
      sales: data['sales'] ?? 0,
      alertStock: data['alertStock'] ?? 5,
      revenue: (data['revenue'] ?? 0.0).toDouble(),
      salePrice: (data['salePrice'] ?? 0.0).toDouble(),
      purchasePrice: (data['purchasePrice'] ?? 0.0).toDouble(),
      attributes: data.containsKey('attributes')
          ? Map<String, dynamic>.from(data['attributes'])
          : {},
      // Migración: Lee 'status' si existe, sino convierte desde 'verified'
      status: data.containsKey('status')
          ? data['status']
          : (data.containsKey('verified') && data['verified'] == true)
              ? 'verified'
              : 'pending',
    );
  }
}
