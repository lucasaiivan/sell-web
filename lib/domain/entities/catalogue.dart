import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/core.dart';

class Product {
  String id = ""; // ID del producto / código del producto
  String idMark = ""; // ID de la marca por defecto esta vacia
  String nameMark = ''; // nombre de la marca
  String imageMark = ''; // url de la imagen de la marca
  String description = ""; // Informacion
  String image = ""; // URL imagen
  String code = ""; // codigo del producto
  // valores de comunidad
  int followers = 0; // seguidores
  bool favorite = false; // producto destacado
  bool verified = false; // estado de verificación  al un moderador
  bool reviewed = false; // estado de revisado por un moderador
  Timestamp creation =
      Timestamp.now(); // Marca de tiempo ( hora en que se creo el producto )
  Timestamp upgrade =
      Timestamp.now(); // Marca de tiempo ( hora en que se edito el producto )
  // datos del usuario y cuenta
  String idUserCreation = ''; // id del usuario que creo el documento
  String idUserUpgrade = ''; // id del usuario que actualizo el documento

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
  Map<String, dynamic> toJsonUpdate() => {
        "id": id,
        'followers': followers,
        //'idUserCreation': idUserCreation,
        'idUserUpgrade': idUserUpgrade,
        "verified": verified,
        'reviewed': reviewed,
        "favorite": favorite,
        "idMark": idMark,
        'nameMark': nameMark,
        'imageMark': imageMark,
        "image": image,
        "description": description,
        //"code": code,
        //"creation": creation,
        "upgrade": upgrade,
      };

  factory Product.fromMap(Map data) {
    return Product(
      id: data.containsKey('id') ? data['id'] : '',
      followers: data.containsKey('followers') ? data['followers'] : 0,
      idUserCreation:
          data.containsKey('idUserCreation') ? data['idUserCreation'] : '',
      idUserUpgrade:
          data.containsKey('idUserUpgrade') ? data['idUserUpgrade'] : '',
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
      upgrade: data.containsKey('upgrade') ? data['upgrade'] : Timestamp.now(),
      creation:
          data.containsKey('creation') ? data['creation'] : Timestamp.now(),
    );
  }
  Product.fromDocumentSnapshot({required DocumentSnapshot documentSnapshot}) {
    // convert
    Map data = documentSnapshot.data() as Map;
    // set
    id = data['id'] ?? '';
    followers = data.containsKey('followers') ? data['followers'] : 0;
    idUserCreation = data['idUserCreation'] ?? '';
    idUserUpgrade = data['idUserUpgrade'] ?? '';
    verified = data.containsKey('verified')
        ? data['verified']
        : data['verificado'] ?? false;
    reviewed = data.containsKey('reviewed')
        ? data['reviewed']
        : data['revisado'] ?? false;
    favorite = data['favorite'] ?? false;
    idMark =
        data.containsKey('idMark') ? data['idMark'] : data['id_marca'] ?? '';
    nameMark = data['nameMark'] ?? '';
    imageMark = data['imageMark'] ?? '';
    image = data.containsKey('image') ? data['image'] : data['urlimagen'] ?? '';
    description = data.containsKey('description')
        ? data['description']
        : data['descripcion'] ?? '';
    code = data.containsKey('code') ? data['code'] : data['codigo'] ?? '';
    upgrade = data.containsKey('upgrade')
        ? data['upgrade']
        : data['timestamp_actualizacion'] ?? Timestamp.now();
    creation = data.containsKey('creation')
        ? data['creation']
        : data['timestamp_creation'] ?? Timestamp.now();
  }
  ProductCatalogue convertProductCatalogue() {
    // convierte la entidad [Product] a [ProductCatalogue]
    ProductCatalogue productCatalogue = ProductCatalogue(
      upgrade: upgrade,
      creation: creation,
      documentCreation: creation,
      documentUpgrade: upgrade,
    );
    //  set
    productCatalogue.id = id;
    productCatalogue.followers = followers;
    productCatalogue.image = image;
    productCatalogue.verified = verified;
    productCatalogue.reviewed = reviewed;
    productCatalogue.outstanding = favorite;
    productCatalogue.idMark = idMark;
    productCatalogue.nameMark = nameMark;
    productCatalogue.imageMark = imageMark;
    productCatalogue.description = description;
    productCatalogue.code = code;
    productCatalogue.documentUpgrade = upgrade;
    productCatalogue.documentCreation = creation;
    productCatalogue.documentIdCreation = idUserCreation;
    productCatalogue.documentIdUpgrade = idUserUpgrade;

    return productCatalogue;
  }
}

