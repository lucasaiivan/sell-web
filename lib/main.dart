import 'package:firebase_core/firebase_core.dart' ;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:google_sign_in/google_sign_in.dart';
import 'firebase_options.dart';
import 'domain.dart';
import 'data.dart';
import 'auth_provider.dart';
import 'login_page.dart';
import 'home_page.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final authRepository = AuthRepositoryImpl(
    fb_auth.FirebaseAuth.instance,
    GoogleSignIn(),
  );

  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthProvider(
        signInWithGoogleUseCase: SignInWithGoogleUseCase(authRepository),
        signOutUseCase: SignOutUseCase(authRepository),
        getUserStreamUseCase: GetUserStreamUseCase(authRepository),
      ),
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
      title: 'SellWeb',
      home: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          if (authProvider.user != null) {
            return HomePage(authProvider: authProvider);
          } else {
            return LoginPage(authProvider: authProvider);
          }
        },
      ),
    );
  }
}
