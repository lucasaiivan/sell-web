import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'features/auth/domain/usecases/get_user_accounts_usecase.dart';
import 'package:sellweb/features/home/presentation/pages/home_page.dart';
import 'package:sellweb/features/sales/presentation/providers/printer_provider.dart';
import 'package:sellweb/features/home/presentation/providers/home_provider.dart';
import 'package:sellweb/features/sales/presentation/providers/sales_provider.dart';
import 'core/config/firebase_options.dart';

import 'features/auth/presentation/providers/auth_provider.dart';
import 'package:sellweb/core/di/injection_container.dart';
import 'features/catalogue/presentation/providers/catalogue_provider.dart';
import 'features/catalogue/domain/repositories/catalogue_repository.dart';
import 'features/catalogue/domain/usecases/catalogue_usecases.dart';
import 'package:sellweb/features/cash_register/presentation/providers/cash_register_provider.dart';
import 'package:sellweb/core/presentation/providers/theme_provider.dart';
import 'package:sellweb/features/landing/presentation/pages/landing_page.dart';
import 'package:sellweb/features/analytics/presentation/providers/analytics_provider.dart';
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

  // ← NUEVO: Configurar inyección de dependencias para Clean Architecture
  await configureDependencies();

  // Run app initialization
  _runApp();
}

void _runApp() {
  // ✅ Obtener repositorio desde DI usando la interfaz (registrado como CatalogueRepository)
  final catalogueRepository = getIt<CatalogueRepository>();

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
          create: (_) => PrinterProvider(getIt<ThermalPrinterHttpService>())..initialize(),
        ),
        ChangeNotifierProvider(create: (_) => HomeProvider()),

        // AuthProvider - gestiona el estado de autenticación
        ChangeNotifierProvider(
          create: (_) => getIt<AuthProvider>(),
        ),

        // SalesProvider - creado una sola vez y reutilizado
        ChangeNotifierProxyProvider<AuthProvider, SalesProvider>(
          create: (_) {
            final catalogueUseCases = CatalogueUseCases(catalogueRepository);
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
              catalogueUseCases: catalogueUseCases,
            );
          },
          update: (_, auth, previousSell) {
            if (previousSell != null) return previousSell;
            final catalogueUseCases = CatalogueUseCases(catalogueRepository);
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
              catalogueUseCases: catalogueUseCases,
            );
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
            home: Consumer<AuthProvider>(
              builder: (context, authProvider, _) {
                if (authProvider.user == null) {
                  return const AppPresentationPage();
                }

                return Consumer<SalesProvider>(
                  builder: (context, sellProvider, _) {
                    // 🆕 Inicializar AdminProfile cuando hay usuario autenticado y cuenta seleccionada
                    // Esto maneja el caso cuando el usuario recarga la app con una sesión activa
                    if (authProvider.user?.email != null &&
                        sellProvider.profileAccountSelected.id.isNotEmpty &&
                        sellProvider.currentAdminProfile == null) {
                      // Ejecutar en el siguiente frame para evitar setState durante build
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        sellProvider
                            .initializeAdminProfile(authProvider.user!.email!);
                      });
                    }

                    // Providers específicos de la cuenta seleccionada
                    return _buildAccountSpecificProviders(
                      accountId: sellProvider.profileAccountSelected.id,
                      sellProvider: sellProvider,
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    ),
  );
}

Widget _buildAccountSpecificProviders({
  required String accountId,
  required SalesProvider sellProvider,
}) {
  return MultiProvider(
    key: ValueKey('account_providers_$accountId'),
    providers: [
      // Providers específicos de la cuenta actual
      ChangeNotifierProvider(
        create: (_) {
          final catalogueProvider = getIt<CatalogueProvider>();

          if (accountId.isNotEmpty) {
            catalogueProvider.initCatalogue(accountId);
          }

          return catalogueProvider;
        },
      ),
      ChangeNotifierProvider(
        create: (_) {
          final cashRegisterProvider = getIt<CashRegisterProvider>();
          cashRegisterProvider.initializeFromPersistence(accountId);
          return cashRegisterProvider;
        },
      ),
      // AnalyticsProvider - métricas de ventas
      ChangeNotifierProvider(
        create: (_) {
          final analyticsProvider = getIt<AnalyticsProvider>();
          if (accountId.isNotEmpty) {
            analyticsProvider.subscribeToAnalytics(accountId);
          }
          return analyticsProvider;
        },
      ),
    ],
    child: const HomePage(),
  );
}
