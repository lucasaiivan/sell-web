import 'dart:async';
import 'package:rxdart/rxdart.dart'; // ✅ Necesario para combinar streams
import 'package:fpdart/fpdart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';
import 'package:sellweb/core/core.dart';
import 'package:sellweb/core/services/storage/app_data_persistence_service.dart';
import 'package:sellweb/features/cash_register/domain/entities/cash_register.dart';
import 'package:sellweb/features/cash_register/domain/entities/cash_register_metrics.dart';
import 'package:sellweb/features/sales/domain/entities/ticket_model.dart';
import 'package:sellweb/core/presentation/providers/initializable_provider.dart';

// UseCases
import '../../domain/usecases/open_cash_register_usecase.dart';
import '../../domain/usecases/close_cash_register_usecase.dart';
import '../../domain/usecases/get_active_cash_registers_usecase.dart';
import '../../domain/usecases/get_active_cash_registers_stream_usecase.dart';
import '../../domain/usecases/add_cash_inflow_usecase.dart';
import '../../domain/usecases/add_cash_outflow_usecase.dart';
import '../../domain/usecases/update_sales_and_billing_usecase.dart';
import '../../domain/usecases/get_cash_register_history_usecase.dart';
import '../../domain/usecases/get_cash_register_by_days_usecase.dart';
import '../../domain/usecases/get_cash_register_by_date_range_usecase.dart';
import '../../domain/usecases/process_ticket_annullment_usecase.dart';
import '../../domain/usecases/create_cash_register_fixed_description_usecase.dart';
import '../../domain/usecases/get_cash_register_fixed_descriptions_usecase.dart';
import '../../domain/usecases/delete_cash_register_fixed_description_usecase.dart';
import '../../domain/usecases/get_today_transactions_stream_usecase.dart';
import '../../domain/usecases/get_transactions_by_date_range_usecase.dart';
import '../../domain/usecases/save_ticket_to_transaction_history_usecase.dart';
import '../../domain/usecases/calculate_cash_register_metrics_usecase.dart';
import '../../../../core/services/demo_account/demo_account_service.dart';

/// Extension helper para firstOrNull si no está disponible
extension ListExtensions<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

/// Estado inmutable del provider de caja registradora
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
  final Map<String, bool> expandedMonths;
  final CashRegisterMetrics? cachedMetrics; // ✅ OPTIMIZACIÓN: Caché de métricas

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
    this.expandedMonths = const {},
    this.cachedMetrics,
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
    Map<String, bool>? expandedMonths,
    CashRegisterMetrics? cachedMetrics,
    bool clearCachedMetrics = false,
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
      expandedMonths: expandedMonths ?? this.expandedMonths,
      cachedMetrics: clearCachedMetrics ? null : (cachedMetrics ?? this.cachedMetrics),
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

