import 'package:flutter/material.dart';
import 'package:sellweb/domain/entities/user.dart';
import 'package:sellweb/presentation/widgets/dialogs/base/base_dialog.dart';
import 'package:sellweb/presentation/widgets/dialogs/components/dialog_components.dart';

/// Diálogo que muestra la información detallada de un AdminProfile
///
/// Muestra todos los datos relevantes del perfil de administrador incluyendo:
/// - Información básica (nombre, email, cuenta)
/// - Estado y roles (superAdmin, admin, activo/inactivo)
/// - Fechas de creación y actualización
/// - Horarios de acceso configurados
/// - Días de la semana habilitados
/// - Permisos personalizados
///
/// ## Ejemplo de uso:
/// ```dart
/// showAdminProfileInfoDialog(
///   context: context,
///   admin: adminProfile,
/// );
/// ```

/// Función auxiliar para mostrar el diálogo de información del perfil de administrador
Future<void> showAdminProfileInfoDialog({
  required BuildContext context,
  required AdminProfile admin,
}) {
  return showBaseDialog(
    context: context,
    title: 'Perfil de Administrador', 
    width: 500,
    content: _AdminProfileInfoContent(admin: admin),
    actions: [
      DialogComponents.secondaryActionButton(
        context: context,
        text: 'Ok', 
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Información básica
        _buildBasicInfoSection(context),
        DialogComponents.sectionSpacing,

        // Estado y roles
        _buildStatusAndRolesSection(context), 

        // Restricciones de acceso (horarios y días)
        if (admin.hasAccessTimeConfiguration || admin.daysOfWeek.isNotEmpty)
          ...[
            DialogComponents.sectionSpacing,
            _buildAccessRestrictionsSection(context),
          ],
      ],
    );
  }

  /// Sección de información básica
  Widget _buildBasicInfoSection(BuildContext context) {
    return DialogComponents.infoSection(
      context: context,
      title: 'Información Básica', 
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
            icon: Icons.business_outlined,
          ),  
          // Fechas de creación y actualización
          DialogComponents.infoRow(
              context: context,
              label: 'Creación',
              value: admin.formatTimestamp(admin.creation),
              icon: Icons.event_available_rounded,
            ), 
            DialogComponents.infoRow(
              context: context,
              label: 'Última actualización',
              value: admin.formatTimestamp(admin.lastUpdate),
              icon: Icons.update_rounded,
            ),
        ],
      ),
    );
  }

  /// Sección de roles
  Widget _buildStatusAndRolesSection(BuildContext context) {
    final theme = Theme.of(context);
    
    return DialogComponents.infoSection(
      context: context,
      title: 'Permisos', 
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [ 
          
          // Roles
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (admin.superAdmin && admin.admin == true)
                _buildRoleBadge(
                  context,
                  'Super Administrador',
                  Icons.workspace_premium_rounded,
                  theme.colorScheme.primary,
                ),
              if (admin.admin && admin.superAdmin == false)
                _buildRoleBadge(
                  context,
                  'Administrador',
                  Icons.admin_panel_settings_rounded,
                  theme.colorScheme.secondary,
                ),
              if (admin.personalized)
                _buildRoleBadge(
                  context,
                  'Permisos Personalizados',
                  Icons.tune_rounded,
                  theme.colorScheme.tertiary,
                ),
            ],
          ),
          
          // Permisos personalizados detallados
          if (admin.personalized) ...[ 
            const SizedBox(height: 8),
            _buildDetailedPermissions(context),
          ],
        ],
      ),
    );
  }

  /// Widget para mostrar los permisos detallados
  Widget _buildDetailedPermissions(BuildContext context) {
    final theme = Theme.of(context);
    
    final permissions = [
      if (admin.arqueo)
        _PermissionInfo('Arqueo de caja', Icons.calculate_outlined),
      if (admin.historyArqueo)
        _PermissionInfo('Historial de arqueos', Icons.history_rounded),
      if (admin.transactions)
        _PermissionInfo('Transacciones', Icons.receipt_long_rounded),
      if (admin.catalogue)
        _PermissionInfo('Catálogo', Icons.inventory_2_outlined),
      if (admin.multiuser)
        _PermissionInfo('Multiusuario', Icons.people_outline_rounded),
      if (admin.editAccount)
        _PermissionInfo('Editar cuenta', Icons.edit_rounded),
    ];

    if (permissions.isEmpty) {
      return Text(
        'Sin permisos asignados',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontStyle: FontStyle.italic,
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: permissions.map((permission) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: theme.colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                permission.icon,
                size: 16,
                color: theme.colorScheme.onSecondaryContainer,
              ),
              const SizedBox(width: 6),
              Text(
                permission.label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSecondaryContainer,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
 

  /// Sección unificada de restricciones de acceso (días con horarios implícitos)
  Widget _buildAccessRestrictionsSection(BuildContext context) {
    final theme = Theme.of(context);
    final startTime = admin.formatTime(admin.startTime);
    final endTime = admin.formatTime(admin.endTime);
    final hasTimeRestriction = admin.hasAccessTimeConfiguration && 
                               (startTime.isNotEmpty || endTime.isNotEmpty);

    return DialogComponents.infoSection(
      context: context,
      title: 'Restricciones de Acceso',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Días habilitados con horario implícito
          if (admin.daysOfWeek.isNotEmpty) ...[ 
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: admin.daysOfWeek.map<Widget>((day) {
                return _buildDayCard(
                  context,
                  admin.translateDay(day: day.toString()),
                  hasTimeRestriction ? startTime : null,
                  hasTimeRestriction ? endTime : null,
                );
              }).toList(),
            ),
          ],
          
          // Solo mostrar horarios si no hay días configurados
          if (admin.daysOfWeek.isEmpty && hasTimeRestriction) ...[
            Row(
              children: [
                Icon(
                  Icons.schedule_rounded,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Horario permitido (todos los días)',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (startTime.isNotEmpty) ...[
                    Icon(
                      Icons.login_rounded,
                      size: 18,
                      color: theme.colorScheme.tertiary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      startTime,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.tertiary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                  if (startTime.isNotEmpty && endTime.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        color: theme.colorScheme.onSurfaceVariant,
                        size: 20,
                      ),
                    ),
                  ],
                  if (endTime.isNotEmpty) ...[
                    Icon(
                      Icons.logout_rounded,
                      size: 18,
                      color: theme.colorScheme.error,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      endTime,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.error,
                        fontWeight: FontWeight.bold,
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

  /// Widget para mostrar una tarjeta de día con horarios implícitos
  Widget _buildDayCard(
    BuildContext context,
    String dayName,
    String? startTime,
    String? endTime,
  ) {
    final theme = Theme.of(context);
    final hasTimeRestriction = startTime != null && startTime.isNotEmpty ||
                                endTime != null && endTime.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Nombre del día con ícono
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle_rounded,
                size: 16,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Text(
                dayName,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          // Horarios si están configurados
          if (hasTimeRestriction) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (startTime != null && startTime.isNotEmpty) ...[
                    Text(
                      startTime,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.tertiary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                  if (startTime != null && startTime.isNotEmpty &&
                      endTime != null && endTime.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        size: 10,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  if (endTime != null && endTime.isNotEmpty) ...[
                    Text(
                      endTime,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.error,
                        fontWeight: FontWeight.bold,
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

  /// Helper para crear un badge de rol
  Widget _buildRoleBadge(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
  ) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 18,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Clase auxiliar para información de permisos
class _PermissionInfo {
  final String label;
  final IconData icon;

  _PermissionInfo(this.label, this.icon);
}
