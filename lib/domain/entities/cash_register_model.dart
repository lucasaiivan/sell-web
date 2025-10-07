import 'package:cloud_firestore/cloud_firestore.dart';

class CashRegister {
  String id; // id de la caja
  String description; // descripción de la caja
  DateTime opening; // fecha de apertura
  DateTime closure; // fecha de cierre
  double initialCash; // monto inicial
  int sales; // cantidad de ventas
  int annulledTickets; // cantidad de tickets anulados
  double billing; // monto de facturación
  double discount; // monto de descuento
  double cashInFlow; // monto de ingresos
  double cashOutFlow; // monto de egresos (numero negativo)
  double expectedBalance; // monto esperado
  double balance; // monto de cierre
  List<dynamic> cashInFlowList; // lista de ingresos de caja [CashFlow]
  List<dynamic> cashOutFlowList; // lista de egresos de caja [CashFlow]

  CashRegister({
    required this.id,
    required this.description,
    required this.initialCash,
    required this.opening,
    required this.closure,
    required this.sales,
    required this.annulledTickets,
    required this.billing,
    required this.discount,
    required this.cashInFlow,
    required this.cashOutFlow,
    required this.expectedBalance,
    required this.balance,
    required this.cashInFlowList,
    required this.cashOutFlowList,
  });

  // contructor

  // difference : devuelve la diferencia entre el monto esperado y el monto de cierre
  double get getDifference {
    if (balance == 0) {
      return 0.0;
    }
    return balance - getExpectedBalance;
  }

  // balance : devuelve el balance esperado de la caja
  double get getExpectedBalance {
    return (initialCash + cashInFlow + billing) + cashOutFlow;
  }

  // default values
  factory CashRegister.initialData() {
    return CashRegister(
      id: '',
      description: '',
      initialCash: 0.0,
      opening: DateTime.now(),
      closure: DateTime.now(),
      sales: 0,
      annulledTickets: 0,
      billing: 0.0,
      discount: 0.0,
      cashInFlow: 0.0,
      cashOutFlow: 0.0,
      expectedBalance: 0.0,
      balance: 0.0,
      cashInFlowList: [],
      cashOutFlowList: [],
    );
  }
  // tojson : convierte el objeto a json
  Map<String, dynamic> toJson() => {
        "id": id,
        "description": description,
        "initialCash": initialCash,
        "opening": opening,
        "closure": closure,
        "sales": sales,
        "annulledTickets": annulledTickets,
        "billing": billing,
        "discount": discount,
        "cashInFlow": cashInFlow,
        "cashOutFlow": cashOutFlow,
        "expectedBalance": expectedBalance,
        "balance": balance,
        "cashInFlowList": cashInFlowList,
        "cashOutFlowList": cashOutFlowList,
      };

  // fromjson : convierte el json en un objeto
  factory CashRegister.fromMap(Map data) {
    return CashRegister(
      id: data['id'],
      description: data.containsKey('description') ? data['description'] : '',
      initialCash: data.containsKey('initialCash')
          ? double.parse(data['initialCash'].toString())
          : 0.0,
      opening: data.containsKey('opening')
          ? data['opening'].toDate()
          : DateTime.now(),
      closure: data.containsKey('closure')
          ? data['closure'].toDate()
          : DateTime.now(),
      sales: data.containsKey('sales') ? data['sales'] ?? 0 : 0,
      annulledTickets: data.containsKey('annulledTickets') ? data['annulledTickets'] ?? 0 : 0,
      billing: data.containsKey('billing')
          ? double.parse(data['billing'].toString())
          : 0.0,
      discount: data.containsKey('discount')
          ? double.parse(data['discount'].toString())
          : 0.0,
      cashInFlow: data.containsKey('cashInFlow')
          ? double.parse(data['cashInFlow'].toString())
          : 0.0,
      cashOutFlow: data.containsKey('cashOutFlow')
          ? double.parse(data['cashOutFlow'].toString())
          : 0.0,
      expectedBalance: data.containsKey('expectedBalance')
          ? double.parse(data['expectedBalance'].toString())
          : 0.0,
      balance: data.containsKey('balance')
          ? double.parse(data['balance'].toString())
          : 0.0,
      cashInFlowList: data.containsKey('cashInFlowList')
          ? data['cashInFlowList'] ?? []
          : [],
      cashOutFlowList: data.containsKey('cashOutFlowList')
          ? data['cashOutFlowList'] ?? []
          : [],
    );
  }