/// Provider para gestionar el estado de cajas registradoras
@injectable
class CashRegisterProvider extends ChangeNotifier
    implements InitializableProvider {
  // UseCases
  final OpenCashRegisterUseCase _openCashRegisterUseCase;
  final CloseCashRegisterUseCase _closeCashRegisterUseCase;
  final GetActiveCashRegistersUseCase _getActiveCashRegistersUseCase;
  final GetActiveCashRegistersStreamUseCase
      _getActiveCashRegistersStreamUseCase;
  final AddCashInflowUseCase _addCashInflowUseCase;
  final AddCashOutflowUseCase _addCashOutflowUseCase;
  final UpdateSalesAndBillingUseCase _updateSalesAndBillingUseCase;
  final GetCashRegisterHistoryUseCase _getCashRegisterHistoryUseCase;
  final GetCashRegisterByDaysUseCase _getCashRegisterByDaysUseCase;
  final GetCashRegisterByDateRangeUseCase _getCashRegisterByDateRangeUseCase;
  final ProcessTicketAnnullmentUseCase _processTicketAnnullmentUseCase;
  final CreateCashRegisterFixedDescriptionUseCase
      _createCashRegisterFixedDescriptionUseCase;
  final GetCashRegisterFixedDescriptionsUseCase
      _getCashRegisterFixedDescriptionsUseCase;
  final DeleteCashRegisterFixedDescriptionUseCase
      _deleteCashRegisterFixedDescriptionUseCase;
  final GetTodayTransactionsStreamUseCase _getTodayTransactionsStreamUseCase;
  final GetTransactionsByDateRangeUseCase _getTransactionsByDateRangeUseCase;
  final SaveTicketToTransactionHistoryUseCase
      _saveTicketToTransactionHistoryUseCase;
  final CalculateCashRegisterMetricsUseCase _calculateMetricsUseCase;
  final AppDataPersistenceService _persistenceService;

  // Stream subscriptions
  StreamSubscription<List<CashRegister>>? _activeCashRegistersSubscription;
  StreamSubscription<CashRegisterMetrics>? _metricsSubscription;
  String? _currentAccountId;
  bool _disposed = false;

  // Tickets management
  Future<List<TicketModel>?>? _cashRegisterTickets;
  String? _cachedCashRegisterId;
  bool _isLoadingTickets = false;

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
  final TextEditingController noteController =
      TextEditingController(); // Notas de cierre de caja


  // Immutable state
  _CashRegisterState _state = const _CashRegisterState();

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
  
  /// Métricas cacheadas de la caja activa actual
  /// ✅ OPTIMIZACIÓN: Acceso inmediato sin esperar al stream
  CashRegisterMetrics? get cachedMetrics => _state.cachedMetrics;

  Future<List<TicketModel>?>? get cashRegisterTickets => _cashRegisterTickets;
  bool get isLoadingTickets => _isLoadingTickets;

  /// Verifica si un mes está expandido
  bool isMonthExpanded(String monthKey) {
    return _state.expandedMonths[monthKey] ?? false; // Por defecto colapsado
  }

  /// Alterna el estado de expansión de un mes
  void toggleMonthExpansion(String monthKey) {
    final currentExpanded = _state.expandedMonths[monthKey] ?? false;
    final newExpandedMonths = Map<String, bool>.from(_state.expandedMonths);
    newExpandedMonths[monthKey] = !currentExpanded;

    _state = _state.copyWith(expandedMonths: newExpandedMonths);
    notifyListeners();
  }

  @override
  void notifyListeners() {
    if (!_disposed) {
      super.notifyListeners();
    }
  }

  CashRegisterProvider(
    this._openCashRegisterUseCase,
    this._closeCashRegisterUseCase,
    this._getActiveCashRegistersUseCase,
    this._getActiveCashRegistersStreamUseCase,
    this._addCashInflowUseCase,
    this._addCashOutflowUseCase,
    this._updateSalesAndBillingUseCase,
    this._getCashRegisterHistoryUseCase,
    this._getCashRegisterByDaysUseCase,
    this._getCashRegisterByDateRangeUseCase,
    this._processTicketAnnullmentUseCase,
    this._createCashRegisterFixedDescriptionUseCase,
    this._getCashRegisterFixedDescriptionsUseCase,
    this._deleteCashRegisterFixedDescriptionUseCase,
    this._getTodayTransactionsStreamUseCase,
    this._getTransactionsByDateRangeUseCase,
    this._saveTicketToTransactionHistoryUseCase,
    this._calculateMetricsUseCase,
    this._persistenceService,
  );

  @override
  void dispose() {
    _disposed = true;
    _activeCashRegistersSubscription?.cancel();
    _metricsSubscription?.cancel();
    openDescriptionController.dispose();
    initialCashController.dispose();
    finalBalanceController.dispose();
    movementDescriptionController.dispose();
    movementAmountController.dispose();
    noteController.dispose();
    super.dispose();
  }

  /// Suscribe automáticamente al stream de métricas para mantener el caché actualizado
  /// ✅ OPTIMIZACIÓN: El caché se actualiza en tiempo real cuando cambian los datos
  void _subscribeToMetricsStream(String accountId) {
    final cashRegister = currentActiveCashRegister;
    if (cashRegister == null || accountId.isEmpty) {
      _metricsSubscription?.cancel();
      _metricsSubscription = null;
      return;
    }

    // Cancelar suscripción anterior si existe
    _metricsSubscription?.cancel();

    // Suscribirse al stream de métricas
    _metricsSubscription = getCashRegisterMetricsStream(
      accountId: accountId,
    ).listen(
      (metrics) {
        // El caché ya se actualiza dentro de getCashRegisterMetricsStream
        // Pero aseguramos notificar listeners para que el UI se actualice
        notifyListeners();
      },
      onError: (_) {
        // Ignorar errores silenciosamente para no interrumpir el flujo
      },
    );
  }

  /// Implementación de InitializableProvider: Inicializa el provider para una cuenta
  @override
  Future<void> initialize(String accountId) async {
    return initializeFromPersistence(accountId);
  }

  /// Implementación de InitializableProvider: Limpia recursos y cancela suscripciones
  ///
  /// **CRÍTICO:** Cancela suscripciones activas para evitar
  /// errores de "used after being disposed" al cambiar de cuenta o cerrar sesión
  @override
  void cleanup() {
    // Cancelar suscripción a cajas activas
    _activeCashRegistersSubscription?.cancel();
    _activeCashRegistersSubscription = null;

    // Resetear estado pero mantener controllers (se reutilizarán)
    _state = const _CashRegisterState();
    _currentAccountId = null;
    _cashRegisterTickets = null;
    _cachedCashRegisterId = null;
    _isLoadingTickets = false;

    // No notificar listeners si ya está disposed
    try {
      notifyListeners();
    } catch (e) {
      debugPrint('⚠️ CashRegisterProvider.cleanup: Provider ya disposed');
    }
  }

  void clearError() {
    _state = _state.copyWith(errorMessage: null);
    notifyListeners();
  }

  // ==========================================
  // MÉTODOS DE PERSISTENCIA
  // ==========================================

  Future<void> initializeFromPersistence(String accountId) async {
    if (accountId.isEmpty) return;
    if (_disposed) return;

    try {
      await _loadActiveCashRegistersAndWait(accountId);

      if (_state.activeCashRegisters.isEmpty) {
        try {
          final result = await _getActiveCashRegistersUseCase(
              GetActiveCashRegistersParams(accountId));

          result.fold(
            (failure) {},
            (directCashRegisters) {
              if (directCashRegisters.isNotEmpty) {
                _state = _state.copyWith(
                  activeCashRegisters: directCashRegisters,
                  isLoadingActive: false,
                );
                notifyListeners();
              }
            },
          );
        } catch (_) {}
      }

      final savedCashRegisterId =
          await _persistenceService.getSelectedCashRegisterId();

      if (savedCashRegisterId != null && savedCashRegisterId.isNotEmpty) {
        final savedCashRegister = _state.activeCashRegisters
            .where((cr) => cr.id == savedCashRegisterId)
            .firstOrNull;
        if (savedCashRegister != null) {
          _state = _state.copyWith(selectedCashRegister: savedCashRegister);
          // ✅ Suscribirse al stream de métricas para mantener caché actualizado
          _subscribeToMetricsStream(accountId);
          notifyListeners();
        } else {
          await _persistenceService.clearSelectedCashRegisterId();
        }
      }
    } catch (e) {
      _state = _state.copyWith(errorMessage: e.toString());
      notifyListeners();
    }
  }

  Future<void> _loadActiveCashRegistersAndWait(String accountId) async {
    if (_currentAccountId == accountId &&
        _activeCashRegistersSubscription != null) {
      await Future.delayed(const Duration(milliseconds: 500));
      return;
    }

    await _activeCashRegistersSubscription?.cancel();
    _currentAccountId = accountId;

    _state = _state.copyWith(isLoadingActive: true, errorMessage: null);
    notifyListeners();

    final completer = Completer<void>();
    bool firstDataReceived = false;

    try {
      _activeCashRegistersSubscription = _getActiveCashRegistersStreamUseCase(
              GetActiveCashRegistersStreamParams(accountId))
          .listen(
        (activeCashRegisters) {
          _state = _state.copyWith(
            activeCashRegisters: activeCashRegisters,
            isLoadingActive: false,
            errorMessage: null,
          );

          if (_state.selectedCashRegister != null) {
            final updatedSelectedCashRegister = activeCashRegisters
                .where((cr) => cr.id == _state.selectedCashRegister!.id)
                .firstOrNull;

            if (updatedSelectedCashRegister != null) {
              _state = _state.copyWith(
                selectedCashRegister: updatedSelectedCashRegister,
              );
            } else {
              clearSelectedCashRegister();
            }
          }

          notifyListeners();

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

  Future<void> selectCashRegister(CashRegister cashRegister) async {
    try {
      clearTicketsCache();
      _state = _state.copyWith(selectedCashRegister: cashRegister);
      // ✅ Suscribirse al stream de métricas para mantener caché actualizado
      if (_currentAccountId != null) {
        _subscribeToMetricsStream(_currentAccountId!);
      }
      notifyListeners();
      await _persistenceService.saveSelectedCashRegisterId(cashRegister.id);
    } catch (e) {
      _state = _state.copyWith(clearSelectedCashRegister: true);
      notifyListeners();
      rethrow;
    }
  }

  Future<void> clearSelectedCashRegister() async {
    try {
      _state = _state.copyWith(clearSelectedCashRegister: true);
      clearTicketsCache();
      notifyListeners();
      await _persistenceService.clearSelectedCashRegisterId();
    } catch (e) {
      _state = _state.copyWith(errorMessage: 'Error al limpiar selección: $e');
      notifyListeners();
    }
  }

  // ==========================================
  // MÉTODOS PÚBLICOS - CAJAS ACTIVAS
  // ==========================================

  Future<void> loadActiveCashRegisters(String accountId) async {
    if (_currentAccountId == accountId &&
        _activeCashRegistersSubscription != null) {
      return;
    }

    await _activeCashRegistersSubscription?.cancel();
    _currentAccountId = accountId;

    _state = _state.copyWith(isLoadingActive: true, errorMessage: null);
    notifyListeners();

    try {
      _activeCashRegistersSubscription = _getActiveCashRegistersStreamUseCase(
              GetActiveCashRegistersStreamParams(accountId))
          .listen(
        (activeCashRegisters) {
          _state = _state.copyWith(
            activeCashRegisters: activeCashRegisters,
            isLoadingActive: false,
            errorMessage: null,
          );

          if (_state.selectedCashRegister != null) {
            final updatedSelectedCashRegister = activeCashRegisters
                .where((cr) => cr.id == _state.selectedCashRegister!.id)
                .firstOrNull;

            if (updatedSelectedCashRegister != null) {
              _state = _state.copyWith(
                selectedCashRegister: updatedSelectedCashRegister,
              );
            } else {
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

  Future<bool> openCashRegister({
    required String accountId,
    required String cashierId,
    required String cashierName,
  }) async {
    _state = _state.copyWith(isProcessing: true, errorMessage: null);
    notifyListeners();

    final result = await _openCashRegisterUseCase(OpenCashRegisterParams(
      accountId: accountId,
      description: openDescriptionController.text,
      initialCash: initialCashController.doubleValue,
      cashierId: cashierId,
      cashierName: cashierName,
    ));

    return result.fold(
      (failure) {
        _state =
            _state.copyWith(isProcessing: false, errorMessage: failure.message);
        notifyListeners();
        return false;
      },
      (newCashRegister) async {
        await selectCashRegister(newCashRegister);
        _clearOpenForm();
        _state = _state.copyWith(isProcessing: false);
        notifyListeners();
        return true;
      },
    );
  }

  Future<bool> closeCashRegister(
      String accountId, String cashRegisterId) async {
    _state = _state.copyWith(isProcessing: true, errorMessage: null);
    notifyListeners();

    try {
      // Obtener transacciones reales de hoy para validar contadores
      final todayTickets = await _getTodayTransactionsStreamUseCase(
        accountId: accountId,
        cashRegisterId: cashRegisterId,
      ).first;

      final effectiveSales =
          todayTickets.where((ticket) => ticket['annulled'] != true).length;

      final annulledCount =
          todayTickets.where((ticket) => ticket['annulled'] == true).length;

      final totalTransactions = effectiveSales + annulledCount;

      if (_state.selectedCashRegister != null && totalTransactions > 0) {
        final currentSales = _state.selectedCashRegister!.sales;
        final currentAnnulled = _state.selectedCashRegister!.annulledTickets;

        final salesNeedsUpdate = currentSales != effectiveSales;
        final annulledNeedsUpdate = currentAnnulled != annulledCount;

        if (salesNeedsUpdate || annulledNeedsUpdate) {
          final updatedCashRegister = _state.selectedCashRegister!.update(
            sales: effectiveSales,
            annulledTickets: annulledCount,
          );

          _state = _state.copyWith(selectedCashRegister: updatedCashRegister);
        }
      }

      final result = await _closeCashRegisterUseCase(CloseCashRegisterParams(
        accountId: accountId,
        cashRegisterId: cashRegisterId,
        finalBalance: finalBalanceController.doubleValue,
        note: noteController.text.trim().isNotEmpty ? noteController.text.trim() : null,
      ));

      return result.fold(
        (failure) {
          _state = _state.copyWith(
              isProcessing: false, errorMessage: failure.message);
          notifyListeners();
          return false;
        },
        (_) async {
          await clearSelectedCashRegister();
          _clearCloseForm();
          _state = _state.copyWith(isProcessing: false);
          notifyListeners();
          return true;
        },
      );
    } catch (e) {
      _state = _state.copyWith(
          isProcessing: false, errorMessage: 'Error inesperado: $e');
      notifyListeners();
      return false;
    }
  }

  // ==========================================
  // MÉTODOS PÚBLICOS - MOVIMIENTOS DE CAJA
  // ==========================================

  Future<bool> addCashInflow(
      String accountId, String cashRegisterId, String userId) async {
    _state = _state.copyWith(isProcessing: true, errorMessage: null);
    notifyListeners();

    final cashFlow = CashFlow(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      description: movementDescriptionController.text,
      amount: movementAmountController.doubleValue,
      date: DateTime.now(),
    );

    final result = await _addCashInflowUseCase(AddCashInflowParams(
      accountId: accountId,
      cashRegisterId: cashRegisterId,
      cashFlow: cashFlow,
    ));

    return result.fold(
      (failure) {
        _state =
            _state.copyWith(isProcessing: false, errorMessage: failure.message);
        notifyListeners();
        return false;
      },
      (_) {
        _clearMovementForm();
        // ✅ Invalidar caché para forzar recálculo de métricas
        _state = _state.copyWith(isProcessing: false, clearCachedMetrics: true);
        notifyListeners();
        return true;
      },
    );
  }

  Future<bool> addCashOutflow(
      String accountId, String cashRegisterId, String userId) async {
    _state = _state.copyWith(isProcessing: true, errorMessage: null);
    notifyListeners();

    final cashFlow = CashFlow(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      description: movementDescriptionController.text,
      amount: movementAmountController.doubleValue,
      date: DateTime.now(),
    );

    final result = await _addCashOutflowUseCase(AddCashOutflowParams(
      accountId: accountId,
      cashRegisterId: cashRegisterId,
      cashFlow: cashFlow,
    ));

    return result.fold(
      (failure) {
        _state =
            _state.copyWith(isProcessing: false, errorMessage: failure.message);
        notifyListeners();
        return false;
      },
      (_) {
        _clearMovementForm();
        // ✅ Invalidar caché para forzar recálculo de métricas
        _state = _state.copyWith(isProcessing: false, clearCachedMetrics: true);
        notifyListeners();
        return true;
      },
    );
  }

  Future<bool> cashRegisterSale({
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

    final result =
        await _updateSalesAndBillingUseCase(UpdateSalesAndBillingParams(
      accountId: accountId,
      cashRegisterId: currentActiveCashRegister!.id,
      billingIncrement: saleAmount,
      discountIncrement: discountAmount,
    ));

    return result.fold(
      (failure) {
        _state = _state.copyWith(errorMessage: failure.message);
        notifyListeners();
        return false;
      },
      (_) => true,
    );
  }

  // ==========================================
  // MÉTODOS PÚBLICOS - GESTIÓN DE TICKETS
  // ==========================================

  Future<void> loadCashRegisterTickets({
    required String accountId,
    bool forceReload = false,
  }) async {
    final cashRegisterId = currentActiveCashRegister?.id ?? '';

    if (cashRegisterId.isEmpty || accountId.isEmpty) {
      _cashRegisterTickets = Future.value(null);
      _cachedCashRegisterId = null;
      scheduleMicrotask(() {
        notifyListeners();
      });
      return;
    }

    if (forceReload ||
        _cachedCashRegisterId != cashRegisterId ||
        _cashRegisterTickets == null) {
      _cachedCashRegisterId = cashRegisterId;
      _isLoadingTickets = true;

      scheduleMicrotask(() {
        notifyListeners();
      });

      _cashRegisterTickets = getCashRegisterTickets(
        accountId: accountId,
        cashRegisterId: cashRegisterId,
        todayOnly: false,
      );

      await _cashRegisterTickets;
      _isLoadingTickets = false;

      scheduleMicrotask(() {
        notifyListeners();
      });
    }
  }

  Future<void> reloadTickets({required String accountId}) async {
    await loadCashRegisterTickets(accountId: accountId, forceReload: true);
  }

  void clearTicketsCache() {
    _cashRegisterTickets = null;
    _cachedCashRegisterId = null;
    _isLoadingTickets = false;
    notifyListeners();
  }

  // ==========================================
  // MÉTODOS PÚBLICOS - HISTORIAL
  // ==========================================

  Future<void> loadCashRegisterHistory(String accountId) async {
    _state = _state.copyWith(isLoadingHistory: true, errorMessage: null);
    notifyListeners();

    try {
      List<CashRegister> history = [];
      
      // Detectar modo demo
      if (accountId == 'demo') {
        // En modo demo, por defecto mostramos TODO el historial si el filtro es el default ('Última semana')
        // para asegurar que el usuario vea la riqueza de los datos generados
        if (_state.historyFilter == 'Última semana') {
            _state = _state.copyWith(historyFilter: 'Todo');
        }
        
        history = _loadDemoCashRegisterHistory();
        _state = _state.copyWith(
          cashRegisterHistory: history,
          isLoadingHistory: false,
        );
      } else {
        // Modo Firebase
        Either<Failure, List<CashRegister>> result;

        switch (_state.historyFilter) {
          case 'Última semana':
            result = await _getCashRegisterByDaysUseCase(
                GetCashRegisterByDaysParams(accountId: accountId, days: 7));
            break;
          case 'Último mes':
            result = await _getCashRegisterByDaysUseCase(
                GetCashRegisterByDaysParams(accountId: accountId, days: 30));
            break;
          case 'Mes anterior':
            final now = DateTime.now();
            final endDate = DateTime(now.year, now.month, 1);
            final startDate = DateTime(now.year, now.month - 1, 1);
            result = await _getCashRegisterByDateRangeUseCase(
                GetCashRegisterByDateRangeParams(
                    accountId: accountId,
                    startDate: startDate,
                    endDate: endDate));
            break;
          case 'Todo':
            result = await _getCashRegisterHistoryUseCase(
                GetCashRegisterHistoryParams(accountId));
            break;
          default:
            result = await _getCashRegisterByDaysUseCase(
                GetCashRegisterByDaysParams(accountId: accountId, days: 7));
        }

        result.fold(
          (failure) {
            _state = _state.copyWith(
              errorMessage: failure.message,
              isLoadingHistory: false,
            );
          },
          (data) {
            history = data;
            _state = _state.copyWith(
              cashRegisterHistory: history,
              isLoadingHistory: false,
            );
          },
        );
      }
    } catch (e) {
      _state = _state.copyWith(
        errorMessage: e.toString(),
        isLoadingHistory: false,
      );
    }
    notifyListeners();
  }

  /// Carga datos demo de arqueos con filtros de fecha aplicados
  List<CashRegister> _loadDemoCashRegisterHistory() {
    final allDemoRegisters = DemoAccountService().cashRegisters;
    
    // Si estamos en demo y el filtro es el por defecto (Semana), cambiar a Todo para mostrar la riqueza de datos
    // O simplemente retornar todo si el filtro es 'Todo'
    
    // Aplicar filtros de fecha
    final now = DateTime.now();
    switch (_state.historyFilter) {
      case 'Última semana':
        final cutoff = now.subtract(const Duration(days: 7));
        return allDemoRegisters
            .where((cr) => cr.opening.isAfter(cutoff))
            .toList();
      
      case 'Último mes':
        final cutoff = now.subtract(const Duration(days: 30));
        return allDemoRegisters
            .where((cr) => cr.opening.isAfter(cutoff))
            .toList();
      
      case 'Mes anterior':
        final endDate = DateTime(now.year, now.month, 1);
        final startDate = DateTime(now.year, now.month - 1, 1);
        return allDemoRegisters
            .where((cr) => cr.opening.isAfter(startDate) && cr.opening.isBefore(endDate))
            .toList();
      
      case 'Todo':
      default:
        // Ordenar por fecha descendente (lo más nuevo primero)
        allDemoRegisters.sort((a, b) => b.opening.compareTo(a.opening));
        return allDemoRegisters;
    }
  }

  void setHistoryFilter(String filter, String accountId) {
    if (_state.historyFilter != filter) {
      _state = _state.copyWith(historyFilter: filter);
      loadCashRegisterHistory(accountId);
    }
  }

  // ==========================================
  // MÉTODOS PÚBLICOS - DESCRIPCIONES FIJAS
  // ==========================================

  Future<void> loadFixedDescriptions(String accountId) async {
    try {
      final result = await _getCashRegisterFixedDescriptionsUseCase(
          GetCashRegisterFixedDescriptionsParams(accountId: accountId));
      result.fold(
        (failure) {},
        (descriptions) {
          final list = descriptions
              .map((desc) => desc['description'] as String? ?? '')
              .where((desc) => desc.isNotEmpty)
              .toList();
          _state = _state.copyWith(fixedDescriptions: list);
          notifyListeners();
        },
      );
    } catch (e) {
      // Silencioso
    }
  }

  Future<void> addFixedDescription(String accountId, String description) async {
    try {
      final result = await _createCashRegisterFixedDescriptionUseCase(
          CreateCashRegisterFixedDescriptionParams(
              accountId: accountId, description: description));
      result.fold(
        (failure) {
          _state = _state.copyWith(errorMessage: failure.message);
          notifyListeners();
        },
        (_) async {
          await loadFixedDescriptions(accountId);
        },
      );
    } catch (e) {
      _state = _state.copyWith(errorMessage: e.toString());
      notifyListeners();
    }
  }

  Future<void> deleteFixedDescription(
      String accountId, String description) async {
    try {
      final result = await _deleteCashRegisterFixedDescriptionUseCase(
          DeleteCashRegisterFixedDescriptionParams(
              accountId: accountId, descriptionId: description));
      result.fold(
        (failure) {
          _state = _state.copyWith(errorMessage: failure.message);
          notifyListeners();
        },
        (_) async {
          await loadFixedDescriptions(accountId);
        },
      );
    } catch (e) {
      _state = _state.copyWith(errorMessage: e.toString());
      notifyListeners();
    }
  }

  // ==========================================
  // MÉTODOS PÚBLICOS - API ALIASES PARA DIALOGS
  // ==========================================

  /// Alias para loadFixedDescriptions - usado por dialogs
  Future<void> loadCashRegisterFixedDescriptions(String accountId) async {
    await loadFixedDescriptions(accountId);
  }

  /// Alias para addFixedDescription - usado por dialogs
  Future<bool> createCashRegisterFixedDescription(
      String accountId, String description) async {
    try {
      await addFixedDescription(accountId, description);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Alias para deleteFixedDescription - usado por dialogs
  Future<bool> deleteCashRegisterFixedDescription(
      String accountId, String description) async {
    try {
      await deleteFixedDescription(accountId, description);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Stream de tickets para una caja registradora específica
  ///
  /// Usado por dialogs para mostrar tickets en tiempo real
  /// Filtra las transacciones por cashRegisterId desde la apertura de la caja
  Stream<List<TicketModel>> getCashRegisterTicketsStream({
    required String accountId,
    required String cashRegisterId,
  }) async* {
    try {
      // Obtener la caja registradora para determinar si es activa o histórica
      final activeCashRegister = _state.activeCashRegisters
          .where((cr) => cr.id == cashRegisterId)
          .firstOrNull;

      if (activeCashRegister != null) {
        // Si es caja activa, cargar por rango de fechas desde apertura hasta ahora
        // Emitir una carga inicial
        final start = activeCashRegister.opening;
        final end = DateTime.now();

        final result = await _getTransactionsByDateRangeUseCase(
          GetTransactionsByDateRangeParams(
            accountId: accountId,
            startDate: start,
            endDate: end,
          ),
        );

        final tickets = result.fold(
          (failure) => <TicketModel>[],
          (data) => data
              .where((t) => t['cashRegisterId'] == cashRegisterId)
              .map((t) => TicketModel.fromMap(t))
              .toList(),
        );

        yield tickets;

        // Luego escuchar cambios en tiempo real solo para hoy
        // (las transacciones nuevas siempre serán de hoy)
        yield* _getTodayTransactionsStreamUseCase(
          accountId: accountId,
          cashRegisterId: cashRegisterId,
        ).asyncMap((todayTransactions) async {
          // Combinar con transacciones históricas si la caja no se abrió hoy
          final today = DateTime.now();
          final isOpenedToday = activeCashRegister.opening.year == today.year &&
              activeCashRegister.opening.month == today.month &&
              activeCashRegister.opening.day == today.day;

          if (isOpenedToday) {
            // Si se abrió hoy, solo mostrar las de hoy
            return todayTransactions
                .map((t) => TicketModel.fromMap(t))
                .toList();
          } else {
            // Si se abrió en días anteriores, combinar históricas + hoy
            final historicalResult = await _getTransactionsByDateRangeUseCase(
              GetTransactionsByDateRangeParams(
                accountId: accountId,
                startDate: start,
                endDate: DateTime(today.year, today.month, today.day),
              ),
            );

            final historicalTickets = historicalResult.fold(
              (failure) => <TicketModel>[],
              (data) => data
                  .where((t) => t['cashRegisterId'] == cashRegisterId)
                  .map((t) => TicketModel.fromMap(t))
                  .toList(),
            );

            final todayTickets =
                todayTransactions.map((t) => TicketModel.fromMap(t)).toList();

            return [...historicalTickets, ...todayTickets];
          }
        });
      } else {
        // Si es caja histórica, cargar por rango de fechas
        final end = DateTime.now();
        final start = end.subtract(const Duration(days: 30));
        final result = await _getTransactionsByDateRangeUseCase(
          GetTransactionsByDateRangeParams(
            accountId: accountId,
            startDate: start,
            endDate: end,
          ),
        );

        final tickets = result.fold(
          (failure) => <TicketModel>[],
          (data) => data
              .where((t) => t['cashRegisterId'] == cashRegisterId)
              .map((t) => TicketModel.fromMap(t))
              .toList(),
        );

        yield tickets;
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error obteniendo stream de tickets: $e');
      }
      yield [];
    }
  }

  // ==========================================
  // MÉTRICAS CENTRALIZADAS
  // ==========================================

  /// Stream de métricas centralizadas para la caja registradora activa.
  ///
  /// **Responsabilidad:**
  /// - Combinar datos de [CashRegister] con tickets para producir [CashRegisterMetrics]
  /// - Emitir nuevas métricas cuando los tickets o la caja cambien
  ///
  /// **Uso en UI:**
  /// ```dart
  /// StreamBuilder<CashRegisterMetrics>(
  ///   stream: provider.getCashRegisterMetricsStream(accountId: accountId),
  ///   builder: (context, snapshot) => ...
  /// )
  /// ```
  Stream<CashRegisterMetrics> getCashRegisterMetricsStream({
    required String accountId,
  }) {
    final initialCashRegister = currentActiveCashRegister;
    if (initialCashRegister == null || accountId.isEmpty) {
      return Stream.value(CashRegisterMetrics.empty());
    }

    // 1. Stream de la caja registradora (filtrado de todas las activas)
    // Esto asegura que detectemos cambios en cashInFlow, cashOutFlow, etc.
    final cashRegisterStream = _getActiveCashRegistersStreamUseCase(
      GetActiveCashRegistersStreamParams(accountId)
    ).map((activeRegisters) {
      return activeRegisters
          .where((cr) => cr.id == initialCashRegister.id)
          .firstOrNull ?? initialCashRegister;
    });

    // 2. Stream de tickets
    final ticketsStream = getCashRegisterTicketsStream(
      accountId: accountId,
      cashRegisterId: initialCashRegister.id,
    );
    
    // 3. Combinar ambos streams
    // ✅ CORRECCIÓN: Ahora recalculamos si cambian los tickets O la caja
    return Rx.combineLatest2<CashRegister, List<TicketModel>, CashRegisterMetrics>(
      cashRegisterStream,
      ticketsStream,
      (cashRegister, tickets) {
        // ✅ ARQUITECTURA: Calcular métricas con ambos datos actualizados
        final metrics = _calculateMetricsUseCase(
          cashRegister: cashRegister,
          tickets: tickets,
        );
        
        // ✅ OPTIMIZACIÓN: Actualizar caché para acceso inmediato en UI
        _state = _state.copyWith(cachedMetrics: metrics);
        
        return metrics;
      }
    );
  }

  /// Calcula métricas de forma síncrona desde tickets precargados.
  ///
  /// Útil cuando ya tienes los tickets en memoria y no necesitas stream.
  CashRegisterMetrics calculateMetrics({
    required List<TicketModel> tickets,
    CashRegister? cashRegister,
  }) {
    final cr = cashRegister ?? currentActiveCashRegister;
    if (cr == null) {
      return CashRegisterMetrics.empty();
    }
    // ✅ ARQUITECTURA: Usar UseCase inyectado
    return _calculateMetricsUseCase(
      cashRegister: cr,
      tickets: tickets,
    );
  }

  // ==========================================
  // HELPERS PRIVADOS
  // ==========================================

  void _clearOpenForm() {
    openDescriptionController.clear();
    initialCashController.clear();
  }

  void _clearCloseForm() {
    finalBalanceController.clear();
    noteController.clear();
  }

  void _clearMovementForm() {
    movementDescriptionController.clear();
    movementAmountController.clear();
  }

  // ==========================================
  // GESTIÓN DE TICKETS (Implementación Local)
  // ==========================================

  Future<List<TicketModel>?> getCashRegisterTickets({
    required String accountId,
    required String cashRegisterId,
    bool todayOnly = false,
  }) async {
    try {
      List<Map<String, dynamic>> transactions = [];

      if (todayOnly) {
        // Usar stream para obtener datos de hoy (primera emisión)
        transactions = await _getTodayTransactionsStreamUseCase(
          accountId: accountId,
          cashRegisterId: cashRegisterId,
        ).first;
      } else {
        // Usar caso de uso por rango de fechas (últimos 30 días por defecto o similar)
        // Para simplificar, si no es todayOnly, traemos un rango amplio o todo
        // Aquí asumiremos que si no es todayOnly, queremos ver todo lo asociado a esta caja
        // PERO getTransactionsByDateRangeUseCase requiere fechas.
        // Si la caja está abierta, 'todayOnly' suele ser true.
        // Si estamos viendo historial, 'todayOnly' es false.

        // Estrategia: Si la caja tiene fecha de apertura y cierre, usar ese rango.
        // Si está activa, usar desde apertura hasta ahora.
        // Como no tenemos la instancia de CashRegister aquí fácilmente (solo ID),
        // y el método es genérico...

        // Si cashRegisterId corresponde a la caja activa actual:
        if (currentActiveCashRegister?.id == cashRegisterId) {
          final start = currentActiveCashRegister!.opening;
          final end = DateTime.now();
          final result = await _getTransactionsByDateRangeUseCase(
            GetTransactionsByDateRangeParams(
              accountId: accountId,
              startDate: start,
              endDate: end,
            ),
          );
          result.fold(
            (failure) => transactions = [],
            (data) => transactions = data
                .where((t) => t['cashRegisterId'] == cashRegisterId)
                .toList(),
          );
        } else {
          // Si es una caja histórica, deberíamos buscarla para saber sus fechas
          // Por ahora, para evitar complejidad, si no es la activa, retornamos vacío o implementamos búsqueda
          // O usamos un rango por defecto (ej. último mes)
          final end = DateTime.now();
          final start = end.subtract(const Duration(days: 30));
          final result = await _getTransactionsByDateRangeUseCase(
            GetTransactionsByDateRangeParams(
              accountId: accountId,
              startDate: start,
              endDate: end,
            ),
          );
          result.fold(
            (failure) => transactions = [],
            (data) => transactions = data
                .where((t) => t['cashRegisterId'] == cashRegisterId)
                .toList(),
          );
        }
      }

      return transactions.map((map) => TicketModel.fromMap(map)).toList();
    } catch (e) {
      return null;
    }
  }

  Future<void> processTicketAnnullment({
    required String accountId,
    required TicketModel ticket,
  }) async {
    _state = _state.copyWith(isProcessing: true, errorMessage: null);
    notifyListeners();

    final result =
        await _processTicketAnnullmentUseCase(ProcessTicketAnnullmentParams(
      accountId: accountId,
      ticket: ticket,
      activeCashRegister: currentActiveCashRegister,
    ));

    result.fold(
      (failure) {
        _state =
            _state.copyWith(isProcessing: false, errorMessage: failure.message);
      },
      (annulledTicket) {
        _state = _state.copyWith(isProcessing: false);
        reloadTickets(accountId: accountId);
      },
    );
    notifyListeners();
  }

  /// Guarda un ticket en el historial de transacciones
  ///
  /// RESPONSABILIDAD: Coordinar guardado con UseCase
  /// Usado por SalesProvider para guardar tickets de venta
  Future<bool> saveTicketToTransactionHistory({
    required String accountId,
    required TicketModel ticket,
  }) async {
    final result = await _saveTicketToTransactionHistoryUseCase(
      SaveTicketToTransactionHistoryParams(
        accountId: accountId,
        ticket: ticket,
      ),
    );

    return result.fold(
      (failure) {
        if (kDebugMode) {
          print('❌ Error guardando ticket en historial: ${failure.message}');
        }
        return false;
      },
      (_) {
        if (kDebugMode) {
          print('✅ Ticket guardado en historial: ${ticket.id}');
        }
        // Recargar tickets si hay una caja activa
        if (hasActiveCashRegister) {
          reloadTickets(accountId: accountId);
        }
        return true;
      },
    );
  }

  /// Anula un ticket en el historial de transacciones
  ///
  /// RESPONSABILIDAD: Coordinar anulación con UseCase y callback
  /// Usado por SalesProvider para anular tickets
  Future<bool> annullTicket({
    required String accountId,
    required TicketModel ticket,
    Function()? onLastSoldTicketUpdated,
  }) async {
    final result = await _processTicketAnnullmentUseCase(
      ProcessTicketAnnullmentParams(
        accountId: accountId,
        ticket: ticket,
        activeCashRegister: currentActiveCashRegister,
      ),
    );

    return result.fold(
      (failure) {
        if (kDebugMode) {
          print('❌ Error anulando ticket: ${failure.message}');
        }
        return false;
      },
      (annulledTicket) {
        if (kDebugMode) {
          print('✅ Ticket anulado: ${ticket.id}');
        }
        // Ejecutar callback si existe
        onLastSoldTicketUpdated?.call();
        // Recargar tickets
        reloadTickets(accountId: accountId);
        return true;
      },
    );
  }
}
