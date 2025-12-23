import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:sellweb/core/constants/payment_methods.dart';
import 'package:sellweb/features/catalogue/domain/entities/product_catalogue.dart';

class TicketModel {
  String id = ''; // id unic
  String sellerName = ''; // nombre del vendedor
  String sellerId = ''; // id del vendedor
  String cashRegisterName =
      '1'; // nombre o numero de caja que se efectuo la venta
  String cashRegisterId = ''; // id de la caja que se efectuo la venta
  String payMode =
      ''; // cash (Efectivo) - transfer (Transferencia) - card (Tarjeta Déb/Créd) - qr (QR)
  double priceTotal = 0.0; // precio total de la venta
  double valueReceived = 0.0; // valor recibido por la venta
  double discount =
      0.0; // descuento aplicado: valor original ingresado (porcentaje o monto) segun [discountIsPercentage]
  String currencySymbol = '\$'; // simbolo de la moneda utilizada en la venta
  /// Información del descuento aplicado
  bool discountIsPercentage =
      false; // true si el descuento es porcentual, false si es monto fijo

  /// Tipo de transacción que representa este ticket
  ///
  /// Valores posibles:
  /// - 'sale': Venta normal (por defecto)
  /// - 'refund': Devolución
  /// - 'exchange': Cambio de producto
  /// - 'adjustment': Ajuste de inventario
  String transactionType = 'sale';

  /// Indica si el ticket ha sido anulado
  /// true si el ticket está anulado, false si está activo
  bool annulled = false;

  /// Lista de productos en el ticket almacenados como mapas de ProductCatalogue
  /// Almacena directamente los datos completos del producto del catálogo
  /// PRIVADA: Solo se accede a través de getters/setters y métodos específicos
  List<Map<String, dynamic>> _listPoduct = [];
  late Timestamp
      creation; // Marca de tiempo ( hora en que se reporto el producto )

  TicketModel({
    this.id = "",
    this.payMode = "",
    this.currencySymbol = "\$",
    this.sellerName = "",
    this.sellerId = "",
    this.cashRegisterName = "",
    this.cashRegisterId = "",
    this.priceTotal = 0.0,
    this.valueReceived = 0.0,
    this.discount = 0.0,
    this.discountIsPercentage = false,
    this.transactionType = "sale",
    this.annulled = false,
    required List<Map<String, dynamic>> listPoduct,
    required this.creation,
  }) : _listPoduct = listPoduct;

  // ==========================================
  // GETTERS Y SETTERS PARA ProductCatalogue
  // ==========================================

  /// Obtiene los productos como lista de ProductCatalogue
  /// (convierte desde mapas almacenados internamente)
  List<ProductCatalogue> get products {
    return _listPoduct.map((productMap) {
      return ProductCatalogue.fromMap(productMap);
    }).toList();
  }

  /// Establece los productos desde una lista de ProductCatalogue
  /// (almacena directamente como mapas)
  set products(List<ProductCatalogue> productList) {
    _listPoduct = productList.map((product) {
      return product.toMap();
    }).toList();
  }

  /// Agrega un producto desde ProductCatalogue
  void addProductFromCatalogue(ProductCatalogue product) {
    addProductMap(product.toMap());
  }

  /// Agrega un producto desde un mapa de ProductCatalogue al ticket
  void addProductMap(Map<String, dynamic> productMap) {
    // Verificar si el producto ya existe
    bool exist = false;
    for (var i = 0; i < _listPoduct.length; i++) {
      if (_listPoduct[i]['id'] == productMap['id']) {
        // Incrementar cantidad
        _listPoduct[i]['quantity'] =
            (_listPoduct[i]['quantity'] ?? 0) + (productMap['quantity'] ?? 1);
        exist = true;
        break;
      }
    }

    // Si no existe, agregarlo
    if (!exist) {
      _listPoduct.add(Map<String, dynamic>.from(productMap));
    }
  }

  /// Obtiene un producto específico por ID como ProductCatalogue
  ProductCatalogue? getProductById(String productId) {
    for (var productMap in _listPoduct) {
      if (productMap['id'] == productId) {
        return ProductCatalogue.fromMap(productMap);
      }
    }
    return null;
  }

