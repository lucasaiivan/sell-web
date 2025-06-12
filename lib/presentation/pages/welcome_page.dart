import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/user.dart';
import '../providers/auth_provider.dart';

class WelcomePage extends StatelessWidget {

  final void Function(ProfileAccountModel) onSelectAccount;
  
  const WelcomePage({super.key, required this.onSelectAccount});

  @override
  Widget build(BuildContext context) {
    
    final authProvider = Provider.of<AuthProvider>(context);
    final accounts = authProvider.accountsAssociateds;

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.account_circle_outlined, size: 80, color: Colors.blueGrey),
              const SizedBox(height: 24),
              const Text(
                '¡Bienvenido!',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                'Selecciona una cuenta para continuar',
                style: TextStyle(fontSize: 18, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              if (accounts.isEmpty)
                const Text('No tienes cuentas disponibles', style: TextStyle(color: Colors.redAccent)),
              if (accounts.isNotEmpty)
                ...accounts.map((account) => Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue.shade100,
                      child: Text(account.name.isNotEmpty ? account.name[0] : '?'),
                    ),
                    title: Text(account.name),
                    subtitle: Text(account.id),
                    onTap: () => onSelectAccount(account),
                  ),
                )),
            ],
          ),
        ),
      ),
    );
  }
}
