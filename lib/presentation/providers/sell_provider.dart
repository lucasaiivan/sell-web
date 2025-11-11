import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:sellweb/core/core.dart';
import 'package:sellweb/core/services/storage/app_data_persistence_service.dart';
import 'package:sellweb/core/services/external/thermal_printer_http_service.dart';
import 'package:sellweb/domain/entities/catalogue.dart';
import 'package:sellweb/domain/entities/user.dart';
import 'package:sellweb/domain/entities/ticket_model.dart';
import 'package:sellweb/domain/usecases/account_usecase.dart';
import 'package:sellweb/domain/usecases/sell_usecases.dart';
import 'package:sellweb/domain/usecases/catalogue_usecases.dart';
import 'package:provider/provider.dart' as provider;
import '../providers/auth_provider.dart';
import '../providers/cash_register_provider.dart';
import '../providers/catalogue_provider.dart';

/// Estado inmutable del provider de ventas
///
/// Encapsula todo el estado relacionado con el proceso de venta
/// para optimizar notificaciones y mantener coherencia
class _SellProviderState {
  final bool ticketView;
  final bool shouldPrintTicket; // si se debe imprimir el ticket
  final AccountProfile profileAccountSelected;
  final AdminProfile? currentAdminProfile; // Perfil del administrador actual
  final TicketModel ticket;
  final TicketModel? lastSoldTicket;

  const _SellProviderState({
    required this.ticketView,
    required this.shouldPrintTicket,
    required this.profileAccountSelected,
    required this.currentAdminProfile,
    required this.ticket,
    required this.lastSoldTicket,
  });

