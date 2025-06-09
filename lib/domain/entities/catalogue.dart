import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  String id;
  String idMark;
  String nameMark;
  String imageMark;
  String description;
  String image;
  String code;
  int followers;
  bool favorite;
  bool verified;
  bool reviewed;
  Timestamp creation;
  Timestamp upgrade;
  String idUserCreation;
  String idUserUpgrade;

  Product({
    this.id = "",
    this.followers = 0,
    this.idUserCreation = '',
    this.idUserUpgrade = '',
    this.verified = false,
    this.reviewed = false,
    this.favorite = false,
    this.idMark = "",
    this.nameMark = '',
    this.imageMark = '',
    this.image = "",
    this.description = "",
    this.code = "",
    required this.upgrade,
    required this.creation,
  });

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
        "creation": creation,
        "upgrade": upgrade,
      };

  factory Product.fromMap(Map<String, dynamic> data) {
    return Product(
      id: data['id'] ?? '',
      followers: data['followers'] ?? 0,
      idUserCreation: data['idUserCreation'] ?? '',
      idUserUpgrade: data['idUserUpgrade'] ?? '',
      verified: data['verified'] ?? data['verificado'] ?? false,
      reviewed: data['reviewed'] ?? data['revisado'] ?? false,
      favorite: data['favorite'] ?? false,
      idMark: data['idMark'] ?? data['id_marca'] ?? '',
      nameMark: data['nameMark'] ?? '',
      imageMark: data['imageMark'] ?? '',
      image: data['image'] ?? data['urlimagen'] ?? '',
      description: data['description'] ?? data['descripcion'] ?? '',
      code: data['code'] ?? data['codigo'] ?? '',
      upgrade: data['upgrade'] ?? Timestamp.now(),
      creation: data['creation'] ?? Timestamp.now(),
    );
  }

  factory Product.fromDocumentSnapshot({required DocumentSnapshot documentSnapshot}) {
    final data = documentSnapshot.data() as Map<String, dynamic>;
    return Product.fromMap(data);
  }

  ProductCatalogue toProductCatalogue() {
    return ProductCatalogue(
      id: id,
      followers: followers,
      image: image,
      verified: verified,
      reviewed: reviewed,
      outstanding: favorite,
      idMark: idMark,
      nameMark: nameMark,
      imageMark: imageMark,
      description: description,
      code: code,
      documentUpgrade: upgrade,
      documentCreation: creation,
      creation: creation,
      upgrade: upgrade,
    );
  }
}

class ProductCatalogue {
  String id;
  String idMark;
  String nameMark;
  String imageMark;
  String image;
  String description;
  String code;
  Timestamp documentCreation;
  Timestamp documentUpgrade;
  String documentIdCreation;
  String documentIdUpgrade;
  bool verified;
  bool reviewed;
  bool outstanding;
  int followers;
  bool local;
  Timestamp creation;
  Timestamp upgrade;
  bool favorite;
  String category;
  String provider;
  String nameProvider;
  String nameCategory;
  int quantityStock;
  bool stock;
  int alertStock;
  int sales;
  double salePrice;
  double purchasePrice;
  String currencySign;
  int quantity;
  double revenue;
  double priceTotal;
  String subcategory;
  String nameSubcategory;

  ProductCatalogue({
    this.id = "",
    this.verified = false,
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
    this.priceTotal = 0.0,
  });

  ProductCatalogue copyWith({
    String? id,
    bool? verified,
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
    Timestamp? creation,
    Timestamp? upgrade,
    Timestamp? documentCreation,
    Timestamp? documentUpgrade,
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
    double? priceTotal,
    bool? reviewed,
  }) {
    return ProductCatalogue(
      id: id ?? this.id,
      verified: verified ?? this.verified,
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
      priceTotal: priceTotal ?? this.priceTotal,
    );
  }

  factory ProductCatalogue.fromMap(Map<String, dynamic> data) {
    return ProductCatalogue(
      id: data['id'] ?? '',
      verified: data['verified'] ?? data['verificado'] ?? false,
      reviewed: data['reviewed'] ?? data['revisado'] ?? false,
      followers: data['followers'] ?? data['seguidores'] ?? 0,
      outstanding: data['outstanding'] ?? data['destacado'] ?? false,
      favorite: data['favorite'] ?? data['favorito'] ?? false,
      idMark: data['idMark'] ?? data['id_marca'] ?? '',
      nameMark: data['nameMark'] ?? data['nombre_marca'] ?? '',
      imageMark: data['imageMark'] ?? '',
      image: data['image'] ?? data['urlimagen'] ?? 'https://default',
      description: data['description'] ?? data['descripcion'] ?? '',
      code: data['code'] ?? data['codigo'] ?? '',
      provider: data['provider'] ?? data['proveedor'] ?? '',
      nameProvider: data['nameProvider'] ?? data['proveedorName'] ?? '',
      category: data['category'] ?? data['categoria'] ?? '',
      nameCategory: data['nameCategory'] ?? data['categoriaName'] ?? '',
      subcategory: data['subcategory'] ?? data['subcategoria'] ?? '',
      nameSubcategory: data['nameSubcategory'] ?? data['subcategoriaName'] ?? '',
      upgrade: data['upgrade'] ?? data['timestamp_actualizacion'] ?? Timestamp.now(),
      creation: data['creation'] ?? data['timestamp_creation'] ?? Timestamp.now(),
      documentCreation: data['documentCreation'] ?? Timestamp.now(),
      documentUpgrade: data['documentUpgrade'] ?? Timestamp.now(),
      documentIdCreation: data['documentIdCreation'] ?? '',
      documentIdUpgrade: data['documentIdUpgrade'] ?? '',
      salePrice: (data['salePrice'] ?? 0.0).toDouble(),
      purchasePrice: (data['purchasePrice'] ?? 0.0).toDouble(),
      currencySign: data['currencySign'] ?? data['signo_moneda'] ?? '',
      quantityStock: data['quantityStock'] ?? 0,
      sales: data['sales'] ?? 0,
      stock: data['stock'] ?? false,
      alertStock: data['alertStock'] ?? 5,
      revenue: (data['revenue'] ?? 0.0).toDouble(),
      quantity: data['quantity'] ?? 1,
      local: data['local'] ?? false,
      priceTotal: (data['priceTotal'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() => {
        "id": id,
        'local': local,
        "verified": verified,
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
        "priceTotal": priceTotal,
      };

  String get porcentageFormat {
    if (purchasePrice == 0 || salePrice == 0) {
      return '';
    }
    final ganancia = salePrice - purchasePrice;
    final porcentajeDeGanancia = (ganancia / purchasePrice) * 100;
    return '${porcentajeDeGanancia.toInt()}%';
  }

  int get porcentageValue {
    if (purchasePrice == 0 || salePrice == 0) return 0;
    final ganancia = salePrice - purchasePrice;
    final porcentajeDeGanancia = (ganancia / purchasePrice) * 100;
    return porcentajeDeGanancia.toInt();
  }

  String get benefits {
    if (salePrice != 0.0 && purchasePrice != 0.0) {
      final ganancia = salePrice - purchasePrice;
      return ganancia.toStringAsFixed(2);
    }
    return '';
  }

  bool get isComplete => description.isNotEmpty && nameMark.isNotEmpty;
}