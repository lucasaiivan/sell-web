import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sellweb/core/utils/fuctions.dart';
import '../../core/services/cash_register_persistence_service.dart';
import '../../domain/entities/cash_register_model.dart';
import '../../domain/usecases/cash_register_usecases.dart';

/// Extension helper para firstOrNull si no está disponible
extension ListExtensions<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

class _CashRegisterState {
  final List<CashRegister> activeCashRegisters;
  final CashRegister? selectedCashRegister;
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
    bool? isLoadingActive,
    List<CashRegister>? cashRegisterHistory,
    bool? isLoadingHistory,
    String? historyFilter,
    Object? errorMessage = const Object(),
    bool? isProcessing,
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

  // Form controllers
  final TextEditingController openDescriptionController =
      TextEditingController();
  final AppMoneyTextEditingController initialCashController = AppMoneyTextEditingController();
  final AppMoneyTextEditingController finalBalanceController = AppMoneyTextEditingController();
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
  CashRegister? get currentActiveCashRegister =>  _state.currentActiveCashRegister;

  CashRegisterProvider(this._cashRegisterUsecases);

  // ==========================================
  // MÉTODOS DE PERSISTENCIA
  // ==========================================

  /// Inicializa el provider cargando la caja seleccionada desde persistencia
  Future<void> initializeFromPersistence(String accountId) async {
    final persistenceService = CashRegisterPersistenceService.instance;
    
    // Cargar cajas activas
    await loadActiveCashRegisters(accountId);
    
    // Intentar cargar la caja seleccionada desde persistencia
    final savedCashRegisterId = await persistenceService.getSelectedCashRegisterId();
    if (savedCashRegisterId != null) {
      final savedCashRegister = _state.activeCashRegisters
          .where((cr) => cr.id == savedCashRegisterId)
          .firstOrNull;
      
      if (savedCashRegister != null) {
        _state = _state.copyWith(selectedCashRegister: savedCashRegister);
        notifyListeners();
      } else {
        // Si la caja guardada ya no existe, limpiar persistencia
        await persistenceService.clearSelectedCashRegisterId();
      }
    }
  }

  /// Selecciona una caja registradora y la guarda en persistencia
  Future<void> selectCashRegister(CashRegister cashRegister) async {
    final persistenceService = CashRegisterPersistenceService.instance;
    
    _state = _state.copyWith(selectedCashRegister: cashRegister);
    await persistenceService.saveSelectedCashRegisterId(cashRegister.id);
    notifyListeners();
  }

  /// Deselecciona la caja registradora actual y limpia persistencia
  Future<void> clearSelectedCashRegister() async {
    final persistenceService = CashRegisterPersistenceService.instance;
    
    _state = _state.copyWith(clearSelectedCashRegister: true);
    await persistenceService.clearSelectedCashRegisterId();
    notifyListeners();
  }

  // ==========================================
  // MÉTODOS PÚBLICOS - CAJAS ACTIVAS
  // ==========================================

  /// Carga las cajas registradoras activas
  Future<void> loadActiveCashRegisters(String accountId) async {
    // Mostrar indicador de carga
    _state = _state.copyWith(isLoadingActive: true, errorMessage: null);
    notifyListeners();

    try {
      // Limpiar estado previo
      final activeCashRegisters = await _cashRegisterUsecases.getActiveCashRegisters(accountId);
      _state = _state.copyWith(activeCashRegisters: activeCashRegisters);
    } catch (e) {
      _state = _state.copyWith(errorMessage: e.toString());
    } finally {
      _state = _state.copyWith(isLoadingActive: false);
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

      // Actualizar lista local y seleccionar automáticamente la nueva caja
      final updatedActiveCashRegisters = [..._state.activeCashRegisters, newCashRegister];
      _state = _state.copyWith(activeCashRegisters: updatedActiveCashRegisters);
      
      // Seleccionar automáticamente la nueva caja
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
  Future<bool> closeCashRegister(String accountId, String cashRegisterId) async {
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
      final closedCashRegister = await _cashRegisterUsecases.closeCashRegister(
        accountId: accountId,
        cashRegisterId: cashRegisterId,
        finalBalance: finalBalance,
      );

      // Actualizar listas locales
      final updatedActiveCashRegisters = _state.activeCashRegisters
          .where((cr) => cr.id != cashRegisterId)
          .toList();
      
      _state = _state.copyWith(
        activeCashRegisters: updatedActiveCashRegisters,
        cashRegisterHistory: [
          closedCashRegister,
          ..._state.cashRegisterHistory
        ],
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

      // Recargar las cajas activas
      final activeCashRegisters =
          await _cashRegisterUsecases.getActiveCashRegisters(accountId);
      _state = _state.copyWith(activeCashRegisters: activeCashRegisters);

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

      // Recargar las cajas activas
      final activeCashRegisters =
          await _cashRegisterUsecases.getActiveCashRegisters(accountId);
      _state = _state.copyWith(activeCashRegisters: activeCashRegisters);

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

      // Recargar cajas activas para reflejar cambios
      await loadActiveCashRegisters(accountId);

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
      final descriptions =
          await _cashRegisterUsecases.getCashRegisterFixedDescriptions(accountId);
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

  /// Limpia todos los mensajes de error
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

  @override
  void dispose() {
    openDescriptionController.dispose();
    initialCashController.dispose();
    finalBalanceController.dispose();
    movementDescriptionController.dispose();
    movementAmountController.dispose();
    super.dispose();
  }
}
