import 'package:flutter/material.dart';
import 'auth_provider.dart';

class HomePage extends StatelessWidget {
  final AuthProvider authProvider;
  const HomePage({super.key, required this.authProvider});

  @override
  Widget build(BuildContext context) {
    final user = authProvider.user;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bienvenido'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authProvider.signOut();
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (user?.photoUrl != null)
              CircleAvatar(
                backgroundImage: NetworkImage(user!.photoUrl!),
                radius: 40,
              ),
            const SizedBox(height: 16),
            Text('Hola, ${user?.displayName ?? 'Usuario'}'),
            Text(user?.email ?? ''),
          ],
        ),
      ),
    );
  }
}
