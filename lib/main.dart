import 'package:firebase_core/firebase_core.dart' ;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sellweb/presentation/providers/sell_provider.dart';
import 'firebase_options.dart';
import 'data/auth_repository_impl.dart';
import 'data/catalogue_repository_impl.dart';
import 'domain/usecases/auth_usecases.dart';
import 'domain/usecases/catalogue_usecases.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/catalogue_provider.dart';
import 'presentation/pages/login_page.dart';
import 'presentation/pages/sell_page.dart';

void main() async{

  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform );

  final authRepository = AuthRepositoryImpl(fb_auth.FirebaseAuth.instance,GoogleSignIn());
  final catalogueRepository = CatalogueRepositoryImpl();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(
            signInWithGoogleUseCase: SignInWithGoogleUseCase(authRepository),
            signOutUseCase: SignOutUseCase(authRepository),
            getUserStreamUseCase: GetUserStreamUseCase(authRepository),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) {
            final getProductsStreamUseCase = GetProductsStreamUseCase(catalogueRepository);
            final getProductByCodeUseCase = GetProductByCodeUseCase();
            final isProductScannedUseCase = IsProductScannedUseCase(getProductByCodeUseCase);
            return CatalogueProvider(
              getProductsStreamUseCase: getProductsStreamUseCase,
              getProductByCodeUseCase: getProductByCodeUseCase,
              isProductScannedUseCase: isProductScannedUseCase,
            );
          },
        ),
        ChangeNotifierProvider(
          create: (_) => HomeProvider(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SellWeb',
      home: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          if (authProvider.user != null) {
            return HomePage();
          } else {
            return LoginPage(authProvider: authProvider);
          }
        },
      ),
    );
  }
}
