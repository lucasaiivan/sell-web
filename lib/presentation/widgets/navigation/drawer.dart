import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/auth_provider.dart';
import '../../providers/sell_provider.dart';
import '../../providers/home_provider.dart';
import '../core_widgets.dart';

/// Widget reutilizable del Drawer para las pantallas principales
/// Muestra información de la cuenta seleccionada, controles de tema y acceso a funcionalidades
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Stack(
          children: [
            // button : cambiar el tema de la app
            Positioned(
              right: 8,
              top: 8,
              child: ThemeControlButtons(
                spacing: 4,
                iconSize: 20,
              ),
            ),
            // view : cuerpo del drawer
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.max,
              children: [
                const SizedBox(height: 30),
                // Cuenta seleccionada con avatar e información
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
                  child: _AccountsAssociatedsButton(
                    onTap: () => showAccountSelectionDialog(context: context),
                  ),
                ),
                const Divider(thickness: 0.08),
                const SizedBox(height: 12),
                const _NavigationMenu(),
                const Spacer(),
                const _DrawerFooter(),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Botón personalizado que muestra la cuenta seleccionada con avatar e información
class _AccountsAssociatedsButton extends StatelessWidget {
  final VoidCallback onTap;

  const _AccountsAssociatedsButton({
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Usar Consumer2 para escuchar cambios en AuthProvider y SellProvider
    return Consumer2<AuthProvider, SellProvider>(
      builder: (context, authProvider, sellProvider, child) {
        final selectedAccount = sellProvider.profileAccountSelected;
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        const double iconSize = 24;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Avatar del comercio
                  if (selectedAccount.id.isNotEmpty)
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: colorScheme.primary,
                          width: 2.0,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: iconSize / 2,
                        backgroundColor: colorScheme.primaryContainer,
                        backgroundImage: (selectedAccount.image.isNotEmpty &&
                                selectedAccount.image.contains('https://'))
                            ? NetworkImage(selectedAccount.image)
                            : null,
                        child: (selectedAccount.image.isEmpty)
                            ? Text(
                                selectedAccount.name.isNotEmpty
                                    ? selectedAccount.name[0].toUpperCase()
                                    : '?',
                                style: TextStyle(
                                  fontSize: iconSize * 0.30,
                                  color: colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),
                    ),

                  // Información de la cuenta seleccionada
                  if (selectedAccount.id.isNotEmpty) ...[
                    const SizedBox(width: 12),
                    Flexible(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            selectedAccount.name,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (sellProvider.currentAdminProfile?.email != null &&
                              sellProvider
                                  .currentAdminProfile!.email.isNotEmpty)
                            Text(
                              sellProvider.currentAdminProfile!.email,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                fontSize: 10,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _NavigationMenu extends StatelessWidget {
  const _NavigationMenu();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Consumer<HomeProvider>(
      builder: (context, homeProvider, _) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Material(
            color: Colors.transparent,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DrawerNavTile(
                  icon: Icons.point_of_sale,
                  label: 'Ventas',
                  description: 'Gestiona cobros y tickets',
                  index: 0,
                  currentIndex: homeProvider.currentPageIndex,
                  onSelected: () {
                    if (homeProvider.currentPageIndex != 0) {
                      homeProvider.setPageIndex(0);
                    }
                    Navigator.of(context).pop();
                  },
                  colorScheme: colorScheme,
                ),
                _DrawerNavTile(
                  icon: Icons.inventory_2,
                  label: 'Catálogo',
                  description: 'Administra productos y precios',
                  index: 1,
                  currentIndex: homeProvider.currentPageIndex,
                  onSelected: () {
                    if (homeProvider.currentPageIndex != 1) {
                      homeProvider.setPageIndex(1);
                    }
                    Navigator.of(context).pop();
                  },
                  colorScheme: colorScheme,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DrawerNavTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final int index;
  final int currentIndex;
  final VoidCallback onSelected;
  final ColorScheme colorScheme;

  const _DrawerNavTile({
    required this.icon,
    required this.label,
    required this.description,
    required this.index,
    required this.currentIndex,
    required this.onSelected,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = index == currentIndex;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: ListTile(
        leading: Icon(
          icon,
          color:
              isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
        ),
        title: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isSelected ? colorScheme.primary : colorScheme.onSurface,
          ),
        ),
        subtitle: Text(
          description,
          style: TextStyle(
            fontSize: 12,
            color: isSelected
                ? colorScheme.primary.withValues(alpha: 0.7)
                : colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: isSelected
            ? Icon(Icons.check_circle, color: colorScheme.primary)
            : null,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        tileColor: isSelected
            ? colorScheme.primaryContainer.withValues(alpha: 0.8)
            : null,
        onTap: onSelected,
      ),
    );
  }
}

class _DrawerFooter extends StatelessWidget {
  const _DrawerFooter();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Divider(thickness: 0.1, color: Colors.grey.shade300),
          const SizedBox(height: 8),
          Text(
            '¡Más funciones en nuestra app móvil!',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.blueGrey.shade700,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ButtonApp.primary(
              borderRadius: 4,
              text: 'Descargar de Play Store',
              onPressed: () async {
                final url = Uri.parse(
                  'https://play.google.com/store/apps/details?id=com.logicabooleana.sell',
                );
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                }
              },
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
