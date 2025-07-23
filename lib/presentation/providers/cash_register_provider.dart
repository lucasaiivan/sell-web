import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sellweb/core/utils/fuctions.dart';
import '../../core/services/app_data_persistence_service.dart';
import '../../domain/entities/cash_register_model.dart';
import '../../domain/entities/ticket_model.dart';
import '../../domain/usecases/cash_register_usecases.dart';

/// Extension helper para firstOrNull si no está disponible
extension ListExtensions<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

class _CashRegisterState {
  final List<CashRegister> activeCashRegisters;
  final CashRegister?
      selectedCashRegister; // Puede ser null si no hay caja seleccionada
  final bool isLoadingActive;
  final List<CashRegister> cashRegisterHistory;
  final bool isLoadingHistory;
  final String historyFilter;
  final String? errorMessage;
  final bool isProcessing;
  final List<String> fixedDescriptions;

  const _CashRegisterState({
    this.activeCashRegisters = const [],
    this.selectedCashRegister,
    this.isLoadingActive = false,
    this.cashRegisterHistory = const [],
    this.isLoadingHistory = false,
    this.historyFilter = 'Última semana',
    this.errorMessage,
    this.isProcessing = false,
    this.fixedDescriptions = const [],
  });

  bool get hasActiveCashRegister => selectedCashRegister != null;
  CashRegister? get currentActiveCashRegister => selectedCashRegister;
  bool get hasAvailableCashRegisters => activeCashRegisters.isNotEmpty;

