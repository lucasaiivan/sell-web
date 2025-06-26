import 'package:firebase_core/firebase_core.dart' ;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:google_sign_in/google_sign_in.dart';
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

void main() async{

  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform );

  final authRepository = AuthRepositoryImpl(fb_auth.FirebaseAuth.instance,GoogleSignIn()); 


  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(
            signInWithGoogleUseCase: SignInWithGoogleUseCase(authRepository),
            signInSilentlyUseCase: SignInSilentlyUseCase(authRepository),
            signOutUseCase: SignOutUseCase(authRepository),
            getUserStreamUseCase: GetUserStreamUseCase(authRepository),
            getUserAccountsUseCase: GetUserAccountsUseCase(AccountRepositoryImpl()),
          )
        ),
        ChangeNotifierProvider(
          create: (_) => ThemeDataAppProvider(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeDataAppProvider>(
      builder: (context, themeProvider, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false, 
          title: 'Punto de Venta',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
            useMaterial3: true,
            brightness: Brightness.light,
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.dark),
            useMaterial3: true,
            brightness: Brightness.dark,
          ),
          themeMode: themeProvider.themeMode,
          home: Consumer<AuthProvider>(
            builder: (context, authProvider, _) {
              if (authProvider.user != null) {

                // Mostrar WelcomePage solo si no se ha seleccionado una cuenta
                // ... 
                // ...
                // ...

                // Proveedor de catálogo solo cuando el usuario está autenticado
                return MultiProvider(
                  providers: [
                    ChangeNotifierProvider(
                      create: (_) {
                        final userId = authProvider.user!.uid;
                        final getProductsStreamUseCase = GetCatalogueStreamUseCase(
                          CatalogueRepositoryImpl(id: userId),
                        );
                        final getProductByCodeUseCase = GetProductByCodeUseCase();
                        final isProductScannedUseCase = IsProductScannedUseCase(getProductByCodeUseCase);
                        return CatalogueProvider(
                          getProductsStreamUseCase: getProductsStreamUseCase,
                          getProductByCodeUseCase: getProductByCodeUseCase,
                          isProductScannedUseCase: isProductScannedUseCase,
                          getPublicProductByCodeUseCase: GetPublicProductByCodeUseCase(
                            CatalogueRepositoryImpl(), // Sin id para acceso público
                          ), addProductToCatalogueUseCase: AddProductToCatalogueUseCase(
                            CatalogueRepositoryImpl(id: userId),
                          ),
                        );
                      },
                    ),
                    ChangeNotifierProvider(
                      create: (_) => SellProvider(getUserAccountsUseCase: GetUserAccountsUseCase(AccountRepositoryImpl())),
                    ),
                  ],
                  child: SellPage(),
                );
              } else {
                return LoginPage(authProvider: authProvider);
              }
            },
          ),
        );
      },
    );
  }
}
