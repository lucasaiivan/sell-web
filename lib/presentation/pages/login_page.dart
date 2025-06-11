import 'package:flutter/material.dart';
import '../providers/auth_provider.dart';

class LoginPage extends StatelessWidget {
  final AuthProvider authProvider;
  const LoginPage({super.key, required this.authProvider});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,

          children: [
            // text
            const Text(
                'Sell',
                style: TextStyle(
                  fontSize: 60, 
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                '¡Gestiona tus ventas de manera fácil y rápida!',
                textAlign: TextAlign.center,
                style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
                ), 
            ),
            const SizedBox(height: 150),
            // button
            ElevatedButton.icon( 
              label: const Text('Iniciar sesión con Google'),
              onPressed: () async {
                await authProvider.signInWithGoogle();
              },
            ),
          ],
        ),
      ),
    );
  }
}
