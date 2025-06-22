import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as provider_package;
import 'package:sellweb/core/utils/fuctions.dart';
import 'package:sellweb/domain/entities/catalogue.dart';
import 'package:sellweb/domain/entities/user.dart'; 
import 'package:sellweb/domain/entities/ticket_model.dart';
import 'package:sellweb/presentation/providers/catalogue_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sellweb/domain/usecases/account_usecase.dart';

class SellProvider extends ChangeNotifier {
  
  bool _ticketView = false; // Indica si se debe mostrar la vista del ticket
  bool get ticketView => _ticketView; 
  ProfileAccountModel profileAccountSelected = ProfileAccountModel();
  // keys para SharedPreferences
  static const String _selectedAccountKey = 'selected_account_id';
  static const String _ticketKey = 'current_ticket';

  // Ticket actual en memoria
  TicketModel _ticket = TicketModel(listPoduct: [], creation: Timestamp.now());

  final GetUserAccountsUseCase getUserAccountsUseCase;

  // clean data : limpieza de datos cada vez que cambiar de cuenta o cierrar sesión
  void cleanData() {
    profileAccountSelected = ProfileAccountModel();
    _ticket = TicketModel(listPoduct: [], creation: Timestamp.now()); 
    _ticketView = false;  
    _saveTicket();  
  }

  /// Carga la cuenta seleccionada desde SharedPreferences al inicializar el provider.
  Future<void> _loadSelectedAccount() async {

    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_selectedAccountKey);
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
    await prefs.setString(_ticketKey, jsonEncode(_ticket.toJson()));
  }

  /// Carga el ticket guardado desde SharedPreferences.
  Future<void> _loadTicket() async {

    final prefs = await SharedPreferences.getInstance();
    final ticketJson = prefs.getString(_ticketKey);
    if (ticketJson != null ) { 
      try {
        _ticket = TicketModel.fromMap(_decodeJson(ticketJson));
        notifyListeners();
      } catch (_) {}
    } 
  }

 
 

  /// Utilidad para decodificar de JSON.
  Map<String, dynamic> _decodeJson(String source) =>
      const JsonDecoder().convert(source) as Map<String, dynamic>;

  /// Agrega un producto al ticket actual.
  void addProduct(ProductCatalogue product, {bool replaceQuantity = false}) {
    // Si el producto ya existe y replaceQuantity es true, actualiza la cantidad
    bool exist = false;
    for (var i = 0; i < _ticket.listPoduct.length; i++) {
      if (_ticket.listPoduct[i]['id'] == product.id) {
        if (replaceQuantity) {
          _ticket.listPoduct[i]['quantity'] = product.quantity;
        } else {
          _ticket.listPoduct[i]['quantity'] += (product.quantity > 0 ? product.quantity : 1);
        }
        exist = true;
        break;
      }
    }
    if (!exist) {
      _ticket.listPoduct.add(product.toMap());
    }
    _saveTicket();
    notifyListeners();
  }

  void removeProduct(ProductCatalogue product) {
    _ticket.listPoduct.removeWhere((item) => item['id'] == product.id);
    if (_ticket.listPoduct.isEmpty) {
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
    _ticket.listPoduct.clear();
    _ticketView = false;
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
    addProduct(product, replaceQuantity: true);
    notifyListeners();
  }

  /// Devuelve el ticket actual
  TicketModel get getTicket => _ticket;

  Future<void> _saveSelectedAccount(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectedAccountKey, id);
  }
 

  Future<void> selectAccount({required ProfileAccountModel account, required BuildContext context}) async {

    cleanData(); // Limpiar datos del ticket y productos
    profileAccountSelected = account.copyWith();  // asignamos los valores de la cuenta seleccionada 

    // Accede al provider antes de cualquier await
    CatalogueProvider? catalogueProvider;
    try {
      catalogueProvider = provider_package.Provider.of<CatalogueProvider>(context, listen: false);
    } catch (e) {
      print('[SellProvider] Error al obtener el CatalogueProvider: $e');
    }
    // Guarda la cuenta seleccionada
    await _saveSelectedAccount(account.id);

    // Inicializa el catálogo si se pudo obtener el provider
    if (catalogueProvider != null) {
      catalogueProvider.initCatalogue(account.id); 
    }

    notifyListeners();
  }

   /// Quita la cuenta (negocio) seleccionada y notifica a los listeners.
  Future<void> removeSelectedAccount() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_selectedAccountKey);
    cleanData();
    notifyListeners();
  }

  /// Actualiza el método de pago del ticket y notifica a los listeners.
  void setPayMode({String payMode = 'effective'}) {
    _ticket.payMode = payMode;
    // Si el método de pago NO es efectivo, restaurar el monto recibido a 0
    if (payMode != 'effective') {
      _ticket.valueReceived = 0.0;
    }
    _saveTicket();
    notifyListeners();
  }

  /// Asigna el monto recibido en efectivo por el cliente para calcular el vuelto.
  void addIncomeCash({double value = 0.0}) {
    _ticket.valueReceived = value;
    _saveTicket();
    notifyListeners();
  }

  /// Actualiza el valor recibido en efectivo para el ticket actual.
  void setReceivedCash(double value) {
    _ticket.valueReceived = value;
    _saveTicket();
    notifyListeners();
  }
}