class ProductCatalogue {
  // información basica del producto
  String id = "";
  String idMark = ""; // ID de la marca por defecto esta vacia
  String nameMark = ''; // nombre de la marca
  String imageMark = ''; // url de la imagen de la marca
  String image = ""; // URL imagen
  String description = ""; // Información
  String code = "";
  Timestamp documentCreation = Timestamp
      .now(); // Marca de tiempo ( hora en que se creo el producto publico )
  Timestamp documentUpgrade = Timestamp
      .now(); // Marca de tiempo ( hora en que se actualizo el producto publico )
  String documentIdCreation = ""; // ID del usuaario de creacion
  String documentIdUpgrade = ""; // ID del usuario de actualizacion

  // variables del producto global
  bool verified = false; // estado de verificación por un moderador
  bool reviewed = false; // estado de revisado por un moderador
  bool outstanding = false; // producto destacado en la DB global

  // TODO : eliminar esta variable (followers) porque esta en desuso
  int followers = 0; // seguidores (pronto a liminar)

  // variables del catalogo de la cuenta
  bool local = false;
  Timestamp creation = Timestamp
      .now(); // Marca de tiempo ( hora en que se creo el documento en el catalogo de la cuenta  )
  Timestamp upgrade = Timestamp
      .now(); // Marca de tiempo ( hora en que se actualizo el precio de venta al publico )
  bool favorite = false;
  String category = ""; // ID de la categoria del producto
  String provider = ""; // ID del proveedor del producto
  String nameProvider = ""; // nombre del proveedor
  String nameCategory = ""; // nombre de la categoria
  int quantityStock = 0;
  bool stock = false;
  int alertStock = 5;
  int sales = 0; // ventas
  double salePrice = 0.0; // precio de venta al publico
  double purchasePrice = 0.0; // precio de compra
  String currencySign = "\$"; // signo de la moneda

  //  variables en tiempo de ejecucion
  int quantity = 0;
  double revenue = 0.0;
  double priceTotal = 0;

  // variables en desuso
  String subcategory = ""; // ID de la subcategoria del producto
  String nameSubcategory = ""; // name subcategory

