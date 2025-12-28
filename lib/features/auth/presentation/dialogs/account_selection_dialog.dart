import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:sellweb/features/auth/domain/entities/account_profile.dart';
import 'package:sellweb/features/auth/presentation/providers/auth_provider.dart';
import 'package:sellweb/features/sales/presentation/providers/sales_provider.dart';
import 'package:sellweb/core/presentation/widgets/ui/avatar_user.dart';
import 'package:sellweb/core/presentation/widgets/dialogs/base/base_dialog.dart';
import 'package:sellweb/core/presentation/widgets/dialogs/components/dialog_components.dart';
import 'admin_profile_info_dialog.dart';

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
    width: 600, // Slightly wider for better desktop presentation
    content: const _AccountSelectionContent(),
    actions: [
      // Botón: Cerrar sesión (más discreto pero accesible)
      Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          if (authProvider.user?.email == null) {
            return const SizedBox.shrink();
          }
          final theme = Theme.of(context);
          return TextButton.icon(
            onPressed: () => _handleSignOut(context, authProvider),
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            icon: const Icon(Icons.logout_rounded, size: 20),
            label: const Text('Cerrar sesión'),
          );
        },
      ),
      // Botón: Cancelar/Cerrar
      DialogComponents.secondaryActionButton(
        context: context,
        text: 'Cancelar',
        onPressed: () => Navigator.of(context).pop(),
      ),
    ],
  );
}

/// Manejar el cierre de sesión
Future<void> _handleSignOut(
  BuildContext context,
  AuthProvider authProvider,
) async {
  final theme = Theme.of(context);
  final confirm = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Cerrar sesión'),
      content: const Text(
          '¿Estás seguro de que deseas cerrar sesión en este dispositivo?'),
      icon: Icon(Icons.logout_rounded, color: theme.colorScheme.error),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: FilledButton.styleFrom(
            backgroundColor: theme.colorScheme.error,
            foregroundColor: theme.colorScheme.onError,
          ),
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

/// Contenido del diálogo de selección de cuentas
class _AccountSelectionContent extends StatelessWidget {
  const _AccountSelectionContent();

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Sección: Información del usuario administrador
        _buildAdminSection(context)
            .animate()
            .fadeIn(duration: 400.ms)
            .slideY(begin: -0.1, end: 0, curve: Curves.easeOutQuad),

        const SizedBox(height: 24),

        // Sección: Lista de cuentas asociadas
        _buildAccountsSection(context, authProvider.accountsAssociateds)
            .animate()
            .fadeIn(duration: 500.ms, delay: 100.ms)
            .slideY(begin: 0.1, end: 0, curve: Curves.easeOutQuad),

        const SizedBox(height: 8), // Pequeño espacio extra al final
      ],
    );
  }

  /// Sección de información del usuario administrador (clickeable)
  Widget _buildAdminSection(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final sellProvider = Provider.of<SalesProvider>(context, listen: false);
    final adminProfile = sellProvider.currentAdminProfile;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: adminProfile != null
              ? () async {
                  try {
                    await showAdminProfileInfoDialog(
                      context: context,
                      admin: adminProfile,
                    );
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).clearSnackBars();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          behavior: SnackBarBehavior.floating,
                          content: Text(
                              'Error al cargar la información: ${e.toString()}'),
                          backgroundColor: colorScheme.error,
                        ),
                      );
                    }
                  }
                }
              : null,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Avatar del administrador con borde destacado
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: colorScheme.primary.withValues(alpha: 0.2),
                      width: 2,
                    ),
                  ),
                  child: UserAvatar(
                    imageUrl: null,
                    text: adminProfile?.name ?? adminProfile?.email,
                    radius: 28,
                    backgroundColor: colorScheme.primaryContainer,
                    foregroundColor: colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 16),

                // Información del administrador
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Administrador',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        adminProfile?.name ?? 'Usuario',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        adminProfile?.email ?? 'Sin email',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Action Prompt
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
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
    final colorScheme = theme.colorScheme;
    final sellProvider = Provider.of<SalesProvider>(context, listen: false);

    if (accounts.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        width: double.infinity,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.1),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.storefront_outlined,
              size: 48,
              color: colorScheme.outline.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 12),
            Text(
              'No tienes cuentas asociadas',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'TUS COMERCIOS',
            style: theme.textTheme.labelLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
        ),
        DialogComponents.itemList(
          context: context,
          items: accounts.map((account) {
            final isSelected =
                sellProvider.profileAccountSelected.id == account.id;
            return _buildAccountItem(context, account, isSelected, sellProvider);
          }).toList(),
          showDividers: true,
          maxVisibleItems: 10,
          borderRadius: 16,
          useFillStyle: true,
          backgroundColor: colorScheme.surfaceContainerLow.withValues(alpha: 0.6),
          padding: const EdgeInsets.symmetric(vertical: 4),
        ),
      ],
    );
  }

  /// Item individual de cuenta con diseño premium
  Widget _buildAccountItem(
    BuildContext context,
    AccountProfile account,
    bool isSelected,
    SalesProvider sellProvider,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // Seleccionar cuenta y cerrar el diálogo
          sellProvider.initAccount(account: account, context: context);
          Navigator.of(context).pop();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? colorScheme.primaryContainer.withValues(alpha: 0.3)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: isSelected
                ? Border.all(
                    color: colorScheme.primary.withValues(alpha: 0.3),
                    width: 1)
                : Border.all(color: Colors.transparent, width: 1),
          ),
          child: Row(
            children: [
              // Avatar del comercio
              Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: UserAvatar(
                      imageUrl: account.image,
                      text: account.name.isNotEmpty
                          ? account.name[0].toUpperCase()
                          : '?',
                      radius: 20,
                      backgroundColor: isSelected
                          ? colorScheme.primary
                          : colorScheme.surfaceContainerHigh,
                      foregroundColor: isSelected
                          ? colorScheme.onPrimary
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (isSelected)
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.check_circle,
                          size: 14,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),

              // Información del comercio
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      account.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.w600,
                        color: isSelected
                            ? colorScheme.primary
                            : colorScheme.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (account.province.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 12,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              account.province,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Indicador visual (flecha o selección)
              if (!isSelected)
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: colorScheme.surfaceContainerHigh,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
