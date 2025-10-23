import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sellweb/data/account_repository_impl.dart';
import 'package:sellweb/domain/usecases/account_usecase.dart';
import 'package:sellweb/presentation/providers/printer_provider.dart';
import 'package:sellweb/presentation/providers/sell_provider.dart';
import 'package:sellweb/presentation/widgets/views/welcome_selected_account_page.dart';
import 'core/config/firebase_options.dart';
import 'core/config/oauth_config.dart';
import 'core/services/storage/app_data_persistence_service.dart'; // NUEVO
import 'data/auth_repository_impl.dart';
import 'data/catalogue_repository_impl.dart';
import 'data/cash_register_repository_impl.dart';
import 'domain/usecases/auth_usecases.dart';
import 'domain/usecases/catalogue_usecases.dart';
import 'domain/usecases/cash_register_usecases.dart';
import 'domain/usecases/sell_usecases.dart'; // NUEVO
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/catalogue_provider.dart';
import 'presentation/providers/cash_register_provider.dart';
import 'presentation/providers/theme_data_app_provider.dart';
import 'presentation/pages/presentation_page.dart';
import 'presentation/pages/sell_page.dart';

void main() async {
  // CRITICAL: Initialize bindings FIRST in the main zone, synchronously
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase initialization in the SAME zone as runApp
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Run app initialization
  _runApp();
}

void _runApp() {

  // Configuración de GoogleSignIn usando configuración centralizada y segura
  final googleSignIn = GoogleSignIn(
    scopes: OAuthConfig.googleSignInScopes,
    clientId: OAuthConfig.googleSignInClientId,
  );

  // Inicializar repositorios
  final authRepository = AuthRepositoryImpl(
    fb_auth.FirebaseAuth.instance,
    googleSignIn,
  );
  final accountRepository = AccountRepositoryImpl();
  final getUserAccountsUseCase = GetUserAccountsUseCase(accountRepository);

  // Inicializar repositorio y usecases compartidos globalmente
  final cashRegisterRepository = CashRegisterRepositoryImpl();

  // Inicializar SellUsecases (lógica de negocio de tickets - compartido globalmente)
  final persistenceService = AppDataPersistenceService.instance;
  final sellUsecases = SellUsecases(
    repository: cashRegisterRepository,
    persistenceService: persistenceService,
  );

  runApp(
    MultiProvider(
      providers: [
        // Providers globales que no dependen del estado de autenticación
        ChangeNotifierProvider(create: (_) => ThemeDataAppProvider()),
        ChangeNotifierProvider(create: (_) => PrinterProvider()..initialize()),

        // AuthProvider - gestiona el estado de autenticación
        ChangeNotifierProvider(
          create: (_) => AuthProvider(
            signInWithGoogleUseCase: SignInWithGoogleUseCase(authRepository),
            signInSilentlyUseCase: SignInSilentlyUseCase(authRepository),
            signOutUseCase: SignOutUseCase(authRepository),
            getUserStreamUseCase: GetUserStreamUseCase(authRepository),
            getUserAccountsUseCase: getUserAccountsUseCase,
          ),
        ),

        // SellProvider - creado una sola vez y reutilizado
        ChangeNotifierProxyProvider<AuthProvider, SellProvider>(
          create: (_) => SellProvider(
            getUserAccountsUseCase: getUserAccountsUseCase,
            sellUsecases: sellUsecases, // NUEVO: Solo SellUsecases para tickets
          ),
          update: (_, auth, previousSell) =>
              previousSell ??
              SellProvider(
                getUserAccountsUseCase: getUserAccountsUseCase,
                sellUsecases:
                    sellUsecases, // NUEVO: Solo SellUsecases para tickets
              ),
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

                return Consumer<SellProvider>(
                  builder: (context, sellProvider, _) {
                    // 🆕 Inicializar AdminProfile cuando hay usuario autenticado y cuenta seleccionada
                    // Esto maneja el caso cuando el usuario recarga la app con una sesión activa
                    if (authProvider.user?.email != null &&
                        sellProvider.profileAccountSelected.id.isNotEmpty &&
                        sellProvider.currentAdminProfile == null) {
                      // Ejecutar en el siguiente frame para evitar setState durante build
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        sellProvider.initializeAdminProfile(authProvider.user!.email!);
                      });
                    }

                    if (sellProvider.profileAccountSelected.id.isEmpty) {
                      return WelcomeSelectedAccountPage(
                        onSelectAccount: (account) => sellProvider.initAccount(
                          account: account,
                          context: context,
                        ),
                      );
                    }

                    // Providers específicos de la cuenta seleccionada
                    return _buildAccountSpecificProviders(
                      accountId: sellProvider.profileAccountSelected.id,
                      sellProvider: sellProvider,
                      accountRepository: accountRepository,
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
  required SellProvider sellProvider,
  required AccountRepositoryImpl accountRepository,
}) {
  // Crear repositorios específicos de la cuenta
  final catalogueRepository = CatalogueRepositoryImpl(id: accountId);

  // Reutilizar el repository de cash register (ya está inicializado globalmente)
  // Compartir el mismo cashRegisterRepository pero crear nuevos UseCases
  final cashRegisterRepository = CashRegisterRepositoryImpl();
  final cashRegisterUsecases = CashRegisterUsecases(cashRegisterRepository);
  final persistenceService = AppDataPersistenceService.instance;
  final sellUsecases = SellUsecases(
    repository: cashRegisterRepository,
    persistenceService: persistenceService,
  );

  return MultiProvider(
    key: ValueKey('account_providers_$accountId'),
    providers: [
      // Providers específicos de la cuenta actual
      ChangeNotifierProvider(
        create: (_) => CatalogueProvider(
          getProductsStreamUseCase:
              GetCatalogueStreamUseCase(catalogueRepository),
          getProductByCodeUseCase: GetProductByCodeUseCase(),
          isProductScannedUseCase:
              IsProductScannedUseCase(GetProductByCodeUseCase()),
          getPublicProductByCodeUseCase:
              GetPublicProductByCodeUseCase(CatalogueRepositoryImpl()),
          addProductToCatalogueUseCase:
              AddProductToCatalogueUseCase(catalogueRepository),
          createPublicProductUseCase:
              CreatePublicProductUseCase(catalogueRepository),
          registerProductPriceUseCase:
              RegisterProductPriceUseCase(catalogueRepository),
          getUserAccountsUseCase: GetUserAccountsUseCase(accountRepository),
        )..initCatalogue(accountId),
      ),
      ChangeNotifierProvider(
        create: (_) => CashRegisterProvider(
          cashRegisterUsecases, // Operaciones de caja
          sellUsecases, // NUEVO: Operaciones de tickets
        ),
      ),
    ],
    child: const SellPage(),
  );
}