  fromDocumentSnapshot({required DocumentSnapshot documentSnapshot}) {
    id = documentSnapshot.id;
    description = documentSnapshot['description'];
    initialCash = documentSnapshot['initialCash'].toDouble();
    opening = documentSnapshot['opening'].toDate();
    closure = documentSnapshot['closure'].toDate();
    billing = documentSnapshot['billing'].toDouble();
    discount = documentSnapshot['discount'].toDouble();
    sales = documentSnapshot['sales'];
    annulledTickets = documentSnapshot.data().toString().contains('annulledTickets') ? documentSnapshot['annulledTickets'] : 0;
    cashInFlow = documentSnapshot['cashInFlow'].toDouble();
    cashOutFlow = documentSnapshot['cashOutFlow'].toDouble();
    expectedBalance = documentSnapshot['expectedBalance'].toDouble();
    balance = documentSnapshot['balance'].toDouble();
    cashInFlowList = documentSnapshot['cashInFlowList'];
    cashOutFlowList = documentSnapshot['cashOutFlowList'];
  }

  // update : actualiza los valores individualmente de la caja
  CashRegister update({
    String? id,
    String? description,
    double? initialCash,
    DateTime? opening,
    DateTime? closure,
    int? sales,
    int? annulledTickets,
    double? billing,
    double? discount,
    double? cashInFlow,
    double? cashOutFlow,
    double? expectedBalance,
    double? balance,
    List<dynamic>? cashInFlowList, // lista de ingresos de caja [CashFlow]
    List<dynamic>? cashOutFlowList, // lista de egresos de caja [CashFlow]
  }) {
    return CashRegister(
      id: id ?? this.id,
      description: description ?? this.description,
      initialCash: initialCash ?? this.initialCash,
      opening: opening ?? this.opening,
      closure: closure ?? this.closure,
      sales: sales ?? this.sales,
      annulledTickets: annulledTickets ?? this.annulledTickets,
      billing: billing ?? this.billing,
      discount: discount ?? this.discount,
      cashInFlow: cashInFlow ?? this.cashInFlow,
      cashOutFlow: cashOutFlow ?? this.cashOutFlow,
      expectedBalance: expectedBalance ?? this.expectedBalance,
      balance: balance ?? this.balance,
      cashInFlowList: cashInFlowList ?? this.cashInFlowList,
      cashOutFlowList: cashOutFlowList ?? this.cashOutFlowList,
    );
  }
}

// CashFlow : Representa el flujo de caja de 'ingresos' y 'egresos'
class CashFlow {
  String id = ''; // id del flujo de caja
  String userId = ''; // id del usuario que realiza el flujo de caja
  String description = '';
  double amount = 0.0; // monto del flujo de caja
  DateTime date = DateTime.now(); // marca de tiempo

  CashFlow({
    required this.id,
    required this.userId,
    required this.description,
    required this.amount,
    required this.date,
  });

  // default values
  factory CashFlow.initialData() {
    return CashFlow(
      id: '',
      userId: '',
      description: '',
      amount: 0.0,
      date: DateTime.now(),
    );
  }
  // tojson : convierte el objeto a json
  Map<String, dynamic> toJson() => {
        "id": id,
        "userId": userId,
        "description": description,
        "amount": amount,
        "date": date,
      };
  // fromjson : convierte el json en un objeto
  factory CashFlow.fromMap(Map<dynamic, dynamic> data) {
    return CashFlow(
      id: data['id'] ?? '',
      userId: data['userId'] ?? '',
      description: data['description'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      date: data['date'].toDate(),
    );
  }
}
