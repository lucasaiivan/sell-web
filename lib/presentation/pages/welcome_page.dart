import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:web/web.dart' as html;

import '../../domain/entities/user.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_data_app_provider.dart';

class WelcomePage extends StatelessWidget {
  final Future<void> Function(ProfileAccountModel) onSelectAccount;

  const WelcomePage({super.key, required this.onSelectAccount});

  @override
  Widget build(BuildContext context) {
    html.document.title = 'Bienvenido';

    // providers
    final authProvider = Provider.of<AuthProvider>(context);
    List<ProfileAccountModel> accounts = authProvider.getUserAccountsUseCase
        .getAccountsWithDemo(authProvider.accountsAssociateds,
            isAnonymous: authProvider.user?.isAnonymous == true);

    return Scaffold(
      body: Stack(
        children: [
          // view : body
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.storefront, size: 80, color: Colors.blueGrey),
                  const SizedBox(height: 12),
                  const Text('¡Bienvenido!',
                      style:
                          TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 50),
                  if (accounts.isNotEmpty)
                    const Text(
                      'Selecciona una cuenta para continuar',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  const SizedBox(height: 24),
                  // view notification : si no hay cuentas disponibles, muestra un mensaje informativo
                  if (accounts.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.blueGrey.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blueGrey, width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.info_outline,
                              color: Colors.blueGrey, size: 18),
                          const SizedBox(width: 8),
                          const Flexible(
                            child: Text(
                              'No tienes cuentas disponibles',
                              style: TextStyle(
                                color: Colors.blueGrey,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  // view : muestra lista de cuentas asociadas al usuario
                  if (accounts.isNotEmpty)
                    ...accounts.map((account) => Container(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          constraints: const BoxConstraints(
                              minWidth: 220, maxWidth: 320),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withValues(alpha: 0.4),
                                width: 1),
                          ),
                          child: Material(
                            elevation: 0,
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () async => await onSelectAccount(account),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CircleAvatar(
                                      child: Text(
                                          account.name.isNotEmpty
                                              ? account.name[0]
                                              : '?'),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(account.name,
                                              style: const TextStyle(
                                                  fontWeight:
                                                      FontWeight.w600)),
                                          Opacity(
                                              opacity: 0.5,
                                              child: Text(account.country)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        )),
                  const SizedBox(height: 30),
                  // Botón para cerrar sesión del usuario
                  if (authProvider.user?.email != null)
                    const SizedBox(height: 50),
                  // text : Mostrar el correo electrónico del usuario
                  Text(
                    authProvider.user?.email ?? 'Invitado',
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  // button : Cerrar sesión de Firebase Auth
                  TextButton.icon(
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Confirmar'),
                          content:
                              const Text('¿Seguro que deseas cerrar sesión?'),
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
                    label: const Text('Cerrar sesión'),
                  )
                ],
              ),
            ),
          ),
          // button : cambiar el brillo de tema de la aplicación
          Positioned(
            top: 20,
            right: 20,
            child: Consumer<ThemeDataAppProvider>(
              builder: (context, themeProvider, _) => Material(
                color: Colors.transparent,
                child: IconButton(
                  icon: Icon(
                    themeProvider.themeMode == ThemeMode.dark
                        ? Icons.light_mode
                        : Icons.dark_mode,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  tooltip: 'Cambiar brillo',
                  onPressed: () => themeProvider.toggleTheme(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