  /// Actualiza la cantidad de un producto específico
  void updateProductQuantity(String productId, int newQuantity) {
    for (var i = 0; i < _listPoduct.length; i++) {
      if (_listPoduct[i]['id'] == productId) {
        if (newQuantity <= 0) {
          _listPoduct.removeAt(i);
        } else {
          _listPoduct[i]['quantity'] = newQuantity;
        }
        return;
      }
    }
  }

  /// Elimina un producto por ID
  void removeProductById(String productId) {
    _listPoduct.removeWhere((product) => product['id'] == productId);
  }

  /// Obtiene el total de productos usando ProductCatalogue
  /// Retorna double para soportar cantidades fraccionarias (kg, L, m)
  double get totalProductCount {
    return products.fold(0.0, (total, product) => total + product.quantity);
  }

  /// Calcula el total usando ProductCatalogue
  double get calculatedTotal {
    return products.fold(0.0,
        (total, product) => total + (product.salePrice * product.quantity));
  }

  /// Getter de solo lectura para acceso controlado a la lista interna
  /// Solo para depuración y casos especiales - NO modificar directamente
  List<Map<String, dynamic>> get internalProductList =>
      List.unmodifiable(_listPoduct);

  /// Valida que todos los elementos en _listPoduct tengan la estructura de ProductCatalogue
  bool _validateInternalProductStructure() {
    for (var product in _listPoduct) {
      final requiredFields = [
        'id',
        'code',
        'description',
        'quantity',
        'salePrice'
      ];
      for (var field in requiredFields) {
        if (!product.containsKey(field)) return false;
      }

      // Validar tipos de datos básicos
      if (product['id'] is! String) return false;
      if (product['code'] is! String) return false;
      if (product['description'] is! String) return false;
      if (product['quantity'] is! int) return false;
      if (product['salePrice'] is! num) return false;
    }
    return true;
  }

  // ==========================================
  // MÉTODOS ADICIONALES DE CONVENIENCIA
  // ==========================================

  int getProductsQuantity() {
    int count = 0;
    for (var element in _listPoduct) {
      count += element['quantity'] as int;
    }
    return count;
  }

  // get style : obtiene el color asociado al medio de pago
  Color get getPayModeColor {
    final method = PaymentMethod.fromCode(payMode);
    return method.color;
  }

  //  get : obtiene el nombre del medio de pago en formato legible
  String get getNamePayMode {
    final method = PaymentMethod.fromCode(payMode);
    return method.displayName;
  }

  // get : recibe un id de medio de pago y devuelve su nombre en formato legible
  static String getFormatPayMode({required String id}) {
    final method = PaymentMethod.fromCode(id);
    return method.displayName;
  }

