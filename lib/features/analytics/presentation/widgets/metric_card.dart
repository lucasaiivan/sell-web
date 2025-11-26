import 'package:flutter/material.dart';

/// Widget: Card de Métrica
///
/// **Responsabilidad:**
/// - Mostrar una métrica individual con icono, título y valor
/// - Diseño responsive y reutilizable
///
/// **Uso:**
/// ```dart
/// MetricCard(
///   title: 'Total Transacciones',
///   value: '150',
///   icon: Icons.receipt_long,
///   color: Colors.blue,
/// )
/// ```
class MetricCard extends StatelessWidget {
  /// Título descriptivo de la métrica
  final String title;

  /// Valor formateado de la métrica
  final String value;

  /// Icono representativo
  final IconData icon;

  /// Color del icono (opcional, usa primaryColor por defecto)
  final Color? color;

  /// Subtítulo opcional (ej: "promedio por venta")
  final String? subtitle;

  const MetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.color,
    this.subtitle,
  });

    @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconColor = color ?? theme.colorScheme.primary;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: iconColor.withValues(alpha: 0.08),
      child: InkWell(
        onTap: () {}, // Placeholder para futuras interacciones
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icono circular
                  Material(
                    color: iconColor.withValues(alpha: 0.15),
                    shape: const CircleBorder(),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Icon(
                        icon,
                        color: iconColor,
                        size: 20,
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Valor grande y bold
                  Text(
                    value,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Título
                  Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  // Subtítulo opcional
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

}