  _CashRegisterState copyWith({
    List<CashRegister>? activeCashRegisters,
    CashRegister? selectedCashRegister,
    bool clearSelectedCashRegister = false,
    bool? isLoadingActive, // estado de carga de cajas activas
    List<CashRegister>? cashRegisterHistory,
    bool? isLoadingHistory,
    String? historyFilter,
    Object? errorMessage = const Object(),
    bool? isProcessing, // estado de procesamiento de acciones
    List<String>? fixedDescriptions,
  }) {
    return _CashRegisterState(
      activeCashRegisters: activeCashRegisters ?? this.activeCashRegisters,
      selectedCashRegister: clearSelectedCashRegister
          ? null
          : selectedCashRegister ?? this.selectedCashRegister,
      isLoadingActive: isLoadingActive ?? this.isLoadingActive,
      cashRegisterHistory: cashRegisterHistory ?? this.cashRegisterHistory,
      isLoadingHistory: isLoadingHistory ?? this.isLoadingHistory,
      historyFilter: historyFilter ?? this.historyFilter,
      errorMessage: errorMessage == const Object()
          ? this.errorMessage
          : errorMessage as String?,
      isProcessing: isProcessing ?? this.isProcessing,
      fixedDescriptions: fixedDescriptions ?? this.fixedDescriptions,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _CashRegisterState &&
          runtimeType == other.runtimeType &&
          listEquals(activeCashRegisters, other.activeCashRegisters) &&
          selectedCashRegister == other.selectedCashRegister &&
          isLoadingActive == other.isLoadingActive &&
          listEquals(cashRegisterHistory, other.cashRegisterHistory) &&
          isLoadingHistory == other.isLoadingHistory &&
          historyFilter == other.historyFilter &&
          errorMessage == other.errorMessage &&
          isProcessing == other.isProcessing &&
          listEquals(fixedDescriptions, other.fixedDescriptions);

  @override
  int get hashCode =>
      activeCashRegisters.hashCode ^
      selectedCashRegister.hashCode ^
      isLoadingActive.hashCode ^
      cashRegisterHistory.hashCode ^
      isLoadingHistory.hashCode ^
      historyFilter.hashCode ^
      errorMessage.hashCode ^
      isProcessing.hashCode ^
      fixedDescriptions.hashCode;
}

/// Provider para el sistema de caja registradora
///
/// Maneja el estado de:
/// - Cajas registradoras activas
/// - Historial de arqueos
/// - Flujos de caja
/// - Operaciones de apertura y cierre
class CashRegisterProvider extends ChangeNotifier {
  final CashRegisterUsecases _cashRegisterUsecases;

  // Stream subscriptions para actualizaciones automáticas
  StreamSubscription<List<CashRegister>>? _activeCashRegistersSubscription;
  String? _currentAccountId;

  // Form controllers
  final TextEditingController openDescriptionController =
      TextEditingController();
  final AppMoneyTextEditingController initialCashController =
      AppMoneyTextEditingController();
  final AppMoneyTextEditingController finalBalanceController =
      AppMoneyTextEditingController();
  final TextEditingController movementDescriptionController =
      TextEditingController();
  final AppMoneyTextEditingController movementAmountController =
      AppMoneyTextEditingController();

  // Immutable state
  _CashRegisterState _state = _CashRegisterState();

  // Public getters
  List<CashRegister> get activeCashRegisters => _state.activeCashRegisters;
  CashRegister? get selectedCashRegister => _state.selectedCashRegister;
  bool get isLoadingActive => _state.isLoadingActive;
  List<CashRegister> get cashRegisterHistory => _state.cashRegisterHistory;
  bool get isLoadingHistory => _state.isLoadingHistory;
  String get historyFilter => _state.historyFilter;
  String? get errorMessage => _state.errorMessage;
  bool get isProcessing => _state.isProcessing;
  List<String> get fixedDescriptions => _state.fixedDescriptions;
  bool get hasActiveCashRegister => _state.hasActiveCashRegister;
  bool get hasAvailableCashRegisters => _state.hasAvailableCashRegisters;
  CashRegister? get currentActiveCashRegister =>
      _state.currentActiveCashRegister;

  CashRegisterProvider(this._cashRegisterUsecases);

  @override
  void dispose() {
    // Cancelar subscripciones de streams
    _activeCashRegistersSubscription?.cancel();

    // Limpiar controllers
    openDescriptionController.dispose();
    initialCashController.dispose();
    finalBalanceController.dispose();
    movementDescriptionController.dispose();
    movementAmountController.dispose();

    super.dispose();
  }

  // ==========================================
  // MÉTODOS DE PERSISTENCIA
  // ==========================================

  /// Inicializa
  Future<void> initializeFromPersistence(String accountId) async {
    if (accountId.isEmpty) {
      return;
    } // No hacer nada si no hay cuenta

    // Obtener instancia de AppDataPersistenceService
    final persistenceService = AppDataPersistenceService.instance;

    try {
      // Cargar cajas activas con espera explícita
      await _loadActiveCashRegistersAndWait(accountId);

      // continuar solo si hay cajas activas
      if (_state.activeCashRegisters.isEmpty) {
        // Intentar cargar directamente una vez más
        try {
          final directCashRegisters =
              await _cashRegisterUsecases.getActiveCashRegisters(accountId);

          if (directCashRegisters.isNotEmpty) {
            _state = _state.copyWith(
              activeCashRegisters: directCashRegisters,
              isLoadingActive: false,
            );
            notifyListeners();
          }
        } catch (e) {
          // Error silencioso para no interrumpir la UI
        }
      }
      // Intentar cargar la caja seleccionada desde persistencia
      final savedCashRegisterId =
          await persistenceService.getSelectedCashRegisterId();

      // Si hay una caja guardada, verificar si existe en las activas
      if (savedCashRegisterId != null && savedCashRegisterId.isNotEmpty) {
        // Verificar si la caja guardada existe en las activas
        final savedCashRegister = _state.activeCashRegisters
            .where((cr) => cr.id == savedCashRegisterId)
            .firstOrNull; //  usa firstOrNull para evitar excepciones
        if (savedCashRegister != null) {
          // si existe una caja seleccionada, actualizar el estado
          _state = _state.copyWith(selectedCashRegister: savedCashRegister);
          notifyListeners();
        } else {
          // Si la caja guardada ya no existe, limpiar persistencia
          await persistenceService.clearSelectedCashRegisterId();
        }
      }
    } catch (e) {
      _state = _state.copyWith(errorMessage: e.toString());
      notifyListeners();
    }
  }

  /// Método auxiliar que espera a que se carguen las cajas activas
  Future<void> _loadActiveCashRegistersAndWait(String accountId) async {
    // Si ya estamos escuchando la misma cuenta, esperar a los datos existentes
    if (_currentAccountId == accountId &&
        _activeCashRegistersSubscription != null) {
      // Esperar un momento para que el stream emita datos si los tiene
      await Future.delayed(const Duration(milliseconds: 500));
      return;
    }

    // Cancelar suscripción anterior si existe
    await _activeCashRegistersSubscription?.cancel();
    _currentAccountId = accountId;

    // Mostrar indicador de carga
    _state = _state.copyWith(isLoadingActive: true, errorMessage: null);
    notifyListeners();

    // Crear un Completer para esperar el primer resultado del stream
    final completer = Completer<void>();
    bool firstDataReceived = false;

    try {
      // Configurar stream para actualizaciones automáticas
      _activeCashRegistersSubscription =
          _cashRegisterUsecases.getActiveCashRegistersStream(accountId).listen(
        (activeCashRegisters) {
          // Actualizar la lista de cajas activas
          _state = _state.copyWith(
            activeCashRegisters: activeCashRegisters,
            isLoadingActive: false,
            errorMessage: null,
          );

          // Si hay una caja seleccionada, verificar si aún existe y actualizarla
          if (_state.selectedCashRegister != null) {
            final updatedSelectedCashRegister = activeCashRegisters
                .where((cr) => cr.id == _state.selectedCashRegister!.id)
                .firstOrNull;

            if (updatedSelectedCashRegister != null) {
              // Actualizar la caja seleccionada con los datos más recientes
              _state = _state.copyWith(
                selectedCashRegister: updatedSelectedCashRegister,
              );
            } else {
              // La caja seleccionada ya no existe, limpiar selección
              clearSelectedCashRegister();
            }
          }

          notifyListeners();

          // Completar solo en la primera emisión
          if (!firstDataReceived) {
            firstDataReceived = true;
            completer.complete();
          }
        },
        onError: (error) {
          _state = _state.copyWith(
            errorMessage: error.toString(),
            isLoadingActive: false,
          );
          notifyListeners();

          if (!firstDataReceived) {
            firstDataReceived = true;
            completer.completeError(error);
          }
        },
      );

      // Esperar a que el stream emita el primer resultado (máximo 10 segundos)
      await completer.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Timeout esperando datos de cajas activas');
        },
      );
    } catch (e) {
      _state = _state.copyWith(
        errorMessage: e.toString(),
        isLoadingActive: false,
      );
      notifyListeners();
      rethrow;
    }
  }