  /// Analiza una lista de tickets y devuelve los medios de pago ordenados por uso
  ///
  /// Retorna una lista ordenada de mayor a menor uso con la siguiente estructura:
  /// ```dart
  /// [
  ///   {
  ///     'description': 'Efectivo',      // Nombre del medio de pago
  ///     'amount': 15000.50,             // Monto total vendido con este medio
  ///     'percentage': 45.5,             // Porcentaje del total de ventas
  ///     'count': 120                    // Cantidad de tickets con este medio
  ///   },
  ///   ...
  /// ]
  /// ```
  ///
  /// [tickets] - Lista de tickets a analizar
  /// [includeAnnulled] - Si es true, incluye tickets anulados en el análisis (por defecto: false)
  static List<Map<String, dynamic>> getPaymentMethodsRanking({
    required List<TicketModel> tickets,
    bool includeAnnulled = false, // por defecto no incluir anulados
  }) {
    // Filtrar tickets anulados si corresponde
    final validTickets = includeAnnulled
        ? tickets
        : tickets.where((ticket) => !ticket.annulled).toList();

    if (validTickets.isEmpty) {
      return [];
    }

    // Agrupar por medio de pago (usando mapa dinámico para incluir no registrados)
    final Map<String, Map<String, dynamic>> paymentStats = {};

    double totalAmount = 0.0;

    // Acumular estadísticas
    for (var ticket in validTickets) {
      final payMode = ticket.payMode;
      final amount = ticket.getTotalPrice;

      // Si el medio de pago no existe en el mapa, inicializarlo
      if (!paymentStats.containsKey(payMode)) {
        paymentStats[payMode] = {
          'description': getFormatPayMode(id: payMode),
          'amount': 0.0,
          'count': 0,
        };
      }

      // Acumular datos
      paymentStats[payMode]!['amount'] =
          (paymentStats[payMode]!['amount'] as double) + amount;
      paymentStats[payMode]!['count'] =
          (paymentStats[payMode]!['count'] as int) + 1;
      totalAmount += amount;
    }

    // Convertir a lista y calcular porcentajes
    final List<Map<String, dynamic>> result = [];

    paymentStats.forEach((key, stats) {
      final amount = stats['amount'] as double;
      final count = stats['count'] as int;

      // Solo incluir medios de pago que se han utilizado
      if (count > 0) {
        final percentage = totalAmount > 0 ? (amount / totalAmount) * 100 : 0.0;

        result.add({
          'description': stats['description'],
          'amount': amount,
          'percentage': double.parse(percentage.toStringAsFixed(2)),
          'count': count,
        });
      }
    });

    // Ordenar por monto (de mayor a menor)
    result.sort(
        (a, b) => (b['amount'] as double).compareTo(a['amount'] as double));

    // devuelve la lista de métodos de pago ordenados
    return result;
  }

  // Map : serializa el objeto a un mapa con tipo de datos primitivos
  Map<String, dynamic> toMap() => {
        "id": id,
        "payMode": payMode,
        "currencySymbol": currencySymbol,
        "sellerName": sellerName,
        'sellerId': sellerId,
        "cashRegisterName": cashRegisterName,
        'cashRegisterId': cashRegisterId,
        "priceTotal": priceTotal,
        "valueReceived": valueReceived,
        "discountIsPercentage": discountIsPercentage,
        "discount": discount,
        "transactionType": transactionType,
        "annulled": annulled,
        // Usar directamente los mapas de ProductCatalogue almacenados
        "listPoduct": _listPoduct,
        "creation": creation,
      };

  /// Serializa el ticket usando ProductCatalogue almacenados directamente como mapas
  Map<String, dynamic> toMapOptimized() => {
        "id": id,
        "payMode": payMode,
        "currencySymbol": currencySymbol,
        "sellerName": sellerName,
        'sellerId': sellerId,
        "cashRegisterName": cashRegisterName,
        'cashRegisterId': cashRegisterId,
        "priceTotal": priceTotal,
        "valueReceived": valueReceived,
        "discountIsPercentage": discountIsPercentage,
        "discount": discount,
        "transactionType": transactionType,
        "annulled": annulled,
        // Usar directamente el _listPoduct (que contiene mapas de ProductCatalogue)
        "listPoduct": _listPoduct,
        "creation": creation,
      };

  /// Serializa el ticket a un mapa JSON. Convierte 'creation' a milisegundos desde época para compatibilidad JSON.
  Map<String, dynamic> toJson({bool cache = false}) => {
        "id": id,
        "payMode": payMode,
        "currencySymbol": currencySymbol,
        "sellerName": sellerName,
        'sellerId': sellerId,
        "cashRegisterName": cashRegisterName,
        'cashRegisterId': cashRegisterId,
        "priceTotal": priceTotal,
        "valueReceived": valueReceived,
        "discountIsPercentage": discountIsPercentage,
        "discount": discount,
        "transactionType": transactionType,
        "annulled": annulled,
        // Serializar productos con Timestamp convertidos a milliseconds para SharedPreferences
        "listPoduct": _listPoduct.map((productMap) {
          Map<String, dynamic> serializedProduct =
              Map<String, dynamic>.from(productMap);

          // Convertir campos Timestamp a milliseconds para JSON
          if (serializedProduct['creation'] is Timestamp) {
            serializedProduct['creation'] =
                (serializedProduct['creation'] as Timestamp)
                    .millisecondsSinceEpoch;
          }
          if (serializedProduct['upgrade'] is Timestamp) {
            serializedProduct['upgrade'] =
                (serializedProduct['upgrade'] as Timestamp)
                    .millisecondsSinceEpoch;
          }
          if (serializedProduct['documentCreation'] is Timestamp) {
            serializedProduct['documentCreation'] =
                (serializedProduct['documentCreation'] as Timestamp)
                    .millisecondsSinceEpoch;
          }
          if (serializedProduct['documentUpgrade'] is Timestamp) {
            serializedProduct['documentUpgrade'] =
                (serializedProduct['documentUpgrade'] as Timestamp)
                    .millisecondsSinceEpoch;
          }

          return serializedProduct;
        }).toList(),
        // Serializamos creation como int (milisegundos desde época)
        "creation": creation.millisecondsSinceEpoch,
      };

