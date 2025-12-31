import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sellweb/core/presentation/providers/theme_provider.dart';
import 'package:sellweb/core/presentation/providers/connectivity_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sellweb/features/auth/presentation/providers/auth_provider.dart';
import 'package:sellweb/features/auth/presentation/dialogs/account_selection_dialog.dart';
import 'package:sellweb/features/auth/domain/entities/admin_profile.dart';
import 'package:sellweb/features/sales/presentation/providers/sales_provider.dart';
import 'package:sellweb/features/home/presentation/providers/home_provider.dart';
import '../widgets.dart';

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
              child: ThemeBrightnessButton(
                iconSize: 20,
                iconColor: Theme.of(context).colorScheme.primary,
                themeProvider:
                    Provider.of<ThemeDataAppProvider>(context, listen: false),
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
                const Divider(thickness: 0.3, endIndent: 75, indent: 75),
                const SizedBox(height: 20),
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
    // Usar Consumer3 para escuchar cambios en AuthProvider, SalesProvider y ConnectivityProvider
    return Consumer3<AuthProvider, SalesProvider, ConnectivityProvider>(
      builder: (context, authProvider, sellProvider, connectivity, child) {
        final selectedAccount = sellProvider.profileAccountSelected;
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        final isOffline = connectivity.isOffline;

        return Opacity(
          opacity: isOffline ? 0.5 : 1.0, // Reducir opacidad si está offline
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: isOffline ? null : onTap, // Deshabilitar si está offline
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
                        child: UserAvatar(
                          imageUrl: selectedAccount.image,
                          text: selectedAccount.name.isNotEmpty
                              ? selectedAccount.name[0].toUpperCase()
                              : '?',
                          radius: 16,
                          backgroundColor:
                              colorScheme.primaryContainer.withValues(
                            alpha: 0.9,
                          ),
                          foregroundColor: colorScheme.onPrimaryContainer,
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
                            if (sellProvider.currentAdminProfile?.email !=
                                    null &&
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
                      // Icono de offline si está deshabilitado
                      if (isOffline) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.cloud_off,
                          size: 16,
                          color: colorScheme.onSurfaceVariant
                              .withValues(alpha: 0.5),
                        ),
                      ],
                    ],
                  ],
                ),
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

    return Consumer3<HomeProvider, ConnectivityProvider, SalesProvider>(
      builder: (context, homeProvider, connectivity, sellProvider, _) {
        final isOffline = connectivity.isOffline;
        final adminProfile = sellProvider.currentAdminProfile;

        // Usar hasPermission() para verificaciones consistentes
        final hasSalesAccess = adminProfile?.hasPermission(AdminPermission.registerSales) ?? false;
        final hasCatalogueAccess = adminProfile?.hasPermission(AdminPermission.manageCatalogue) ?? false;
        final hasAnalyticsAccess = adminProfile?.hasPermission(AdminPermission.manageTransactions) ?? false;
        final hasUsersAccess = adminProfile?.hasPermission(AdminPermission.manageUsers) ?? false;
        final hasHistoryAccess = adminProfile?.hasPermission(AdminPermission.viewCashCountHistory) ?? false;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Material(
            color: Colors.transparent,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ventas - Requiere permiso registerSales
                if (hasSalesAccess)
                  _DrawerNavTile(
                    icon: Icons.point_of_sale,
                    label: 'Ventas',
                    index: 0,
                    currentIndex: homeProvider.currentPageIndex,
                    onSelected: () {
                      if (homeProvider.currentPageIndex != 0) {
                        homeProvider.setPageIndex(0);
                      }
                      Navigator.of(context).pop();
                    },
                    colorScheme: colorScheme,
                    isEnabled: true,
                  ),

                // Catálogo - Requiere permiso manageCatalogue
                if (hasCatalogueAccess)
                  _DrawerNavTile(
                    icon: Icons.inventory_2,
                    label: 'Catálogo',
                    index: 1,
                    currentIndex: homeProvider.currentPageIndex,
                    onSelected: () {
                      if (isOffline) return;
                      if (homeProvider.currentPageIndex != 1) {
                        homeProvider.setPageIndex(1);
                      }
                      Navigator.of(context).pop();
                    },
                    colorScheme: colorScheme,
                    isEnabled: !isOffline,
                  ),

                // Analíticas - Requiere permiso manageTransactions
                if (hasAnalyticsAccess)
                  _DrawerNavTile(
                    icon: Icons.analytics,
                    label: 'Analíticas',
                    index: 2,
                    currentIndex: homeProvider.currentPageIndex,
                    onSelected: () {
                      if (isOffline) return;
                      if (homeProvider.currentPageIndex != 2) {
                        homeProvider.setPageIndex(2);
                      }
                      Navigator.of(context).pop();
                    },
                    colorScheme: colorScheme,
                    isEnabled: !isOffline,
                  ),

                // Historial Caja - Requiere permiso viewCashCountHistory
                if (hasHistoryAccess)
                  _DrawerNavTile(
                    icon: Icons.history,
                    label: 'Historial Caja',
                    index: 3,
                    currentIndex: homeProvider.currentPageIndex,
                    onSelected: () {
                      if (isOffline) return;
                      if (homeProvider.currentPageIndex != 3) {
                        homeProvider.setPageIndex(3);
                      }
                      Navigator.of(context).pop();
                    },
                    colorScheme: colorScheme,
                    isEnabled: !isOffline,
                  ),

                // Usuarios - Requiere permiso manageUsers
                if (hasUsersAccess)
                  _DrawerNavTile(
                    icon: Icons.people,
                    label: 'Usuarios',
                    index: 4,
                    currentIndex: homeProvider.currentPageIndex,
                    onSelected: () {
                      if (isOffline) return;
                      if (homeProvider.currentPageIndex != 4) {
                        homeProvider.setPageIndex(4);
                      }
                      Navigator.of(context).pop();
                    },
                    colorScheme: colorScheme,
                    isEnabled: !isOffline,
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
  final int index;
  final int currentIndex;
  final VoidCallback onSelected;
  final ColorScheme colorScheme;
  final bool isEnabled; // ← NUEVO parámetro

  const _DrawerNavTile({
    required this.icon,
    required this.label,
    required this.index,
    required this.currentIndex,
    required this.onSelected,
    required this.colorScheme,
    this.isEnabled = true, // Por defecto habilitado
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = index == currentIndex;

    return Opacity(
      opacity: isEnabled ? 1.0 : 0.4, // Reducir opacidad si está deshabilitado
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: ListTile(
          enabled: isEnabled, // Deshabilitar interacción
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
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Círculo indicador si está seleccionado
              if (isSelected)
                Icon(
                  Icons.circle,
                  color: colorScheme.primary,
                  size: 16,
                ),
              // Icono de offline si está deshabilitado
              if (!isEnabled) ...[
                if (isSelected) const SizedBox(width: 8),
                Icon(
                  Icons.cloud_off,
                  size: 14,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                ),
              ],
            ],
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          tileColor: isSelected
              ? colorScheme.primaryContainer.withValues(alpha: 0.8)
              : null,
          onTap:
              isEnabled ? onSelected : null, // Solo ejecutar si está habilitado
        ),
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
            'Disponible para móvil',
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
            child: AppButton.primary(
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
