import 'package:flutter/material.dart';
import '../../../constants/demo_mode_icons.dart';

/// Widget de ayuda contextual para modo demo
///
/// Muestra tips y mensajes educativos de forma sutil y no intrusiva.
/// Se oculta automáticamente cuando el usuario no está en modo demo.
class DemoContextualHelp extends StatelessWidget {
  /// Mensaje de ayuda a mostrar
  final String tip;

  /// Icono a mostrar junto al mensaje (default: lightbulb)
  final IconData icon;

  /// Color personalizado (default: blue)
  final Color? color;

  /// Si debe mostrarse siempre (ignora modo demo)
  final bool alwaysShow;

  const DemoContextualHelp({
    super.key,
    required this.tip,
    this.icon = Icons.lightbulb_outline,
    this.color,
    this.alwaysShow = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveColor = color ?? DemoModeColors.info;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: effectiveColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: effectiveColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: effectiveColor,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              tip,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