  /// Helper para normalizar campos Timestamp que pueden venir como int
  static void _normalizeTimestampField(
      Map<String, dynamic> map, String fieldName) {
    if (map.containsKey(fieldName) && map[fieldName] != null) {
      if (map[fieldName] is int) {
        map[fieldName] = Timestamp.fromMillisecondsSinceEpoch(map[fieldName]);
      }
      // Si ya es Timestamp, no hacemos nada
    }
  }

  /// Factory constructor para crear un TicketModel desde un Map (principalmente para Firestore)
  factory TicketModel.fromMap(Map<String, dynamic> data) {
    try {
      // Manejo robusto de la marca de tiempo para soportar Timestamp o int (milisegundos)
      Timestamp creationTimestamp;
      if (data.containsKey('creation')) {
        if (data['creation'] is Timestamp) {
          creationTimestamp = data['creation'];
        } else if (data['creation'] is int) {
          creationTimestamp =
              Timestamp.fromMillisecondsSinceEpoch(data['creation']);
        } else {
          creationTimestamp = Timestamp.now();
        }
      } else {
        creationTimestamp = Timestamp.now();
      }

      // Procesar la lista de productos
      List<Map<String, dynamic>> processedProducts = [];
      if (data.containsKey('listPoduct') && data['listPoduct'] != null) {
        final productList = data['listPoduct'] as List;
        processedProducts = productList.map((item) {
          Map<String, dynamic> productMap = item is Map<String, dynamic>
              ? Map<String, dynamic>.from(item)
              : Map<String, dynamic>.from(item as Map);

          // Normalizar todos los campos timestamp conocidos dentro de los productos
          _normalizeTimestampField(productMap, 'creation');
          _normalizeTimestampField(productMap, 'upgrade');
          _normalizeTimestampField(productMap, 'documentCreation');
          _normalizeTimestampField(productMap, 'documentUpgrade');
          // Normalizar también timestamps con nombres legacy
          _normalizeTimestampField(productMap, 'timestamp_actualizacion');
          _normalizeTimestampField(productMap, 'timestamp_creation');
          _normalizeTimestampField(productMap, 'timestamp_creation_document');
          _normalizeTimestampField(productMap, 'timestamp_upgrade_document');

          return productMap;
        }).toList();
      }

      // Normalizar payMode al cargar desde Firestore (migración automática)
      final rawPayMode = data['payMode'] ?? '';
      final normalizedPayMode = PaymentMethod.migrateLegacyCode(rawPayMode);

      return TicketModel(
        id: data['id'] ?? '',
        payMode: normalizedPayMode,
        sellerName: data['sellerName'] ?? '',
        sellerId: data['sellerId'] ?? '',
        currencySymbol: data['currencySymbol'] ?? '\$',
        cashRegisterName: data['cashRegisterName'] ??
            data['cashRegister'] ??
            '', // Soporte para ambos nombres de campo
        cashRegisterId: data['cashRegisterId'] ?? '',
        priceTotal: (data['priceTotal'] ?? 0.0).toDouble(),
        valueReceived: (data['valueReceived'] ?? 0.0).toDouble(),
        discount: (data['discount'] ?? 0.0).toDouble(),
        discountIsPercentage: data['discountIsPercentage'] ?? false,
        transactionType: data['transactionType'] ?? 'sale',
        annulled: data['annulled'] ?? false,
        listPoduct: processedProducts,
        creation: creationTimestamp,
      );
    } catch (e, stackTrace) {
      // Log detallado del error para debugging
      if (kDebugMode) {
        print('❌ Error en TicketModel.fromMap:');
        print('   Ticket ID: ${data['id']}');
        print('   Error: $e');
        print('   Data keys: ${data.keys.toList()}');
        if (data.containsKey('listPoduct')) {
          print('   Products count: ${(data['listPoduct'] as List?)?.length}');
          final products = data['listPoduct'] as List?;
          if (products != null && products.isNotEmpty) {
            print(
                '   First product keys: ${(products[0] as Map).keys.toList()}');
            print(
                '   First product creation type: ${(products[0] as Map)['creation']?.runtimeType}');
          }
        }
        print('   Stack: $stackTrace');
      }
      rethrow;
    }
  }

