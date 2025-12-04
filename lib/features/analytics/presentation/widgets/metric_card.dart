import 'package:flutter/material.dart';

/// Widget: Card de Métrica (Rediseñado - Sin desbordamiento)
///
/// **Responsabilidad:**
/// - Mostrar una métrica individual con diseño premium
/// - Adaptarse a diferentes tamaños de celda (Bento Box)
/// - Manejar valores largos sin desbordamiento
class MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? subtitle;
  final bool isZero;

  const MetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
    this.isZero = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Sistema de colores Material 3 con tinte de la métrica
    // Si es cero (sin datos), usamos colores neutros/deshabilitados
    final containerColor = isZero
        ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)
        : (isDark
            ? color.withValues(alpha: 0.15)
            : color.withValues(alpha: 0.08));

    final onContainerColor = theme.colorScheme.onSurface;

    // Icon container más sutil
    final iconContainerColor = isZero
        ? theme.colorScheme.onSurface.withValues(alpha: 0.05)
        : color.withValues(alpha: 0.2);

    final iconColor = isZero
        ? theme.colorScheme.onSurface.withValues(alpha: 0.38)
        : color;

    final valueColor = isZero
        ? theme.colorScheme.onSurface.withValues(alpha: 0.38)
        : onContainerColor;

    return Card(
      elevation: 0,
      color: containerColor,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: isZero
              ? theme.colorScheme.outline.withValues(alpha: 0.1)
              : color.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {},
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final h = constraints.maxHeight;
            final minDim = w < h ? w : h;

            // 1. Cálculos de escala base
            // Usamos la dimensión más pequeña para elementos UI (iconos, padding)
            // Usamos el ancho para textos largos
            // Usamos el alto para el valor numérico

            final padding = (minDim * 0.05).clamp(12.0, 24.0);

            // Icono
            final iconSize = (minDim * 0.01).clamp(20.0, 32.0);
            final iconBoxSize = (iconSize * 1).clamp(36.0, 56.0);

            // Textos
            final titleSize = (w * 0.08).clamp(12.0, 16.0);
            final subtitleSize = (w * 0.05).clamp(10.0, 13.0);

            // El valor debe ser GRANDE. Calculamos basado en altura disponible.
            // Estimamos espacio ocupado por header y footer
            final estimatedHeaderH = iconBoxSize;
            final estimatedFooterH = subtitle != null ? 20.0 : 0.0;
            final availableH =
                h - (padding * 2) - estimatedHeaderH - estimatedFooterH;

            // El valor usa ~60-70% del espacio restante vertical
            final valueSizeHeightBase = availableH * 0.7;

            final valueFontSize = valueSizeHeightBase.clamp(24.0, 64.0);

            return Padding(
              padding: EdgeInsets.all(padding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Header: Icono y Título ---
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: iconBoxSize,
                        height: iconBoxSize,
                        decoration: BoxDecoration(
                          color: iconContainerColor,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          icon,
                          color: iconColor,
                          size: iconSize,
                        ),
                      ),
                      SizedBox(width: padding * 0.8),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            title,
                            style: TextStyle(
                              color: onContainerColor.withValues(alpha: 0.8),
                              fontSize: titleSize,
                              fontWeight: FontWeight.w600,
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const Spacer(),

                  // --- Valor Principal ---
                  // Usamos FittedBox para asegurar que quepa horizontalmente
                  // y calculamos el tamaño de fuente para que llene verticalmente
                  Flexible(
                    flex: 2,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        value,
                        style: TextStyle(
                          color: valueColor,
                          fontSize: valueFontSize,
                          fontWeight: FontWeight.bold,
                          height: 1.0,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                  ),

                  // --- Subtítulo ---
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        color: onContainerColor.withValues(alpha: 0.6),
                        fontSize: subtitleSize,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