  ProductCatalogue({
    // Valores del producto
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
    Timestamp? creation,
    Timestamp? upgrade,
    Timestamp? documentCreation,
    Timestamp? documentUpgrade,
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
  })  : creation = creation ?? Timestamp.now(),
        upgrade = upgrade ?? Timestamp.now(),
        documentCreation = documentCreation ?? Timestamp.now(),
        documentUpgrade = documentUpgrade ?? Timestamp.now();

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
  }) {
    return ProductCatalogue(
      id: id ?? this.id,
      verified: verified ?? this.verified,
      reviewed: reviewed,
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
    );
  }

  factory ProductCatalogue.fromMap(Map data) {
    Timestamp parseTimestamp(dynamic value) {
      if (value is Timestamp) return value;
      if (value is int) return Timestamp.fromMillisecondsSinceEpoch(value);
      return Timestamp.now();
    }

    return ProductCatalogue(
      id: data.containsKey('id') ? data['id'] : '',
      verified: data.containsKey('verified')
          ? data['verified']
          : data['verificado'] ?? false,
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
          parseTimestamp(data['upgrade'] ?? data['timestamp_actualizacion']),
      creation: parseTimestamp(data['creation'] ?? data['timestamp_creation']),
      documentCreation: parseTimestamp(data['documentCreation']),
      documentUpgrade: parseTimestamp(data['documentUpgrade']),
      documentIdCreation: data.containsKey('documentIdCreation')
          ? data['documentIdCreation']
          : data['documentIdCreation'] ?? '',
      documentIdUpgrade: data.containsKey('documentIdUpgrade')
          ? data['documentIdUpgrade']
          : data['documentIdUpgrade'] ?? '',
      salePrice: data.containsKey('salePrice')
          ? (data['salePrice'] is int
              ? (data['salePrice'] as int).toDouble()
              : data['salePrice'] ?? 0.0)
          : 0.0,
      purchasePrice: data.containsKey('purchasePrice')
          ? (data['purchasePrice'] is int
              ? (data['purchasePrice'] as int).toDouble()
              : data['purchasePrice'] ?? 0.0)
          : 0.0,
      currencySign: data.containsKey('currencySign')
          ? data['currencySign']
          : data['signo_moneda'] ?? '',
      quantityStock:
          data.containsKey('quantityStock') ? data['quantityStock'] : 0,
      sales: data.containsKey('sales') ? data['sales'] : 0,
      stock: data.containsKey('stock') ? data['stock'] : false,
      alertStock: data.containsKey('alertStock') ? data['alertStock'] : 5,
      revenue: data.containsKey('revenue') ? data['revenue'] : 0.0,
      quantity: data.containsKey('quantity') ? data['quantity'] : 1,
      local: data.containsKey('local') ? data['local'] : false,
    );
  }
  factory ProductCatalogue.translatePrimitiveData(Map data) {
    return ProductCatalogue(
      // Valores del producto
      id: data.containsKey('id') ? data['id'] : '',
      local: data.containsKey('local') ? data['local'] : false,
      verified: data.containsKey('verified')
          ? data['verified']
          : data['verificado'] ?? false,
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
      // traducir datos primitivos
      upgrade: data.containsKey('upgrade')
          ? Timestamp.fromMillisecondsSinceEpoch(data['upgrade'])
          : Timestamp.fromMillisecondsSinceEpoch(
              data['timestamp_actualizacion']),
      creation: data.containsKey('creation')
          ? Timestamp.fromMillisecondsSinceEpoch(data['creation'])
          : Timestamp.fromMillisecondsSinceEpoch(data['timestamp_creation']),
      documentCreation: data.containsKey('documentCreation')
          ? Timestamp.fromMillisecondsSinceEpoch(data['documentCreation'])
          : Timestamp.fromMillisecondsSinceEpoch(data['documentCreation']),
      documentUpgrade: data.containsKey('documentUpgrade')
          ? Timestamp.fromMillisecondsSinceEpoch(data['documentUpgrade'])
          : Timestamp.fromMillisecondsSinceEpoch(data['documentUpgrade']),
      documentIdCreation: data.containsKey('documentIdCreation')
          ? data['documentIdCreation']
          : data['documentIdCreation'] ?? '',
      documentIdUpgrade: data.containsKey('documentIdUpgrade')
          ? data['documentIdUpgrade']
          : data['documentIdUpgrade'] ?? '',
      // valores de la cuenta
      salePrice: data.containsKey('salePrice')
          ? data['salePrice'].toDouble() ?? 0.0.toDouble()
          : 0.0.toDouble(),
      purchasePrice: data.containsKey('purchasePrice')
          ? data['purchasePrice'].toDouble() ?? 0.0.toDouble()
          : 0.0.toDouble(),
      currencySign: data.containsKey('currencySign')
          ? data['currencySign']
          : data['signo_moneda'] ?? '',
      quantityStock:
          data.containsKey('quantityStock') ? data['quantityStock'] : 0,
      sales: data.containsKey('sales') ? data['sales'] : 0,
      stock: data.containsKey('stock') ? data['stock'] : false,
      alertStock: data.containsKey('alertStock') ? data['alertStock'] : 5,
      revenue: data.containsKey('revenue') ? data['revenue'] : 0.0,
      // values of app
      quantity: data.containsKey('quantity') ? data['quantity'] : 1,
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
        "creation": creation, // guardamos como Timestamp para compatibilidad
        "upgrade": upgrade, // guardamos como Timestamp para compatibilidad
        "documentCreation":
            documentCreation, // guardamos como Timestamp para compatibilidad
        "documentUpgrade":
            documentUpgrade, // guardamos como Timestamp para compatibilidad
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

  // convierte los datos a primitivos guardar en shared preferences
  Map<String, dynamic> toJson() => {
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
        "creation": creation,
        "upgrade": upgrade,
        "documentCreation": documentCreation,
        "documentUpgrade": documentUpgrade,
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
  factory ProductCatalogue.mapRefactoring(Map<dynamic, dynamic> data) {
    return ProductCatalogue(
      id: data['id'] ?? '',
      local: data['local'] ?? false,
      verified: data['verified'] ?? false,
      reviewed: data['reviewed'] ?? false,
      followers: data['followers'] ?? 0,
      favorite: data['favorite'] ?? false,
      outstanding: data['outstanding'] ?? false,
      idMark: data['idMark'] ?? '',
      nameMark: data['nameMark'] ?? '',
      imageMark: data['imageMark'] ?? '',
      image: data['image'] ?? '',
      description: data['description'] ?? '',
      code: data['code'] ?? '',
      provider: data['provider'] ?? '',
      nameProvider: data['nameProvider'] ?? '',
      category: data['category'] ?? '',
      nameCategory: data['nameCategory'] ?? '',
      subcategory: data['subcategory'] ?? '',
      nameSubcategory: data['nameSubcategory'] ?? '',
      salePrice: data['salePrice'] ?? 0.0,
      purchasePrice: data['purchasePrice'] ?? 0.0,
      currencySign: data['currencySign'] ?? '',
      creation: data['creation'] ?? Timestamp.now(),
      upgrade: data['upgrade'] ?? Timestamp.now(),
      documentCreation: data['documentCreation'] ?? Timestamp.now(),
      documentUpgrade: data['documentUpgrade'] ?? Timestamp.now(),
      documentIdCreation: data['documentIdCreation'] ?? '',
      documentIdUpgrade: data['documentIdUpgrade'] ?? '',
      quantityStock: data['quantityStock'] ?? 0,
      stock: data['stock'] ?? false,
      alertStock: data['alertStock'] ?? 5,
      revenue: data['revenue'] ?? 0.0,
      sales: data['sales'] ?? 0,
      quantity: data['quantity'] ?? 1,
    );
  }

  Product convertProductoDefault() {
    // convertimos en el modelo para producto global
    Product productoDefault =
        Product(upgrade: Timestamp.now(), creation: Timestamp.now());
    productoDefault.id = id;
    productoDefault.followers = followers;
    productoDefault.image = image;
    productoDefault.verified = verified;
    productoDefault.reviewed = reviewed;
    productoDefault.favorite = outstanding;
    productoDefault.idMark = idMark;
    productoDefault.nameMark = nameMark;
    productoDefault.imageMark = imageMark;
    productoDefault.description = description;
    productoDefault.code = code;
    productoDefault.upgrade = documentUpgrade;
    productoDefault.creation = documentCreation;
    productoDefault.idUserCreation = documentIdCreation;
    productoDefault.idUserUpgrade = documentIdUpgrade;

    return productoDefault;
  }

  ProductCatalogue updateData({required Product product}) {
    // actualizamos los datos del documento publico
    local = false;
    id = product.id;
    followers = product.followers;
    image = product.image;
    verified = product.verified;
    reviewed = product.verified;
    outstanding = product.favorite;
    idMark = product.idMark;
    nameMark = product.nameMark;
    imageMark = product.imageMark;
    description = product.description;
    code = product.code;
    documentCreation = product.creation;
    documentUpgrade = product.upgrade;
    documentIdCreation = product.idUserCreation;
    documentIdUpgrade = product.idUserUpgrade;

    return this;
  }

  // Fuction
  String get getPorcentageFormat {
    // description : obtenemos el porcentaje de las ganancias
    if (purchasePrice == 0 || salePrice == 0) {
      return '';
    }

    double ganancia = salePrice - purchasePrice;
    double porcentajeDeGanancia = (ganancia / purchasePrice) * 100;

    if (ganancia % 1 != 0) {
      return '${porcentajeDeGanancia.toInt()}%';
    } else {
      return '${porcentajeDeGanancia.toInt()}%';
    }
  }

  int get getPorcentageValue {
    // description : obtenemos el porcentaje de las ganancias
    if (purchasePrice == 0 || salePrice == 0) {
      return 0;
    }
    double ganancia = salePrice - purchasePrice;
    double porcentajeDeGanancia = (ganancia / purchasePrice) * 100;
    return porcentajeDeGanancia.toInt();
  }

  String get getBenefits {
    // description : obtenemos las ganancias
    double ganancia = 0.0;
    if (salePrice != 0.0 && purchasePrice != 0.0) {
      ganancia = salePrice - purchasePrice;

      final String value = CurrencyFormatter.formatPrice(value: ganancia);
      return value;
    }
    return '';
  }

  get isComplete => description.isNotEmpty && nameMark.isNotEmpty;
}

class ProductPrice {
  String id = '';
  double price = 0.0;
  late Timestamp time; // marca de tiempo en la que se registro el precio
  String currencySign = ""; // signo de la moneda
  String province = ""; // provincia
  String town = ""; // ciudad o pueblo
  // data account
  String idAccount = "";
  String imageAccount = ''; // imagen de perfil de la cuenta
  String nameAccount = ''; // nombre de la cuenta

  ProductPrice({
    required this.id,
    required this.idAccount,
    required this.imageAccount,
    required this.nameAccount,
    required this.price,
    required this.time,
    required this.currencySign,
    this.province = '',
    this.town = '',
  });

  ProductPrice.fromMap(Map data) {
    id = data['id'] ?? '';
    idAccount = data['idAccount'] ?? '';
    imageAccount = data.containsKey('imageAccount')
        ? data['imageAccount']
        : data['urlImageAccount'] ?? '';
    nameAccount = data['nameAccount'] ?? '';
    price = data.containsKey('price') ? data['price'] : data['precio'] ?? 0.0;
    time = data.containsKey('time') ? data['time'] : data['timestamp'];
    currencySign = data.containsKey('currencySign')
        ? data['currencySign']
        : data['moneda'] ?? '';
    province = data.containsKey('province')
        ? data['province']
        : data['provincia'] ?? '';
    town = data.containsKey('town') ? data['town'] : data['ciudad'] ?? '';
  }
  Map<String, dynamic> toJson() => {
        'id': id,
        "idAccount": idAccount,
        "imageAccount": imageAccount,
        "nameAccount": nameAccount,
        "price": price,
        "time": time,
        "currencySign": currencySign,
        "province": province,
        "town": town,
      };
}

class Category {
  String id = "";
  String name = "";
  Map<String, dynamic> subcategories = <String, dynamic>{};

  Category({
    this.id = "",
    this.name = "",
    this.subcategories = const {},
  });
  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "subcategories": subcategories,
      };
  factory Category.fromMap(Map<String, dynamic> data) {
    return Category(
      id: data['id'] ?? '',
      name: data.containsKey('name') ? data['name'] : data['nombre'] ?? '',
      subcategories: data.containsKey('subcategories')
          ? data['subcategories']
          : data['subcategorias'] ?? <String, dynamic>{},
    );
  }
  Category.fromDocumentSnapshot({required DocumentSnapshot documentSnapshot}) {
    Map data = documentSnapshot.data() as Map;

    id = data['id'] ?? '';
    name = data.containsKey('name') ? data['name'] : data['nombre'] ?? '';
    subcategories = data.containsKey('subcategories')
        ? data['subcategories']
        : data['subcategorias'] ?? <String, dynamic>{};
  }
}

class Mark {
  String id = "";
  String name = "";
  String description = "";
  String image = "";
  bool verified = false;
  // Datos de la creación
  String idUsuarioCreador = ""; // ID el usuaruio que creo el productos
  Timestamp creation =
      Timestamp.now(); // Marca de tiempo de la creacion del documento
  Timestamp upgrade =
      Timestamp.now(); // Marca de tiempo de la ultima actualizacion

  Mark({
    this.id = "",
    this.name = "",
    this.description = "",
    this.image = "",
    this.verified = false,
    required this.upgrade,
    required this.creation,
  });
  Mark.fromMap(Map data) {
    id = data['id'] ?? '';
    name = data.containsKey('name') ? data['name'] : data['titulo'] ?? '';
    description = data.containsKey('description')
        ? data['description']
        : data['descripcion'] ?? '';
    image =
        data.containsKey('image') ? data['image'] : data['url_imagen'] ?? '';
    verified = data.containsKey('verified')
        ? data['verified']
        : data['verificado'] ?? false;
    creation = data.containsKey('creation')
        ? data['creation']
        : data['timestampCreacion'] ?? Timestamp.now();
    upgrade = data.containsKey('upgrade')
        ? data['upgrade']
        : data['timestampUpdate'] ?? Timestamp.now();
  }
  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "description": description,
        "image": image,
        "verified": verified,
        "creation": creation,
        "upgrade": upgrade,
      };

  // Sobreescribir el operador ==
  @override
  bool operator ==(other) {
    return other is Mark && other.id == id && other.name == name;
  }

  // Sobreescribir el metodo hashCode
  @override
  int get hashCode => id.hashCode ^ name.hashCode;
}