  factory TicketModel.sahredPreferencefromMap(Map<dynamic, dynamic> data) {
    // Manejo robusto de la marca de tiempo para soportar int (milisegundos) o Timestamp obtenido de shared preferences
    Timestamp creationTimestamp;
    if (data.containsKey('creation')) {
      if (data['creation'] is int) {
        creationTimestamp =
            Timestamp.fromMillisecondsSinceEpoch(data['creation']);
      } else if (data['creation'] is Timestamp) {
        creationTimestamp = data['creation'];
      } else {
        creationTimestamp = Timestamp.now();
      }
    } else {
      creationTimestamp = Timestamp.now();
    }

    // Procesar la lista de productos y convertir milliseconds de vuelta a Timestamp
    List<Map<String, dynamic>> processedProducts = [];
    if (data.containsKey('listPoduct') && data['listPoduct'] != null) {
      final productList = data['listPoduct'] as List;
      processedProducts = productList.map((item) {
        Map<String, dynamic> productMap = item is Map<String, dynamic>
            ? Map<String, dynamic>.from(item)
            : Map<String, dynamic>.from(item as Map);

        // Convertir campos de milliseconds de vuelta a Timestamp
        if (productMap['creation'] is int) {
          productMap['creation'] =
              Timestamp.fromMillisecondsSinceEpoch(productMap['creation']);
        }
        if (productMap['upgrade'] is int) {
          productMap['upgrade'] =
              Timestamp.fromMillisecondsSinceEpoch(productMap['upgrade']);
        }
        if (productMap['documentCreation'] is int) {
          productMap['documentCreation'] = Timestamp.fromMillisecondsSinceEpoch(
              productMap['documentCreation']);
        }
        if (productMap['documentUpgrade'] is int) {
          productMap['documentUpgrade'] = Timestamp.fromMillisecondsSinceEpoch(
              productMap['documentUpgrade']);
        }

        return productMap;
      }).toList();
    }

    return TicketModel(
      id: data.containsKey('id') ? data['id'] : '',
      payMode: data.containsKey('payMode') ? data['payMode'] : '',
      sellerName: data.containsKey('sellerName') ? data['sellerName'] : '',
      sellerId: data.containsKey('sellerId') ? data['sellerId'] : '',
      currencySymbol:
          data.containsKey('currencySymbol') ? data['currencySymbol'] : '',
      cashRegisterName:
          data.containsKey('cashRegisterName') ? data['cashRegisterName'] : '',
      cashRegisterId:
          data.containsKey('cashRegisterId') ? data['cashRegisterId'] : '',
      priceTotal: data.containsKey('priceTotal')
          ? (data['priceTotal'] ?? 0).toDouble()
          : 0.0,
      valueReceived: data.containsKey('valueReceived')
          ? (data['valueReceived'] ?? 0).toDouble()
          : 0.0,
      discountIsPercentage: data.containsKey('discountIsPercentage')
          ? (data['discountIsPercentage'] ?? false) as bool
          : false,
      discount: data.containsKey('discount')
          ? (data['discount'] ?? 0.0).toDouble()
          : 0.0,
      transactionType: data.containsKey('transactionType')
          ? data['transactionType'] as String
          : 'sale',
      annulled: data.containsKey('annulled')
          ? (data['annulled'] ?? false) as bool
          : false,
      listPoduct: processedProducts,
      creation: creationTimestamp,
    );
  }
  // copyWith : crea una copia del ticket con modificaciones opcionales
  TicketModel copyWith({
    String? id,
    String? payMode,
    String? currencySymbol,
    String? sellerName,
    String? sellerId,
    String? cashRegisterName,
    String? cashRegisterId,
    double? priceTotal,
    double? valueReceived,
    double? discount,
    bool? discountIsPercentage,
    String? transactionType,
    bool? annulled,
    List<Map<String, dynamic>>? listPoduct,
    Timestamp? creation,
  }) {
    return TicketModel(
      id: id ?? this.id,
      payMode: payMode ?? this.payMode,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      sellerName: sellerName ?? this.sellerName,
      sellerId: sellerId ?? this.sellerId,
      cashRegisterName: cashRegisterName ?? this.cashRegisterName,
      cashRegisterId: cashRegisterId ?? this.cashRegisterId,
      priceTotal: priceTotal ?? this.priceTotal,
      valueReceived: valueReceived ?? this.valueReceived,
      discount: discount ?? this.discount,
      discountIsPercentage: discountIsPercentage ?? this.discountIsPercentage,
      transactionType: transactionType ?? this.transactionType,
      annulled: annulled ?? this.annulled,
      listPoduct: listPoduct ?? _listPoduct,
      creation: creation ?? this.creation,
    );
  }

