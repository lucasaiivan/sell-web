import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sellweb/features/auth/domain/entities/admin_profile.dart';
import 'package:sellweb/core/presentation/widgets/dialogs/base/base_dialog.dart';
import 'package:sellweb/core/presentation/widgets/dialogs/components/dialog_components.dart';
import 'package:provider/provider.dart';
import 'package:sellweb/features/auth/presentation/providers/auth_provider.dart';
import 'package:sellweb/core/presentation/widgets/success/process_success_view.dart';
import 'package:sellweb/features/sales/presentation/providers/sales_provider.dart';

/// Diálogo: Información del Perfil de Administrador
///
/// **Responsabilidad:**
/// - Mostrar información básica del perfil (nombre, email, fechas)
/// - Visualizar roles y permisos asignados
/// - Presentar restricciones de acceso (horarios y días)
///
/// **Ejemplo de uso:**
/// ```dart
/// showAdminProfileInfoDialog(
///   context: context,
///   admin: adminProfile,
/// );
/// ```

/// Muestra el diálogo de información del perfil de administrador
Future<void> showAdminProfileInfoDialog({
  required BuildContext context,
  required AdminProfile admin,
}) {
  return showBaseDialog(
    context: context,
    title: 'Perfil de Administrador',
    icon: Icons.person_outline_rounded,
    width: 500,
    content: _AdminProfileInfoContent(admin: admin),
    actions: [
      DialogComponents.primaryActionButton(
        context: context,
        text: 'Cerrar',
        onPressed: () => Navigator.of(context).pop(),
      ),
    ],
  );
}

/// Contenido del diálogo de información del perfil de administrador
class _AdminProfileInfoContent extends StatelessWidget {
  const _AdminProfileInfoContent({required this.admin});

  final AdminProfile admin;

