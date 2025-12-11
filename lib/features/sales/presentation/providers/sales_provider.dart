import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:sellweb/core/core.dart';
import 'package:sellweb/core/constants/payment_methods.dart';
import 'package:sellweb/core/services/storage/app_data_persistence_service.dart';
import 'package:sellweb/core/services/external/thermal_printer_http_service.dart';
import 'package:sellweb/features/catalogue/domain/entities/product_catalogue.dart';
import 'package:sellweb/features/auth/domain/entities/account_profile.dart';
import 'package:sellweb/features/auth/domain/entities/admin_profile.dart';
import 'package:sellweb/features/sales/domain/entities/ticket_model.dart';
import 'package:sellweb/features/auth/domain/usecases/get_user_accounts_usecase.dart';
import 'package:sellweb/features/catalogue/domain/usecases/catalogue_usecases.dart';
import 'package:provider/provider.dart' as provider;

// Sales UseCases
import 'package:sellweb/features/sales/domain/usecases/add_product_to_ticket_usecase.dart';
import 'package:sellweb/features/sales/domain/usecases/remove_product_from_ticket_usecase.dart';
import 'package:sellweb/features/sales/domain/usecases/create_quick_product_usecase.dart';
import 'package:sellweb/features/sales/domain/usecases/set_ticket_payment_mode_usecase.dart';
import 'package:sellweb/features/sales/domain/usecases/set_ticket_discount_usecase.dart';
import 'package:sellweb/features/sales/domain/usecases/set_ticket_received_cash_usecase.dart';
import 'package:sellweb/features/sales/domain/usecases/associate_ticket_with_cash_register_usecase.dart';
import 'package:sellweb/features/sales/domain/usecases/prepare_sale_ticket_usecase.dart';
import 'package:sellweb/features/sales/domain/usecases/prepare_ticket_for_transaction_usecase.dart';
import 'package:sellweb/features/sales/domain/usecases/save_last_sold_ticket_usecase.dart';
import 'package:sellweb/features/sales/domain/usecases/get_last_sold_ticket_usecase.dart';

import 'package:sellweb/features/cash_register/presentation/providers/cash_register_provider.dart';
import 'package:sellweb/features/auth/presentation/providers/auth_provider.dart';

/// Estado inmutable del provider de ventas
///
/// Encapsula todo el estado relacionado con el proceso de venta
/// para optimizar notificaciones y mantener coherencia
class _SalesProviderState {
  final bool ticketView;
  final bool shouldPrintTicket; // si se debe imprimir el ticket
  final AccountProfile profileAccountSelected;
  final AdminProfile? currentAdminProfile; // Perfil del administrador actual
  final TicketModel ticket;
  final TicketModel? lastSoldTicket;

  const _SalesProviderState({
    required this.ticketView,
    required this.shouldPrintTicket,
    required this.profileAccountSelected,
    required this.currentAdminProfile,
    required this.ticket,
    required this.lastSoldTicket,
  });