  /// Factory constructor desde una lista de ProductCatalogue
  factory TicketModel.fromProductCatalogues({
    required List<ProductCatalogue> products,
    String id = "",
    String payMode = "",
    String currencySymbol = "\$",
    String sellerName = "",
    String sellerId = "",
    String cashRegisterName = "",
    String cashRegisterId = "",
    double priceTotal = 0.0,
    double valueReceived = 0.0,
    double discount =
        0.0, // descuento aplicado: valor original ingresado (porcentaje o monto) segun [discountIsPercentage]
    bool discountIsPercentage =
        false, // true si el descuento es porcentual, false si es monto fijo
    String transactionType =
        "sale", // tipo de transacción que representa este ticket
    bool annulled = false,
    Timestamp? creation,
  }) {
    final ticket = TicketModel(
      id: id,
      payMode: payMode,
      currencySymbol: currencySymbol,
      sellerName: sellerName,
      sellerId: sellerId,
      cashRegisterName: cashRegisterName,
      cashRegisterId: cashRegisterId,
      priceTotal: priceTotal,
      valueReceived: valueReceived,
      discount: discount,
      discountIsPercentage: discountIsPercentage,
      transactionType: transactionType,
      annulled: annulled,
      listPoduct: [],
      creation: creation ?? Timestamp.now(),
    );

    // Establecer productos usando el setter
    ticket.products = products;

    // Calcular precio total si no se proporcionó
    if (priceTotal == 0.0) {
      ticket.priceTotal = ticket.calculatedTotal;
    }

    return ticket;
  }
  TicketModel.fromDocumentSnapshot(
      {required DocumentSnapshot documentSnapshot}) {
    Map data = documentSnapshot.data() as Map;
    id = data['id'] ?? '';
    payMode = data['payMode'] ?? '';
    sellerName = data['sellerName'] ?? '';
    sellerId = data['sellerId'] ?? '';
    currencySymbol = data['currencySymbol'] ?? '\$';
    cashRegisterName = data['cashRegister'] ?? '';
    cashRegisterId = data['cashRegisterId'] ?? '';
    priceTotal = data['priceTotal'];
    valueReceived = data['valueReceived'];
    discountIsPercentage = data['discountIsPercentage'] ?? false;
    discount = data['discount'] ?? 0.0;
    transactionType = data['transactionType'] ?? 'sale';
    annulled = data['annulled'] ?? false;
    _listPoduct = data['listPoduct'] != null
        ? List<Map<String, dynamic>>.from((data['listPoduct'] as List).map(
            (item) => item is Map<String, dynamic>
                ? item
                : Map<String, dynamic>.from(item as Map)))
        : [];
    creation = data['creation'];
  }

