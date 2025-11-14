import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../core/core.dart';
import '../../core/services/storage/app_data_persistence_service.dart';
import '../../domain/entities/cash_register_model.dart';
import '../../domain/entities/ticket_model.dart';
import '../../domain/usecases/cash_register_usecases.dart';
import '../../domain/usecases/sell_usecases.dart'; // NUEVO: Lógica de negocio de tickets

/// Extension helper para firstOrNull si no está disponible
extension ListExtensions<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

/// Estado inmutable del provider de caja registradora
///
/// Encapsula todo el estado relacionado con cajas registradoras
/// para optimizar notificaciones y mantener coherencia
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

/// Provider para gestionar el estado de cajas registradoras
///
/// **Responsabilidad:** Coordinar UI y casos de uso de cajas registradoras
/// - Gestiona estado de cajas activas, historial y tickets
/// - Delega lógica de negocio a CashRegisterUsecases (abrir, cerrar, movimientos)
/// - Delega gestión de tickets a SellUsecases
/// - Maneja estados de carga, procesamiento y errores para la UI
/// - Proporciona streams para actualizaciones en tiempo real
/// - No contiene validaciones ni lógica de negocio, solo coordinación
///
/// **Arquitectura:**
/// - Estado inmutable con _CashRegisterState para optimizar notificaciones
/// - Streams de Firebase para sincronización automática
/// - Persistencia local con AppDataPersistenceService
///
/// **Uso:**
/// ```dart
/// final cashProvider = Provider.of<CashRegisterProvider>(context);
/// await cashProvider.openCashRegister(...); // Abrir caja
/// await cashProvider.closeCashRegister(...); // Cerrar caja
/// await cashProvider.addCashInflow(...); // Registrar ingreso
/// ```
class CashRegisterProvider extends ChangeNotifier {
  final CashRegisterUsecases _cashRegisterUsecases; // Operaciones de caja
  final SellUsecases _sellUsecases; // NUEVO: Operaciones de tickets

  // Stream subscriptions para actualizaciones automáticas
  StreamSubscription<List<CashRegister>>? _activeCashRegistersSubscription;
  String? _currentAccountId;

  // ✅ Gestión de tickets de la caja registradora activa
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

  // ✅ Getters para tickets de la caja registradora
  Future<List<TicketModel>?>? get cashRegisterTickets => _cashRegisterTickets;
  bool get isLoadingTickets => _isLoadingTickets;

  CashRegisterProvider(
    this._cashRegisterUsecases,
    this._sellUsecases, // NUEVO: Inyectar lógica de tickets
  );

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
      // ✅ Limpiar cache de tickets de la caja anterior
      clearTicketsCache();

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

