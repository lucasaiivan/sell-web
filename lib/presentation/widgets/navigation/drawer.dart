import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sellweb/core/core.dart';
import 'package:sellweb/presentation/providers/auth_provider.dart';
import 'package:sellweb/presentation/providers/sell_provider.dart';
import 'package:sellweb/presentation/widgets/dialogs/views/account/account_selection_dialog.dart';
import 'package:web/web.dart' as html;

/// Widget del drawer principal de la aplicación
class AppDrawer extends StatelessWidget {
  /// Página actual seleccionada ('sell' o 'catalogue')
  final String currentPage;
  
  /// Callback cuando se selecciona una página
  final Function(String page) onPageSelected;

  const AppDrawer({
    super.key,
    required this.currentPage,
    required this.onPageSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            // view : logo y título de encabezado
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  // button : button personalizado que abre el modal de selección de cuenta administradas
                  Expanded(
                    child: _accountsAssociatedsButton(
                      context: context,
                      onTap: () => showAccountSelectionDialog(context: context),
                    ),
                  ),
                  // Controles de tema reutilizables
                  ThemeControlButtons(
                    spacing: 4,
                    iconSize: 20,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Navegación principal
            _buildNavigationItem(
              context: context,
              icon: Icons.point_of_sale,
              title: 'Punto de Venta',
              isSelected: currentPage == 'sell',
              onTap: () {
                Navigator.pop(context); // Cerrar drawer
                onPageSelected('sell');
              },
            ),
            
            _buildNavigationItem(
              context: context,
              icon: Icons.inventory_2_outlined,
              title: 'Catálogo',
              isSelected: currentPage == 'catalogue',
              onTap: () {
                Navigator.pop(context); // Cerrar drawer
                onPageSelected('catalogue');
              },
            ),
            
            const Spacer(),
            
            // view : Mas funciones en nuestra app
            Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Divider(thickness: 0.2, color: Colors.grey.shade300),
                  const SizedBox(height: 8),
                  Text(
                    '¡Descubre todas las funciones en nuestra app móvil!',
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
                      onPressed: () {
                        // Abre la URL de descarga de la app
                        html.window.open(
                          'https://play.google.com/store/apps/details?id=com.sellweb.app',
                          '_blank',
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  /// Construye un item de navegación del drawer
  Widget _buildNavigationItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
      child: Material(
        color: isSelected 
            ? colorScheme.primaryContainer.withValues(alpha: 0.5)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isSelected 
                      ? colorScheme.primary 
                      : colorScheme.onSurface.withValues(alpha: 0.7),
                  size: 24,
                ),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: isSelected 
                        ? colorScheme.primary 
                        : colorScheme.onSurface,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Botón personalizado que muestra la cuenta seleccionada con avatar e información
  Widget _accountsAssociatedsButton({
    required BuildContext context,
    required VoidCallback onTap,
    double iconSize = 30,
  }) {
    // Usar Consumer2 para escuchar cambios en AuthProvider y SellProvider
    return Consumer2<AuthProvider, SellProvider>(
      builder: (context, authProvider, sellProvider, child) {
        final selectedAccount = sellProvider.profileAccountSelected;
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        
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
                                  fontSize: iconSize * 0.45,
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
                              sellProvider.currentAdminProfile!.email.isNotEmpty)
                            Text(
                              sellProvider.currentAdminProfile!.email,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurface.withValues(alpha: 0.6),
                                fontSize: 11,
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