  /// Selecciona una caja registradora y la guarda en persistencia
  Future<void> selectCashRegister(CashRegister cashRegister) async {
    final persistenceService = AppDataPersistenceService.instance;

    try {
      // Actualizar estado
      _state = _state.copyWith(selectedCashRegister: cashRegister);
      notifyListeners();

      // Guardar en persistencia
      await persistenceService.saveSelectedCashRegisterId(cashRegister.id);
    } catch (e) {
      // Revertir cambio de estado si falló la persistencia
      _state = _state.copyWith(clearSelectedCashRegister: true);
      notifyListeners();
      rethrow;
    }
  }

  /// Deselecciona la caja registradora actual y limpia persistencia
  Future<void> clearSelectedCashRegister() async {
    final persistenceService = AppDataPersistenceService.instance;

    try {
      // Limpiar estado
      _state = _state.copyWith(clearSelectedCashRegister: true);
      notifyListeners();

      // Limpiar persistencia
      await persistenceService.clearSelectedCashRegisterId();
    } catch (e) {
      _state = _state.copyWith(errorMessage: 'Error al limpiar selección: $e');
      notifyListeners();
    }
  }

  // ==========================================
  // MÉTODOS PÚBLICOS - CAJAS ACTIVAS
  // ==========================================

  /// Carga las cajas registradoras activas usando streams para actualizaciones automáticas
  Future<void> loadActiveCashRegisters(String accountId) async {
    // Si ya estamos escuchando la misma cuenta, no hacer nada
    if (_currentAccountId == accountId &&
        _activeCashRegistersSubscription != null) {
      return;
    }

    // Cancelar suscripción anterior si existe
    await _activeCashRegistersSubscription?.cancel();
    _currentAccountId = accountId;

    // Mostrar indicador de carga
    _state = _state.copyWith(isLoadingActive: true, errorMessage: null);
    notifyListeners();

    try {
      // Configurar stream para actualizaciones automáticas
      _activeCashRegistersSubscription =
          _cashRegisterUsecases.getActiveCashRegistersStream(accountId).listen(
        (activeCashRegisters) {
          // Actualizar la lista de cajas activas
          _state = _state.copyWith(
            activeCashRegisters: activeCashRegisters,
            isLoadingActive: false,
            errorMessage: null,
          );

          // Si hay una caja seleccionada, verificar si aún existe y actualizarla
          if (_state.selectedCashRegister != null) {
            final updatedSelectedCashRegister = activeCashRegisters
                .where((cr) => cr.id == _state.selectedCashRegister!.id)
                .firstOrNull;

            if (updatedSelectedCashRegister != null) {
              // Actualizar la caja seleccionada con los datos más recientes
              _state = _state.copyWith(
                selectedCashRegister: updatedSelectedCashRegister,
              );
            } else {
              // La caja seleccionada ya no existe, limpiar selección
              clearSelectedCashRegister();
            }
          }

          notifyListeners();
        },
        onError: (error) {
          _state = _state.copyWith(
            errorMessage: error.toString(),
            isLoadingActive: false,
          );
          notifyListeners();
        },
      );
    } catch (e) {
      _state = _state.copyWith(
        errorMessage: e.toString(),
        isLoadingActive: false,
      );
      notifyListeners();
    }
  }

