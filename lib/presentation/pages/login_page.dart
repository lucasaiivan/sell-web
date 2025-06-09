import 'package:flutter/material.dart';
import '../providers/auth_provider.dart';

class LoginPage extends StatelessWidget {
  final AuthProvider authProvider;
  const LoginPage({super.key, required this.authProvider});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton.icon(
          icon: Image.asset(
            'web/icons/Icon-192.png',
            width: 24,
            height: 24,
          ),
          label: const Text('Iniciar sesión con Google'),
          onPressed: () async {
            await authProvider.signInWithGoogle();
          },
        ),
      ),
    );
  }
}
