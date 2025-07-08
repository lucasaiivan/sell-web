import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sellweb/domain/entities/catalogue.dart';

class TicketModel {
  String id = '';
  String sellerName = ''; // nombre del vendedor
  String sellerId = ''; // id del vendedor
  String cashRegisterName =
      '1'; // nombre o numero de caja que se efectuo la venta
  String cashRegisterId = ''; // id de la caja que se efectuo la venta
  String payMode =
      ''; // efective (Efectivo) - mercadopago (Mercado Pago) - card (Tarjeta De Crédito/Débito)
  double priceTotal = 0.0; // precio total de la venta
  double valueReceived = 0.0; // valor recibido por la venta
  double discount = 0.0; // descuento aplicado a la venta
  String currencySymbol = '\$';
  List<dynamic> listPoduct = [];
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
    required this.listPoduct,
    required this.creation,
  });
  int getProductsQuantity() {
    int count = 0;
    for (var element in listPoduct) {
      count += element['quantity'] as int;
    }
    return count;
  }

  // format : formateo de texto
  String get getNamePayMode {
    if (payMode == 'effective') return 'Efectivo';
    if (payMode == 'mercadopago') return 'Mercado Pago';
    if (payMode == 'card') return 'Tarjeta De Crédito/Débito';
    return 'Sin Especificar';
  }

  static String getFormatPayMode({required String id}) {
    if (id == 'effective') return 'Efectivo';
    if (id == 'mercadopago') return 'Mercado Pago';
    if (id == 'card') return 'Tarjeta De Crédito/Débito';
    return 'Sin Especificar';
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
        "discount": discount,
        // refactorizamos los valores [Timestamp]  a un [String]
        "listPoduct":
            listPoduct.map((e) => ProductCatalogue.fromMap(e).toMap()).toList(),
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
        "discount": discount,
        // Serializamos las marcas de tiempo de los productos a milisegundos
        "listPoduct": listPoduct.map((e) {
          final ProductCatalogue product = ProductCatalogue.fromMap(e);
          final map = product.toMap();
          if (map.containsKey('creation') && map['creation'] is Timestamp) {
            map['creation'] =
                (map['creation'] as Timestamp).millisecondsSinceEpoch;
          }
          if (map.containsKey('upgrade') && map['upgrade'] is Timestamp) {
            map['upgrade'] =
                (map['upgrade'] as Timestamp).millisecondsSinceEpoch;
          }
          if (map.containsKey('documentCreation') &&
              map['documentCreation'] is Timestamp) {
            map['documentCreation'] =
                (map['documentCreation'] as Timestamp).millisecondsSinceEpoch;
          }
          if (map.containsKey('documentUpgrade') &&
              map['documentUpgrade'] is Timestamp) {
            map['documentUpgrade'] =
                (map['documentUpgrade'] as Timestamp).millisecondsSinceEpoch;
          }
          return map;
        }).toList(),
        // Serializamos creation como int (milisegundos desde época)
        "creation": creation.millisecondsSinceEpoch,
      };

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
      discount: data.containsKey('discount')
          ? (data['discount'] ?? 0.0).toDouble()
          : 0.0,
      listPoduct: data.containsKey('listPoduct') ? data['listPoduct'] : [],
      creation: creationTimestamp,
    );
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
    discount = data['discount'] ?? 0.0;
    listPoduct = data['listPoduct'] ?? [];
    creation = data['creation'];
  }

  // get : obtenemos el porcentaje de ganancia de la venta del ticket
  int get getPercentageProfit {
    // se obtiene el total de la venta de los productos sin descuento
    double total = 0.0;
    double totalWithoutDiscount = getTotalPrice;
    for (var element in listPoduct) {
      // obtenemos el objeto del producto
      ProductCatalogue product = ProductCatalogue.fromMap(element);
      // condition : si el producto tiene un valor de compra y venta se calcula la ganancia
      if (product.purchasePrice != 0) {
        total += (product.salePrice - product.purchasePrice) * product.quantity;
      }
    }

    // si existe un descuento se calcula el porcentaje de ganancia con el descuento aplicado
    if (discount != 0) {
      total -= discount;
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

  // double : obtenemos las ganancias de la venta del ticket
  double get getProfit {
    // se obtiene el total de la venta de los productos sin descuento
    double total = 0.0;
    for (var element in listPoduct) {
      // obtenemos el objeto del producto
      ProductCatalogue product = ProductCatalogue.fromMap(element);
      // condition : si el producto tiene un valor de compra y venta se calcula la ganancia
      if (product.purchasePrice > 0) {
        total += (product.salePrice - product.purchasePrice) * product.quantity;
      }
    }

    // si existe un descuento se calcula el porcentaje de ganancia con el descuento aplicado
    if (discount > 0 && total > 0) {
      if (total - discount < 0) {
        return 0;
      }
      total -= discount;
    }

    return total;
  }

  // get : obtiene el monto total del ticket sin descuento aplicados
  double get getTotalPriceWithoutDiscount {
    // se obtiene el total de la venta de los productos sin descuento
    double total = 0.0;
    for (var element in listPoduct) {
      ProductCatalogue product = ProductCatalogue.fromMap(element);
      total += product.salePrice * product.quantity;
    }
    return total;
  }

  // get : obtiene el monto total del ticket con descuento aplicados
  double get getTotalPrice {
    // se obtiene el total de la venta de los productos con todos los descuentos aplicados al ticket
    double total = 0.0;
    for (var element in listPoduct) {
      ProductCatalogue product = ProductCatalogue.fromMap(element);
      int qauntity = product.quantity;
      double salePrice = product.salePrice;
      total += salePrice * qauntity;
    }

    return total - discount;
  }

  //
  // Fuctions
  //

  // void : incrementa el producto seleccionado del ticket
  void incrementProduct({required ProductCatalogue product}) {
    // se verifica la coincidencia del producto en la lista de productos del ticket
    for (var i = 0; i < listPoduct.length; i++) {
      if (listPoduct[i]['id'] == product.id) {
        listPoduct[i]['quantity']++;
        return;
      }
    }
  }

  // void : decrementa el producto seleccionado del ticket
  void decrementProduct({required ProductCatalogue product}) {
    // se verifica la coincidencia del producto en la lista de productos del ticket
    for (var i = 0; i < listPoduct.length; i++) {
      if (listPoduct[i]['id'] == product.id) {
        // condition : si la cantidad del producto es mayor a 1 se decrementa
        if (listPoduct[i]['quantity'] > 1) {
          listPoduct[i]['quantity'] = listPoduct[i]['quantity'] - 1;
        }
        return;
      }
    }
  }

  // void : elimina el producto seleccionado del ticket
  void removeProduct({required ProductCatalogue product}) {
    // se verifica la coincidencia del producto en la lista de productos del ticket
    for (var i = 0; i < listPoduct.length; i++) {
      if (listPoduct[i]['id'] == product.id) {
        listPoduct.removeAt(i);
        return;
      }
    }
  }

  // void : agrega un producto al ticket
  void addProduct({required ProductCatalogue product}) {
    // normalizar la cantidad cuantificada del producto
    if (product.quantity != 1) product.quantity = 1;
    // se verifica si el producto ya esta en el ticket
    bool exist = false;
    for (var i = 0; i < listPoduct.length; i++) {
      if (listPoduct[i]['id'] == product.id) {
        listPoduct[i]['quantity']++;
        exist = true;
        break;
      }
    }
    // si el producto no esta en el ticket se agrega
    if (!exist) {
      listPoduct.add(product.toMap());
    }
  }
}
