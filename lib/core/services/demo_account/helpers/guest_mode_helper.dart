import 'package:flutter/material.dart';
import 'package:sellweb/core/constants/demo_mode_icons.dart';
import 'package:sellweb/core/constants/demo_messages.dart';
import 'package:sellweb/core/presentation/widgets/demo/demo_restriction_dialog.dart';

/// Enum para identificar las acciones que pueden requerir autenticación
enum GuestAction {
  cashRegister,
  userManagement,
  dataPersistence,
  analytics,
  accountSettings,
}

/// Helper service para gestión centralizada del modo invitado
///
/// Proporciona utilidades para:
/// - Verificar si una acción requiere autenticación
/// - Mostrar diálogos y mensajes de restricción
/// - Obtener mensajes contextuales
class GuestModeHelper {
  GuestModeHelper._();

  // ==================== Action Validation ====================

  /// Verifica si una acción requiere autenticación
  ///
  /// [action]: La acción a validar
  /// Retorna `true` si requiere cuenta registrada, `false` si está disponible en demo
  static bool requiresAuth(GuestAction action) {
    switch (action) {
      case GuestAction.cashRegister:
      case GuestAction.userManagement:
      case GuestAction.accountSettings:
        return true; // Requieren autenticación
      case GuestAction.dataPersistence:
      case GuestAction.analytics:
        return false; // Disponibles en modo limitado
    }
  }

  // ==================== Dialogs ====================

  /// Muestra un diálogo de restricción para una funcionalidad bloqueada
  ///
  /// [context]: BuildContext para mostrar el diálogo
  /// [featureName]: Nombre de la funcionalidad bloqueada
  /// [benefits]: Lista opcional de beneficios personalizados
  static Future<void> showRestrictionDialog(
    BuildContext context, {
    required String featureName,
    List<String>? benefits,
  }) {
    return DemoRestrictionDialog.show(
      context,
      feature: featureName,
      benefits: benefits,
    );
  }

  // ==================== Snackbars ====================

  /// Muestra un snackbar informativo con estilo consistente
  ///
  /// [context]: BuildContext para mostrar el snackbar
  /// [message]: Mensaje a mostrar
  /// [showRegisterAction]: Si debe incluir botón de registro (default: true)
  static void showInfoSnackbar(
    BuildContext context, {
    required String message,
    bool showRegisterAction = true,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              DemoModeIcons.info,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
        action: showRegisterAction
            ? SnackBarAction(
                label: 'Registrarse',
                textColor: Colors.white,
                onPressed: () {
                  Navigator.of(context).pushReplacementNamed('/');
                },
              )
            : null,
        backgroundColor: DemoModeColors.warning,
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  /// Muestra un snackbar cuando se bloquea una acción
  ///
  /// [context]: BuildContext para mostrar el snackbar
  /// [action]: Nombre de la acción bloqueada
  static void showActionBlockedSnackbar(
    BuildContext context, {
    required String action,
  }) {
    showInfoSnackbar(
      context,
      message: DemoMessages.actionBlockedMessage(action),
      showRegisterAction: true,
    );
  }

  // ==================== Contextual Messages ====================

  /// Obtiene el mensaje contextual para una acción
  ///
  /// [action]: La acción para la cual obtener el mensaje
  /// Retorna el mensaje apropiado según el tipo de acción
  static String getContextualMessage(GuestAction action) {
    final featureKey = action.toString().split('.').last;
    return DemoMessages.getRestrictionMessage(featureKey);
  }

  /// Obtiene el tooltip apropiado para una sección de la app
  ///
  /// [section]: Identificador de la sección
  /// Retorna el tooltip correspondiente o null si no aplica
  static String? getTooltipForSection(String section) {
    switch (section.toLowerCase()) {
      case 'sales':
      case 'ventas':
        return DemoMessages.salesTooltip;
      case 'catalogue':
      case 'catalogo':
        return DemoMessages.catalogueTooltip;
      case 'analytics':
      case 'analiticas':
        return DemoMessages.analyticsTooltip;
      case 'users':
      case 'usuarios':
        return DemoMessages.usersTooltip;
      default:
        return null;
    }
  }

  // ==================== UI Helpers ====================

  /// Obtiene el color apropiado para el estado de modo invitado
  ///
  /// [isRestricted]: Si la funcionalidad está restringida
  /// Retorna el color apropiado según el estado
  static Color getStateColor({bool isRestricted = false}) {
    return isRestricted ? DemoModeColors.restriction : DemoModeColors.info;
  }

  /// Obtiene el icono apropiado para el estado
  ///
  /// [isRestricted]: Si la funcionalidad está restringida
  /// Retorna el icono apropiado según el estado
  static IconData getStateIcon({bool isRestricted = false}) {
    return isRestricted ? DemoModeIcons.locked : DemoModeIcons.available;
  }
}
