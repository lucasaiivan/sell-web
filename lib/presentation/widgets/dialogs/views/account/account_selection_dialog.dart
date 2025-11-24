import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sellweb/domain/entities/user.dart';
import 'package:sellweb/presentation/providers/auth_provider.dart';
import 'package:sellweb/presentation/providers/sell_provider.dart';
import 'package:sellweb/presentation/widgets/components/avatar_user.dart';
import 'package:sellweb/presentation/widgets/dialogs/base/base_dialog.dart';
import 'package:sellweb/presentation/widgets/dialogs/components/dialog_components.dart';
import 'package:sellweb/presentation/widgets/dialogs/views/account/admin_profile_info_dialog.dart';

/// Diálogo de selección de cuentas con información del administrador
///
/// Muestra:
/// - Información del usuario administrador (avatar, nombre, email) - clickeable para ver más detalles
/// - Lista de cuentas asociadas al usuario
/// - Botones de acción: Cerrar sesión y Cerrar
///
/// ## Ejemplo de uso:
/// ```dart
/// showAccountSelectionDialog(
///   context: context,
/// );
/// ```

/// Función auxiliar para mostrar el diálogo de selección de cuentas
Future<void> showAccountSelectionDialog({
  required BuildContext context,
}) {
  return showBaseDialog(
    context: context,
    title: 'Seleccionar Cuenta',
    width: 500,
    content: const _AccountSelectionContent(),
    actions: [],
  );
}

/// Contenido del diálogo de selección de cuentas
class _AccountSelectionContent extends StatelessWidget {
  const _AccountSelectionContent();

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final sellProvider = context.watch<SellProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Sección: Información del usuario administrador
        _buildAdminSection(context),

        DialogComponents.sectionSpacing,

        // Sección: Lista de cuentas asociadas
        _buildAccountsSection(context, authProvider.accountsAssociateds),

        DialogComponents.sectionSpacing,

        // Sección: Botones de acción
        _buildActionsSection(context, authProvider, sellProvider),
      ],
    );
  }

  /// Sección de información del usuario administrador (clickeable)
  Widget _buildAdminSection(BuildContext context) {
    final theme = Theme.of(context);

    final sellProvider = Provider.of<SellProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;

    return DialogComponents.infoSection(
      context: context,
      title: 'Identificación',
      showBorder: false,
      content: InkWell(
        onTap: user?.email != null
            ? () async {
                try {
                  // Obtener AdminProfile desde SellProvider
                  final adminProfile = sellProvider.currentAdminProfile;

                  if (adminProfile != null) {
                    await showAdminProfileInfoDialog(
                      context: context,
                      admin: adminProfile,
                    );
                  } else if (context.mounted) {
                    ScaffoldMessenger.of(context).clearSnackBars();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        behavior: SnackBarBehavior.floating,
                        content: Text(
                            'No se encontró información del administrador'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).clearSnackBars();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        behavior: SnackBarBehavior.floating,
                        content: Text(
                            'Error al cargar la información: ${e.toString()}'),
                        backgroundColor: Colors.red,
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                }
              }
            : null,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              // Avatar del usuario
              UserAvatar(
                imageUrl: user?.photoUrl,
                text: user?.displayName ?? user?.email,
                radius: 24,
              ),
              const SizedBox(width: 12),

              // Información del usuario
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.displayName ?? 'Usuario',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user?.email ?? 'Sin email',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // icon : arrow right
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Sección de lista de cuentas asociadas
  Widget _buildAccountsSection(
    BuildContext context,
    List<AccountProfile> accounts,
  ) {
    final theme = Theme.of(context);
    final sellProvider = Provider.of<SellProvider>(context, listen: false);

    if (accounts.isEmpty) {
      return DialogComponents.infoSection(
        context: context,
        title: 'Cuentas asociadas',
        content: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Text(
              'No tienes cuentas asociadas',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ),
      );
    }

    return DialogComponents.infoSection(
      context: context,
      title: 'Comercios',
      content: DialogComponents.itemList(
        context: context,
        items: accounts.map((account) {
          final isSelected =
              sellProvider.profileAccountSelected.id == account.id;
          return _buildAccountItem(context, account, isSelected, sellProvider);
        }).toList(),
        showDividers: true,
        maxVisibleItems: 4,
        expandText: 'Ver más cuentas',
        collapseText: 'Ver menos',
        borderRadius: 8,
        useFillStyle: true,
        backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.5),
        padding: EdgeInsets.zero,
      ),
    );
  }

  /// Item individual de cuenta
  Widget _buildAccountItem(
    BuildContext context,
    AccountProfile account,
    bool isSelected,
    SellProvider sellProvider,
  ) {
    final theme = Theme.of(context);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 0),
      dense: true,
      visualDensity: const VisualDensity(vertical: -4),
      leading: UserAvatar(
        imageUrl: account.image,
        text: account.name.isNotEmpty ? account.name[0].toUpperCase() : '?',
        radius: 18,
      ),
      title: Text(
        account.name,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: account.province.isNotEmpty
          ? Text(
              account.province,
              style: theme.textTheme.bodySmall,
              overflow: TextOverflow.ellipsis,
            )
          : null,
      trailing: isSelected
          ? Icon(
              Icons.check_circle_rounded,
              color: theme.colorScheme.primary,
              size: 24,
            )
          : null,
      onTap: () {
        // Seleccionar cuenta y cerrar el diálogo
        sellProvider.initAccount(account: account, context: context);
        Navigator.of(context).pop();
      },
    );
  }

  /// Sección de botones de acción
  Widget _buildActionsSection(
    BuildContext context,
    AuthProvider authProvider,
    SellProvider sellProvider,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Botón: Cerrar sesión
        if (authProvider.user?.email != null)
          Expanded(
            child: TextButton(
              onPressed: () => _handleSignOut(context, authProvider),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text('Cerrar sesión'),
            ),
          ),

        const SizedBox(width: 12),

        // Botón: Cerrar
        Expanded(
          child: DialogComponents.primaryActionButton(
            context: context,
            text: 'ok',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      ],
    );
  }

  /// Manejar el cierre de sesión
  Future<void> _handleSignOut(
    BuildContext context,
    AuthProvider authProvider,
  ) async {
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

    if (confirm == true && context.mounted) {
      await authProvider.signOut();
      Navigator.of(context).pop(); // Cerrar el diálogo de selección de cuentas
    }
  }
}
