import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sellweb/data/account_repository_impl.dart';
import 'package:sellweb/domain/usecases/account_usecase.dart';
import 'package:sellweb/presentation/providers/sell_provider.dart';
import 'firebase_options.dart';
import 'data/auth_repository_impl.dart';
import 'data/catalogue_repository_impl.dart';
import 'domain/usecases/auth_usecases.dart';
import 'domain/usecases/catalogue_usecases.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/catalogue_provider.dart';
import 'presentation/providers/theme_data_app_provider.dart';
import 'presentation/pages/login_page.dart';
import 'presentation/pages/sell_page.dart';
import 'presentation/pages/welcome_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Inicializar SharedPreferences
  final prefs = await SharedPreferences.getInstance();

  // Inicializar repositorios para autenticación del usuario
  final authRepository =
      AuthRepositoryImpl(fb_auth.FirebaseAuth.instance, GoogleSignIn());
  final accountRepository = AccountRepositoryImpl(prefs: prefs);

  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(
        create: (_) => AuthProvider(
          signInWithGoogleUseCase: SignInWithGoogleUseCase(authRepository),
          signInSilentlyUseCase: SignInSilentlyUseCase(authRepository),
          signOutUseCase: SignOutUseCase(authRepository),
          getUserStreamUseCase: GetUserStreamUseCase(authRepository),
          getUserAccountsUseCase: GetUserAccountsUseCase(accountRepository),
        ),
      ),
      ChangeNotifierProvider(create: (_) => ThemeDataAppProvider()),
    ],
    child: Consumer<ThemeDataAppProvider>(
      builder: (context, themeProvider, _) {
        return MaterialApp(
          title: 'Sell Web',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
            useMaterial3: true,
            brightness: Brightness.light,
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.blue, brightness: Brightness.dark),
            useMaterial3: true,
            brightness: Brightness.dark,
          ),
          themeMode: themeProvider.themeMode,
          home: Consumer<AuthProvider>(
            builder: (context, authProvider, _) {
              if (authProvider.user != null) {
                return ChangeNotifierProvider(
                  create: (_) => SellProvider(
                      getUserAccountsUseCase:
                          GetUserAccountsUseCase(accountRepository)),
                  child: Consumer<SellProvider>(
                    builder: (context, sellProvider, _) {
                      // Si no hay cuenta seleccionada, mostrar WelcomePage para seleccionar una cuenta
                      if (sellProvider.profileAccountSelected.id == '') {
                        return WelcomePage(
                          onSelectAccount: (account) async {
                            await sellProvider.initAccount(
                                account: account, context: context);
                          },
                        );
                      }
                      // Si hay cuenta seleccionada, usar Consumer para reaccionar a cambios
                      return Consumer<SellProvider>(
                        builder: (context, sellProvider, _) {
                          final accountId =
                              sellProvider.profileAccountSelected.id;
                          final catalogueRepository =
                              CatalogueRepositoryImpl(id: accountId);
                          final getProductsStreamUseCase =
                              GetCatalogueStreamUseCase(catalogueRepository);
                          final getProductByCodeUseCase =
                              GetProductByCodeUseCase();
                          final isProductScannedUseCase =
                              IsProductScannedUseCase(getProductByCodeUseCase);
                          final getPublicProductByCodeUseCase =
                              GetPublicProductByCodeUseCase(
                                  CatalogueRepositoryImpl());
                          final addProductToCatalogueUseCase =
                              AddProductToCatalogueUseCase(catalogueRepository);
                          final createPublicProductUseCase =
                              CreatePublicProductUseCase(catalogueRepository);
                          final getUserAccountsUseCase =
                              GetUserAccountsUseCase(accountRepository);

                          return MultiProvider(
                            // Usar key para forzar la recreación cuando cambia la cuenta
                            key: ValueKey('catalogue_$accountId'),
                            providers: [
                              // Reutilizar el SellProvider existente del contexto padre
                              ChangeNotifierProvider.value(value: sellProvider),
                              // Crear el CatalogueProvider con la cuenta actual
                              ChangeNotifierProvider(
                                create: (_) {
                                  final provider = CatalogueProvider(
                                    getProductsStreamUseCase:
                                        getProductsStreamUseCase,
                                    getProductByCodeUseCase:
                                        getProductByCodeUseCase,
                                    isProductScannedUseCase:
                                        isProductScannedUseCase,
                                    getPublicProductByCodeUseCase:
                                        getPublicProductByCodeUseCase,
                                    addProductToCatalogueUseCase:
                                        addProductToCatalogueUseCase,
                                    createPublicProductUseCase:
                                        createPublicProductUseCase,
                                    getUserAccountsUseCase:
                                        getUserAccountsUseCase,
                                  );
                                  // Inicializar el catálogo con el ID de la cuenta seleccionada
                                  provider.initCatalogue(accountId);
                                  return provider;
                                },
                              ),
                            ],
                            child: const SellPage(),
                          );
                        },
                      );
                    },
                  ),
                );
              } else {
                return LoginPage(authProvider: authProvider);
              }
            },
          ),
        );
      },
    ),
  ));
}