  @override
  Widget build(BuildContext context) {
    final hasAccessRestrictions =
        admin.hasAccessTimeConfiguration || admin.daysOfWeek.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildBasicInfo(context),
        DialogComponents.sectionSpacing,
        _buildRolesAndPermissions(context),
        if (hasAccessRestrictions) ...[
          DialogComponents.sectionSpacing,
          _buildAccessRestrictions(context),
        ],
        // Zona de peligro
        DialogComponents.sectionSpacing,
        _buildDangerZone(context),
      ],
    );
  }

  /// Zona de peligro para eliminación de usuario
  Widget _buildDangerZone(BuildContext context) {
    return DialogComponents.infoSection(
      context: context,
      title: 'Zona de Peligro',
      icon: Icons.warning_amber_rounded,
      content: _DeleteUserAccountButton(admin: admin),
    );
  }

  /// Información básica del administrador
  Widget _buildBasicInfo(BuildContext context) {
    return DialogComponents.infoSection(
      context: context,
      title: 'Información Básica',
      icon: Icons.badge_outlined,
      content: Column(
        children: [
          if (admin.name.isNotEmpty)
            DialogComponents.infoRow(
              context: context,
              label: 'Nombre',
              value: admin.name,
              icon: Icons.person_outline_rounded,
            ),
          DialogComponents.infoRow(
            context: context,
            label: 'Email',
            value: admin.email,
            icon: Icons.email_outlined,
          ),
          DialogComponents.infoRow(
            context: context,
            label: 'Creado',
            value: _formatDate(admin.creation),
            icon: Icons.event_available_rounded,
          ),
          DialogComponents.infoRow(
            context: context,
            label: 'Actualizado',
            value: _formatDate(admin.lastUpdate),
            icon: Icons.update_rounded,
          ),
        ],
      ),
    );
  }

  /// Roles y permisos del administrador
  Widget _buildRolesAndPermissions(BuildContext context) {
    return DialogComponents.infoSection(
      context: context,
      title: 'Roles y Permisos',
      icon: Icons.security_rounded,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Rol principal
          _buildRoleBadge(context),

          // Permisos detallados si son personalizados
          if (admin.personalized) ...[
            DialogComponents.itemSpacing,
            _buildPermissionsList(context),
          ],
        ],
      ),
    );
  }

  /// Badge del rol principal
  Widget _buildRoleBadge(BuildContext context) {
    final theme = Theme.of(context);

    String roleText;
    IconData roleIcon;
    Color roleColor;

    if (admin.superAdmin) {
      roleText = 'Super Administrador';
      roleIcon = Icons.workspace_premium_rounded;
      roleColor = theme.colorScheme.primary;
    } else if (admin.admin && !admin.personalized) {
      roleText = 'Administrador';
      roleIcon = Icons.admin_panel_settings_rounded;
      roleColor = theme.colorScheme.secondary;
    } else if (admin.personalized) {
      roleText = 'Permisos Personalizados';
      roleIcon = Icons.tune_rounded;
      roleColor = theme.colorScheme.tertiary;
    } else {
      roleText = 'Usuario';
      roleIcon = Icons.person_outline_rounded;
      roleColor = theme.colorScheme.outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: roleColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: roleColor.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(roleIcon, size: 20, color: roleColor),
          const SizedBox(width: 8),
          Text(
            roleText,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: roleColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// Lista de permisos específicos
  Widget _buildPermissionsList(BuildContext context) {
    final theme = Theme.of(context);

    final permissions = [
      if (admin.arqueo) (icon: Icons.calculate_outlined, label: 'Arqueo'),
      if (admin.historyArqueo)
        (icon: Icons.history_rounded, label: 'Historial'),
      if (admin.transactions)
        (icon: Icons.receipt_long_rounded, label: 'Transacciones'),
      if (admin.catalogue)
        (icon: Icons.inventory_2_outlined, label: 'Catálogo'),
      if (admin.multiuser)
        (icon: Icons.people_outline_rounded, label: 'Multiusuario'),
      if (admin.editAccount) (icon: Icons.edit_rounded, label: 'Editar cuenta'),
    ];

    if (permissions.isEmpty) {
      return Text(
        'Sin permisos específicos',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
          fontStyle: FontStyle.italic,
        ),
      );
    }

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: permissions.map((perm) {
        return DialogComponents.infoBadge(
          context: context,
          text: perm.label,
          icon: perm.icon,
        );
      }).toList(),
    );
  }

  /// Restricciones de acceso (días y horarios)
  Widget _buildAccessRestrictions(BuildContext context) {
    final theme = Theme.of(context);
    final startTime = _formatTime(admin.startTime);
    final endTime = _formatTime(admin.endTime);
    final hasTimeConfig = startTime.isNotEmpty || endTime.isNotEmpty;
    final hasDays = admin.daysOfWeek.isNotEmpty;

    return DialogComponents.infoSection(
      context: context,
      title: 'Restricciones de Acceso',
      icon: Icons.lock_clock_rounded,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Días permitidos
          if (hasDays) ...[
            Text(
              'Días habilitados:',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: admin.daysOfWeek.map((day) {
                return DialogComponents.infoBadge(
                  context: context,
                  text: _translateDay(day.toString()),
                  icon: Icons.check_circle_outline_rounded,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  textColor: theme.colorScheme.onPrimaryContainer,
                );
              }).toList(),
            ),
          ],

          // Horario permitido
          if (hasTimeConfig) ...[
            if (hasDays) DialogComponents.itemSpacing,
            Text(
              hasDays
                  ? 'Horario en días habilitados:'
                  : 'Horario (todos los días):',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color:
                    theme.colorScheme.secondaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (startTime.isNotEmpty) ...[
                    Icon(Icons.login_rounded,
                        size: 16, color: theme.colorScheme.tertiary),
                    const SizedBox(width: 6),
                    Text(
                      startTime,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.tertiary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  if (startTime.isNotEmpty && endTime.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        size: 16,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  if (endTime.isNotEmpty) ...[
                    Icon(Icons.logout_rounded,
                        size: 16, color: theme.colorScheme.error),
                    const SizedBox(width: 6),
                    Text(
                      endTime,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Formatea una fecha a formato legible
  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  /// Formatea un mapa de tiempo a formato HH:mm
  String _formatTime(Map<String, dynamic> time) {
    if (time.isEmpty) return '';
    final hour = time['hour'] ?? 0;
    final minute = time['minute'] ?? 0;
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  /// Traduce el nombre del día al español (abreviado)
  String _translateDay(String day) {
    const days = {
      'monday': 'Lun',
      'tuesday': 'Mar',
      'wednesday': 'Mié',
      'thursday': 'Jue',
      'friday': 'Vie',
      'saturday': 'Sáb',
      'sunday': 'Dom',
    };
    return days[day.toLowerCase()] ?? day;
  }
}

/// Botón de eliminación de cuenta de usuario
class _DeleteUserAccountButton extends StatefulWidget {
  const _DeleteUserAccountButton({required this.admin});
  
  final AdminProfile admin;

  @override
  State<_DeleteUserAccountButton> createState() => _DeleteUserAccountButtonState();
}

class _DeleteUserAccountButtonState extends State<_DeleteUserAccountButton> {
  bool _isDeleting = false;

  Future<void> _confirmDeleteAction() async {
    final theme = Theme.of(context);
    final isOwner = widget.admin.superAdmin;
    
    // Configurar textos según rol
    final title = isOwner ? '¿Eliminar Negocio?' : '¿Salir del Negocio?';
    final content = isOwner 
        ? 'Estás a punto de ELIMINAR ESTE NEGOCIO y todos sus datos (ventas, productos, clientes).\n\nEsta acción es IRREVERSIBLE, pero TU usuario personal seguirá existiendo.'
        : 'Estás a punto de salir de este negocio. Perderás el acceso a sus datos, pero tu usuario personal seguirá activo en otros comercios.';
    
    final confirmBtnText = isOwner ? 'Sí, eliminar negocio' : 'Sí, salir del negocio';
    final btnColor = theme.colorScheme.error;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        icon: Icon(Icons.warning_amber_rounded,
            color: btnColor, size: 48),
        content: Text(content),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: btnColor),
              onPressed: () => Navigator.pop(context, true),
              child: Text(confirmBtnText)),
        ],
      ),
    );

    if (confirm == true) {
      if (!mounted) return;
      
      final authProvider = context.read<AuthProvider>();
      // Obtener el nombre de la cuenta para mostrar mensaje amigable
      final accountName = authProvider.getProfileAccountById(widget.admin.account)?.name ?? widget.admin.account;
      
      // Cerrar el diálogo de perfil primero
      Navigator.of(context).pop();
      
      // Navegar a la vista de proceso
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ProcessSuccessView(
            loadingText: isOwner ? 'Eliminando negocio...' : 'Saliendo del negocio...',
            successTitle: isOwner ? '¡Negocio eliminado!' : '¡Salida exitosa!',
            successSubtitle: accountName,
            finalText: 'Redirigiendo...',
            loadingDuration: 1500,
            successDuration: 1500,
            playSound: false,
            onComplete: () async {
              // Ejecutar la acción contextual
              final success = await authProvider.deleteAdminAccess(
                widget.admin.account, 
                widget.admin
              );
              
              if (!context.mounted) return;
              
              if (success) {
                // Cerrar ProcessView
                Navigator.of(context).pop();

                // Limpiar datos de venta para forzar navegación a la pantalla de selección de cuenta
                if (context.mounted) {
                  context.read<SalesProvider>().cleanData();
                }
                
                // Si borramos el negocio o salimos, debemos ir a la selección de cuenta
                // El authProvider ya actualizó la lista de cuentas
                // Navegar al root para que HomePage detecte que no hay cuenta seleccionada
                 Navigator.of(context).popUntil((route) => route.isFirst);
              } else {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(authProvider.authError ?? 'Error al procesar la solicitud'),
                    backgroundColor: theme.colorScheme.error,
                  ),
                );
              }
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final errorColor = theme.colorScheme.error;
    final isOwner = widget.admin.superAdmin;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      enabled: !_isDeleting,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: errorColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          _isDeleting 
              ? Icons.hourglass_empty_rounded 
              : (isOwner ? Icons.delete_forever_rounded : Icons.exit_to_app_rounded),
          color: errorColor,
        ),
      ),
      title: Text(
        isOwner ? 'Eliminar este Negocio' : 'Salir de este Negocio',
        style: TextStyle(color: errorColor, fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        _isDeleting
            ? 'Procesando...'
            : (isOwner 
                ? 'Elimina el negocio actual permanentemente' 
                : 'Desvincula tu cuenta de este negocio'),
      ),
      onTap: _isDeleting ? null : _confirmDeleteAction,
    );
  }
}

