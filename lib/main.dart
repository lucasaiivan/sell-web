import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'features/auth/domain/usecases/get_user_accounts_usecase.dart';
import 'package:sellweb/features/home/presentation/pages/home_page.dart';
import 'package:sellweb/features/sales/presentation/providers/printer_provider.dart';
import 'package:sellweb/features/home/presentation/providers/home_provider.dart';
import 'package:sellweb/features/sales/presentation/providers/sales_provider.dart';
import 'core/config/firebase_options.dart';

import 'features/auth/presentation/providers/auth_provider.dart';
import 'package:sellweb/core/di/injection_container.dart';
import 'features/catalogue/presentation/providers/catalogue_provider.dart';
import 'features/catalogue/domain/usecases/catalogue_usecases.dart';
import 'package:sellweb/features/cash_register/presentation/providers/cash_register_provider.dart';
import 'package:sellweb/core/presentation/providers/theme_provider.dart';
import 'package:sellweb/core/presentation/providers/connectivity_provider.dart';
import 'package:sellweb/features/landing/presentation/pages/landing_page.dart';
import 'package:sellweb/features/analytics/presentation/providers/analytics_provider.dart';
import 'package:sellweb/core/presentation/providers/account_scope_provider.dart';
// Sales UseCases imports
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
import 'package:sellweb/core/services/theme/theme_service.dart';
import 'package:sellweb/core/services/storage/app_data_persistence_service.dart';
import 'package:sellweb/core/services/external/thermal_printer_http_service.dart';

void main() async {
  // CRITICAL: Initialize bindings FIRST in the main zone, synchronously
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase initialization in the SAME zone as runApp
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // ✅ NUEVO: Habilitar Persistencia Offline para todas las plataformas
  try {
    await FirebaseFirestore.instance.enablePersistence(
      const PersistenceSettings(synchronizeTabs: true),
    );
    debugPrint('✅ Persistencia offline habilitada correctamente');
  } catch (e) {
    // Común en modo incógnito o cuando ya está habilitada
    debugPrint('⚠️ No se pudo habilitar persistencia offline: $e');
  }

  // ← NUEVO: Configurar inyección de dependencias para Clean Architecture
  await configureDependencies();

  // Run app initialization
  _runApp();
}

void _runApp() {
  runApp(
    MultiProvider(
      providers: [
        // Providers globales que no dependen del estado de autenticación
        ChangeNotifierProvider(
          create: (_) => ThemeDataAppProvider(
            getIt<ThemeService>(),
            getIt<AppDataPersistenceService>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => ConnectivityProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => PrinterProvider(getIt<ThermalPrinterHttpService>())..initialize(),
        ),
        ChangeNotifierProvider(create: (_) => HomeProvider()),

        // AuthProvider - gestiona el estado de autenticación
        ChangeNotifierProvider(
          create: (_) => getIt<AuthProvider>(),
        ),

        // SalesProvider - creado una sola vez y reutilizado
        ChangeNotifierProxyProvider<AuthProvider, SalesProvider>(
          create: (_) => _createSalesProvider(),
          update: (_, auth, previousSell) {
            // Preservar instancia existente para mantener estado del ticket
            if (previousSell != null) {
              // Sincronizar AdminProfile cuando hay usuario autenticado y cuenta seleccionada
              if (auth.user?.email != null &&
                  previousSell.profileAccountSelected.id.isNotEmpty &&
                  previousSell.currentAdminProfile == null) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  previousSell.initializeAdminProfile(auth.user!.email!);
                });
              }
              return previousSell;
            }
            return _createSalesProvider();
          },
        ),
      ],
      child: Consumer<ThemeDataAppProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'Sell Web',
            debugShowCheckedModeBanner: false,
            theme: themeProvider.lightTheme,
            darkTheme: themeProvider.darkTheme,
            themeMode: themeProvider.themeMode,
            home: const _AppNavigator(),
          );
        },
      ),
    ),
  );
}