  /// Abre una nueva caja registradora
  Future<bool> openCashRegister(String accountId, String cashierId) async {
    if (openDescriptionController.text.trim().isEmpty) {
      _state = _state.copyWith(errorMessage: 'La descripción es obligatoria');
      notifyListeners();
      return false;
    }

    final initialCash = initialCashController.doubleValue;
    if (initialCash < 0) {
      _state = _state.copyWith(
          errorMessage: 'El monto inicial no puede ser negativo');
      notifyListeners();
      return false;
    }

    _state = _state.copyWith(isProcessing: true, errorMessage: null);
    notifyListeners();

    try {
      final newCashRegister = await _cashRegisterUsecases.openCashRegister(
        accountId: accountId,
        description: openDescriptionController.text.trim(),
        initialCash: initialCash,
        cashierId: cashierId,
      );

      // Seleccionar automáticamente la nueva caja (el stream se actualizará automáticamente)
      await selectCashRegister(newCashRegister);

      // Limpiar formulario
      _clearOpenForm();

      return true;
    } catch (e) {
      _state = _state.copyWith(errorMessage: e.toString());
      return false;
    } finally {
      _state = _state.copyWith(isProcessing: false);
      notifyListeners();
    }
  }

  /// Cierra una caja registradora
  Future<bool> closeCashRegister(
      String accountId, String cashRegisterId) async {
    final finalBalance = finalBalanceController.doubleValue;
    if (finalBalance < 0) {
      _state = _state.copyWith(
          errorMessage: 'El balance final no puede ser negativo');
      notifyListeners();
      return false;
    }

    _state = _state.copyWith(isProcessing: true, errorMessage: null);
    notifyListeners();

    try {
      await _cashRegisterUsecases.closeCashRegister(
        accountId: accountId,
        cashRegisterId: cashRegisterId,
        finalBalance: finalBalance,
      );

      // Si se cierra la caja seleccionada, limpiar selección
      if (_state.selectedCashRegister?.id == cashRegisterId) {
        await clearSelectedCashRegister();
      }

      // Limpiar formulario
      _clearCloseForm();

      return true;
    } catch (e) {
      _state = _state.copyWith(errorMessage: e.toString());
      return false;
    } finally {
      _state = _state.copyWith(isProcessing: false);
      notifyListeners();
    }
  }

  // ==========================================
  // MÉTODOS PÚBLICOS - MOVIMIENTOS DE CAJA
  // ==========================================

