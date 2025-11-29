import 'package:flutter/material.dart';
import 'package:sellweb/core/core.dart';
import 'package:sellweb/core/utils/helpers/user_access_validator.dart';
import 'package:sellweb/features/auth/domain/entities/admin_profile.dart';

/// Diálogo: Acceso Denegado
///
/// **Responsabilidad:**
/// - Informar al usuario por qué no tiene acceso
/// - Proporcionar opciones para cerrar sesión o cambiar de cuenta
/// - Mostrar información relevante según el tipo de restricción
/// - Mostrar mensaje personalizado de bloqueo (nota)
class AccessDeniedDialog extends StatelessWidget {
  final UserAccessResult accessResult;
  final VoidCallback onSignOut;
  final VoidCallback onChangeAccount;
  final AdminProfile? adminProfile;

  const AccessDeniedDialog({
    super.key,
    required this.accessResult,
    required this.onSignOut,
    required this.onChangeAccount,
    this.adminProfile,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return BaseDialog(
      title: accessResult.title,
      icon: Icons.lock_rounded,
      headerColor: colorScheme.errorContainer,
      width: 450,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icono emoji grande
          Text(
            accessResult.icon,
            style: const TextStyle(fontSize: 64),
          ),
          const SizedBox(height: 16),
          
          // Mensaje principal
          Text(
            accessResult.message,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          
          // Nota personalizada de bloqueo (si está disponible)
          if (accessResult.reason == UserAccessDeniedReason.userBlocked &&
              adminProfile?.inactivateNote.isNotEmpty == true) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.error,
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: colorScheme.error,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Nota:',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: colorScheme.error,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    adminProfile!.inactivateNote,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onErrorContainer,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          // Información adicional según el tipo de restricción
          _buildAdditionalInfo(context),
        ],
      ),
      actions: [
        AppButton.text(
          text: 'Cambiar de Cuenta',
          onPressed: onChangeAccount,
        ),
        AppButton.primary(
          text: 'Cerrar Sesión',
          onPressed: onSignOut,
          backgroundColor: colorScheme.error,
        ),
      ],
    );
  }

  /// Construye información adicional según el tipo de restricción
  Widget _buildAdditionalInfo(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    String infoText;
    IconData infoIcon;

    switch (accessResult.reason) {
      case UserAccessDeniedReason.userBlocked:
        infoText = 'Contacta con el administrador de la cuenta para más información.';
        infoIcon = Icons.person_outline;
        break;
      case UserAccessDeniedReason.dayNotAllowed:
        infoText = 'Tu cuenta tiene restricciones de acceso por día de la semana.';
        infoIcon = Icons.event_busy_rounded;
        break;
      case UserAccessDeniedReason.outsideAllowedHours:
        infoText = 'Tu cuenta tiene restricciones de acceso por horario.';
        infoIcon = Icons.access_time_rounded;
        break;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.error.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            infoIcon,
            color: colorScheme.error,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              infoText,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Muestra el diálogo de acceso denegado
  static Future<void> show({
    required BuildContext context,
    required UserAccessResult accessResult,
    required VoidCallback onSignOut,
    required VoidCallback onChangeAccount,
    AdminProfile? adminProfile,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false, // No se puede cerrar tocando fuera
      builder: (context) => AccessDeniedDialog(
        accessResult: accessResult,
        onSignOut: onSignOut,
        onChangeAccount: onChangeAccount,
        adminProfile: adminProfile,
      ),
    );
  }
}