/// Widget navegador que maneja la transición entre login y home
///
/// **Responsabilidad:**
/// - Mostrar AppPresentationPage cuando no hay usuario autenticado
/// - Mostrar HomePage con providers de cuenta cuando hay usuario
/// - Gestionar ciclo de vida de providers sin destruirlos al hacer logout
class _AppNavigator extends StatefulWidget {
  const _AppNavigator();

  @override
  State<_AppNavigator> createState() => _AppNavigatorState();
}

class _AppNavigatorState extends State<_AppNavigator> {
  AccountScopeProvider? _accountScope;
  String? _lastAccountId;

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        // Usuario no autenticado: mostrar landing page
        if (authProvider.user == null) {
          // Limpiar providers si había sesión anterior
          if (_accountScope != null) {
            _accountScope!.reset();
          }
          return const AppPresentationPage();
        }

        // Usuario autenticado: mostrar home con providers
        final sellProvider = context.watch<SalesProvider>();
        final accountId = sellProvider.profileAccountSelected.id;

        // Crear o reutilizar AccountScopeProvider
        if (_accountScope == null) {
          _accountScope = getIt<AccountScopeProvider>();
        }

        // Inicializar para nueva cuenta si cambió
        if (accountId.isNotEmpty && accountId != _lastAccountId) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _accountScope!.initializeForAccount(accountId);
            _lastAccountId = accountId;
          });
        }

        return _buildAccountSpecificProviders(
          accountScope: _accountScope!,
        );
      },
    );
  }

  @override
  void dispose() {
    _accountScope?.reset();
    super.dispose();
  }
}

Widget _buildAccountSpecificProviders({
  required AccountScopeProvider accountScope,
}) {
  return MultiProvider(
    providers: [
      // Reutilizar AccountScopeProvider existente
      ChangeNotifierProvider.value(
        value: accountScope,
      ),
      // Exponer providers individuales para acceso directo desde widgets
      ChangeNotifierProxyProvider<AccountScopeProvider, CatalogueProvider>(
        create: (_) => accountScope.catalogueProvider,
        update: (_, scope, __) => scope.catalogueProvider,
      ),
      ChangeNotifierProxyProvider<AccountScopeProvider, CashRegisterProvider>(
        create: (_) => accountScope.cashRegisterProvider,
        update: (_, scope, __) => scope.cashRegisterProvider,
      ),
      ChangeNotifierProxyProvider<AccountScopeProvider, AnalyticsProvider>(
        create: (_) => accountScope.analyticsProvider,
        update: (_, scope, __) => scope.analyticsProvider,
      ),
    ],
    child: const HomePage(),
  );
}

/// Factory para crear SalesProvider con todas sus dependencias
///
/// **Ventajas:**
/// - Elimina duplicación de código
/// - Centraliza configuración de dependencias
/// - Facilita mantenimiento
SalesProvider _createSalesProvider() {
  return SalesProvider(
    getUserAccountsUseCase: getIt<GetUserAccountsUseCase>(),
    persistenceService: getIt<AppDataPersistenceService>(),
    printerService: getIt<ThermalPrinterHttpService>(),
    addProductToTicketUseCase: getIt<AddProductToTicketUseCase>(),
    removeProductFromTicketUseCase: getIt<RemoveProductFromTicketUseCase>(),
    createQuickProductUseCase: getIt<CreateQuickProductUseCase>(),
    setTicketPaymentModeUseCase: getIt<SetTicketPaymentModeUseCase>(),
    setTicketDiscountUseCase: getIt<SetTicketDiscountUseCase>(),
    setTicketReceivedCashUseCase: getIt<SetTicketReceivedCashUseCase>(),
    associateTicketWithCashRegisterUseCase: getIt<AssociateTicketWithCashRegisterUseCase>(),
    prepareSaleTicketUseCase: getIt<PrepareSaleTicketUseCase>(),
    prepareTicketForTransactionUseCase: getIt<PrepareTicketForTransactionUseCase>(),
    saveLastSoldTicketUseCase: getIt<SaveLastSoldTicketUseCase>(),
    getLastSoldTicketUseCase: getIt<GetLastSoldTicketUseCase>(),
    catalogueUseCases: getIt<CatalogueUseCases>(),
  );
}