  _SellProviderState copyWith({
    bool? ticketView,
    bool? shouldPrintTicket,
    AccountProfile? profileAccountSelected,
    AdminProfile? currentAdminProfile,
    TicketModel? ticket,
    Object? lastSoldTicket = const Object(),
  }) {
    return _SellProviderState(
      ticketView: ticketView ?? this.ticketView,
      shouldPrintTicket: shouldPrintTicket ?? this.shouldPrintTicket,
      profileAccountSelected:
          profileAccountSelected ?? this.profileAccountSelected,
      currentAdminProfile: currentAdminProfile ?? this.currentAdminProfile,
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
          currentAdminProfile == other.currentAdminProfile &&
          ticket == other.ticket &&
          lastSoldTicket == other.lastSoldTicket;

  @override
  int get hashCode =>
      ticketView.hashCode ^
      shouldPrintTicket.hashCode ^
      profileAccountSelected.hashCode ^
      currentAdminProfile.hashCode ^
      ticket.hashCode ^
      lastSoldTicket.hashCode;
}

/// Provider para gestionar el proceso de ventas
///
/// **Responsabilidad:** Coordinar UI y casos de uso de ventas
/// - Gestiona estado del ticket actual, cuenta seleccionada y último ticket vendido
/// - Delega lógica de negocio a SellUsecases (crear, preparar, confirmar ventas)
/// - Delega operaciones de caja a CashRegisterUsecases vía CashRegisterProvider
/// - Delega actualización de productos a CatalogueUseCases
/// - Maneja persistencia local con AppDataPersistenceService
/// - Coordina impresión de tickets con ThermalPrinterHttpService
/// - No contiene validaciones ni lógica de negocio, solo coordinación
///
/// **Arquitectura:**
/// - Estado inmutable con _SellProviderState para optimizar notificaciones
/// - Persistencia automática de ticket en curso
/// - Coordinación entre múltiples providers (CashRegister, Catalogue, Auth)
///
/// **Flujo de venta:**
/// 1. Agregar productos al ticket → SellUsecases (lógica de negocio)
/// 2. Configurar descuentos/pago → SellUsecases (validaciones)
/// 3. Confirmar venta → processSale() coordina todos los pasos:
///    - Preparar ticket (SellUsecases)
///    - Guardar en Firebase (CashRegisterUsecases)
///    - Actualizar caja (CashRegisterUsecases)
///    - Actualizar productos (CatalogueUseCases)
///    - Imprimir ticket (ThermalPrinterHttpService)
///
/// **Uso:**
/// ```dart
/// final sellProvider = Provider.of<SellProvider>(context);
/// sellProvider.addProductsticket(product); // Agregar producto
/// sellProvider.setDiscount(discount: 10.0); // Configurar descuento
/// await sellProvider.processSale(context); // Confirmar venta
/// ```
class SellProvider extends ChangeNotifier {
  final AccountsUseCase getUserAccountsUseCase;
  final SellUsecases _sellUsecases;
  final CatalogueUseCases? _catalogueUseCases;
  final AppDataPersistenceService _persistenceService =
      AppDataPersistenceService.instance;

  // Estado encapsulado para optimizar notificaciones
  late var _state = _SellProviderState(
    ticketView: false,
    shouldPrintTicket: false,
    profileAccountSelected: AccountProfile(),
    currentAdminProfile: null,
    ticket: _sellUsecases.createEmptyTicket(),
    lastSoldTicket: null,
  );

  /// Crea un ticket vacío delegando al UseCase
  ///
  /// RESPONSABILIDAD: Solo coordinar llamada al UseCase
  TicketModel _createEmptyTicket() {
    return _sellUsecases.createEmptyTicket();
  }

  // Getters que no causan rebuild
  bool get ticketView => _state.ticketView;
  bool get shouldPrintTicket => _state.shouldPrintTicket;
  AccountProfile get profileAccountSelected => _state.profileAccountSelected;
  AdminProfile? get currentAdminProfile => _state.currentAdminProfile;
  TicketModel get ticket => _state.ticket;
  TicketModel? get lastSoldTicket => _state.lastSoldTicket;

  SellProvider({
    required this.getUserAccountsUseCase,
    required SellUsecases sellUsecases,
    CatalogueUseCases? catalogueUseCases,
  })  : _sellUsecases = sellUsecases,
        _catalogueUseCases = catalogueUseCases {
    _loadInitialState();
  }

  Future<void> _loadInitialState() async {
    await Future.wait([
      _loadSelectedAccount(),
      _loadAdminProfile(),
      _loadTicket(),
      _loadLastSoldTicket(),
      _loadShouldPrintTicket(),
    ]);
  }

  /// Inicializa el AdminProfile cuando el usuario está autenticado
  ///
  /// RESPONSABILIDAD: Obtener el perfil desde Firebase cuando hay usuario y cuenta
  /// Este método debe llamarse después de que AuthProvider tenga un usuario autenticado
  ///
  /// @param email Email del usuario autenticado
  Future<void> initializeAdminProfile(String email) async {
    // Solo actualizar si hay una cuenta seleccionada
    if (_state.profileAccountSelected.id.isNotEmpty) {
      await updateAdminProfileForSelectedAccount(email);
    }
  }

  void cleanData() {
    _state = _state.copyWith(
      profileAccountSelected: AccountProfile(),
      currentAdminProfile: null,
      ticket: _createEmptyTicket(),
      ticketView: false,
      shouldPrintTicket: false,
      lastSoldTicket: null,
    );
    _saveAllState();
    notifyListeners();
  }

  // Métodos optimizados para minimizar notificaciones
  Future<void> initAccount({
    required AccountProfile account,
    required BuildContext context,
  }) async {
    // Solo limpiar datos si la cuenta es diferente a la actual
    // Esto preserva el ticket en progreso cuando se reselecciona la misma cuenta
    _state = _state.copyWith(profileAccountSelected: account.copyWith());
    await _saveSelectedAccount(account.id);

    // Actualizar el AdminProfile para la cuenta seleccionada
    final authProvider =
        provider.Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.user?.email != null) {
      await updateAdminProfileForSelectedAccount(authProvider.user!.email!);
    }

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
      _saveShouldPrintTicket(),
    ]);
  }

  /// Carga la cuenta seleccionada desde SharedPreferences al inicializar el provider.
  Future<void> _loadSelectedAccount() async {
    final id = await getUserAccountsUseCase.loadSelectedAccountId();
    if (id != null && id.isNotEmpty) {
      if (kDebugMode) {
        print('📦 SellProvider: Cargando cuenta desde persistencia: $id');
      }

      final account = await fetchAccountById(id);
      if (account != null) {
        _state = _state.copyWith(profileAccountSelected: account);
        notifyListeners();

        if (kDebugMode) {
          print('✅ SellProvider: Cuenta cargada exitosamente');
          print('   - ID: ${account.id}');
          print('   - Nombre: ${account.name}');
        }
      } else {
        if (kDebugMode) {
          print(
              '⚠️ SellProvider: No se pudo obtener los datos de la cuenta $id');
        }
      }
    } else {
      if (kDebugMode) {
        print('📦 SellProvider: No hay cuenta guardada en persistencia');
      }
    }
  }
  /// Obtiene el AccountProfile por ID desde Firebase
  Future<AccountProfile?> fetchAccountById(String id) async {
    try {
      return await getUserAccountsUseCase.getAccount(idAccount: id);
    } catch (_) {
      return null;
    }
  }

  /// Carga el AdminProfile desde SharedPreferences al inicializar el provider
  Future<void> _loadAdminProfile() async {
    try {
      final adminProfile = await getUserAccountsUseCase.loadAdminProfile();
      if (adminProfile != null) {
        _state = _state.copyWith(currentAdminProfile: adminProfile);
        notifyListeners();

        if (kDebugMode) {
          print('✅ SellProvider: AdminProfile cargado desde persistencia');
          print('   - Email: ${adminProfile.email}');
          print('   - Cuenta: ${adminProfile.account}');
          print('   - Admin: ${adminProfile.admin}');
        }
      } else {
        if (kDebugMode) {
          print('📦 SellProvider: No hay AdminProfile guardado en persistencia');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print(
            '❌ SellProvider: Error al cargar AdminProfile desde persistencia: $e');
      }
    }
  }

  /// Guarda el AdminProfile actual en SharedPreferences
  Future<void> _saveAdminProfile() async {
    try {
      if (_state.currentAdminProfile != null) {
        await getUserAccountsUseCase.saveAdminProfile(_state.currentAdminProfile!);
      }
    } catch (e) {
      if (kDebugMode) {
        print(
            '❌ SellProvider: Error al guardar AdminProfile en persistencia: $e');
      }
      rethrow;
    }
  }

  /// Configura el AdminProfile del usuario administrador actual
  ///
  /// RESPONSABILIDAD: Actualizar estado UI y persistencia local
  /// Este método debe llamarse cuando:
  /// - El usuario inicia sesión
  /// - El usuario selecciona una cuenta (para obtener sus permisos específicos)
  ///
  /// @param adminProfile El perfil del administrador a configurar
  void setAdminProfile(AdminProfile adminProfile) {
    _state = _state.copyWith(currentAdminProfile: adminProfile);
    _saveAdminProfile();
    notifyListeners();
  }

  /// Obtiene el AdminProfile del usuario actual desde Firebase
  ///
  /// RESPONSABILIDAD: Coordinar obtención del perfil admin con UseCase
  /// Este método busca el AdminProfile correspondiente a la cuenta seleccionada
  ///
  Future<AdminProfile?> fetchAdminProfile(String email) async {
    try {
      if (kDebugMode) {
        print('🔍 SellProvider: Buscando AdminProfile para email: $email');
      }

      // UseCase maneja toda la lógica de búsqueda y selección
      final adminProfile = await getUserAccountsUseCase.fetchAdminProfile(
        email,
        accountId: _state.profileAccountSelected.id,
      );

      if (kDebugMode) {
        if (adminProfile != null) {
          print('✅ SellProvider: AdminProfile encontrado');
          print('   - Email: ${adminProfile.email}');
          print('   - Cuenta: ${adminProfile.account}');
          print('   - Admin: ${adminProfile.admin}');
        } else {
          print('⚠️ SellProvider: No se encontró AdminProfile');
        }
      }

      return adminProfile;
    } catch (e) {
      if (kDebugMode) {
        print('❌ SellProvider: Error buscando AdminProfile: $e');
      }
      return null;
    }
  }

  /// Actualiza el AdminProfile cuando cambia la cuenta seleccionada
  ///
  /// RESPONSABILIDAD: Sincronizar AdminProfile con la cuenta activa
  /// Este método debe llamarse después de initAccount() para obtener
  /// los permisos específicos del usuario en la cuenta seleccionada
  ///
  /// @param email Email del usuario autenticado
  Future<void> updateAdminProfileForSelectedAccount(String email) async {
    final adminProfile = await fetchAdminProfile(email);
    if (adminProfile != null) {
      setAdminProfile(adminProfile);
    } else {
      // Limpiar AdminProfile si no se encuentra
      _state = _state.copyWith(currentAdminProfile: null);
      await getUserAccountsUseCase.clearAdminProfile();
      notifyListeners();
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
          print('❌ SellProvider: Error al cargar ticket desde persistencia: $e');
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

  /// Agrega un producto al ticket
  ///
  /// RESPONSABILIDAD: Coordinar UI y persistencia
  /// La lógica de negocio (buscar, incrementar, agregar) está en SellUsecases
  void addProductsticket(ProductCatalogue product,
      {bool replaceQuantity = false}) {
    try {
      // PASO 1: UseCase maneja toda la lógica de negocio
      final updatedTicket = _sellUsecases.addProductToTicket(
        // CAMBIADO
        _state.ticket,
        product,
        replaceQuantity: replaceQuantity,
      );

      // PASO 2: Actualizar estado UI
      _state = _state.copyWith(ticket: updatedTicket);
      _saveTicket();
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error agregando producto: $e');
      }
      rethrow;
    }
  }

  /// Elimina un producto del ticket
  ///
  /// RESPONSABILIDAD: Coordinar UI y persistencia
  /// La lógica de negocio (filtrar producto) está en SellUsecases
  void removeProduct(ProductCatalogue product) {
    try {
      // PASO 1: UseCase maneja la lógica de eliminación
      final updatedTicket = _sellUsecases.removeProductFromTicket(
        // CAMBIADO
        _state.ticket,
        product,
      );

      // PASO 2: Actualizar estado UI (cerrar vista si no hay productos)
      _state = _state.copyWith(
        ticket: updatedTicket,
        ticketView: updatedTicket.products.isNotEmpty,
      );
      _saveTicket();
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error eliminando producto: $e');
      }
      rethrow;
    }
  }

  void discartTicket() {
    _state = _state.copyWith(ticket: _createEmptyTicket(), ticketView: false);
    _saveTicket();
    notifyListeners();
  }

  void addQuickProduct(
      {required String description, required double salePrice}) {
    final product = _sellUsecases.createQuickProduct(
      description: description,
      salePrice: salePrice,
    );
    addProductsticket(product, replaceQuantity: true);
  }

  Future<void> _saveSelectedAccount(String id) async {
    await getUserAccountsUseCase.saveAccountId(id);
  }

  /// Configura la forma de pago del ticket
  ///
  /// RESPONSABILIDAD: Coordinar UI y persistencia
  /// La lógica de negocio (validar, resetear valor recibido) está en SellUsecases
  void setPayMode({String payMode = 'effective'}) {
    try {
      // PASO 1: UseCase maneja validaciones y lógica
      final updatedTicket = _sellUsecases.setTicketPaymentMode(
        // CAMBIADO
        _state.ticket,
        payMode,
      );

      // PASO 2: Actualizar estado UI
      _state = _state.copyWith(ticket: updatedTicket);
      _saveTicket();
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error configurando forma de pago: $e');
      }
      rethrow;
    }
  }

  /// Configura el descuento del ticket
  ///
  /// RESPONSABILIDAD: Coordinar UI y persistencia
  /// La lógica de negocio (validar descuento no negativo) está en SellUsecases
  void setDiscount({required double discount, bool isPercentage = false}) {
    try {
      // PASO 1: UseCase maneja validaciones y lógica
      final updatedTicket = _sellUsecases.setTicketDiscount(
        // CAMBIADO
        _state.ticket,
        discount: discount,
        isPercentage: isPercentage,
      );

      // PASO 2: Actualizar estado UI
      _state = _state.copyWith(ticket: updatedTicket);
      _saveTicket();
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error configurando descuento: $e');
      }
      rethrow;
    }
  }

  /// Configura el valor recibido en efectivo
  ///
  /// RESPONSABILIDAD: Coordinar UI y persistencia
  /// La lógica de negocio (validar valor no negativo) está en SellUsecases
  void setReceivedCash(double value) {
    try {
      // PASO 1: UseCase maneja validaciones y lógica
      final updatedTicket = _sellUsecases.setTicketReceivedCash(
        // CAMBIADO
        _state.ticket,
        value,
      );

      // PASO 2: Actualizar estado UI
      _state = _state.copyWith(ticket: updatedTicket);
      _saveTicket();
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error configurando valor recibido: $e');
      }
      rethrow;
    }
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

  /// Guarda el último ticket vendido
  ///
  /// RESPONSABILIDAD: Actualizar estado UI y coordinar llamada al UseCase
  /// La lógica de persistencia está en SellUsecases
  ///
  /// 🆕 Este método mantiene sincronizado el estado en memoria con SharedPreferences
  Future<void> saveLastSoldTicket([TicketModel? ticket]) async {
    final ticketToSave = ticket ?? _state.ticket;

    try {
      // PASO 1: UseCase maneja validación y persistencia en SharedPreferences
      await _sellUsecases.saveLastSoldTicket(ticketToSave); // CAMBIADO

      // PASO 2: Actualizar estado local UI para mantener sincronización
      _state = _state.copyWith(lastSoldTicket: ticketToSave);
      notifyListeners();

      if (kDebugMode) {
        print(
            '✅ Último ticket guardado y estado actualizado: ${ticketToSave.id}');
      }
    } catch (e) {
      // Solo mostrar error, no fallar la operación
      if (kDebugMode) {
        print('❌ Error guardando último ticket: $e');
      }
    }
  }

  /// Anula un ticket tanto en la caja registradora como en el último ticket vendido
  ///
  /// 🆕 Ahora sincroniza correctamente el estado entre:
  /// - Firebase (a través de CashRegisterProvider)
  /// - SharedPreferences (a través de CashRegisterUsecases)
  /// - Estado en memoria del SellProvider (UI)
  Future<bool> annullLastSoldTicket({
    required BuildContext context,
    required TicketModel ticket,
  }) async {
    try {
      // Obtener el provider de caja registradora
      final cashRegisterProvider =
          provider.Provider.of<CashRegisterProvider>(context, listen: false);

      // PASO 1: Anular el ticket en la caja registradora (Firebase + SharedPreferences)
      final success = await cashRegisterProvider.annullTicket(
        accountId: profileAccountSelected.id,
        ticket: ticket,
        onLastSoldTicketUpdated: () async {
          // 🆕 Callback: Recargar el último ticket desde SharedPreferences
          // para sincronizar el estado después de que CashRegisterUsecases lo actualizó
          await _reloadLastSoldTicketFromPersistence();
        },
      );

      if (success) {
        // PASO 2: Asegurar que el estado local esté sincronizado
        // Esto es redundante pero asegura consistencia inmediata en la UI
        _state =
            _state.copyWith(lastSoldTicket: ticket.copyWith(annulled: true));
        notifyListeners();

        if (kDebugMode) {
          print(
              '✅ Ticket ${ticket.id} anulado y sincronizado en todos los niveles');
        }
      }

      return success;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error al anular ticket: $e');
      }
      return false;
    }
  }

  /// 🆕 Recarga el último ticket vendido desde SharedPreferences
  ///
  /// RESPONSABILIDAD: Sincronizar estado en memoria con persistencia local
  /// Útil cuando otro provider actualiza SharedPreferences directamente
  Future<void> _reloadLastSoldTicketFromPersistence() async {
    try {
      final lastTicket = await _sellUsecases.getLastSoldTicket(); // CAMBIADO
      _state = _state.copyWith(lastSoldTicket: lastTicket);
      notifyListeners();

      if (kDebugMode) {
        print('✅ Estado lastSoldTicket recargado desde persistencia');
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Error recargando lastSoldTicket: $e');
      }
    }
  }

  /// Carga el último ticket vendido desde almacenamiento local
  ///
  /// RESPONSABILIDAD: Solo actualizar estado UI con datos del UseCase
  Future<void> _loadLastSoldTicket() async {
    try {
      // UseCase maneja la recuperación y deserialización
      final lastTicket = await _sellUsecases.getLastSoldTicket(); // CAMBIADO

      if (lastTicket != null) {
        _state = _state.copyWith(lastSoldTicket: lastTicket);
      } else {
        _state = _state.copyWith(lastSoldTicket: null);
      }
      notifyListeners();
    } catch (e) {
      _state = _state.copyWith(lastSoldTicket: null);
      notifyListeners();
    }
  }

  /// Actualiza el ticket con la caja registradora activa
  ///
  /// RESPONSABILIDAD: Coordinar UI con datos de caja activa
  /// La lógica de asociación está en SellUsecases
  void updateTicketWithCashRegister(BuildContext context) {
    try {
      // Obtener caja activa
      final cashRegisterProvider =
          provider.Provider.of<CashRegisterProvider>(context, listen: false);

      if (cashRegisterProvider.hasActiveCashRegister) {
        final activeCashRegister =
            cashRegisterProvider.currentActiveCashRegister!;

        // PASO 1: UseCase asocia ticket con caja
        final updatedTicket = _sellUsecases.associateTicketWithCashRegister(
          // CAMBIADO
          _state.ticket,
          activeCashRegister,
        );

        // PASO 2: Actualizar estado UI
        _state = _state.copyWith(ticket: updatedTicket);
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error actualizando ticket con caja: $e');
      }
      rethrow;
    }
  }

  /// Remueve la cuenta seleccionada, limpia todos los datos y notifica a los listeners
  Future<void> removeSelectedAccount() async {
    // Eliminar el ID de la cuenta seleccionada usando UseCase
    await getUserAccountsUseCase.removeSelectedAccountId();
    // Eliminar el AdminProfile guardado usando UseCase
    await getUserAccountsUseCase.clearAdminProfile();
    // Limpiar todos los datos y estado
    cleanData();
    notifyListeners();
  }

  /// PROCESAMIENTO DE VENTA CONFIRMADA
  ///
  /// 1. Preparar ticket (vendedor, caja, precio, ID)
  /// 2. Guardar ticket en Firebase (transacciones)
  /// 3. Incrementar contador de ventas (SOLO si el guardado fue exitoso)
  /// 4. Actualizar estadísticas de productos y stock
  ///
  /// ⚠️ IMPORTANTE: El contador 'sales' se incrementa DESPUÉS de guardar el ticket
  /// para garantizar que cashRegister.sales coincida con los tickets realmente guardados.
  Future<void> processSale(BuildContext context) async {
    try {
      // PASO 1: Preparar el ticket con toda la información necesaria (vendedor, caja, precio, ID)
      _prepareTicketForSale(context);

      // PASO 2: Guardar en historial de transacciones (Firebase)
      // NOTA: El último ticket vendido se guarda automáticamente en saveTicketToTransactionHistory
      // ⚠️ Si esto falla, no se incrementará el contador de ventas
      await _saveToTransactionHistory(context);

      // PASO 3: Procesar caja registradora DESPUÉS de guardar exitosamente
      // ✅ Garantiza consistencia: sales se incrementa SOLO si el ticket se guardó en Firebase
      await _processCashRegister(context);

      // PASO 4: Actualizar estadísticas de productos y stock
      await _updateProductSalesAndStock(context);

      // Manejar impresión o generación de ticket según configuración
      if (_state.shouldPrintTicket) {
        await _handleTicketPrintingOrGeneration(context);
      }

      // Finalizar la venta - el guardado local ya se realizó automáticamente
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

  /// Prepara el ticket para la venta
  ///
  /// RESPONSABILIDAD: Coordinar preparación con UseCase
  /// La lógica de validación, transformación y generación de ID está en SellUsecases
  void _prepareTicketForSale(BuildContext context) {
    try {
      // Obtener caja activa si existe
      final cashRegisterProvider =
          provider.Provider.of<CashRegisterProvider>(context, listen: false);
      final activeCashRegister = cashRegisterProvider.hasActiveCashRegister
          ? cashRegisterProvider.currentActiveCashRegister
          : null;

      // PASO 1: UseCase prepara ticket completo (validaciones, transformaciones, ID)
      final preparedTicket = _sellUsecases.prepareSaleTicket(
        // CAMBIADO
        _state.ticket,
        sellerId: _state.profileAccountSelected.id,
        sellerName: _state.profileAccountSelected.name,
        activeCashRegister: activeCashRegister,
      );

      // PASO 2: Actualizar estado UI con ticket preparado
      _state = _state.copyWith(ticket: preparedTicket);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error preparando ticket para venta: $e');
      }
      rethrow;
    }
  }

  /// Procesa la caja registradora si hay una activa
  ///
  /// ⚠️ IMPORTANTE - ORDEN DE EJECUCIÓN:
  /// Este método DEBE llamarse DESPUÉS de guardar el ticket en Firebase (_saveToTransactionHistory).
  ///
  /// RESPONSABILIDAD:
  /// - Incrementar contador de ventas efectivas (+1) SOLO si el ticket se guardó exitosamente
  /// - Actualizar facturación y descuentos en la caja registradora
  /// - Garantizar consistencia: cashRegister.sales coincide con tickets guardados en Firebase
  ///
  /// NOTA: El ticket ya fue preparado por _prepareTicketForSale (vendedor, caja, precio, ID)
  Future<void> _processCashRegister(BuildContext context) async {
    try {
      final cashRegisterProvider =
          provider.Provider.of<CashRegisterProvider>(context, listen: false);

      if (cashRegisterProvider.hasActiveCashRegister) {
        // ✅ FIX: Usar priceTotal que ya incluye el descuento aplicado
        // priceTotal se estableció correctamente en prepareSaleTicket con getTotalPrice
        // Esto garantiza que billing coincida con la suma de priceTotal de todos los tickets
        await cashRegisterProvider.cashRegisterSale(
          accountId: _state.profileAccountSelected.id,
          saleAmount: _state.ticket.priceTotal,
          discountAmount: _state.ticket
              .getDiscountAmount, // Usar el monto calculado del descuento
          itemCount: _state.ticket.getProductsQuantity(),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error procesando caja registradora: $e');
      }
      rethrow;
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
  Future<void> _printTicketDirectly(
      BuildContext context, ThermalPrinterHttpService printerService) async {
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
  ///
  /// RESPONSABILIDAD: Coordinar guardado y actualizar estado UI local
  /// El UseCase se encarga automáticamente de:
  /// - Preparar y validar el ticket (prepareTicketForTransaction)
  /// - Guardar en Firebase (historial de transacciones)
  /// - Guardar en SharedPreferences (último ticket vendido)
  Future<void> _saveToTransactionHistory(BuildContext context) async {
    final cashRegisterProvider =
        provider.Provider.of<CashRegisterProvider>(context, listen: false);

    // 🆕 PASO 1: Preparar el ticket usando el UseCase antes de guardar
    // Esto asegura que el ticket tenga ID, validaciones, y transformaciones correctas
    final preparedTicket =
        _sellUsecases.prepareTicketForTransaction(_state.ticket); // CAMBIADO

    // PASO 2: Actualizar el ticket actual con el preparado (tiene ID generado si estaba vacío)
    _state = _state.copyWith(ticket: preparedTicket);

    // PASO 3: Guardar en historial (Firebase + SharedPreferences automático)
    // ⚠️ IMPORTANTE: Verificar que el guardado fue exitoso antes de continuar
    final success = await cashRegisterProvider.saveTicketToTransactionHistory(
      accountId: _state.profileAccountSelected.id,
      ticket: preparedTicket, // ← Usar ticket preparado
    );

    // Si el guardado falló, lanzar excepción para detener el flujo
    if (!success) {
      throw Exception(
          'Error al guardar el ticket en el historial de transacciones');
    }

    // PASO 4: Actualizar estado local UI para reflejar el último ticket vendido
    // Usar el ticket preparado para asegurar consistencia total
    _state = _state.copyWith(lastSoldTicket: preparedTicket);
    notifyListeners();
  }

  /// Actualiza las estadísticas de ventas y stock de los productos en el catálogo
  ///
  /// RESPONSABILIDAD: Coordinar actualización de productos usando UseCases
  /// Este método se ejecuta después de confirmar una venta para:
  /// 1. Incrementar el contador de ventas de cada producto
  /// 2. Decrementar el stock si el producto tiene habilitado el control de stock
  Future<void> _updateProductSalesAndStock(BuildContext context) async {
    try {
      final accountId = _state.profileAccountSelected.id;

      // Si no hay casos de uso inyectados, usar el provider (fallback)
      if (_catalogueUseCases == null) {
        await _updateProductSalesAndStockViaProvider(context);
        return;
      }

      // Procesar cada producto del ticket usando UseCases directamente
      for (final product in _state.ticket.products) {
        if (product.code.isEmpty) {
          // Si el producto no tiene código, saltar (productos de venta rápida)
          continue;
        }

        try {
          // Incrementar ventas del producto usando UseCase
          await _catalogueUseCases.incrementProductSales(
            accountId,
            product.id,
            quantity: product.quantity,
          );

          // Si el producto tiene control de stock habilitado, decrementar stock
          if (product.stock && product.quantityStock > 0) {
            await _catalogueUseCases.decrementProductStock(
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

  /// Método de fallback para actualizar productos vía provider cuando no hay UseCases inyectados
  Future<void> _updateProductSalesAndStockViaProvider(BuildContext context) async {
    try {
      // Obtener el provider del catálogo
      final catalogueProvider =
          provider.Provider.of<CatalogueProvider>(context, listen: false);
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
      if (kDebugMode) {
        print('Error general actualizando productos vía provider: $e');
      }
    }
  }
}