class ReportProduct {
  String id = ''; // el id se conforma por (idProduct +'/'+ idUserReport)
  String idProduct = ''; // id/code del producto
  String idUserReport = ''; // id del usuario que reporto el producto
  String description = ''; // descripcion del reporte (opcional)
  List reports = []; // lista de reportes
  late Timestamp time; // Marca de tiempo ( hora en que se reporto el producto )

  ReportProduct({
    this.id = "",
    this.idProduct = "",
    this.idUserReport = "",
    this.description = "",
    this.reports = const [],
    required this.time,
  });
  Map<String, dynamic> toJson() => {
        "id": id,
        "idProduct": idProduct,
        "idUserReport": idUserReport,
        "description": description,
        "reports": reports,
        "time": time,
      };
  factory ReportProduct.fromMap(Map<String, dynamic> data) {
    return ReportProduct(
      id: data['id'] ?? '',
      idProduct: data['idProduct'] ?? '',
      idUserReport: data['idUserReport'] ?? '',
      description: data['description'] ?? '',
      reports: data['reports'] ?? [],
      time: data['time'],
    );
  }
  ReportProduct.fromDocumentSnapshot(
      {required DocumentSnapshot documentSnapshot}) {
    Map data = documentSnapshot.data() as Map;

    id = data['id'] ?? '';
    idProduct = data['name'] ?? '';
    idUserReport = data['idUserReport'] ?? '';
    description = data['description'] ?? '';
    reports = data['reports'] ?? [];
    time = data['time'];
  }
}

// class Supplier: proveedor de productos
class Provider {
  String id = "";
  String name = "";
  Provider({
    this.id = "",
    this.name = "",
  });
  Provider.fromMap(Map data) {
    id = data['id'] ?? '';
    name = data['name'] ?? '';
  }
  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
      };
  Provider.fromDocumentSnapshot({required DocumentSnapshot documentSnapshot}) {
    Map data = documentSnapshot.data() as Map;

    id = data['id'] ?? '';
    name = data['name'] ?? '';
  }
}
