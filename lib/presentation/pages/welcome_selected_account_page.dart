import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/core_widgets.dart';
import '../../../domain/entities/user.dart';
import '../../../presentation/providers/auth_provider.dart';
import '../../../presentation/providers/theme_data_app_provider.dart';

class WelcomeSelectedAccountPage extends StatelessWidget {
  final Future<void> Function(AccountProfile) onSelectAccount;

  const WelcomeSelectedAccountPage({super.key, required this.onSelectAccount});

  /// Obtiene la ubicación prioritaria de la cuenta
  String _getAccountLocation(AccountProfile account) {
    if (account.town.isNotEmpty) return account.town;
    if (account.province.isNotEmpty) return account.province;
    if (account.country.isNotEmpty) return account.country;
    if (account.countrycode.isNotEmpty) return account.countrycode;
    return '';
  }

  /// Construye una tarjeta de cuenta con avatar, nombre y ubicación mejorada
  Widget _buildAccountCard(BuildContext context, AccountProfile account) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Obtener la ubicación con prioridad
    final location = _getAccountLocation(account);

    return InkWell(
      onTap: () async => await onSelectAccount(account),
      splashColor: colorScheme.primary.withValues(alpha: 0.1),
      highlightColor: colorScheme.primary.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Avatar mejorado con sombra sutil
            UserAvatar(
              imageUrl: account.image,
              text:
                  account.name.isNotEmpty ? account.name[0].toUpperCase() : '',
              radius: 22,
              backgroundColor: colorScheme.primaryContainer,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Nombre de la cuenta con mejor tipografía
                  Text(
                    account.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (account.id == 'demo') ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: colorScheme.tertiaryContainer,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'MODO PRUEBA',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onTertiaryContainer,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                  if (location.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    // Ubicación con icono y mejor estilo
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 13,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            location,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w400,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            // Icono de flecha para indicar acción
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // providers
    final authProvider = Provider.of<AuthProvider>(context);
    List<AccountProfile> accounts = authProvider.getUserAccountsUseCase
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
                  const Icon(Icons.storefront,
                      size: 80, color: Colors.blueGrey),
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
                  if (authProvider.isLoadingAccounts)
                    const Center(child: CircularProgressIndicator()),
                  if (accounts.isEmpty &&
                      authProvider.isLoadingAccounts == false)
                    // Si no hay cuentas disponibles, muestra un mensaje informativo
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
                  // view : lista de cuentas asociadas al usuario usando DialogComponents.itemList
                  if (accounts.isNotEmpty)
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: DialogComponents.itemList(
                        context: context,
                        items: accounts
                            .map((account) =>
                                _buildAccountCard(context, account))
                            .toList(),
                        showDividers: true,
                        maxVisibleItems: 4,
                        expandText: 'Ver más cuentas',
                        collapseText: 'Ver menos',
                        borderRadius: 16,
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .surface
                            .withValues(alpha: 0.5),
                      ),
                    ),
                  const SizedBox(height: 30),
                  // Botón para cerrar sesión del usuario
                  if (authProvider.user?.email != null)
                    const SizedBox(height: 50),
                  // text : Mostrar el correo electrónico del usuario
                  authProvider.isLoadingAccounts
                      ? Container()
                      : Column(
                          children: [
                            Text(
                              authProvider.user?.email ?? 'Invitado',
                              style: const TextStyle(
                                  fontSize: 16, color: Colors.grey),
                            ),
                            // button : Cerrar sesión de Firebase Auth
                            TextButton.icon(
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Confirmar'),
                                    content: const Text(
                                        '¿Seguro que deseas cerrar sesión?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(false),
                                        child: const Text('Cancelar'),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(true),
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
                            ),
                          ],
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
