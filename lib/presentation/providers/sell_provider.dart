import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:sellweb/core/core.dart';
import 'package:sellweb/core/services/storage/app_data_persistence_service.dart';
import 'package:sellweb/core/services/external/thermal_printer_http_service.dart';
import 'package:sellweb/domain/entities/catalogue.dart';
import 'package:sellweb/domain/entities/user.dart';
import 'package:sellweb/domain/entities/ticket_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sellweb/domain/usecases/account_usecase.dart';
import 'package:provider/provider.dart' as provider;
import '../providers/cash_register_provider.dart';
import '../providers/catalogue_provider.dart';

class _SellProviderState {
  final bool ticketView;
  final bool shouldPrintTicket; // si se debe imprimir el ticket
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
  final AppDataPersistenceService _persistenceService =
      AppDataPersistenceService.instance;

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
    return TicketModel(listPoduct: [],creation: Timestamp.now());
  }

  /// Crea un nuevo ticket preservando valores específicos pero con productos vacíos
  TicketModel _createTicketWithValues({
    required String id,
    required Timestamp creation,
    bool annulled = false,
    String payMode = '',
    double valueReceived = 0.0,
    String cashRegisterName = '',
    String cashRegisterId = '',
    String sellerName = '',
    String sellerId = '',
    double priceTotal = 0.0,
    double discount = 0.0,
    bool discountIsPercentage = false,
    String transactionType = 'sale',
    String currencySymbol = '\$', 
  }) {
    return TicketModel( 
      id: id,
      annulled: annulled,
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
      discountIsPercentage: discountIsPercentage,
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
    // Solo limpiar datos si la cuenta es diferente a la actual
    // Esto preserva el ticket en progreso cuando se reselecciona la misma cuenta
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
    final id = await _persistenceService.getSelectedAccountId();
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
    try {
      await _persistenceService
          .saveCurrentTicket(jsonEncode(_state.ticket.toJson()));
    } catch (e) {
      // Log del error para debugging
      if (kDebugMode) {
        print(
            '❌ SellProvider (_saveTicket) : Error al guardar ticket en persistencia: $e');
      }
      rethrow;
    }
  }

  Future<void> _loadTicket() async {
    final ticketJson = await _persistenceService.getCurrentTicket();
    if (ticketJson != null) {
      try {
        final newTicket =
            TicketModel.sahredPreferencefromMap(_decodeJson(ticketJson));
        _state = _state.copyWith(ticket: newTicket);

        notifyListeners();
      } catch (e) {
        // Log del error para debugging
        if (kDebugMode) {
          print(
              '❌ SellProvider: Error al cargar ticket desde persistencia: $e');
        }
      }
    } else {
      // Log para debugging
      if (kDebugMode) {
        print('📦 SellProvider: No hay ticket guardado en persistencia');
      }
    }
  }

  Map<String, dynamic> _decodeJson(String source) =>
      const JsonDecoder().convert(source) as Map<String, dynamic>;

  void addProductsticket(ProductCatalogue product,
      {bool replaceQuantity = false}) {
    // Agrega un producto al ticket actual, reemplazando la cantidad si es necesario

    // var
    final currentTicket = _state.ticket;
    bool exist = false;
    final List<ProductCatalogue> updatedProducts =
        List.from(currentTicket.products);

    for (var i = 0; i < updatedProducts.length; i++) {
      if (updatedProducts[i].id == product.id) {
        if (replaceQuantity) {
          // Reemplazar el producto completo pero preservar la cantidad original si el producto nuevo tiene cantidad 0
          final quantityToUse = product.quantity > 0
              ? product.quantity
              : updatedProducts[i].quantity;
          updatedProducts[i] = product.copyWith(quantity: quantityToUse);
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
      updatedProducts.add(product.copyWith( quantity: product.quantity > 0 ? product.quantity : 1));
    }

    // Crea un nuevo ticket con los productos actualizados
    final newTicket = _createTicketWithValues(
      id: currentTicket.id,
      annulled: currentTicket.annulled,
      creation: currentTicket.creation,
      payMode: currentTicket.payMode,
      valueReceived: currentTicket.valueReceived,
      cashRegisterName: currentTicket.cashRegisterName,
      cashRegisterId: currentTicket.cashRegisterId,
      sellerName: currentTicket.sellerName,
      sellerId: currentTicket.sellerId,
      priceTotal: currentTicket.priceTotal,
      discount: currentTicket.discount,
      discountIsPercentage: currentTicket.discountIsPercentage,
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
    final updatedProducts =
        currentTicket.products.where((item) => item.id != product.id).toList();

    final newTicket = _createTicketWithValues(
      id: currentTicket.id,
      annulled: currentTicket.annulled,
      creation: currentTicket.creation,
      payMode: currentTicket.payMode,
      valueReceived: currentTicket.valueReceived,
      cashRegisterName: currentTicket.cashRegisterName,
      cashRegisterId: currentTicket.cashRegisterId,
      sellerName: currentTicket.sellerName,
      sellerId: currentTicket.sellerId,
      priceTotal: currentTicket.priceTotal,
      discount: currentTicket.discount,
      discountIsPercentage: currentTicket.discountIsPercentage,
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
    _state =
        _state.copyWith(ticket: _createEmptyTicketStatic(), ticketView: false);
    _saveTicket();
    notifyListeners();
  }

  void addQuickProduct(
      {required String description, required double salePrice}) {
    final product = ProductCatalogue(
      id: UidHelper.generateUid(),
      description: description,
      salePrice: salePrice,
    );
    addProductsticket(product, replaceQuantity: true);
  }

  Future<void> _saveSelectedAccount(String id) async {
    await _persistenceService.saveSelectedAccountId(id);
  }

  void setPayMode({String payMode = 'effective'}) {
    final currentTicket = _state.ticket;
    final newTicket = _createTicketWithValues(
      id: currentTicket.id,
      annulled: currentTicket.annulled,
      creation: currentTicket.creation,
      payMode: payMode,
      valueReceived: payMode != 'effective' ? 0.0 : currentTicket.valueReceived,
      cashRegisterName: currentTicket.cashRegisterName,
      cashRegisterId: currentTicket.cashRegisterId,
      sellerName: currentTicket.sellerName,
      sellerId: currentTicket.sellerId,
      priceTotal: currentTicket.priceTotal,
      discount: currentTicket.discount,
      discountIsPercentage: currentTicket.discountIsPercentage,
      transactionType: currentTicket.transactionType,
      currencySymbol: currentTicket.currencySymbol,
    );

    // Establecer los productos usando el setter
    newTicket.products = currentTicket.products;

    _state = _state.copyWith(ticket: newTicket);
    _saveTicket();
    notifyListeners();
  }

  void setDiscount({required double discount, bool isPercentage = false}) {
    if (discount < 0) return; // No permitir descuentos negativos

    final currentTicket = _state.ticket;
    final newTicket = _createTicketWithValues(
      id: currentTicket.id,
      annulled: currentTicket.annulled,
      creation: currentTicket.creation,
      payMode: currentTicket.payMode,
      valueReceived: currentTicket.valueReceived,
      cashRegisterName: currentTicket.cashRegisterName,
      cashRegisterId: currentTicket.cashRegisterId,
      sellerName: currentTicket.sellerName,
      sellerId: currentTicket.sellerId,
      priceTotal: currentTicket.priceTotal,
      discount: discount,
      discountIsPercentage: isPercentage,
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
      id: currentTicket.id,
      annulled: currentTicket.annulled,
      creation: currentTicket.creation,
      payMode: currentTicket.payMode,
      valueReceived: value,
      cashRegisterName: currentTicket.cashRegisterName,
      cashRegisterId: currentTicket.cashRegisterId,
      sellerName: currentTicket.sellerName,
      sellerId: currentTicket.sellerId,
      priceTotal: currentTicket.priceTotal,
      discount: currentTicket.discount,
      discountIsPercentage: currentTicket.discountIsPercentage,
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
    // Carga el estado de impresión del ticket desde AppDataPersistenceService
    final shouldPrint = await _persistenceService.getShouldPrintTicket();
    _state = _state.copyWith(shouldPrintTicket: shouldPrint);
    notifyListeners();
  }

  Future<void> _saveShouldPrintTicket() async {
    // Guarda el estado de impresión del ticket en AppDataPersistenceService
    await _persistenceService.saveShouldPrintTicket(_state.shouldPrintTicket);
  }

  Future<void> saveLastSoldTicket([TicketModel? ticket]) async {
    // Guarda el último ticket vendido en SharedPreferences
    // Si no se proporciona un ticket, usa el ticket actual del estado
    final ticketToSave = ticket ?? _state.ticket;
    
    final newLastSoldTicket = _createTicketWithValues(
      id: ticketToSave.id,
      annulled: ticketToSave.annulled,
      creation: ticketToSave.creation,
      payMode: ticketToSave.payMode,
      valueReceived: ticketToSave.valueReceived,
      cashRegisterName: ticketToSave.cashRegisterName,
      cashRegisterId: ticketToSave.cashRegisterId,
      sellerName: ticketToSave.sellerName,
      sellerId: ticketToSave.sellerId,
      priceTotal: ticketToSave.priceTotal,
      discount: ticketToSave.discount,
      discountIsPercentage: ticketToSave.discountIsPercentage,
      transactionType: ticketToSave.transactionType,
      currencySymbol: ticketToSave.currencySymbol,
    );

    // Establecer los productos usando el setter
    newLastSoldTicket.products = List.from(ticketToSave.products);

    _state = _state.copyWith(lastSoldTicket: newLastSoldTicket);
    await _saveLastSoldTicket();
    notifyListeners();
  }

  Future<void> _saveLastSoldTicket() async {
    final lastTicket = _state.lastSoldTicket;
    if (lastTicket != null) {
      await _persistenceService.saveLastSoldTicket(jsonEncode(lastTicket.toJson()));
    } else {
      await _persistenceService.clearLastSoldTicket();
    }
  }

  /// Anula un ticket tanto en la caja registradora como en el último ticket vendido
  Future<bool> annullLastSoldTicket({
    required BuildContext context,
    required TicketModel ticket,
  }) async {
    try {
      // Obtener el provider de caja registradora
      final cashRegisterProvider = provider.Provider.of<CashRegisterProvider>(context, listen: false);
      
      // Anular el ticket en la caja registradora
      final success = await cashRegisterProvider.annullTicket(
        accountId: profileAccountSelected.id, 
        ticket: ticket,
      );
      
      if (success) {
        // Actualizar el último ticket vendido marcándolo como anulado
        await saveLastSoldTicket(ticket.copyWith(annulled: true));
      }
      
      return success;
    } catch (e) {
      // Manejar cualquier error que pueda ocurrir
      return false;
    }
  }
  // Carga el último ticket vendido desde SharedPreferences al inicializar el provider.
  Future<void> _loadLastSoldTicket() async {
    final lastTicketJson = await _persistenceService.getLastSoldTicket();
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
    final cashRegisterProvider =
        provider.Provider.of<CashRegisterProvider>(context, listen: false);

    if (cashRegisterProvider.hasActiveCashRegister) {
      final activeCashRegister =
          cashRegisterProvider.currentActiveCashRegister!;
      final currentTicket = _state.ticket;
      final newTicket = _createTicketWithValues(
        id: currentTicket.id,
        annulled: currentTicket.annulled,
        creation: currentTicket.creation,
        payMode: currentTicket.payMode,
        valueReceived: currentTicket.valueReceived,
        cashRegisterName: activeCashRegister.description,
        cashRegisterId: activeCashRegister.id,
        sellerName: currentTicket.sellerName,
        sellerId: currentTicket.sellerId,
        priceTotal: currentTicket.priceTotal,
        discount: currentTicket.discount,
        discountIsPercentage: currentTicket.discountIsPercentage,
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
    // Eliminar el ID de la cuenta seleccionada de AppDataPersistenceService
    await _persistenceService.clearSelectedAccountId();
    // Limpiar todos los datos y estado
    cleanData();
    notifyListeners();
  }

  /// PROCESAMIENTO DE VENTA CONFIRMADA
  Future<void> processSale(BuildContext context) async {
    try {
      // asignamos valores necesarios 
      _state.ticket.sellerId = _state.profileAccountSelected.id;
      _state.ticket.sellerName = _state.profileAccountSelected.name;
      _state.ticket.priceTotal = _state.ticket.calculatedTotal;
      // Preparar el ticket con ID único
      _prepareTicketForSale();

      // Procesar caja registradora si está activa
      await _processCashRegister(context);

      // Guardar en historial de transacciones
      await _saveToTransactionHistory(context);

      // Actualizar estadísticas de productos y stock
      await _updateProductSalesAndStock(context);

      // Manejar impresión o generación de ticket según configuración
      if (_state.shouldPrintTicket) {
        await _handleTicketPrintingOrGeneration(context);
      }

      // Finalizar la venta
      await saveLastSoldTicket();

    } catch (e) {
      // Mostrar error al usuario
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Error al procesar la venta: $e',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
      rethrow;
    }
  }

  /// Prepara el ticket para la venta asignando un ID único
  void _prepareTicketForSale() {
    final currentTicket = _state.ticket;
    if (currentTicket.id.isEmpty) {
      final newTicket = _createTicketWithValues(
        id:  UidHelper.generateUid(), 
        annulled: false,
        creation: currentTicket.creation,
        payMode: currentTicket.payMode,
        valueReceived: currentTicket.valueReceived,
        cashRegisterName: currentTicket.cashRegisterName,
        cashRegisterId: currentTicket.cashRegisterId,
        sellerName: currentTicket.sellerName,
        sellerId: currentTicket.sellerId,
        priceTotal: currentTicket.priceTotal,
        discount: currentTicket.discount,
        discountIsPercentage: currentTicket.discountIsPercentage,
        transactionType: currentTicket.transactionType,
        currencySymbol: currentTicket.currencySymbol, 
      ); 
      newTicket.products = currentTicket.products;
      
      _state = _state.copyWith(ticket: newTicket);
    }
  }

  /// Procesa la caja registradora si hay una activa
  Future<void> _processCashRegister(BuildContext context) async {
    final cashRegisterProvider = provider.Provider.of<CashRegisterProvider>(context, listen: false);
    
    if (cashRegisterProvider.hasActiveCashRegister) {
      final activeCashRegister = cashRegisterProvider.currentActiveCashRegister!;
      final currentTicket = _state.ticket;
      
      // Actualizar datos del ticket con información de la caja
      final newTicket = _createTicketWithValues(
        id: currentTicket.id,
        annulled: currentTicket.annulled,
        creation: currentTicket.creation,
        payMode: currentTicket.payMode,
        valueReceived: currentTicket.valueReceived,
        cashRegisterName: activeCashRegister.description,
        cashRegisterId: activeCashRegister.id,
        sellerName: currentTicket.sellerName,
        sellerId: currentTicket.sellerId,
        priceTotal: currentTicket.priceTotal,
        discount: currentTicket.discount,
        discountIsPercentage: currentTicket.discountIsPercentage,
        transactionType: currentTicket.transactionType,
        currencySymbol: currentTicket.currencySymbol,
      ); 
      newTicket.products = currentTicket.products;
      
      _state = _state.copyWith(ticket: newTicket);

      // Registrar la venta en la caja activa
      await cashRegisterProvider.cashRegisterSale(
        accountId: _state.profileAccountSelected.id,
        saleAmount: _state.ticket.getTotalPrice,
        discountAmount: _state.ticket.discount,
        itemCount: _state.ticket.getProductsQuantity(),
      );
    }
  }

  /// Maneja la impresión o generación de ticket según la configuración
  Future<void> _handleTicketPrintingOrGeneration(BuildContext context) async {
    // Verificar si hay impresora conectada
    final printerService = ThermalPrinterHttpService();
    await printerService.initialize();

    if (printerService.isConnected) {
      // Si hay impresora conectada, imprimir directamente
      await _printTicketDirectly(context, printerService);
    } else {
      // Si no hay impresora, mostrar diálogo de opciones
      await _showTicketOptionsDialog(context);
    }
  }

  /// Imprime el ticket directamente usando la impresora térmica
  Future<void> _printTicketDirectly(BuildContext context, ThermalPrinterHttpService printerService) async {
    try {
      // Determinar método de pago
      String paymentMethod = 'Efectivo';
      switch (_state.ticket.payMode) {
        case 'mercadopago':
          paymentMethod = 'Mercado Pago';
          break;
        case 'card':
          paymentMethod = 'Tarjeta Déb/Créd';
          break;
        default:
          paymentMethod = 'Efectivo';
      }

      // Preparar datos del ticket
      final products = _state.ticket.products.map((item) {
        return {
          'quantity': item.quantity.toString(),
          'description': item.description,
          'price': item.salePrice,
        };
      }).toList();

      // Imprimir el ticket
      final printSuccess = await printerService.printTicket(
        businessName: _state.profileAccountSelected.name.isNotEmpty
            ? _state.profileAccountSelected.name
            : 'PUNTO DE VENTA',
        products: products,
        total: _state.ticket.getTotalPrice,
        paymentMethod: paymentMethod,
        cashReceived: _state.ticket.valueReceived > 0
            ? _state.ticket.valueReceived
            : null,
        change: _state.ticket.valueReceived > _state.ticket.getTotalPrice
            ? _state.ticket.valueReceived - _state.ticket.getTotalPrice
            : null,
      );

      // Mostrar resultado
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  printSuccess ? Icons.check_circle : Icons.error,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    printSuccess
                        ? 'Ticket impreso correctamente'
                        : 'Error al imprimir ticket: ${printerService.lastError ?? "Error desconocido"}',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: printSuccess ? Colors.green : Colors.red,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Error al procesar impresión: $e',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  /// Muestra el diálogo de opciones de ticket cuando no hay impresora
  Future<void> _showTicketOptionsDialog(BuildContext context) async {
    await Future.delayed(const Duration(milliseconds: 800));

    if (context.mounted) {
      await showTicketOptionsDialog(
        context: context,
        ticket: _state.ticket,
        businessName: _state.profileAccountSelected.name.isNotEmpty
            ? _state.profileAccountSelected.name
            : 'PUNTO DE VENTA',
        onComplete: () {
          // Este callback se ejecuta solo cuando se completa exitosamente
        },
      );
    }
  }

  /// Guarda el ticket en el historial de transacciones
  Future<void> _saveToTransactionHistory(BuildContext context) async {
    final cashRegisterProvider = provider.Provider.of<CashRegisterProvider>(context, listen: false);
    
    await cashRegisterProvider.saveTicketToTransactionHistory(accountId: _state.profileAccountSelected.id, ticket: _state.ticket);
  }

  /// Actualiza las estadísticas de ventas y stock de los productos en el catálogo
  ///
  /// Este método se ejecuta después de confirmar una venta para:
  /// 1. Incrementar el contador de ventas de cada producto
  /// 2. Decrementar el stock si el producto tiene habilitado el control de stock
  Future<void> _updateProductSalesAndStock(BuildContext context) async {
    try {
      // Obtener el provider del catálogo
      final catalogueProvider = provider.Provider.of<CatalogueProvider>(context, listen: false);
      final accountId = _state.profileAccountSelected.id;

      // Procesar cada producto del ticket
      for (final product in _state.ticket.products) {
        if (product.code.isEmpty) {
          // Si el producto no tiene código, saltar (productos de venta rápida)
          continue;
        }

        try {
          // Incrementar ventas del producto en el catálogo
          await catalogueProvider.incrementProductSales(
            accountId,
            product.id,
            quantity: product.quantity,
          );

          // Si el producto tiene control de stock habilitado, decrementar stock
          if (product.stock && product.quantityStock > 0) {
            await catalogueProvider.decrementProductStock(
              accountId,
              product.id,
              product.quantity,
            );
          }
        } catch (productError) {
          // Si falla la actualización de un producto específico, continuar con los demás
          if (kDebugMode) {
            print('Error actualizando producto ${product.id}: $productError');
          }
        }
      }
    } catch (e) {
      // Registrar el error pero no fallar la venta
      if (kDebugMode) {
        print('Error general actualizando productos: $e');
      }

      // Opcionalmente mostrar una notificación al usuario
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.warning, color: Colors.white),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Venta registrada correctamente. Hay un problema menor con la actualización de estadísticas.',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }
 
}
