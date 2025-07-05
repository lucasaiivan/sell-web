import 'dart:convert'; 
import 'package:flutter/material.dart';
import 'package:sellweb/core/utils/fuctions.dart';
import 'package:sellweb/core/utils/shared_prefs_keys.dart';
import 'package:sellweb/domain/entities/catalogue.dart';
import 'package:sellweb/domain/entities/user.dart'; 
import 'package:sellweb/domain/entities/ticket_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sellweb/domain/usecases/account_usecase.dart';

class SellProvider extends ChangeNotifier {

  // Caso de uso para obtener las cuentas del usuario
  final GetUserAccountsUseCase getUserAccountsUseCase;
 
  // Indica si se debe mostrar la vista del ticket
  bool _ticketView = false; // Indica si se debe mostrar la vista del ticket
  bool get ticketView => _ticketView; 
  
  // Indica si se debe imprimir el ticket al confirmar la venta
  bool _shouldPrintTicket = false;
  bool get shouldPrintTicket => _shouldPrintTicket; 
  // Cuenta seleccionada actualmente
  ProfileAccountModel profileAccountSelected = ProfileAccountModel();
  
  // Ticket actual en memoria
  TicketModel _ticket = TicketModel(listPoduct: [], creation: Timestamp.now());
  TicketModel get ticket => _ticket;
  set ticket(TicketModel value) {
    _ticket = value;
    notifyListeners();
  }
  

  // clean data : limpieza de datos cada vez que cambiar de cuenta o cierrar sesión
  void cleanData() {
    profileAccountSelected = ProfileAccountModel();
    ticket = TicketModel(listPoduct: [], creation: Timestamp.now()); 
    _ticketView = false;
    _shouldPrintTicket = false;
    _saveTicket();  
  }

  /// Carga la cuenta seleccionada desde SharedPreferences al inicializar el provider.
  Future<void> _loadSelectedAccount() async {
    // shared preferences : Cargar la cuenta seleccionada desde SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(SharedPrefsKeys.selectedAccountId);
    // Si hay un ID de cuenta guardado, intenta cargar la cuenta
    if (id != null && id.isNotEmpty) { 
      profileAccountSelected = await fetchAccountById(id) ?? ProfileAccountModel();
      notifyListeners();
    }
  }

  SellProvider({required this.getUserAccountsUseCase}) {
    _loadSelectedAccount().whenComplete(() => _loadTicket());
  }

  /// Obtiene los datos completos de la cuenta por su [id].
  Future<ProfileAccountModel?> fetchAccountById(String id) async {
    try {
      return await getUserAccountsUseCase.getAccount(idAccount: id);
    } catch (_) {
      return null;
    }
  }

  /// Guarda el ticket actual en SharedPreferences.
  Future<void> _saveTicket() async { 
    final prefs = await SharedPreferences.getInstance(); 
    await prefs.setString(SharedPrefsKeys.currentTicket, jsonEncode(ticket.toJson()));
  }

  /// Carga el ticket guardado desde SharedPreferences.
  Future<void> _loadTicket() async {

    final prefs = await SharedPreferences.getInstance();
    final ticketJson = prefs.getString(SharedPrefsKeys.currentTicket);
    if (ticketJson != null ) { 
      try {
        ticket = TicketModel.sahredPreferencefromMap(_decodeJson(ticketJson));
        notifyListeners();
      } catch (_) {}
    } 
  }

 
  /// Utilidad para decodificar de JSON.
  Map<String, dynamic> _decodeJson(String source) => const JsonDecoder().convert(source) as Map<String, dynamic>;

  /// Agrega un producto al ticket actual.
  void addProductsticket(ProductCatalogue product, {bool replaceQuantity = false}) {
    // Si el producto ya existe y replaceQuantity es true, actualiza la cantidad
    bool exist = false;
    for (var i = 0; i < ticket.listPoduct.length; i++) {
      if (ticket.listPoduct[i]['id'] == product.id) {
        if (replaceQuantity) {
          ticket.listPoduct[i]['quantity'] = product.quantity;
        } else {
          ticket.listPoduct[i]['quantity'] += (product.quantity > 0 ? product.quantity : 1);
        }
        exist = true;
        break;
      }
    }
    if (!exist) {
      ticket.listPoduct.add(product.toMap());
    }
    _saveTicket();
    notifyListeners();
  }

  void removeProduct(ProductCatalogue product) {
    ticket.listPoduct.removeWhere((item) => item['id'] == product.id);
    if (ticket.listPoduct.isEmpty) {
      _ticketView = false;
    }
    _saveTicket();
    notifyListeners();
  }

  void setTicketView(bool value) {
    _ticketView = value;
    notifyListeners();
  }

  void discartTicket() {
    ticket = TicketModel(listPoduct: [], creation: Timestamp.now()); 
    _ticketView = false;
    _shouldPrintTicket = false;
    _saveTicket();
    notifyListeners();
  }

  void addQuickProduct({required String description, required double salePrice}) {
    var id = Publications.generateUid();
    var product = ProductCatalogue(
      id: id,
      description: description,
      salePrice: salePrice, 
    );
    addProductsticket(product, replaceQuantity: true);
    notifyListeners();
  }
 

  Future<void> _saveSelectedAccount(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(SharedPrefsKeys.selectedAccountId, id);
  }
 
  /// Selecciona una cuenta (negocio) y actualiza el catálogo.
  Future<void> initAccount({required ProfileAccountModel account, required BuildContext context}) async {
    cleanData(); // Limpiar datos del ticket y productos
    profileAccountSelected = account.copyWith();  // Asignamos los valores de la cuenta seleccionada

    // Guarda la cuenta seleccionada y espera a que termine
    await _saveSelectedAccount(profileAccountSelected.id);
    
    // Notifica solo una vez al final
    notifyListeners();
  }

   /// Quita la cuenta (negocio) seleccionada y notifica a los listeners.
  Future<void> removeSelectedAccount() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(SharedPrefsKeys.selectedAccountId);
    cleanData();
    notifyListeners();
  }

  /// Actualiza el método de pago del ticket y notifica a los listeners.
  void setPayMode({String payMode = 'effective'}) {
    ticket.payMode = payMode;
    // Si el método de pago NO es efectivo, restaurar el monto recibido a 0
    if (payMode != 'effective') {
      ticket.valueReceived = 0.0;
    }
    _saveTicket();
    notifyListeners();
  }

  /// Asigna el monto recibido en efectivo por el cliente para calcular el vuelto.
  void addIncomeCash({double value = 0.0}) {
    ticket.valueReceived = value;
    _saveTicket();
    notifyListeners();
  }

  /// Actualiza el valor recibido en efectivo para el ticket actual.
  void setReceivedCash(double value) {
    ticket.valueReceived = value;
    _saveTicket();
    notifyListeners();
  }

  /// Establece si se debe imprimir el ticket al confirmar la venta.
  void setShouldPrintTicket(bool value) {
    _shouldPrintTicket = value;
    notifyListeners();
  }
}