      // ✅ Limpiar cache de tickets al deseleccionar caja
      clearTicketsCache();

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
  ///
  /// RESPONSABILIDAD: Solo coordinar UI y llamar al UseCase
  /// Las validaciones y lógica de negocio están en CashRegisterUsecases
  Future<bool> openCashRegister({
    required String accountId,
    required String cashierId,
    required String cashierName,
  }) async {
    _state = _state.copyWith(isProcessing: true, errorMessage: null);
    notifyListeners();

    try {
      // UseCase maneja TODAS las validaciones y lógica de negocio
      final newCashRegister = await _cashRegisterUsecases.openCashRegister(
        accountId: accountId,
        description: openDescriptionController.text,
        initialCash: initialCashController.doubleValue,
        cashierId: cashierId,
        cashierName: cashierName,
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
  ///
  /// RESPONSABILIDAD: Coordinar UI, validar contadores reales y cerrar caja
  ///
  /// ⚠️ NUEVA LÓGICA DE CONTADORES:
  /// - sales: Representa SOLO ventas efectivas (NO incluye anulaciones)
  /// - annulledTickets: Contador de tickets anulados
  /// - totalTransactions = sales + annulledTickets
  ///
  /// FLUJO:
  /// 1. Obtener transacciones reales de hoy de esta caja
  Future<bool> closeCashRegister(
      String accountId, String cashRegisterId) async {
    _state = _state.copyWith(isProcessing: true, errorMessage: null);
    notifyListeners();

    try {
      // Obtener transacciones reales de hoy para validar contadores
      final todayTickets = await _cashRegisterUsecases
          .getTodayTransactionsStream(
            accountId: accountId,
            cashRegisterId: cashRegisterId,
          )
          .first;

      // Calcular contadores desde la fuente de verdad
      final effectiveSales =
          todayTickets.where((ticket) => ticket['annulled'] != true).length;

      final annulledCount =
          todayTickets.where((ticket) => ticket['annulled'] == true).length;

      final totalTransactions = effectiveSales + annulledCount;

      // 🎯 PASO 3: Verificar consistencia de contadores
      // ⚠️ IMPORTANTE:
      // - sales debe coincidir con effectiveSales (ventas efectivas)
      // - annulledTickets debe coincidir con annulledCount
      // - Si hay desincronización, corregir antes de cerrar
      if (_state.selectedCashRegister != null && totalTransactions > 0) {
        final currentSales = _state.selectedCashRegister!.sales;
        final currentAnnulled = _state.selectedCashRegister!.annulledTickets;

        // Verificar si los contadores necesitan corrección
        final salesNeedsUpdate = currentSales != effectiveSales;
        final annulledNeedsUpdate = currentAnnulled != annulledCount;

        if (salesNeedsUpdate || annulledNeedsUpdate) {
          final updatedCashRegister = _state.selectedCashRegister!.update(
            sales: effectiveSales, // Corregir si hay desincronización
            annulledTickets: annulledCount, // Corregir si hay desincronización
          );

          // Actualizar estado local
          _state = _state.copyWith(selectedCashRegister: updatedCashRegister);

          if (kDebugMode) {
            print('📊 Contadores corregidos antes de cerrar:');
            if (salesNeedsUpdate) {
              print(
                  '   - Ventas efectivas: $currentSales → $effectiveSales (corregido)');
            } else {
              print('   - Ventas efectivas: $currentSales ✅');
            }
            if (annulledNeedsUpdate) {
              print(
                  '   - Anulados: $currentAnnulled → $annulledCount (corregido)');
            } else {
              print('   - Anulados: $currentAnnulled ✅');
            }
            print('   - Total transacciones: $totalTransactions');
          }
        } else if (kDebugMode) {
          print('✅ Contadores correctos - No requieren actualización');
          print('   - Ventas efectivas: $currentSales');
          print('   - Anulados: $currentAnnulled');
          print('   - Total transacciones: $totalTransactions');
        }
      }

      // 🎯 PASO 4: Cerrar la caja con contadores validados
      await _cashRegisterUsecases.closeCashRegister(
        accountId: accountId,
        cashRegisterId: cashRegisterId,
        finalBalance: finalBalanceController.doubleValue,
      );

      // Deseleccionar la caja cerrada
      await clearSelectedCashRegister();

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
  ///
  /// RESPONSABILIDAD: Solo coordinar UI y llamar al UseCase
  /// Las validaciones están en CashRegisterUsecases
  Future<bool> addCashInflow(
      String accountId, String cashRegisterId, String userId) async {
    _state = _state.copyWith(isProcessing: true, errorMessage: null);
    notifyListeners();

    try {
      // UseCase maneja TODAS las validaciones
      await _cashRegisterUsecases.addCashInflow(
        accountId: accountId,
        cashRegisterId: cashRegisterId,
        description: movementDescriptionController.text,
        amount: movementAmountController.doubleValue,
        userId: userId,
      );

      // Limpiar formulario
      _clearMovementForm();

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
  ///
  /// RESPONSABILIDAD: Solo coordinar UI y llamar al UseCase
  /// Las validaciones están en CashRegisterUsecases
  Future<bool> addCashOutflow(
      String accountId, String cashRegisterId, String userId) async {
    _state = _state.copyWith(isProcessing: true, errorMessage: null);
    notifyListeners();

    try {
      // UseCase maneja TODAS las validaciones
      await _cashRegisterUsecases.addCashOutflow(
        accountId: accountId,
        cashRegisterId: cashRegisterId,
        description: movementDescriptionController.text,
        amount: movementAmountController.doubleValue,
        userId: userId,
      );

      // Limpiar formulario
      _clearMovementForm();

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

    try {
      // case use : realizar venta en caja registradora activa
      await _cashRegisterUsecases.cashRegisterSale(
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
  // MÉTODOS PÚBLICOS - GESTIÓN DE TICKETS
  // ==========================================

  /// Carga los tickets de la caja registradora activa solo si es necesario.
  /// Detecta cambios en la caja registradora para evitar llamadas innecesarias.
  ///
  /// **Uso:**
  /// ```dart
  /// await cashRegisterProvider.loadCashRegisterTickets(
  ///   accountId: accountId,
  ///   forceReload: false, // opcional: forzar recarga
  /// );
  /// ```
  Future<void> loadCashRegisterTickets({
    required String accountId,
    bool forceReload = false,
  }) async {
    final cashRegisterId = currentActiveCashRegister?.id ?? '';

    // Validar que haya una caja activa
    if (cashRegisterId.isEmpty || accountId.isEmpty) {
      _cashRegisterTickets = Future.value(null);
      _cachedCashRegisterId = null;
      // Usar scheduleMicrotask para evitar llamar notifyListeners durante build
      scheduleMicrotask(() {
        notifyListeners();
      });
      return;
    }

    // Solo recargar si hay cambios
    if (forceReload ||
        _cachedCashRegisterId != cashRegisterId ||
        _cashRegisterTickets == null) {
      _cachedCashRegisterId = cashRegisterId;
      _isLoadingTickets = true;

      // Usar scheduleMicrotask para evitar llamar notifyListeners durante build
      scheduleMicrotask(() {
        notifyListeners();
      });

      // Obtener tickets de la caja activa
      _cashRegisterTickets = getCashRegisterTickets(
        accountId: accountId,
        cashRegisterId: cashRegisterId,
        todayOnly: false,
      );

      // Esperar a que termine la carga para actualizar el estado
      await _cashRegisterTickets;
      _isLoadingTickets = false;

      // Usar scheduleMicrotask para evitar problemas si se llama durante build
      scheduleMicrotask(() {
        notifyListeners();
      });
    }
  }

  /// Fuerza la recarga de tickets de la caja registradora activa.
  /// Útil después de acciones como anular un ticket, agregar movimientos, etc.
  ///
  /// **Uso:**
  /// ```dart
  /// await cashRegisterProvider.reloadTickets(accountId: accountId);
  /// ```
  Future<void> reloadTickets({required String accountId}) async {
    await loadCashRegisterTickets(accountId: accountId, forceReload: true);
  }

  /// Limpia el cache de tickets.
  /// Útil cuando se cambia de cuenta o se cierra sesión.
  void clearTicketsCache() {
    _cashRegisterTickets = null;
    _cachedCashRegisterId = null;
    _isLoadingTickets = false;
    notifyListeners();
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
  Future<bool> saveTicketToTransactionHistory({
    required String accountId,
    required TicketModel ticket,
  }) async {
    try {
      // Preparar ticket (validaciones en SellUsecases)
      final preparedTicket = _sellUsecases.prepareTicketForTransaction(ticket);

      // Guardar en Firebase (ahora en CashRegisterUsecases)
      await _cashRegisterUsecases.saveTicketToTransactionHistory(
        accountId: accountId,
        ticket: preparedTicket,
      );

      return true;
    } catch (e) {
      _state = _state.copyWith(errorMessage: e.toString());
      notifyListeners();
      return false;
    }
  }

  /// Anula un ticket específico marcándolo como anulado
  ///
  /// RESPONSABILIDAD: Coordinar UI y actualizar estado local
  /// La lógica de negocio está en CashRegisterUsecases
  ///
  /// 🆕 IMPORTANTE: Si el ticket anulado es el último vendido, debe actualizarse
  /// Anula un ticket en el historial de transacciones
  Future<bool> annullTicket({
    required String accountId,
    required TicketModel ticket,
    VoidCallback? onLastSoldTicketUpdated,
  }) async {
    try {
      // Anular ticket (ahora en CashRegisterUsecases)
      final annulledTicket =
          await _cashRegisterUsecases.processTicketAnnullment(
        accountId: accountId,
        ticket: ticket,
        activeCashRegister: _state.selectedCashRegister,
      );

      // Actualizar último ticket local si es necesario
      await _sellUsecases.updateLastSoldTicket(annulledTicket);

      // Recargar caja desde Firebase para obtener contadores actualizados
      if (hasActiveCashRegister &&
          ticket.cashRegisterId == _state.selectedCashRegister!.id) {
        final updatedCashRegisters =
            await _cashRegisterUsecases.getActiveCashRegisters(accountId);
        final updatedCashRegister = updatedCashRegisters.firstWhere(
          (cr) => cr.id == _state.selectedCashRegister!.id,
          orElse: () => _state.selectedCashRegister!,
        );

        _state = _state.copyWith(selectedCashRegister: updatedCashRegister);
        notifyListeners();
      }

      // PASO 3: 🆕 Notificar que el último ticket vendido fue actualizado en SharedPreferences
      // Esto permite que SellProvider recargue su estado desde persistencia
      if (onLastSoldTicketUpdated != null) {
        onLastSoldTicketUpdated();
      }

      if (kDebugMode) {
        print('✅ Ticket ${ticket.id} anulado en Firebase + SharedPreferences');
        print('   - sales: NO modificado (solo ventas efectivas)');
        print('   - annulledTickets: incrementado automáticamente');
        print('   - billing/discount: decrementados automáticamente');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error anulando ticket: $e');
      }
      _state = _state.copyWith(errorMessage: e.toString());
      notifyListeners();
      return false;
    }
  }

  /// Obtiene tickets de una caja registradora específica
  ///
  /// **Parámetros:**
  /// - `accountId`: ID de la cuenta
  /// - `cashRegisterId`: ID de la caja (requerido)
  /// - `todayOnly`: true = solo tickets de hoy, false = todo el historial (default: true)
  ///
  /// **Retorna:** Lista de TicketModel o null si hay error
  ///
  /// **Uso:**
  /// ```dart
  /// // Solo tickets de hoy (default)
  /// final todayTickets = await getCashRegisterTickets(
  ///   accountId: accountId,
  ///   cashRegisterId: cashRegisterId,
  /// );
  ///
  /// // Todo el historial de la caja
  /// final allTickets = await getCashRegisterTickets(
  ///   accountId: accountId,
  ///   cashRegisterId: cashRegisterId,
  ///   todayOnly: false,
  /// );
  /// ```
  Future<List<TicketModel>?> getCashRegisterTickets({
    required String accountId,
    required String cashRegisterId,
    bool todayOnly = false, // por defecto mostrar todos los tickets de la caja
  }) async {
    try {
      // Validar cashRegisterId requerido
      if (cashRegisterId.isEmpty) {
        throw Exception('cashRegisterId es requerido');
      }

      List<Map<String, dynamic>> result;

      if (todayOnly) {
        // Obtener solo tickets de hoy (ahora en CashRegisterUsecases)
        result = await _cashRegisterUsecases.getTodayTransactions(
          accountId: accountId,
          cashRegisterId: cashRegisterId,
        );
      } else {
        // Obtener todo el historial de la caja
        final now = DateTime.now();
        final oneYearAgo = now.subtract(const Duration(days: 365));

        result = await _cashRegisterUsecases.getTransactionsByDateRange(
          accountId: accountId,
          startDate: oneYearAgo,
          endDate: now,
        );

        // Filtrar solo tickets de esta caja
        result = result
            .where((ticket) => ticket['cashRegisterId'] == cashRegisterId)
            .toList();
      }

      // Convertir a TicketModel
      return result.map((ticketMap) => TicketModel.fromMap(ticketMap)).toList();
    } catch (e) {
      _state = _state.copyWith(errorMessage: e.toString());
      notifyListeners();
      return null;
    }
  }

  /// Stream de tickets de caja registradora con actualizaciones en tiempo real
  ///
  /// RESPONSABILIDAD: Proporcionar stream de tickets que se actualiza automáticamente
  ///
  /// PARÁMETROS:
  /// - `accountId`: ID de la cuenta
  /// - `cashRegisterId`: ID de la caja registradora
  /// - `todayOnly`: Si es true, solo devuelve tickets de hoy
  ///
  /// RETORNA: Stream de lista de TicketModel
  ///
  /// USO:
  /// ```dart
  /// // En un StreamBuilder
  /// StreamBuilder<List<TicketModel>>(
  ///   stream: provider.getCashRegisterTicketsStream(
  ///     accountId: accountId,
  ///     cashRegisterId: cashRegisterId,
  ///   ),
  ///   builder: (context, snapshot) {
  ///     if (snapshot.hasData) {
  ///       final tickets = snapshot.data!;
  ///       // Usar tickets actualizados en tiempo real
  ///     }
  ///     return Container();
  ///   },
  /// )
  /// ```
  Stream<List<TicketModel>> getCashRegisterTicketsStream({
    required String accountId,
    required String cashRegisterId,
    bool todayOnly = true,
  }) {
    try {
      if (cashRegisterId.isEmpty) {
        throw Exception('cashRegisterId es requerido');
      }

      // Stream de todos los tickets filtrados por caja
      return _cashRegisterUsecases
          .getTransactionsStream(accountId)
          .map((allTransactions) {
        final filteredTransactions = allTransactions
            .where((ticket) => ticket['cashRegisterId'] == cashRegisterId)
            .toList();

        return filteredTransactions
            .map((ticketMap) => TicketModel.fromMap(ticketMap))
            .toList();
      });
    } catch (e) {
      _state = _state.copyWith(errorMessage: e.toString());
      notifyListeners();
      // Retornar stream vacío en caso de error
      return Stream.value([]);
    }
  }

  /// Obtiene los tickets filtrados por rango de fechas
  Future<List<Map<String, dynamic>>?> getTicketsByDateRange({
    required String accountId,
    required DateTime startDate,
    required DateTime endDate,
    String cashRegisterId = '',
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
  Future<Map<String, dynamic>?> getTransactionAnalytics({
    required String accountId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
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