  // get : obtenemos el porcentaje de ganancia de la venta del ticket
  int get getPercentageProfit {
    // se obtiene el total de la venta de los productos sin descuento
    double total = 0.0;
    double totalWithoutDiscount = getTotalPrice;

    // Usar el getter products que obtiene ProductCatalogue directamente
    for (var product in products) {
      // condition : si el producto tiene un valor de compra y venta se calcula la ganancia
      if (product.purchasePrice != 0) {
        total += (product.salePrice - product.purchasePrice) * product.quantity;
      }
    }

    // si existe un descuento se calcula el porcentaje de ganancia con el descuento aplicado
    if (getDiscountAmount != 0) {
      total -= getDiscountAmount;
    }

    // se calcula el porcentaje de ganancia
    double percentage = 0;
    // condition : si el total de la venta es mayor a 0 y el total de la venta sin descuento es mayor a 0 se calcula el porcentaje
    if (totalWithoutDiscount != 0 &&
        total.isFinite &&
        totalWithoutDiscount.isFinite) {
      percentage = (total * 100) / totalWithoutDiscount;
    }
    // condition : si el porcentaje es menor o igual a 0 o no es finito se retorna 0
    if (percentage <= 0 || !percentage.isFinite) return 0;

    return percentage.toInt();
  }

  /// Obtiene el monto real del descuento aplicado en pesos
  /// Si es porcentual, calcula el monto basado en el porcentaje y total actual
  /// Si es monto fijo, retorna el valor tal como está
  double get getDiscountAmount {
    if (discount <= 0) return 0.0;

    if (discountIsPercentage) {
      // El valor de discount representa el porcentaje, calcular el monto basado en el total actual
      final subtotal = getTotalPriceWithoutDiscount;
      return (subtotal * discount / 100);
    } else {
      // El valor de discount ya es el monto fijo
      return discount;
    }
  }

  // double : obtenemos las ganancias de la venta del ticket
  double get getProfit {
    // se obtiene el total de la venta de los productos sin descuento
    double total = 0.0;

    // Usar el getter products que obtiene ProductCatalogue directamente
    for (var product in products) {
      // condition : si el producto tiene un valor de compra y venta se calcula la ganancia
      if (product.purchasePrice > 0) {
        total += (product.salePrice - product.purchasePrice) * product.quantity;
      }
    }

    // si existe un descuento se calcula el porcentaje de ganancia con el descuento aplicado
    if (getDiscountAmount > 0 && total > 0) {
      if (total - getDiscountAmount < 0) {
        return 0;
      }
      total -= getDiscountAmount;
    }

    return total;
  }

  // get : obtiene el monto total del ticket sin descuento aplicados
  double get getTotalPriceWithoutDiscount {
    // se obtiene el total de la venta de los productos sin descuento
    double total = 0.0;

    // Usar el getter products que obtiene ProductCatalogue directamente
    for (var product in products) {
      total += product.salePrice * product.quantity;
    }
    return total;
  }

  // get : obtiene el monto total del ticket con descuento aplicados
  double get getTotalPrice {
    // se obtiene el total de la venta de los productos con todos los descuentos aplicados al ticket
    double total = 0.0;

    // Usar el getter products que obtiene ProductCatalogue directamente
    for (var product in products) {
      double quantity = product.quantity; // Ahora es double para soportar fraccionarios
      double salePrice = product.salePrice;
      total += salePrice * quantity;
    }

    return total - getDiscountAmount;
  }

  //
  // Fuctions
  //

  // void : incrementa el producto seleccionado del ticket
  void incrementProduct({required ProductCatalogue product}) {
    incrementProductById(product.id);
  }

  /// Incrementa la cantidad de un producto por ID (nuevo método optimizado)
  void incrementProductById(String productId) {
    for (var i = 0; i < _listPoduct.length; i++) {
      if (_listPoduct[i]['id'] == productId) {
        _listPoduct[i]['quantity'] = (_listPoduct[i]['quantity'] ?? 0) + 1;
        return;
      }
    }
  }

  // void : decrementa el producto seleccionado del ticket
  void decrementProduct({required ProductCatalogue product}) {
    decrementProductById(product.id);
  }