  /// Registra un ingreso de caja
  Future<bool> addCashInflow(
      String accountId, String cashRegisterId, String userId) async {
    if (movementDescriptionController.text.trim().isEmpty) {
      _state = _state.copyWith(errorMessage: 'La descripción es obligatoria');
      notifyListeners();
      return false;
    }

    final amount = movementAmountController.doubleValue;
    if (amount <= 0) {
      _state = _state.copyWith(errorMessage: 'El monto debe ser mayor a cero');
      notifyListeners();
      return false;
    }

    _state = _state.copyWith(isProcessing: true, errorMessage: null);
    notifyListeners();

    try {
      await _cashRegisterUsecases.addCashInflow(
        accountId: accountId,
        cashRegisterId: cashRegisterId,
        description: movementDescriptionController.text.trim(),
        amount: amount,
        userId: userId,
      );

      // Limpiar formulario
      _clearMovementForm();

      // Notificar cambios explícitamente
      notifyListeners();
      return true;
    } catch (e) {
      _state = _state.copyWith(errorMessage: e.toString());
      return false;
    } finally {
      _state = _state.copyWith(isProcessing: false);
      notifyListeners();
    }
  }

  /// Registra un egreso de caja
  Future<bool> addCashOutflow(
      String accountId, String cashRegisterId, String userId) async {
    if (movementDescriptionController.text.trim().isEmpty) {
      _state = _state.copyWith(errorMessage: 'La descripción es obligatoria');
      notifyListeners();
      return false;
    }

    final amount = movementAmountController.doubleValue;
    if (amount <= 0) {
      _state = _state.copyWith(errorMessage: 'El monto debe ser mayor a cero');
      notifyListeners();
      return false;
    }

    _state = _state.copyWith(isProcessing: true, errorMessage: null);
    notifyListeners();

    try {
      await _cashRegisterUsecases.addCashOutflow(
        accountId: accountId,
        cashRegisterId: cashRegisterId,
        description: movementDescriptionController.text.trim(),
        amount: amount,
        userId: userId,
      );

      // Limpiar formulario
      _clearMovementForm();

      // Notificar cambios explícitamente
      notifyListeners();
      return true;
    } catch (e) {
      _state = _state.copyWith(errorMessage: e.toString());
      return false;
    } finally {
      _state = _state.copyWith(isProcessing: false);
      notifyListeners();
    }
  }

  /// Registra una venta en la caja activa
  Future<bool> registerSale({
    required String accountId,
    required double saleAmount,
    required double discountAmount,
    int itemCount = 1,
  }) async {
    if (!hasActiveCashRegister) {
      _state =
          _state.copyWith(errorMessage: 'No hay una caja registradora activa');
      notifyListeners();
      return false;
    }

    try {
      await _cashRegisterUsecases.registerSale(
        accountId: accountId,
        cashRegisterId: currentActiveCashRegister!.id,
        saleAmount: saleAmount,
        discountAmount: discountAmount,
      );

      return true;
    } catch (e) {
      _state = _state.copyWith(errorMessage: e.toString());
      notifyListeners();
      return false;
    }
  }

  // ==========================================
  // MÉTODOS PÚBLICOS - HISTORIAL
  // ==========================================

  /// Carga el historial de arqueos según el filtro seleccionado
  Future<void> loadCashRegisterHistory(String accountId) async {
    _state = _state.copyWith(isLoadingHistory: true, errorMessage: null);
    notifyListeners();

    try {
      List<CashRegister> history;
      switch (_state.historyFilter) {
        case 'Última semana':
          history =
              await _cashRegisterUsecases.getLastWeekCashRegisters(accountId);
          break;
        case 'Último mes':
          history =
              await _cashRegisterUsecases.getLastMonthCashRegisters(accountId);
          break;
        case 'Mes anterior':
          history = await _cashRegisterUsecases
              .getPreviousMonthCashRegisters(accountId);
          break;
        case 'Hoy':
          history =
              await _cashRegisterUsecases.getTodayCashRegisters(accountId);
          break;
        default:
          history =
              await _cashRegisterUsecases.getCashRegisterHistory(accountId);
      }
      _state = _state.copyWith(cashRegisterHistory: history);
    } catch (e) {
      _state = _state.copyWith(errorMessage: e.toString());
    } finally {
      _state = _state.copyWith(isLoadingHistory: false);
      notifyListeners();
    }
  }

  /// Cambia el filtro del historial
  void setHistoryFilter(String filter) {
    _state = _state.copyWith(historyFilter: filter);
    notifyListeners();
  }

