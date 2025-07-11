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
      profileAccountSelected: profileAccountSelected ?? this.profileAccountSelected,
      ticket: ticket ?? this.ticket,
      lastSoldTicket: lastSoldTicket == const Object() ? this.lastSoldTicket : lastSoldTicket as TicketModel?,
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
    ticket: TicketModel(listPoduct: [], creation: Timestamp.now()),
    lastSoldTicket: null,
  );

  // Getters que no causan rebuild
  bool get ticketView => _state.ticketView;
  bool get shouldPrintTicket => _state.shouldPrintTicket;
  ProfileAccountModel get profileAccountSelected => _state.profileAccountSelected;
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
      ticket: TicketModel(listPoduct: [], creation: Timestamp.now()),
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
    await prefs.setString(
        SharedPrefsKeys.currentTicket, jsonEncode(_state.ticket.toJson()));
  }

  Future<void> _loadTicket() async {
    final prefs = await SharedPreferences.getInstance();
    final ticketJson = prefs.getString(SharedPrefsKeys.currentTicket);
    if (ticketJson != null) {
      try {
        final newTicket = TicketModel.sahredPreferencefromMap(_decodeJson(ticketJson));
        _state = _state.copyWith(ticket: newTicket);
        notifyListeners();
      } catch (_) {}
    }
  }

  Map<String, dynamic> _decodeJson(String source) =>
      const JsonDecoder().convert(source) as Map<String, dynamic>;

  void addProductsticket(ProductCatalogue product, {bool replaceQuantity = false}) {
    final currentTicket = _state.ticket;
    bool exist = false;
    final updatedProducts = List.from(currentTicket.listPoduct);
    
    for (var i = 0; i < updatedProducts.length; i++) {
      if (updatedProducts[i]['id'] == product.id) {
        if (replaceQuantity) {
          updatedProducts[i]['quantity'] = product.quantity;
        } else {
          updatedProducts[i]['quantity'] += (product.quantity > 0 ? product.quantity : 1);
        }
        exist = true;
        break;
      }
    }
    
    if (!exist) {
      updatedProducts.add(product.toMap());
    }

    final newTicket = TicketModel(
      listPoduct: updatedProducts,
      creation: currentTicket.creation,
      payMode: currentTicket.payMode,
      valueReceived: currentTicket.valueReceived,
      cashRegisterName: currentTicket.cashRegisterName,
      cashRegisterId: currentTicket.cashRegisterId,
    );

    _state = _state.copyWith(ticket: newTicket);
    _saveTicket();
    notifyListeners();
  }

  void removeProduct(ProductCatalogue product) {
    final currentTicket = _state.ticket;
    final updatedProducts = currentTicket.listPoduct
        .where((item) => item['id'] != product.id)
        .toList();

    final newTicket = TicketModel(
      listPoduct: updatedProducts,
      creation: currentTicket.creation,
      payMode: currentTicket.payMode,
      valueReceived: currentTicket.valueReceived,
      cashRegisterName: currentTicket.cashRegisterName,
      cashRegisterId: currentTicket.cashRegisterId,
    );

    _state = _state.copyWith(
      ticket: newTicket,
      ticketView: updatedProducts.isNotEmpty,
    );
    _saveTicket();
    notifyListeners();
  }

  void discartTicket() {
    _state = _state.copyWith(
      ticket: TicketModel(listPoduct: [], creation: Timestamp.now()),
      ticketView: false,
    );
    _saveTicket();
    notifyListeners();
  }

  void addQuickProduct({required String description, required double salePrice}) {
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
    final newTicket = TicketModel(
      listPoduct: currentTicket.listPoduct,
      creation: currentTicket.creation,
      payMode: payMode,
      valueReceived: payMode != 'effective' ? 0.0 : currentTicket.valueReceived,
      cashRegisterName: currentTicket.cashRegisterName,
      cashRegisterId: currentTicket.cashRegisterId,
    );

    _state = _state.copyWith(ticket: newTicket);
    _saveTicket();
    notifyListeners();
  }

  void setReceivedCash(double value) {
    final currentTicket = _state.ticket;
    final newTicket = TicketModel(
      listPoduct: currentTicket.listPoduct,
      creation: currentTicket.creation,
      payMode: currentTicket.payMode,
      valueReceived: value,
      cashRegisterName: currentTicket.cashRegisterName,
      cashRegisterId: currentTicket.cashRegisterId,
    );

    _state = _state.copyWith(ticket: newTicket);
    _saveTicket();
    notifyListeners();
  }

  void addIncomeCash({double value = 0.0}) {
    setReceivedCash(value);
  }

  Future<void> _loadShouldPrintTicket() async {
    final prefs = await SharedPreferences.getInstance();
    final shouldPrint = prefs.getBool(SharedPrefsKeys.shouldPrintTicket) ?? false;
    _state = _state.copyWith(shouldPrintTicket: shouldPrint);
    notifyListeners();
  }

  Future<void> _saveShouldPrintTicket() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(SharedPrefsKeys.shouldPrintTicket, _state.shouldPrintTicket);
  }

  Future<void> saveLastSoldTicket() async {
    final currentTicket = _state.ticket;
    final newLastSoldTicket = TicketModel(
      listPoduct: List.from(currentTicket.listPoduct),
      creation: currentTicket.creation,
      payMode: currentTicket.payMode,
      valueReceived: currentTicket.valueReceived,
      cashRegisterName: currentTicket.cashRegisterName,
      cashRegisterId: currentTicket.cashRegisterId,
    );

    _state = _state.copyWith(lastSoldTicket: newLastSoldTicket);
    await _saveLastSoldTicket();
    notifyListeners();
  }

  Future<void> _saveLastSoldTicket() async {
    final prefs = await SharedPreferences.getInstance();
    final lastTicket = _state.lastSoldTicket;
    if (lastTicket != null) {
      await prefs.setString(
          SharedPrefsKeys.lastSoldTicket, jsonEncode(lastTicket.toJson()));
    } else {
      await prefs.remove(SharedPrefsKeys.lastSoldTicket);
    }
  }

  Future<void> _loadLastSoldTicket() async {
    final prefs = await SharedPreferences.getInstance();
    final lastTicketJson = prefs.getString(SharedPrefsKeys.lastSoldTicket);
    if (lastTicketJson != null) {
      try {
        final lastTicket = TicketModel.sahredPreferencefromMap(_decodeJson(lastTicketJson));
        _state = _state.copyWith(lastSoldTicket: lastTicket);
        notifyListeners();
      } catch (_) {
        _state = _state.copyWith(lastSoldTicket: null);
      }
    }
  }

  void updateTicketWithCashRegister(BuildContext context) {
    final cashRegisterProvider = provider.Provider.of<CashRegisterProvider>(context, listen: false);
    
    if (cashRegisterProvider.hasActiveCashRegister) {
      final activeCashRegister = cashRegisterProvider.currentActiveCashRegister!;
      final currentTicket = _state.ticket;
      final newTicket = TicketModel(
        listPoduct: currentTicket.listPoduct,
        creation: currentTicket.creation,
        payMode: currentTicket.payMode,
        valueReceived: currentTicket.valueReceived,
        cashRegisterName: activeCashRegister.description,
        cashRegisterId: activeCashRegister.id,
      );

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