  /// Decrementa la cantidad de un producto por ID (nuevo método optimizado)
  void decrementProductById(String productId) {
    for (var i = 0; i < _listPoduct.length; i++) {
      if (_listPoduct[i]['id'] == productId) {
        final currentQuantity = _listPoduct[i]['quantity'] ?? 0;
        if (currentQuantity > 1) {
          _listPoduct[i]['quantity'] = currentQuantity - 1;
        } else {
          // Si la cantidad es 1 o menos, eliminar el producto
          _listPoduct.removeAt(i);
        }
        return;
      }
    }
  }

  // void : elimina el producto seleccionado del ticket
  void removeProduct({required ProductCatalogue product}) {
    removeProductById(product.id);
  }

  // void : agrega un producto al ticket
  void addProduct({required ProductCatalogue product}) {
    addProductFromCatalogue(product);
  }

  // ==========================================
  // MÉTODOS DE CONVENIENCIA CON ProductCatalogue
  // ==========================================

  /// Convierte todos los productos del ticket a ProductCatalogue (para compatibilidad)
  List<ProductCatalogue> getProductsAsCatalogue() {
    // Usar el getter products que ya maneja la conversión correctamente
    return products;
  }

  /// Establece productos desde una lista de ProductCatalogue
  void setProductsFromCatalogue(List<ProductCatalogue> catalogueProducts) {
    products = catalogueProducts;
  }

  /// Busca un producto por código
  ProductCatalogue? findProductByCode(String code) {
    for (var productMap in _listPoduct) {
      if (productMap['code'] == code) {
        return ProductCatalogue.fromMap(productMap);
      }
    }
    return null;
  }

  /// Verifica si existe un producto en el ticket
  bool hasProduct(String productId) {
    return _listPoduct.any((product) => product['id'] == productId);
  }

  /// Obtiene la cantidad de un producto específico
  int getProductQuantity(String productId) {
    for (var product in _listPoduct) {
      if (product['id'] == productId) {
        return product['quantity'] ?? 0;
      }
    }
    return 0;
  }

  /// Limpia todos los productos del ticket
  void clearProducts() {
    _listPoduct.clear();
  }

  /// Obtiene un resumen de los productos como texto
  String getProductsSummary() {
    final productModels = products;
    if (productModels.isEmpty) return 'Sin productos';

    return productModels
        .map((product) => '${product.description} (${product.quantity})')
        .join(', ');
  }

  /// Valida la consistencia de los datos del ticket
  Map<String, dynamic> validateTicket() {
    final issues = <String>[];
    final calculatedPrice = calculatedTotal;

    // Validar estructura interna de productos
    if (!_validateInternalProductStructure()) {
      issues.add('Estructura interna de productos inconsistente');
    }

    // Validar que el precio total coincida con el calculado (solo si no está anulado)
    if (!annulled && (priceTotal - calculatedPrice).abs() > 0.01) {
      issues.add(
          'Precio total inconsistente: $priceTotal vs calculado: $calculatedPrice');
    }

    // Validar que hay productos (solo si no está anulado)
    if (!annulled && _listPoduct.isEmpty) {
      issues.add('El ticket no tiene productos');
    }

    // Validar productos individuales (solo si no está anulado)
    if (!annulled) {
      for (var i = 0; i < _listPoduct.length; i++) {
        final product = _listPoduct[i];
        if (product['quantity'] == null || product['quantity'] <= 0) {
          issues.add('Producto en posición $i tiene cantidad inválida');
        }
        if (product['salePrice'] == null || product['salePrice'] < 0) {
          issues.add('Producto en posición $i tiene precio inválido');
        }
      }
    }

    return {
      'isValid': issues.isEmpty,
      'issues': issues,
      'calculatedTotal': calculatedPrice,
      'reportedTotal': priceTotal,
      'productCount': _listPoduct.length,
      'totalQuantity': totalProductCount,
      'isAnnulled': annulled,
    };
  }

  /// Corrige automáticamente el precio total basado en los productos
  void autoFixPriceTotal() {
    priceTotal = calculatedTotal;
  }
}