  // ==========================================
  // MÉTODOS PÚBLICOS - DESCRIPCIONES FIJAS
  // ==========================================

  /// Carga las descripciones fijas para nombres de caja registradora
  Future<void> loadCashRegisterFixedDescriptions(String accountId) async {
    try {
      final descriptions = await _cashRegisterUsecases
          .getCashRegisterFixedDescriptions(accountId);
      _state = _state.copyWith(fixedDescriptions: descriptions);
      notifyListeners();
    } catch (e) {
      // Silenciosamente fallar para no interrumpir la UI
    }
  }

  /// Crea una nueva descripción fija para nombres de caja registradora
  Future<bool> createCashRegisterFixedDescription(
      String accountId, String description) async {
    try {
      await _cashRegisterUsecases.createCashRegisterFixedDescription(
        accountId: accountId,
        description: description,
      );

      // Recargar descripciones
      await loadCashRegisterFixedDescriptions(accountId);

      return true;
    } catch (e) {
      _state = _state.copyWith(errorMessage: e.toString());
      notifyListeners();
      return false;
    }
  }

  /// Elimina una descripción fija para nombres de caja registradora
  Future<bool> deleteCashRegisterFixedDescription(
      String accountId, String description) async {
    try {
      await _cashRegisterUsecases.deleteCashRegisterFixedDescription(
        accountId: accountId,
        description: description,
      );

      // Recargar descripciones para actualizar la vista
      await loadCashRegisterFixedDescriptions(accountId);

      return true;
    } catch (e) {
      _state = _state.copyWith(errorMessage: e.toString());
      notifyListeners();
      return false;
    }
  }

  // ==========================================
  // MÉTODOS PÚBLICOS - UTILIDADES
  // ==========================================

  /// Obtiene un reporte de ventas diario
  Future<Map<String, dynamic>?> getDailySummary(String accountId) async {
    try {
      return await _cashRegisterUsecases.getDailySummary(accountId);
    } catch (e) {
      _state = _state.copyWith(errorMessage: e.toString());
      notifyListeners();
      return null;
    }
  }

  /// Guarda un ticket de venta confirmada en el historial de transacciones
  /// La transacción se registra SIEMPRE, independientemente de si existe una caja registradora activa
  Future<bool> saveTicketToTransactionHistory({
    required String accountId,
    required TicketModel ticket,
    String? sellerName,
    String? sellerId,
  }) async {
    try {
      // Asegurar que el ticket tenga un ID único
      final ticketId =
          ticket.id.isEmpty ? Publications.generateUid() : ticket.id;

      // Asegurar que tenga información del vendedor
      final finalSellerName = ticket.sellerName.isEmpty
          ? (sellerName ?? 'Vendedor')
          : ticket.sellerName;
      final finalSellerId = ticket.sellerId.isEmpty
          ? (sellerId ?? 'default_seller')
          : ticket.sellerId;

      // Si hay una caja activa, asignar su información; si no, usar valores por defecto
      String finalCashRegisterName = ticket.cashRegisterName;
      String finalCashRegisterId = ticket.cashRegisterId;

      if (hasActiveCashRegister) {
        finalCashRegisterName = currentActiveCashRegister!.description;
        finalCashRegisterId = currentActiveCashRegister!.id;
      } else {
        // Si no hay caja activa, usar información por defecto
        finalCashRegisterName = finalCashRegisterName.isEmpty
            ? 'Sin caja asignada'
            : finalCashRegisterName;
        finalCashRegisterId = finalCashRegisterId.isEmpty
            ? 'no_cash_register'
            : finalCashRegisterId;
      }

      // Crear ticket actualizado con toda la información necesaria
      final updatedTicket = TicketModel(
        id: ticketId,
        payMode: ticket.payMode,
        currencySymbol: ticket.currencySymbol,
        sellerName: finalSellerName,
        sellerId: finalSellerId,
        cashRegisterName: finalCashRegisterName,
        cashRegisterId: finalCashRegisterId,
        priceTotal: ticket.priceTotal > 0
            ? ticket.priceTotal
            : _calculateTotalPriceOptimized(ticket), // Usar método optimizado
        valueReceived: ticket.valueReceived,
        discount: ticket.discount,
        transactionType: ticket.transactionType,
        listPoduct: ticket.getProductsAsCatalogue(),
        creation: ticket.creation,
      );
      updatedTicket.products = ticket.products;

      await _cashRegisterUsecases.saveTicketToTransactionHistory(
        accountId: accountId,
        ticket: updatedTicket,
      );

      return true;
    } catch (e) {
      _state = _state.copyWith(errorMessage: e.toString());
      notifyListeners();
      return false;
    }
  }

