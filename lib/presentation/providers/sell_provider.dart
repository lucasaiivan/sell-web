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
import 'package:provider/provider.dart' as provider;
import '../providers/cash_register_provider.dart';

class _SellProviderState {
  final bool ticketView;
  final bool shouldPrintTicket;
  final ProfileAccountModel profileAccountSelected;
  final TicketModel ticket;
  final TicketModel? lastSoldTicket;

  const _SellProviderState({
    required this.ticketView,
    required this.shouldPrintTicket,
    required this.profileAccountSelected,
    required this.ticket,
    required this.lastSoldTicket,
  });

  _SellProviderState copyWith({
    bool? ticketView,
    bool? shouldPrintTicket,
    ProfileAccountModel? profileAccountSelected,
    TicketModel? ticket,
    Object? lastSoldTicket = const Object(),
  }) {
    return _SellProviderState(
      ticketView: ticketView ?? this.ticketView,
      shouldPrintTicket: shouldPrintTicket ?? this.shouldPrintTicket,
      profileAccountSelected:
          profileAccountSelected ?? this.profileAccountSelected,
      ticket: ticket ?? this.ticket,
      lastSoldTicket: lastSoldTicket == const Object()
          ? this.lastSoldTicket
          : lastSoldTicket as TicketModel?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _SellProviderState &&
          runtimeType == other.runtimeType &&
          ticketView == other.ticketView &&
          shouldPrintTicket == other.shouldPrintTicket &&
          profileAccountSelected == other.profileAccountSelected &&
          ticket == other.ticket &&
          lastSoldTicket == other.lastSoldTicket;

  @override
  int get hashCode =>
      ticketView.hashCode ^
      shouldPrintTicket.hashCode ^
      profileAccountSelected.hashCode ^
      ticket.hashCode ^
      lastSoldTicket.hashCode;
}

class SellProvider extends ChangeNotifier {
  final GetUserAccountsUseCase getUserAccountsUseCase;

  // Estado encapsulado para optimizar notificaciones
  var _state = _SellProviderState(
    ticketView: false,
    shouldPrintTicket: false,
    profileAccountSelected: ProfileAccountModel(),
    ticket: _createEmptyTicketStatic(),
    lastSoldTicket: null,
  );
  
  /// Crea un ticket vacío usando la API encapsulada (método estático)
  static TicketModel _createEmptyTicketStatic() {
    return TicketModel(
      listPoduct: [],
      creation: Timestamp.now(),
    );
  }
  
  /// Crea un nuevo ticket preservando valores específicos pero con productos vacíos
  TicketModel _createTicketWithValues({
    required Timestamp creation,
    String payMode = '',
    double valueReceived = 0.0,
    String cashRegisterName = '',
    String cashRegisterId = '',
    String sellerName = '',
    String sellerId = '',
    double priceTotal = 0.0,
    double discount = 0.0,
    String transactionType = 'sale',
    String currencySymbol = '\$',
  }) {
    return TicketModel(
      listPoduct: [],
      creation: creation,
      payMode: payMode,
      valueReceived: valueReceived,
      cashRegisterName: cashRegisterName,
      cashRegisterId: cashRegisterId,
      sellerName: sellerName,
      sellerId: sellerId,
      priceTotal: priceTotal,
      discount: discount,
      transactionType: transactionType,
      currencySymbol: currencySymbol,
    );
  }

  // Getters que no causan rebuild
  bool get ticketView => _state.ticketView;
  bool get shouldPrintTicket => _state.shouldPrintTicket;
  ProfileAccountModel get profileAccountSelected =>
      _state.profileAccountSelected;
  TicketModel get ticket => _state.ticket;
  TicketModel? get lastSoldTicket => _state.lastSoldTicket;

  SellProvider({required this.getUserAccountsUseCase}) {
    _loadInitialState();
  }

  Future<void> _loadInitialState() async {
    await Future.wait([
      _loadSelectedAccount(),
      _loadTicket(),
      _loadLastSoldTicket(),
      _loadShouldPrintTicket(),
    ]);
  }

  void cleanData() {
    _state = _state.copyWith(
      profileAccountSelected: ProfileAccountModel(),
      ticket: _createEmptyTicketStatic(),
      ticketView: false,
      shouldPrintTicket: false,
      lastSoldTicket: null,
    );
    _saveAllState();
    notifyListeners();
  }

  // Métodos optimizados para minimizar notificaciones
  Future<void> initAccount({
    required ProfileAccountModel account,
    required BuildContext context,
  }) async {
    cleanData();
    _state = _state.copyWith(profileAccountSelected: account.copyWith());
    await _saveSelectedAccount(account.id);
    notifyListeners();
  }

  void setTicketView(bool value) {
    if (_state.ticketView != value) {
      _state = _state.copyWith(ticketView: value);
      notifyListeners();
    }
  }

  void setShouldPrintTicket(bool value) {
    if (_state.shouldPrintTicket != value) {
      _state = _state.copyWith(shouldPrintTicket: value);
      _saveShouldPrintTicket();
      notifyListeners();
    }
  }

  // Métodos para guardar estado
  Future<void> _saveAllState() async {
    await Future.wait([
      _saveTicket(),
      _saveLastSoldTicket(),
      _saveShouldPrintTicket(),
    ]);
  }

  /// Carga la cuenta seleccionada desde SharedPreferences al inicializar el provider.
  Future<void> _loadSelectedAccount() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(SharedPrefsKeys.selectedAccountId);
    if (id != null && id.isNotEmpty) {
      final account = await fetchAccountById(id);
      if (account != null) {
        _state = _state.copyWith(profileAccountSelected: account);
        notifyListeners();
      }
    }
  }

  Future<ProfileAccountModel?> fetchAccountById(String id) async {
    try {
      return await getUserAccountsUseCase.getAccount(idAccount: id);
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveTicket() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString( SharedPrefsKeys.currentTicket, jsonEncode(_state.ticket.toJson()));
  }

  Future<void> _loadTicket() async {
    final prefs = await SharedPreferences.getInstance();
    final ticketJson = prefs.getString(SharedPrefsKeys.currentTicket);
    if (ticketJson != null) {
      try {
        final newTicket =
            TicketModel.sahredPreferencefromMap(_decodeJson(ticketJson));
        _state = _state.copyWith(ticket: newTicket);
        notifyListeners();
      } catch (_) {}
    }
  }

  Map<String, dynamic> _decodeJson(String source) => const JsonDecoder().convert(source) as Map<String, dynamic>;

  void addProductsticket(ProductCatalogue product,{bool replaceQuantity = false}) {
    // Agrega un producto al ticket actual, reemplazando la cantidad si es necesario

    // var
    final currentTicket = _state.ticket;
    bool exist = false;
    final List<ProductCatalogue> updatedProducts = List.from(currentTicket.products);

    for (var i = 0; i < updatedProducts.length; i++) {
      if (updatedProducts[i].id == product.id) {
        if (replaceQuantity) {
          updatedProducts[i].quantity = product.quantity;
        } else {
          updatedProducts[i].quantity +=
              (product.quantity > 0 ? product.quantity : 1);
        }
        exist = true;
        break;
      }
    }

    if (!exist) {
      // Si el producto no existe, lo agrega con la cantidad especificada
      updatedProducts.add(product.copyWith(quantity: product.quantity > 0 ? product.quantity : 1));
    }

    // Crea un nuevo ticket con los productos actualizados
    final newTicket = _createTicketWithValues(
      creation: currentTicket.creation,
      payMode: currentTicket.payMode,
      valueReceived: currentTicket.valueReceived,
      cashRegisterName: currentTicket.cashRegisterName,
      cashRegisterId: currentTicket.cashRegisterId,
      sellerName: currentTicket.sellerName,
      sellerId: currentTicket.sellerId,
      priceTotal: currentTicket.priceTotal,
      discount: currentTicket.discount,
      transactionType: currentTicket.transactionType,
      currencySymbol: currentTicket.currencySymbol,
    );
    
    // Establecer los productos usando el setter que maneja la conversión
    newTicket.products = updatedProducts;
    // Actualiza el estado del provider con el nuevo ticket
    _state = _state.copyWith(ticket: newTicket);
    _saveTicket();
    notifyListeners();
  }

  void removeProduct(ProductCatalogue product) {
    // Elimina un producto del ticket actual

    // var 
    final currentTicket = _state.ticket;
    final updatedProducts = currentTicket.products.where((item) => item.id != product.id).toList();

    final newTicket = _createTicketWithValues(
      creation: currentTicket.creation,
      payMode: currentTicket.payMode,
      valueReceived: currentTicket.valueReceived,
      cashRegisterName: currentTicket.cashRegisterName,
      cashRegisterId: currentTicket.cashRegisterId,
      sellerName: currentTicket.sellerName,
      sellerId: currentTicket.sellerId,
      priceTotal: currentTicket.priceTotal,
      discount: currentTicket.discount,
      transactionType: currentTicket.transactionType,
      currencySymbol: currentTicket.currencySymbol,
    );
    
    // Establecer los productos usando el setter que maneja la conversión
    newTicket.products = updatedProducts;

    _state = _state.copyWith(
      ticket: newTicket,
      ticketView: updatedProducts.isNotEmpty,
    );
    _saveTicket();
    notifyListeners();
  }

  void discartTicket() {
    _state = _state.copyWith(
      ticket: _createEmptyTicketStatic(),
      ticketView: false,
    );
    _saveTicket();
    notifyListeners();
  }

  void addQuickProduct(
      {required String description, required double salePrice}) {
    final product = ProductCatalogue(
      id: Publications.generateUid(),
      description: description,
      salePrice: salePrice,
    );
    addProductsticket(product, replaceQuantity: true);
  }

  Future<void> _saveSelectedAccount(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(SharedPrefsKeys.selectedAccountId, id);
  }

  void setPayMode({String payMode = 'effective'}) {
    final currentTicket = _state.ticket;
    final newTicket = _createTicketWithValues(
      creation: currentTicket.creation,
      payMode: payMode,
      valueReceived: payMode != 'effective' ? 0.0 : currentTicket.valueReceived,
      cashRegisterName: currentTicket.cashRegisterName,
      cashRegisterId: currentTicket.cashRegisterId,
      sellerName: currentTicket.sellerName,
      sellerId: currentTicket.sellerId,
      priceTotal: currentTicket.priceTotal,
      discount: currentTicket.discount,
      transactionType: currentTicket.transactionType,
      currencySymbol: currentTicket.currencySymbol,
    );
    
    // Establecer los productos usando el setter
    newTicket.products = currentTicket.products;

    _state = _state.copyWith(ticket: newTicket);
    _saveTicket();
    notifyListeners();
  }

  void setReceivedCash(double value) {
    // Actualiza el valor recibido en el ticket
    final currentTicket = _state.ticket;
    final newTicket = _createTicketWithValues(
      creation: currentTicket.creation,
      payMode: currentTicket.payMode,
      valueReceived: value,
      cashRegisterName: currentTicket.cashRegisterName,
      cashRegisterId: currentTicket.cashRegisterId,
      sellerName: currentTicket.sellerName,
      sellerId: currentTicket.sellerId,
      priceTotal: currentTicket.priceTotal,
      discount: currentTicket.discount,
      transactionType: currentTicket.transactionType,
      currencySymbol: currentTicket.currencySymbol,
    );
    
    // Establecer los productos usando el setter
    newTicket.products = currentTicket.products;

    _state = _state.copyWith(ticket: newTicket);
    _saveTicket();
    notifyListeners();
  }

  void addIncomeCash({double value = 0.0}) {
    setReceivedCash(value);
  }

  Future<void> _loadShouldPrintTicket() async {
    // Carga el estado de impresión del ticket desde SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final shouldPrint =
        prefs.getBool(SharedPrefsKeys.shouldPrintTicket) ?? false;
    _state = _state.copyWith(shouldPrintTicket: shouldPrint);
    notifyListeners();
  }

  Future<void> _saveShouldPrintTicket() async {
    // Guarda el estado de impresión del ticket en SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(
        SharedPrefsKeys.shouldPrintTicket, _state.shouldPrintTicket);
  }

  Future<void> saveLastSoldTicket() async {
    // Guarda el último ticket vendido en SharedPreferences
    final currentTicket = _state.ticket;
    final newLastSoldTicket = _createTicketWithValues(
      creation: currentTicket.creation,
      payMode: currentTicket.payMode,
      valueReceived: currentTicket.valueReceived,
      cashRegisterName: currentTicket.cashRegisterName,
      cashRegisterId: currentTicket.cashRegisterId,
      sellerName: currentTicket.sellerName,
      sellerId: currentTicket.sellerId,
      priceTotal: currentTicket.priceTotal,
      discount: currentTicket.discount,
      transactionType: currentTicket.transactionType,
      currencySymbol: currentTicket.currencySymbol,
    );
    
    // Establecer los productos usando el setter
    newLastSoldTicket.products = List.from(currentTicket.products);

    _state = _state.copyWith(lastSoldTicket: newLastSoldTicket);
    await _saveLastSoldTicket();
    notifyListeners();
  }

  Future<void> _saveLastSoldTicket() async {
    final prefs = await SharedPreferences.getInstance();
    final lastTicket = _state.lastSoldTicket;
    if (lastTicket != null) {
      await prefs.setString( SharedPrefsKeys.lastSoldTicket, jsonEncode(lastTicket.toJson()));
    } else {
      await prefs.remove(SharedPrefsKeys.lastSoldTicket);
    }
  }

  Future<void> _loadLastSoldTicket() async {
    final prefs = await SharedPreferences.getInstance();
    final lastTicketJson = prefs.getString(SharedPrefsKeys.lastSoldTicket);
    if (lastTicketJson != null) {
      try {
        final lastTicket =
            TicketModel.sahredPreferencefromMap(_decodeJson(lastTicketJson));
        _state = _state.copyWith(lastSoldTicket: lastTicket);
        notifyListeners();
      } catch (_) {
        _state = _state.copyWith(lastSoldTicket: null);
      }
    }
  }

  void updateTicketWithCashRegister(BuildContext context) {
    // Actualiza el ticket con la caja activa si existe
    final cashRegisterProvider = provider.Provider.of<CashRegisterProvider>(context, listen: false);

    if (cashRegisterProvider.hasActiveCashRegister) {
      final activeCashRegister =
          cashRegisterProvider.currentActiveCashRegister!;
      final currentTicket = _state.ticket;
      final newTicket = _createTicketWithValues(
        creation: currentTicket.creation,
        payMode: currentTicket.payMode,
        valueReceived: currentTicket.valueReceived,
        cashRegisterName: activeCashRegister.description,
        cashRegisterId: activeCashRegister.id,
        sellerName: currentTicket.sellerName,
        sellerId: currentTicket.sellerId,
        priceTotal: currentTicket.priceTotal,
        discount: currentTicket.discount,
        transactionType: currentTicket.transactionType,
        currencySymbol: currentTicket.currencySymbol,
      );
      
      // Establecer los productos usando el setter
      newTicket.products = currentTicket.products;

      _state = _state.copyWith(ticket: newTicket);
      notifyListeners();
    }
  }

  /// Remueve la cuenta seleccionada, limpia todos los datos y notifica a los listeners
  Future<void> removeSelectedAccount() async {
    final prefs = await SharedPreferences.getInstance();
    // Eliminar el ID de la cuenta seleccionada de SharedPreferences
    await prefs.remove(SharedPrefsKeys.selectedAccountId);
    // Limpiar todos los datos y estado
    cleanData();
    notifyListeners();
  }
}
