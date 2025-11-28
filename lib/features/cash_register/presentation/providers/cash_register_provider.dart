import 'dart:async';
import 'package:fpdart/fpdart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';
import 'package:sellweb/core/di/injection_container.dart';
import 'package:sellweb/core/core.dart';
import 'package:sellweb/core/services/storage/app_data_persistence_service.dart';
import 'package:sellweb/features/cash_register/domain/entities/cash_register.dart';
import 'package:sellweb/features/sales/domain/entities/ticket_model.dart';

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

/// Provider para gestionar el estado de cajas registradoras
@injectable
class CashRegisterProvider extends ChangeNotifier {
  // UseCases
  final OpenCashRegisterUseCase _openCashRegisterUseCase;
  final CloseCashRegisterUseCase _closeCashRegisterUseCase;
  final GetActiveCashRegistersUseCase _getActiveCashRegistersUseCase;
  final GetActiveCashRegistersStreamUseCase _getActiveCashRegistersStreamUseCase;
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
  final SaveTicketToTransactionHistoryUseCase _saveTicketToTransactionHistoryUseCase;

  // Stream subscriptions
  StreamSubscription<List<CashRegister>>? _activeCashRegistersSubscription;
  String? _currentAccountId;

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

  Future<List<TicketModel>?>? get cashRegisterTickets => _cashRegisterTickets;
  bool get isLoadingTickets => _isLoadingTickets;

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
  );

  @override
  void dispose() {
    _activeCashRegistersSubscription?.cancel();
    openDescriptionController.dispose();
    initialCashController.dispose();
    finalBalanceController.dispose();
    movementDescriptionController.dispose();
    movementAmountController.dispose();
    super.dispose();
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

    // TODO: Inyectar AppDataPersistenceService en el constructor (parte de estrategia gradual DI)
    final persistenceService = getIt<AppDataPersistenceService>();

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
          await persistenceService.getSelectedCashRegisterId();

      if (savedCashRegisterId != null && savedCashRegisterId.isNotEmpty) {
        final savedCashRegister = _state.activeCashRegisters
            .where((cr) => cr.id == savedCashRegisterId)
            .firstOrNull;
        if (savedCashRegister != null) {
          _state = _state.copyWith(selectedCashRegister: savedCashRegister);
          notifyListeners();
        } else {
          await persistenceService.clearSelectedCashRegisterId();
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
    final persistenceService = getIt<AppDataPersistenceService>();

    try {
      clearTicketsCache();
      _state = _state.copyWith(selectedCashRegister: cashRegister);
      notifyListeners();
      await persistenceService.saveSelectedCashRegisterId(cashRegister.id);
    } catch (e) {
      _state = _state.copyWith(clearSelectedCashRegister: true);
      notifyListeners();
      rethrow;
    }
  }

  Future<void> clearSelectedCashRegister() async {
    final persistenceService = getIt<AppDataPersistenceService>();

    try {
      _state = _state.copyWith(clearSelectedCashRegister: true);
      clearTicketsCache();
      notifyListeners();
      await persistenceService.clearSelectedCashRegisterId();
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
        _state = _state.copyWith(
            isProcessing: false, errorMessage: failure.message);
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
        _state = _state.copyWith(
            isProcessing: false, errorMessage: failure.message);
        notifyListeners();
        return false;
      },
      (_) {
        _clearMovementForm();
        _state = _state.copyWith(isProcessing: false);
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
        _state = _state.copyWith(
            isProcessing: false, errorMessage: failure.message);
        notifyListeners();
        return false;
      },
      (_) {
        _clearMovementForm();
        _state = _state.copyWith(isProcessing: false);
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
    } catch (e) {
      _state = _state.copyWith(
        errorMessage: e.toString(),
        isLoadingHistory: false,
      );
    }
    notifyListeners();
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
            return todayTransactions.map((t) => TicketModel.fromMap(t)).toList();
          } else {
            // Si se abrió en días anteriores, combinar históricas + hoy
            final historicalResult = await _getTransactionsByDateRangeUseCase(
              GetTransactionsByDateRangeParams(
                accountId: accountId,
                startDate: start,
                endDate: today.subtract(const Duration(days: 1, hours: 12)),
              ),
            );
            
            final historicalTickets = historicalResult.fold(
              (failure) => <TicketModel>[],
              (data) => data
                  .where((t) => t['cashRegisterId'] == cashRegisterId)
                  .map((t) => TicketModel.fromMap(t))
                  .toList(),
            );
            
            final todayTickets = todayTransactions.map((t) => TicketModel.fromMap(t)).toList();
            
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
  // HELPERS PRIVADOS
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
        _state = _state.copyWith(
            isProcessing: false, errorMessage: failure.message);
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