  /// Obtiene los tickets del día actual como objetos TicketModel
  /// Nota: Por ahora devuelve Map hasta implementar conversión completa
  Future<List<Map<String, dynamic>>?> getTodayTickets(String accountId) async {
    try {
      return await _cashRegisterUsecases.getTodayTransactions(accountId);
    } catch (e) {
      _state = _state.copyWith(errorMessage: e.toString());
      notifyListeners();
      return null;
    }
  }

  /// Obtiene los tickets por rango de fechas como objetos TicketModel
  /// Nota: Por ahora devuelve Map hasta implementar conversión completa
  Future<List<Map<String, dynamic>>?> getTicketsByDateRange({
    required String accountId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      return await _cashRegisterUsecases.getTransactionsByDateRange(
        accountId: accountId,
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
      _state = _state.copyWith(errorMessage: e.toString());
      notifyListeners();
      return null;
    }
  }

  /// Obtiene las transacciones del día actual
  Future<List<Map<String, dynamic>>?> getTodayTransactions(
      String accountId) async {
    try {
      return await _cashRegisterUsecases.getTodayTransactions(accountId);
    } catch (e) {
      _state = _state.copyWith(errorMessage: e.toString());
      notifyListeners();
      return null;
    }
  }

  /// Obtiene las transacciones por rango de fechas
  Future<List<Map<String, dynamic>>?> getTransactionsByDateRange({
    required String accountId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      return await _cashRegisterUsecases.getTransactionsByDateRange(
        accountId: accountId,
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
      _state = _state.copyWith(errorMessage: e.toString());
      notifyListeners();
      return null;
    }
  }

  /// Obtiene análisis de transacciones para reportes
  /// TODO: Implementar método getTransactionAnalytics en use case
  Future<Map<String, dynamic>?> getTransactionAnalytics({
    required String accountId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      // Por ahora devolver análisis básico usando los datos disponibles
      final transactions =
          await _cashRegisterUsecases.getTransactionsByDateRange(
        accountId: accountId,
        startDate: startDate,
        endDate: endDate,
      );

      double totalRevenue = 0;
      double totalDiscounts = 0;
      int totalTransactions = transactions.length;

      for (final transaction in transactions) {
        totalRevenue += (transaction['priceTotal'] ?? 0).toDouble();
        totalDiscounts += (transaction['discount'] ?? 0).toDouble();
      }

      return {
        'totalRevenue': totalRevenue,
        'totalDiscounts': totalDiscounts,
        'netRevenue': totalRevenue - totalDiscounts,
        'totalTransactions': totalTransactions,
      };
    } catch (e) {
      _state = _state.copyWith(errorMessage: e.toString());
      notifyListeners();
      return null;
    }
  }

  /// Limpia todos los mensajes de error
  ///
  /// Este método debe ser llamado al inicializar diálogos para resetear
  /// el estado de error y evitar que se muestren errores de operaciones previas
  void clearError() {
    _state = _state.copyWith(errorMessage: null);
    notifyListeners();
  }

  /// Establece una descripción en el formulario de movimientos
  void setMovementDescription(String description) {
    movementDescriptionController.text = description;
    notifyListeners();
  }

  // ==========================================
  // MÉTODOS PRIVADOS
  // ==========================================

  /// Calcula el precio total usando ProductTicketModel (método optimizado)
  double _calculateTotalPriceOptimized(TicketModel ticket) {
    return ticket.calculatedTotal;
  }

  void _clearOpenForm() {
    openDescriptionController.clear();
    initialCashController.clear();
  }

  void _clearCloseForm() {
    finalBalanceController.clear();
  }

  void _clearMovementForm() {
    movementDescriptionController.clear();
    movementAmountController.clear();
  }
}