  _SalesProviderState copyWith({
    bool? ticketView,
    bool? shouldPrintTicket,
    AccountProfile? profileAccountSelected,
    AdminProfile? currentAdminProfile,
    TicketModel? ticket,
    Object? lastSoldTicket = const Object(),
  }) {
    return _SalesProviderState(
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
      other is _SalesProviderState &&
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
/// - Estado inmutable con _SalesProviderState para optimizar notificaciones
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
/// final salesProvider = Provider.of<SalesProvider>(context);
/// salesProvider.addProductsticket(product); // Agregar producto
/// salesProvider.setDiscount(discount: 10.0); // Configurar descuento
/// await salesProvider.processSale(context); // Confirmar venta
/// ```
@injectable
class SalesProvider extends ChangeNotifier {
  final GetUserAccountsUseCase getUserAccountsUseCase;

  // Sales UseCases
  final AddProductToTicketUseCase _addProductToTicketUseCase;
  final RemoveProductFromTicketUseCase _removeProductFromTicketUseCase;
  final CreateQuickProductUseCase _createQuickProductUseCase;
  final SetTicketPaymentModeUseCase _setTicketPaymentModeUseCase;
  final SetTicketDiscountUseCase _setTicketDiscountUseCase;
  final SetTicketReceivedCashUseCase _setTicketReceivedCashUseCase;
  final AssociateTicketWithCashRegisterUseCase
      _associateTicketWithCashRegisterUseCase;
  final PrepareSaleTicketUseCase _prepareSaleTicketUseCase;
  final PrepareTicketForTransactionUseCase _prepareTicketForTransactionUseCase;
  final SaveLastSoldTicketUseCase _saveLastSoldTicketUseCase;
  final GetLastSoldTicketUseCase _getLastSoldTicketUseCase;

  final CatalogueUseCases _catalogueUseCases;
  final AppDataPersistenceService _persistenceService;
  final ThermalPrinterHttpService _printerService;

  // Estado encapsulado para optimizar notificaciones
  late var _state = _SalesProviderState(
    ticketView: false,
    shouldPrintTicket: false,
    profileAccountSelected: AccountProfile.empty(),
    currentAdminProfile: null,
    ticket: TicketModel(listPoduct: [], creation: Timestamp.now()),
    lastSoldTicket: null,
  );

  // Getters que no causan rebuild
  bool get ticketView => _state.ticketView;
  bool get shouldPrintTicket => _state.shouldPrintTicket;
  AccountProfile get profileAccountSelected => _state.profileAccountSelected;
  AdminProfile? get currentAdminProfile => _state.currentAdminProfile;
  TicketModel get ticket => _state.ticket;
  TicketModel? get lastSoldTicket => _state.lastSoldTicket;

  SalesProvider({
    required this.getUserAccountsUseCase,
    required AddProductToTicketUseCase addProductToTicketUseCase,
    required RemoveProductFromTicketUseCase removeProductFromTicketUseCase,
    required CreateQuickProductUseCase createQuickProductUseCase,
    required SetTicketPaymentModeUseCase setTicketPaymentModeUseCase,
    required SetTicketDiscountUseCase setTicketDiscountUseCase,
    required SetTicketReceivedCashUseCase setTicketReceivedCashUseCase,
    required AssociateTicketWithCashRegisterUseCase
        associateTicketWithCashRegisterUseCase,
    required PrepareSaleTicketUseCase prepareSaleTicketUseCase,
    required PrepareTicketForTransactionUseCase
        prepareTicketForTransactionUseCase,
    required SaveLastSoldTicketUseCase saveLastSoldTicketUseCase,
    required GetLastSoldTicketUseCase getLastSoldTicketUseCase,
    required AppDataPersistenceService persistenceService,
    required ThermalPrinterHttpService printerService,
    required CatalogueUseCases catalogueUseCases,
  })  : _persistenceService = persistenceService,
        _printerService = printerService,
        _addProductToTicketUseCase = addProductToTicketUseCase,
        _removeProductFromTicketUseCase = removeProductFromTicketUseCase,
        _createQuickProductUseCase = createQuickProductUseCase,
        _setTicketPaymentModeUseCase = setTicketPaymentModeUseCase,
        _setTicketDiscountUseCase = setTicketDiscountUseCase,
        _setTicketReceivedCashUseCase = setTicketReceivedCashUseCase,
        _associateTicketWithCashRegisterUseCase =
            associateTicketWithCashRegisterUseCase,
        _prepareSaleTicketUseCase = prepareSaleTicketUseCase,
        _prepareTicketForTransactionUseCase =
            prepareTicketForTransactionUseCase,
        _saveLastSoldTicketUseCase = saveLastSoldTicketUseCase,
        _getLastSoldTicketUseCase = getLastSoldTicketUseCase,
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
      profileAccountSelected: AccountProfile.empty(),
      currentAdminProfile: null,
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

    // Manejo especial para cuenta demo
    if (account.id == 'demo') {
      setAdminProfile(getUserAccountsUseCase.getDemoAdminProfile());
    } else if (authProvider.user?.email != null) {
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
    final id = await getUserAccountsUseCase.getSelectedAccountId();
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
  /// Carga AdminProfile desde persistencia local o Firebase
  ///
  /// **Flujo:**
  /// 1. Intenta cargar desde SharedPreferences
  /// 2. Si no existe en persistencia, se debe llamar initializeAdminProfile(email) externamente
  ///
  /// **NOTA:** Esta es una carga inicial optimista. La sincronización con Firebase
  /// se maneja mediante initializeAdminProfile() cuando hay usuario autenticado.
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
          print(
              '📦 SellProvider: No hay AdminProfile guardado en persistencia');
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
        await getUserAccountsUseCase
            .saveAdminProfile(_state.currentAdminProfile!);
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

  /// Agrega un producto al ticket
  ///
  /// RESPONSABILIDAD: Coordinar UI y persistencia
  /// La lógica de negocio (buscar, incrementar, agregar) está en SellUsecases
  Future<void> addProductsticket(ProductCatalogue product,
      {bool replaceQuantity = false}) async {
    // PASO 1: UseCase maneja toda la lógica de negocio con Either
    final result = await _addProductToTicketUseCase(
      AddProductToTicketParams(
        currentTicket: _state.ticket,
        product: product,
        replaceQuantity: replaceQuantity,
      ),
    );

    result.fold(
      (failure) {
        if (kDebugMode) {
          print('❌ Error agregando producto: ${failure.message}');
        }
      },
      (updatedTicket) {
        // PASO 2: Actualizar estado UI
        _state = _state.copyWith(ticket: updatedTicket);
        _saveTicket();
        notifyListeners();
      },
    );
  }

  /// Elimina un producto del ticket
  ///
  /// RESPONSABILIDAD: Coordinar UI y persistencia
  /// La lógica de negocio (filtrar producto) está en SellUsecases
  Future<void> removeProduct(ProductCatalogue product) async {
    // PASO 1: UseCase maneja la lógica de eliminación con Either
    final result = await _removeProductFromTicketUseCase(
      RemoveProductFromTicketParams(
        currentTicket: _state.ticket,
        product: product,
      ),
    );

    result.fold(
      (failure) {
        if (kDebugMode) {
          print('❌ Error eliminando producto: ${failure.message}');
        }
      },
      (updatedTicket) {
        // PASO 2: Actualizar estado UI (cerrar vista si no hay productos)
        _state = _state.copyWith(
          ticket: updatedTicket,
          ticketView: updatedTicket.products.isNotEmpty,
        );
        _saveTicket();
        notifyListeners();
      },
    );
  }

  void discartTicket() {
    _state = _state.copyWith(
      ticket: TicketModel(listPoduct: [], creation: Timestamp.now()),
      ticketView: false,
    );
    _saveTicket();
    notifyListeners();
  }

  Future<void> addQuickProduct(
      {required String description, required double salePrice}) async {
    final result = await _createQuickProductUseCase(
      CreateQuickProductParams(
        description: description,
        salePrice: salePrice,
      ),
    );

    await result.fold(
      (failure) async {
        if (kDebugMode) {
          print('❌ Error creando producto rápido: ${failure.message}');
        }
      },
      (product) async {
        await addProductsticket(product, replaceQuantity: true);
      },
    );
  }

  Future<void> _saveSelectedAccount(String id) async {
    await getUserAccountsUseCase.saveSelectedAccountId(id);
  }

  /// Configura la forma de pago del ticket
  ///
  /// RESPONSABILIDAD: Coordinar UI y persistencia
  /// La lógica de negocio (validar, resetear valor recibido) está en SetTicketPaymentModeUseCase
  Future<void> setPayMode({String payMode = 'effective'}) async {
    final result = await _setTicketPaymentModeUseCase(
      SetTicketPaymentModeParams(
        currentTicket: _state.ticket,
        payMode: payMode,
      ),
    );

    result.fold(
      (failure) {
        if (kDebugMode) {
          print('❌ Error configurando forma de pago: ${failure.message}');
        }
      },
      (updatedTicket) {
        _state = _state.copyWith(ticket: updatedTicket);
        _saveTicket();
        notifyListeners();
      },
    );
  }

  /// Configura el descuento del ticket
  ///
  /// RESPONSABILIDAD: Coordinar UI y persistencia
  /// La lógica de negocio (validar descuento no negativo) está en SetTicketDiscountUseCase
  Future<void> setDiscount(
      {required double discount, bool isPercentage = false}) async {
    final result = await _setTicketDiscountUseCase(
      SetTicketDiscountParams(
        currentTicket: _state.ticket,
        discount: discount,
        isPercentage: isPercentage,
      ),
    );

    result.fold(
      (failure) {
        if (kDebugMode) {
          print('❌ Error configurando descuento: ${failure.message}');
        }
      },
      (updatedTicket) {
        _state = _state.copyWith(ticket: updatedTicket);
        _saveTicket();
        notifyListeners();
      },
    );
  }

  /// Configura el valor recibido en efectivo
  ///
  /// RESPONSABILIDAD: Coordinar UI y persistencia
  /// La lógica de negocio (validar valor no negativo) está en SetTicketReceivedCashUseCase
  Future<void> setReceivedCash(double value) async {
    final result = await _setTicketReceivedCashUseCase(
      SetTicketReceivedCashParams(
        currentTicket: _state.ticket,
        value: value,
      ),
    );

    result.fold(
      (failure) {
        if (kDebugMode) {
          print('❌ Error configurando valor recibido: ${failure.message}');
        }
      },
      (updatedTicket) {
        _state = _state.copyWith(ticket: updatedTicket);
        _saveTicket();
        notifyListeners();
      },
    );
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
  /// La lógica de persistencia está en SaveLastSoldTicketUseCase
  ///
  /// 🆕 Este método mantiene sincronizado el estado en memoria con SharedPreferences
  Future<void> saveLastSoldTicket([TicketModel? ticket]) async {
    final ticketToSave = ticket ?? _state.ticket;

    final result = await _saveLastSoldTicketUseCase(
      SaveLastSoldTicketParams(ticket: ticketToSave),
    );

    result.fold(
      (failure) {
        if (kDebugMode) {
          print('❌ Error guardando último ticket: ${failure.message}');
        }
      },
      (_) {
        _state = _state.copyWith(lastSoldTicket: ticketToSave);
        notifyListeners();
        if (kDebugMode) {
          print('✅ Último ticket guardado: ${ticketToSave.id}');
        }
      },
    );
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
    final result = await _getLastSoldTicketUseCase(const NoParams());

    result.fold(
      (failure) {
        if (kDebugMode) {
          print('⚠️ Error recargando lastSoldTicket: ${failure.message}');
        }
      },
      (lastTicket) {
        _state = _state.copyWith(lastSoldTicket: lastTicket);
        notifyListeners();
        if (kDebugMode) {
          print('✅ Estado lastSoldTicket recargado desde persistencia');
        }
      },
    );
  }

  /// Carga el último ticket vendido desde almacenamiento local
  ///
  /// RESPONSABILIDAD: Solo actualizar estado UI con datos del UseCase
  Future<void> _loadLastSoldTicket() async {
    final result = await _getLastSoldTicketUseCase(const NoParams());

    result.fold(
      (failure) {
        if (kDebugMode) {
          print('⚠️ Error cargando último ticket: ${failure.message}');
        }
        _state = _state.copyWith(lastSoldTicket: null);
        notifyListeners();
      },
      (lastTicket) {
        _state = _state.copyWith(lastSoldTicket: lastTicket);
        notifyListeners();
      },
    );
  }

  /// Actualiza el ticket con la caja registradora activa
  ///
  /// RESPONSABILIDAD: Coordinar UI con datos de caja activa
  /// La lógica de asociación está en AssociateTicketWithCashRegisterUseCase
  Future<void> updateTicketWithCashRegister(BuildContext context) async {
    final cashRegisterProvider =
        provider.Provider.of<CashRegisterProvider>(context, listen: false);

    if (cashRegisterProvider.hasActiveCashRegister) {
      final activeCashRegister =
          cashRegisterProvider.currentActiveCashRegister!;

      final result = await _associateTicketWithCashRegisterUseCase(
        AssociateTicketWithCashRegisterParams(
          currentTicket: _state.ticket,
          cashRegister: activeCashRegister,
        ),
      );

      result.fold(
        (failure) {
          if (kDebugMode) {
            print('❌ Error asociando ticket con caja: ${failure.message}');
          }
        },
        (updatedTicket) {
          _state = _state.copyWith(ticket: updatedTicket);
          notifyListeners();
        },
      );
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

  /// Asegura que AdminProfile esté inicializado antes de procesar una venta
  ///
  /// **CRÍTICO**: Este método resuelve la condición de carrera donde la primera venta
  /// podría ejecutarse antes de que el AdminProfile esté completamente cargado.
  ///
  /// **NOTA**: Las ventas se pueden realizar sin caja registradora activa.
  /// La caja registradora es opcional - si no hay caja activa, la venta se guarda
  /// sin asociación a caja (cashRegisterId y cashRegisterName estarán vacíos).
  ///
  /// **Acciones:**
  /// 1. Si AdminProfile es null, intenta cargarlo desde AuthProvider
  Future<void> _ensureInitializedForSale(BuildContext context) async {
    final authProvider =
        provider.Provider.of<AuthProvider>(context, listen: false);

    // Verificar y cargar AdminProfile si no está disponible
    // Esto es necesario para identificar al vendedor que realiza la venta
    if (_state.currentAdminProfile == null &&
        authProvider.user?.email != null &&
        _state.profileAccountSelected.id.isNotEmpty) {
      if (kDebugMode) {
        print(
            '⚠️ SalesProvider: AdminProfile no disponible, cargando antes de la venta...');
      }
      await updateAdminProfileForSelectedAccount(authProvider.user!.email!);

      if (kDebugMode) {
        print(
            '✅ SalesProvider: AdminProfile cargado: ${_state.currentAdminProfile?.email}');
      }
    }

    // NOTA: No forzamos la inicialización de CashRegister aquí porque
    // las ventas pueden realizarse sin una caja activa seleccionada.
    // Si hay una caja activa, se asociará automáticamente en _prepareTicketForSale.
  }

  /// PROCESAMIENTO DE VENTA CONFIRMADA
  ///
  /// 1. Verificar y cargar AdminProfile si no está disponible
  /// 2. Preparar ticket (vendedor, caja opcional, precio, ID)
  /// 3. Guardar ticket en Firebase (transacciones)
  /// 4. Incrementar contador de ventas en caja (SOLO si hay caja activa y el guardado fue exitoso)
  /// 5. Actualizar estadísticas de productos y stock
  ///
  /// **NOTA**: Las ventas se pueden realizar sin caja registradora activa.
  ///
  /// ⚠️ IMPORTANTE: El contador 'sales' se incrementa DESPUÉS de guardar el ticket
  /// para garantizar que cashRegister.sales coincida con los tickets realmente guardados.
  Future<void> processSale(BuildContext context) async {
    try {
      if (kDebugMode) {
        print('🛒 processSale: Iniciando proceso de venta...');
        print(
            '   - AdminProfile: ${_state.currentAdminProfile?.email ?? "null"}');
        print('   - AccountProfile: ${_state.profileAccountSelected.id}');
      }

      // PASO 0: Asegurar que AdminProfile y CashRegister estén inicializados
      await _ensureInitializedForSale(context);

      // PASO 1: Preparar el ticket con toda la información necesaria (vendedor, caja, precio, ID)
      await _prepareTicketForSale(context);

      if (kDebugMode) {
        print('📋 processSale: Ticket preparado');
        print('   - sellerId: ${_state.ticket.sellerId}');
        print('   - sellerName: ${_state.ticket.sellerName}');
        print('   - cashRegisterId: ${_state.ticket.cashRegisterId}');
      }

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
        ScaffoldMessenger.of(context).clearSnackBars();
        final uniqueKey = UniqueKey();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            key: uniqueKey,
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
  /// La lógica de validación, transformación y generación de ID está en PrepareSaleTicketUseCase
  ///
  /// **NOTA**: El sellerId y sellerName corresponden al usuario administrador
  /// que realiza la venta (currentAdminProfile), NO a la cuenta del comercio.
  ///
  /// **JERARQUÍA DE FALLBACK para datos del vendedor:**
  /// 1. currentAdminProfile (perfil del admin logueado)
  /// 2. AuthProvider.user (usuario autenticado - email)
  /// 3. profileAccountSelected (cuenta comercial seleccionada)
  Future<void> _prepareTicketForSale(BuildContext context) async {
    final cashRegisterProvider =
        provider.Provider.of<CashRegisterProvider>(context, listen: false);
    final authProvider =
        provider.Provider.of<AuthProvider>(context, listen: false);

    final activeCashRegister = cashRegisterProvider.hasActiveCashRegister
        ? cashRegisterProvider.currentActiveCashRegister
        : null;

    // Obtener datos del vendedor con jerarquía de fallbacks
    // PRIORIDAD 1: AdminProfile (contiene email y nombre del admin)
    // PRIORIDAD 2: AuthProvider.user (email del usuario autenticado)
    // PRIORIDAD 3: AccountProfile (datos de la cuenta comercial)
    String sellerId;
    String sellerName;

    if (_state.currentAdminProfile?.id.isNotEmpty == true) {
      // Usar AdminProfile si está disponible
      sellerId = _state.currentAdminProfile!.id;
      sellerName = _state.currentAdminProfile!.name.isNotEmpty
          ? _state.currentAdminProfile!.name
          : _state.currentAdminProfile!.email;
    } else if (authProvider.user?.email?.isNotEmpty == true) {
      // Fallback a datos del usuario autenticado
      sellerId = authProvider.user!.email!;
      sellerName = authProvider.user!.displayName?.isNotEmpty == true
          ? authProvider.user!.displayName!
          : authProvider.user!.email!;
      if (kDebugMode) {
        print(
            '⚠️ _prepareTicketForSale: Usando AuthProvider como fallback - sellerId: $sellerId');
      }
    } else {
      // Fallback final a datos de la cuenta comercial
      sellerId = _state.profileAccountSelected.id;
      sellerName = _state.profileAccountSelected.name;
      if (kDebugMode) {
        print(
            '⚠️ _prepareTicketForSale: Usando AccountProfile como fallback - sellerId: $sellerId');
      }
    }

    if (kDebugMode) {
      print(
          '📝 _prepareTicketForSale: sellerId=$sellerId, sellerName=$sellerName');
    }

    final result = await _prepareSaleTicketUseCase(
      PrepareSaleTicketParams(
        currentTicket: _state.ticket,
        sellerId: sellerId,
        sellerName: sellerName,
        activeCashRegister: activeCashRegister,
      ),
    );

    result.fold(
      (failure) {
        if (kDebugMode) {
          print('❌ Error preparando ticket para venta: ${failure.message}');
        }
        throw Exception(failure.message);
      },
      (preparedTicket) {
        _state = _state.copyWith(ticket: preparedTicket);
      },
    );
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

      // Si es cuenta demo, no procesamos caja en Firebase
      if (_state.profileAccountSelected.id == 'demo') {
        return;
      }

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
    await _printerService.initialize();

    if (_printerService.isConnected) {
      // Si hay impresora conectada, imprimir directamente
      await _printTicketDirectly(context, _printerService);
    } else {
      // Si no hay impresora, mostrar diálogo de opciones
      await _showTicketOptionsDialog(context);
    }
  }

  /// Imprime el ticket directamente usando la impresora térmica
  Future<void> _printTicketDirectly(
      BuildContext context, ThermalPrinterHttpService printerService) async {
    try {
      // Determinar método de pago usando el enum centralizado
      final paymentMethod = PaymentMethod.fromCode(_state.ticket.payMode);
      final paymentMethodLabel = paymentMethod.displayName;

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
        paymentMethod: paymentMethodLabel,
        cashReceived: _state.ticket.valueReceived > 0
            ? _state.ticket.valueReceived
            : null,
        change: _state.ticket.valueReceived > _state.ticket.getTotalPrice
            ? _state.ticket.valueReceived - _state.ticket.getTotalPrice
            : null,
      );

      // Mostrar resultado
      if (context.mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        final uniqueKey = UniqueKey();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            key: uniqueKey,
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
        ScaffoldMessenger.of(context).clearSnackBars();
        final uniqueKey = UniqueKey();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            key: uniqueKey,
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
    final result = await _prepareTicketForTransactionUseCase(
      PrepareTicketForTransactionParams(ticket: _state.ticket),
    );

    late TicketModel preparedTicket;
    result.fold(
      (failure) {
        if (kDebugMode) {
          print(
              '❌ Error preparando ticket para transacción: ${failure.message}');
        }
        throw Exception(failure.message);
      },
      (ticket) {
        preparedTicket = ticket;
      },
    );

    // PASO 2: Actualizar el ticket actual con el preparado (tiene ID generado si estaba vacío)
    _state = _state.copyWith(ticket: preparedTicket);

    // PASO 3: Guardar en historial (Firebase + SharedPreferences automático)
    // ⚠️ IMPORTANTE: Verificar que el guardado fue exitoso antes de continuar

    // Si es cuenta demo, simulamos el guardado exitoso
    if (_state.profileAccountSelected.id == 'demo') {
      _state = _state.copyWith(lastSoldTicket: preparedTicket);
      notifyListeners();
      return;
    }

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

      // Si es cuenta demo, no actualizamos estadísticas en Firebase
      if (accountId == 'demo') {
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
        ScaffoldMessenger.of(context).clearSnackBars();
        final uniqueKey = UniqueKey();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            key: uniqueKey,
            content: const Row(
              children: [
                Icon(Icons.warning, color: Colors.white),
                SizedBox(width: 8),
                Expanded(
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
