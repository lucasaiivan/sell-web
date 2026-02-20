import 'package:flutter/material.dart';
import '../../../constants/demo_mode_icons.dart';
import '../../../services/demo_account/helpers/guest_mode_helper.dart';

/// Widget wrapper que envuelve funcionalidades con indicadores visuales
/// de restricción para modo demo
///
/// Agrega un badge visual cuando la funcionalidad requiere autenticación
/// y opcionalmente intercepta el tap para mostrar un diálogo educativo.
class DemoFeatureWrapper extends StatelessWidget {
  /// Widget hijo a envolver
  final Widget child;

  /// Si la funcionalidad requiere autenticación
  final bool requiresAuth;

  /// Nombre de la funcionalidad (para mensajes)
  final String? featureName;

  /// Callback cuando se toca (opcional)
  final VoidCallback? onTap;

  /// Si debe mostrar el badge visual (default: true)
  final bool showBadge;

  /// Si debe interceptar el tap cuando está bloqueado (default: true)
  final bool interceptTap;

  const DemoFeatureWrapper({
    super.key,
    required this.child,
    this.requiresAuth = false,
    this.featureName,
    this.onTap,
    this.showBadge = true,
    this.interceptTap = true,
  });

  @override
  Widget build(BuildContext context) {
    // Si no requiere auth o no debe mostrar badge, retornar hijo directamente
    if (!requiresAuth || !showBadge) {
      return child;
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Widget hijo
        GestureDetector(
          onTap: () {
            if (interceptTap && requiresAuth && featureName != null) {
              // Mostrar diálogo de restricción
              GuestModeHelper.showRestrictionDialog(
                context,
                featureName: featureName!,
              );
            } else if (onTap != null) {
              onTap!();
            }
          },
          child: child,
        ),

        // Badge de restricción
        Positioned(
          top: -5,
          right: -5,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: DemoModeColors.warning,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              DemoModeIcons.locked,
              size: 12,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
