import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sellweb/core/services/theme_service.dart';
import 'package:sellweb/data/account_repository_impl.dart';
import 'package:sellweb/domain/usecases/account_usecase.dart';
import 'package:sellweb/presentation/providers/printer_provider.dart';
import 'package:sellweb/presentation/providers/sell_provider.dart';
import 'firebase_options.dart';
import 'data/auth_repository_impl.dart';
import 'data/catalogue_repository_impl.dart';
import 'data/cash_register_repository_impl.dart';
import 'domain/usecases/auth_usecases.dart';
import 'domain/usecases/catalogue_usecases.dart';
import 'domain/usecases/cash_register_usecases.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/catalogue_provider.dart';
import 'presentation/providers/cash_register_provider.dart';
import 'presentation/providers/theme_data_app_provider.dart';
import 'presentation/pages/login_page.dart';
import 'presentation/pages/sell_page.dart';
import 'presentation/pages/welcome_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Inicializar SharedPreferences
  final prefs = await SharedPreferences.getInstance();

  // Inicializar repositorios
  final authRepository =
      AuthRepositoryImpl(fb_auth.FirebaseAuth.instance, GoogleSignIn());
  final accountRepository = AccountRepositoryImpl(prefs: prefs);
  final getUserAccountsUseCase = GetUserAccountsUseCase(accountRepository);

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
          create: (_) =>
              SellProvider(getUserAccountsUseCase: getUserAccountsUseCase),
          update: (_, auth, previousSell) =>
              previousSell ??
              SellProvider(getUserAccountsUseCase: getUserAccountsUseCase),
        ),
      ],
      child: Consumer<ThemeDataAppProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'Sell Web',
            debugShowCheckedModeBanner: false,
            theme: ThemeService.lightTheme,
            darkTheme: ThemeService.darkTheme,
            themeMode: themeProvider.themeMode,
            home: Consumer<AuthProvider>(
              builder: (context, authProvider, _) {
                if (authProvider.user == null) {
                  return LoginPage(authProvider: authProvider);
                }

                return Consumer<SellProvider>(
                  builder: (context, sellProvider, _) {
                    if (sellProvider.profileAccountSelected.id.isEmpty) {
                      return WelcomePage(
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
  final cashRegisterRepository = CashRegisterRepositoryImpl();

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
          getUserAccountsUseCase: GetUserAccountsUseCase(accountRepository),
        )..initCatalogue(accountId),
      ),
      ChangeNotifierProvider(
        create: (_) => CashRegisterProvider(
          CashRegisterUsecases(cashRegisterRepository),
        ),
      ),
    ],
    child: const SellPage(),
  );
}
