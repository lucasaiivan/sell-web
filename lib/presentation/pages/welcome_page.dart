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
        mainAxisSize: MainAxisSize.min,
        children: [
            const Icon(Icons.storefront, size: 80, color: Colors.blueGrey),
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
          ...accounts.map((account) => Container(
              margin: const EdgeInsets.symmetric(vertical: 6),
              constraints: const BoxConstraints(minWidth: 220, maxWidth: 320),
              child: Material(
              elevation:0,
              borderRadius: BorderRadius.circular(12),
                color: Colors.white.withValues(alpha: 0.1),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => onSelectAccount(account),
                child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                  CircleAvatar( 
                    child: Text(account.name.isNotEmpty ? account.name[0] : '?'),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(account.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                      Opacity(opacity: 0.5,child: Text(account.country)),
                    ],
                    ),
                  ),
                  ],
                ),
                ),
              ),
              ),
            )),

            // Botón para cerrar sesión del usuario
            if (authProvider.user?.email != null)
              const SizedBox(height:50),
              TextButton.icon(
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Confirmar'),
                    content: const Text('¿Seguro que deseas cerrar sesión?'),
                    actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancelar'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Cerrar sesión'),
                    ),
                    ],
                  ),
                  );
                  if (confirm == true) {
                  await authProvider.signOut();
                  }
                }, 
                icon: const Icon(Icons.logout),
                label: const Text('Cerrar sesión'),)
        ],
        ),
      ),
      ),
    );
  }
}
