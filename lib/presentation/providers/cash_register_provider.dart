import 'package:flutter/material.dart';
import '../../domain/entities/cash_register_model.dart';
import '../../domain/usecases/cash_register_usecases.dart';

/// Provider para el sistema de caja registradora
/// 
/// Maneja el estado de:
/// - Cajas registradoras activas
/// - Historial de arqueos
/// - Flujos de caja
/// - Operaciones de apertura y cierre
class CashRegisterProvider extends ChangeNotifier {
  final CashRegisterUsecases _cashRegisterUsecases;

  CashRegisterProvider(this._cashRegisterUsecases);

  // ==========================================
  // ESTADO DE CAJAS ACTIVAS
  // ==========================================

  List<CashRegister> _activeCashRegisters = [];
  List<CashRegister> get activeCashRegisters => _activeCashRegisters;

  bool _isLoadingActive = false;
  bool get isLoadingActive => _isLoadingActive;

  CashRegister? get currentActiveCashRegister => 
      _activeCashRegisters.isNotEmpty ? _activeCashRegisters.first : null;

  bool get hasActiveCashRegister => _activeCashRegisters.isNotEmpty;

  // ==========================================
  // ESTADO DEL HISTORIAL
  // ==========================================

  List<CashRegister> _cashRegisterHistory = [];
  List<CashRegister> get cashRegisterHistory => _cashRegisterHistory;

  bool _isLoadingHistory = false;
  bool get isLoadingHistory => _isLoadingHistory;

  String _historyFilter = 'Última semana';
  String get historyFilter => _historyFilter;

  // ==========================================
  // ESTADO DE FORMULARIOS
  // ==========================================

  // Formulario de apertura
  final TextEditingController openDescriptionController = TextEditingController();
  final TextEditingController initialCashController = TextEditingController();

  // Formulario de cierre
  final TextEditingController finalBalanceController = TextEditingController();

  // Formulario de movimientos
  final TextEditingController movementDescriptionController = TextEditingController();
  final TextEditingController movementAmountController = TextEditingController();

  bool _isProcessing = false;
  bool get isProcessing => _isProcessing;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // ==========================================
  // DESCRIPCIONES FIJAS
  // ==========================================

  List<String> _fixedDescriptions = [];
  List<String> get fixedDescriptions => _fixedDescriptions;

  // ==========================================
  // MÉTODOS PÚBLICOS - CAJAS ACTIVAS
  // ==========================================

