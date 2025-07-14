import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../domain/entities/cash_register_model.dart';
import '../../domain/usecases/cash_register_usecases.dart';

class _CashRegisterState {
  final List<CashRegister> activeCashRegisters;
  final bool isLoadingActive;
  final List<CashRegister> cashRegisterHistory;
  final bool isLoadingHistory;
  final String historyFilter;
  final String? errorMessage;
  final bool isProcessing;
  final List<String> fixedDescriptions;

  const _CashRegisterState({
    this.activeCashRegisters = const [],
    this.isLoadingActive = false,
    this.cashRegisterHistory = const [],
    this.isLoadingHistory = false,
    this.historyFilter = 'Última semana',
    this.errorMessage,
    this.isProcessing = false,
    this.fixedDescriptions = const [],
  });

  bool get hasActiveCashRegister => activeCashRegisters.isNotEmpty;
  CashRegister? get currentActiveCashRegister =>
      activeCashRegisters.isNotEmpty ? activeCashRegisters.first : null;

  _CashRegisterState copyWith({
    List<CashRegister>? activeCashRegisters,
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
  final TextEditingController initialCashController = TextEditingController();
  final TextEditingController finalBalanceController = TextEditingController();
  final TextEditingController movementDescriptionController =
      TextEditingController();
  final TextEditingController movementAmountController =
      TextEditingController();

  // Immutable state
  _CashRegisterState _state = _CashRegisterState();

  // Public getters
  List<CashRegister> get activeCashRegisters => _state.activeCashRegisters;
  bool get isLoadingActive => _state.isLoadingActive;
  List<CashRegister> get cashRegisterHistory => _state.cashRegisterHistory;
  bool get isLoadingHistory => _state.isLoadingHistory;
  String get historyFilter => _state.historyFilter;
  String? get errorMessage => _state.errorMessage;
  bool get isProcessing => _state.isProcessing;
  List<String> get fixedDescriptions => _state.fixedDescriptions;
  bool get hasActiveCashRegister => _state.hasActiveCashRegister;
  CashRegister? get currentActiveCashRegister =>
      _state.currentActiveCashRegister;

  CashRegisterProvider(this._cashRegisterUsecases);

  // ==========================================
  // MÉTODOS PÚBLICOS - CAJAS ACTIVAS
  // ==========================================

  /// Carga las cajas registradoras activas
  Future<void> loadActiveCashRegisters(String accountId) async {
    _state = _state.copyWith(isLoadingActive: true, errorMessage: null);
    notifyListeners();

    try {
      final activeCashRegisters =
          await _cashRegisterUsecases.getActiveCashRegisters(accountId);
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

    final initialCash = double.tryParse(initialCashController.text) ?? 0.0;
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

      // Actualizar lista local
      _state = _state.copyWith(activeCashRegisters: [newCashRegister]);

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
    final finalBalance = double.tryParse(finalBalanceController.text) ?? 0.0;
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
      _state = _state.copyWith(
        activeCashRegisters: _state.activeCashRegisters
            .where((cr) => cr.id != cashRegisterId)
            .toList(),
        cashRegisterHistory: [
          closedCashRegister,
          ..._state.cashRegisterHistory
        ],
      );

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

    final amount = double.tryParse(movementAmountController.text) ?? 0.0;
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

    final amount = double.tryParse(movementAmountController.text) ?? 0.0;
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
        itemCount: itemCount,
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

  /// Carga las descripciones fijas
  Future<void> loadFixedDescriptions(String accountId) async {
    try {
      final descriptions =
          await _cashRegisterUsecases.getFixedDescriptions(accountId);
      _state = _state.copyWith(fixedDescriptions: descriptions);
      notifyListeners();
    } catch (e) {
      // Silenciosamente fallar para no interrumpir la UI
    }
  }

  /// Crea una nueva descripción fija
  Future<bool> createFixedDescription(
      String accountId, String description) async {
    try {
      await _cashRegisterUsecases.createFixedDescription(
        accountId: accountId,
        description: description,
      );

      // Recargar descripciones
      await loadFixedDescriptions(accountId);

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
