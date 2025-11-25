import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'features/auth/domain/usecases/get_user_accounts_usecase.dart';
import 'package:sellweb/features/home/presentation/pages/home_page.dart';
import 'package:sellweb/core/services/printing/printer_provider.dart';
import 'package:sellweb/features/home/presentation/providers/home_provider.dart';
import 'package:sellweb/features/sales/presentation/providers/sales_provider.dart';
import 'core/config/firebase_options.dart';
import 'core/services/storage/app_data_persistence_service.dart'; // NUEVO
import 'core/di/injection_container.dart'; // ← NUEVO: Dependency Injection
import 'features/catalogue/data/repositories/catalogue_repository_impl.dart';
import 'package:sellweb/features/cash_register/data/repositories/cash_register_repository_impl.dart';
import 'package:sellweb/features/catalogue/domain/usecases/catalogue_usecases.dart';
import 'package:sellweb/features/cash_register/domain/usecases/cash_register_usecases.dart';
import 'package:sellweb/features/sales/domain/usecases/sell_usecases.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/catalogue/presentation/providers/catalogue_provider.dart';
import 'package:sellweb/features/cash_register/presentation/providers/cash_register_provider.dart';
import 'package:sellweb/core/presentation/providers/theme_provider.dart';
import 'package:sellweb/features/landing/presentation/pages/landing_page.dart';

void main() async {
  // CRITICAL: Initialize bindings FIRST in the main zone, synchronously
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase initialization in the SAME zone as runApp
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // ← NUEVO: Configurar inyección de dependencias para Clean Architecture
  configureDependencies();

  // Run app initialization
  _runApp();
}

void _runApp() {
  // Inicializar repositorios
  final catalogueRepository = CatalogueRepositoryImpl();

  runApp(
    MultiProvider(
      providers: [
        // Providers globales que no dependen del estado de autenticación
        ChangeNotifierProvider(create: (_) => ThemeDataAppProvider()),
        ChangeNotifierProvider(create: (_) => PrinterProvider()..initialize()),
        ChangeNotifierProvider(create: (_) => HomeProvider()),

        // AuthProvider - gestiona el estado de autenticación
        ChangeNotifierProvider(
          create: (_) => getIt<AuthProvider>(),
        ),

        // SalesProvider - creado una sola vez y reutilizado
        ChangeNotifierProxyProvider<AuthProvider, SalesProvider>(
          create: (_) {
            final persistenceService = AppDataPersistenceService.instance;
            final sellUsecases = SellUsecases(
              persistenceService: persistenceService,
            );
            final catalogueUseCases = CatalogueUseCases(catalogueRepository);
            return SalesProvider(
              getUserAccountsUseCase: getIt<GetUserAccountsUseCase>(),
              sellUsecases: sellUsecases,
              catalogueUseCases: catalogueUseCases,
            );
          },
          update: (_, auth, previousSell) {
            if (previousSell != null) return previousSell;
            final persistenceService = AppDataPersistenceService.instance;
            final sellUsecases = SellUsecases(
              persistenceService: persistenceService,
            );
            final catalogueUseCases = CatalogueUseCases(catalogueRepository);
            return SalesProvider(
              getUserAccountsUseCase: getIt<GetUserAccountsUseCase>(),
              sellUsecases: sellUsecases,
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
  // Crear repositorios específicos de la cuenta
  final catalogueRepository = CatalogueRepositoryImpl();

  // Inicializar casos de uso
  final cashRegisterRepository = CashRegisterRepositoryImpl();
  final cashRegisterUsecases = CashRegisterUsecases(cashRegisterRepository);
  final persistenceService = AppDataPersistenceService.instance;
  final sellUsecases = SellUsecases(
    persistenceService: persistenceService,
  );

  return MultiProvider(
    key: ValueKey('account_providers_$accountId'),
    providers: [
      // Providers específicos de la cuenta actual
      ChangeNotifierProvider(
        create: (_) {
          final catalogueUseCases = CatalogueUseCases(catalogueRepository);
          final catalogueProvider = CatalogueProvider(
            catalogueUseCases: catalogueUseCases,
          );

          if (accountId.isNotEmpty) {
            catalogueProvider.initCatalogue(accountId);
          }

          return catalogueProvider;
        },
      ),
      ChangeNotifierProvider(
        create: (_) => CashRegisterProvider(
          cashRegisterUsecases, // Operaciones de caja
          sellUsecases, // NUEVO: Operaciones de tickets
        ),
      ),
    ],
    child: const HomePage(),
  );
}