  /// Carga las cajas registradoras activas
  Future<void> loadActiveCashRegisters(String accountId) async {
    _isLoadingActive = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _activeCashRegisters = await _cashRegisterUsecases.getActiveCashRegisters(accountId);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoadingActive = false;
      notifyListeners();
    }
  }

  /// Abre una nueva caja registradora
  Future<bool> openCashRegister(String accountId, String cashierId) async {
    if (openDescriptionController.text.trim().isEmpty) {
      _errorMessage = 'La descripción es obligatoria';
      notifyListeners();
      return false;
    }

    final initialCash = double.tryParse(initialCashController.text) ?? 0.0;
    if (initialCash < 0) {
      _errorMessage = 'El monto inicial no puede ser negativo';
      notifyListeners();
      return false;
    }

    _isProcessing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final newCashRegister = await _cashRegisterUsecases.openCashRegister(
        accountId: accountId,
        description: openDescriptionController.text.trim(),
        initialCash: initialCash,
        cashierId: cashierId,
      );

      // Actualizar lista local
      _activeCashRegisters = [newCashRegister];
      
      // Limpiar formulario
      _clearOpenForm();
      
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  /// Cierra una caja registradora
  Future<bool> closeCashRegister(String accountId, String cashRegisterId) async {
    final finalBalance = double.tryParse(finalBalanceController.text) ?? 0.0;
    if (finalBalance < 0) {
      _errorMessage = 'El balance final no puede ser negativo';
      notifyListeners();
      return false;
    }

    _isProcessing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final closedCashRegister = await _cashRegisterUsecases.closeCashRegister(
        accountId: accountId,
        cashRegisterId: cashRegisterId,
        finalBalance: finalBalance,
      );

      // Actualizar listas locales
      _activeCashRegisters.removeWhere((cr) => cr.id == cashRegisterId);
      _cashRegisterHistory.insert(0, closedCashRegister);
      
      // Limpiar formulario
      _clearCloseForm();
      
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  // ==========================================
  // MÉTODOS PÚBLICOS - MOVIMIENTOS DE CAJA
  // ==========================================

  /// Registra un ingreso de caja
  Future<bool> addCashInflow(String accountId, String cashRegisterId, String userId) async {
    if (movementDescriptionController.text.trim().isEmpty) {
      _errorMessage = 'La descripción es obligatoria';
      notifyListeners();
      return false;
    }

    final amount = double.tryParse(movementAmountController.text) ?? 0.0;
    if (amount <= 0) {
      _errorMessage = 'El monto debe ser mayor a cero';
      notifyListeners();
      return false;
    }

    _isProcessing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _cashRegisterUsecases.addCashInflow(
        accountId: accountId,
        cashRegisterId: cashRegisterId,
        description: movementDescriptionController.text.trim(),
        amount: amount,
        userId: userId,
      );

      // Recargar cajas activas para reflejar cambios
      await loadActiveCashRegisters(accountId);
      
      // Limpiar formulario
      _clearMovementForm();
      
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  /// Registra un egreso de caja
  Future<bool> addCashOutflow(String accountId, String cashRegisterId, String userId) async {
    if (movementDescriptionController.text.trim().isEmpty) {
      _errorMessage = 'La descripción es obligatoria';
      notifyListeners();
      return false;
    }

    final amount = double.tryParse(movementAmountController.text) ?? 0.0;
    if (amount <= 0) {
      _errorMessage = 'El monto debe ser mayor a cero';
      notifyListeners();
      return false;
    }

    _isProcessing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _cashRegisterUsecases.addCashOutflow(
        accountId: accountId,
        cashRegisterId: cashRegisterId,
        description: movementDescriptionController.text.trim(),
        amount: amount,
        userId: userId,
      );

      // Recargar cajas activas para reflejar cambios
      await loadActiveCashRegisters(accountId);
      
      // Limpiar formulario
      _clearMovementForm();
      
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isProcessing = false;
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
      _errorMessage = 'No hay una caja registradora activa';
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
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ==========================================
  // MÉTODOS PÚBLICOS - HISTORIAL
  // ==========================================

  /// Carga el historial de arqueos según el filtro seleccionado
  Future<void> loadCashRegisterHistory(String accountId) async {
    _isLoadingHistory = true;
    _errorMessage = null;
    notifyListeners();

    try {
      switch (_historyFilter) {
        case 'Última semana':
          _cashRegisterHistory = await _cashRegisterUsecases.getLastWeekCashRegisters(accountId);
          break;
        case 'Último mes':
          _cashRegisterHistory = await _cashRegisterUsecases.getLastMonthCashRegisters(accountId);
          break;
        case 'Mes anterior':
          _cashRegisterHistory = await _cashRegisterUsecases.getPreviousMonthCashRegisters(accountId);
          break;
        case 'Hoy':
          _cashRegisterHistory = await _cashRegisterUsecases.getTodayCashRegisters(accountId);
          break;
        default:
          _cashRegisterHistory = await _cashRegisterUsecases.getCashRegisterHistory(accountId);
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoadingHistory = false;
      notifyListeners();
    }
  }

  /// Cambia el filtro del historial
  void setHistoryFilter(String filter) {
    _historyFilter = filter;
    notifyListeners();
  }

  // ==========================================
  // MÉTODOS PÚBLICOS - DESCRIPCIONES FIJAS
  // ==========================================

  /// Carga las descripciones fijas
  Future<void> loadFixedDescriptions(String accountId) async {
    try {
      _fixedDescriptions = await _cashRegisterUsecases.getFixedDescriptions(accountId);
      notifyListeners();
    } catch (e) {
      // Silenciosamente fallar para no interrumpir la UI
    }
  }

  /// Crea una nueva descripción fija
  Future<bool> createFixedDescription(String accountId, String description) async {
    try {
      await _cashRegisterUsecases.createFixedDescription(
        accountId: accountId,
        description: description,
      );
      
      // Recargar descripciones
      await loadFixedDescriptions(accountId);
      
      return true;
    } catch (e) {
      _errorMessage = e.toString();
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
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Limpia todos los mensajes de error
  void clearError() {
    _errorMessage = null;
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
