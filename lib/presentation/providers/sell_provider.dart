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
  // Elimina la lista de productos seleccionados, ahora se usa TicketModel
  bool _ticketView = false; // si mostramos vista de ticket o no
  bool get ticketView => _ticketView; 
  ProfileAccountModel selectedAccount = ProfileAccountModel();
  // keys para SharedPreferences
  static const String _selectedAccountKey = 'selected_account_id';
  static const String _ticketKey = 'current_ticket';

  // Ticket actual en memoria
  TicketModel _ticket = TicketModel(listPoduct: [], creation: Timestamp.now());

  final GetUserAccountsUseCase getUserAccountsUseCase;

  /// Carga la cuenta seleccionada desde SharedPreferences al inicializar el provider.
  Future<void> _loadSelectedAccount() async {

    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_selectedAccountKey);
    if (id != null && id.isNotEmpty) {
      selectedAccount = await fetchAccountById(id) ?? ProfileAccountModel();
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

  Future<void> _removeSelectedAccount() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_selectedAccountKey);
  }

  Future<void> selectAccount({required ProfileAccountModel account, required BuildContext context}) async {
    selectedAccount = account.copyWith(); 
    _ticketView = false; // Ocultar la vista de ticket

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

   /// Quita la cuenta seleccionada y notifica a los listeners.
  Future<void> removeSelectedAccount() async {
    selectedAccount = ProfileAccountModel();
    await _removeSelectedAccount();
    notifyListeners();
  }
}
