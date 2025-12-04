import 'package:flutter/material.dart';

/// Widget: Tarjeta Base para Analytics
///
/// **Responsabilidad:**
/// - Proporcionar una base visual consistente para todas las tarjetas de analytics
/// - Manejar estados vacíos (sin datos) de forma uniforme
/// - Soportar diferentes tamaños y layouts responsivos
///
/// **Uso:**
/// Todas las tarjetas de analytics deben usar este widget como base
/// para mantener un aspecto visual coherente.
class AnalyticsBaseCard extends StatelessWidget {
  /// Color principal de la tarjeta
  final Color color;

  /// Indica si no hay datos (estado vacío)
  final bool isZero;

  /// Icono principal
  final IconData icon;

  /// Título de la tarjeta
  final String title;

  /// Subtítulo opcional
  final String? subtitle;

  /// Contenido principal del card
  final Widget child;

  /// Callback al hacer tap
  final VoidCallback? onTap;

  /// Mostrar indicador de acción (chevron)
  final bool showActionIndicator;

  /// Padding personalizado
  final EdgeInsetsGeometry? padding;

  /// Si es true, el child se expande para llenar el espacio disponible.
  /// Si es false, el card se ajusta al contenido (shrink-wrap).
  /// Usar false para tarjetas con altura dinámica (ej: listas).
  final bool expandChild;

  const AnalyticsBaseCard({
    super.key,
    required this.color,
    required this.icon,
    required this.title,
    required this.child,
    this.isZero = false,
    this.subtitle,
    this.onTap,
    this.showActionIndicator = false,
    this.padding,
    this.expandChild = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Sistema de colores Material 3 con tinte de la métrica
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
        onTap: onTap,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final h = constraints.maxHeight;
            // Si la altura es infinita, usamos el ancho como referencia
            final hasFiniteHeight = h.isFinite;
            final minDim = hasFiniteHeight ? (w < h ? w : h) : w * 0.5;

            final effectivePadding = padding ??
                EdgeInsets.all((minDim * 0.05).clamp(12.0, 20.0));

            final iconSize = (minDim * 0.01).clamp(18.0, 24.0);
            final iconBoxSize = (iconSize * 1).clamp(36.0, 48.0);
            final titleSize = (w * 0.06).clamp(12.0, 14.0);
            final subtitleSize = (w * 0.045).clamp(10.0, 12.0);

            // Determinar si expandir basado en la propiedad y las constraints
            final shouldExpand = expandChild && hasFiniteHeight;

            return Padding(
              padding: effectivePadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: shouldExpand ? MainAxisSize.max : MainAxisSize.min,
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
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          icon,
                          color: iconColor,
                          size: iconSize,
                        ),
                      ),
                      SizedBox(width: (minDim * 0.04).clamp(8.0, 12.0)),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                title,
                                style: TextStyle(
                                  color: onContainerColor.withValues(alpha: 0.8),
                                  fontSize: titleSize,
                                  fontWeight: FontWeight.w600,
                                  height: 1.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (subtitle != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                subtitle!,
                                style: TextStyle(
                                  color: onContainerColor.withValues(alpha: 0.5),
                                  fontSize: subtitleSize,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                      // Indicador de acción
                      if (showActionIndicator && onTap != null)
                        Icon(
                          Icons.chevron_right_rounded,
                          color: onContainerColor.withValues(alpha: 0.4),
                          size: 20,
                        ),
                    ],
                  ),

                  // --- Contenido ---
                  if (shouldExpand)
                    Expanded(child: child)
                  else
                    child,
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Widget helper para mostrar estado vacío consistente
class AnalyticsEmptyState extends StatelessWidget {
  final String message;
  final Color? color;

  const AnalyticsEmptyState({
    super.key,
    this.message = 'Sin datos',
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = color ?? theme.colorScheme.onSurfaceVariant;

    return Center(
      child: Text(
        message,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: textColor.withValues(alpha: 0.5),
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

/// Widget helper para mostrar el valor principal de una métrica
/// Escala automáticamente el texto para aprovechar el espacio disponible
class AnalyticsMainValue extends StatelessWidget {
  final String value;
  final bool isZero;
  final double? fontSize;
  /// Factor de escala adicional (1.0 = normal, 1.5 = 50% más grande)
  final double scaleFactor;

  const AnalyticsMainValue({
    super.key,
    required this.value,
    this.isZero = false,
    this.fontSize,
    this.scaleFactor = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final valueColor = isZero
        ? theme.colorScheme.onSurface.withValues(alpha: 0.38)
        : theme.colorScheme.onSurface;

    // Si se proporciona un fontSize explícito, usarlo
    if (fontSize != null) {
      return FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: fontSize! * scaleFactor,
            fontWeight: FontWeight.bold,
            height: 1.0,
            letterSpacing: -0.5,
          ),
        ),
      );
    }

    // Sin fontSize explícito: usar LayoutBuilder para escalar dinámicamente
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calcular fontSize basado en el espacio disponible
        final availableHeight = constraints.maxHeight.isFinite 
            ? constraints.maxHeight 
            : 60.0;
        final availableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 200.0;
        
        // El fontSize base es proporcional a la altura disponible
        // pero también limitado por el ancho (para valores largos)
        final heightBasedSize = availableHeight * 0.6;
        final widthBasedSize = availableWidth / (value.length * 0.5);
        
        final calculatedSize = (heightBasedSize < widthBasedSize 
            ? heightBasedSize 
            : widthBasedSize).clamp(18.0, 72.0) * scaleFactor;

        return FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: calculatedSize,
              fontWeight: FontWeight.bold,
              height: 1.0,
              letterSpacing: -0.5,
            ),
          ),
        );
      },
    );
  }
}

/// Widget helper para preview de item destacado
class AnalyticsHighlightItem extends StatelessWidget {
  final Widget leading;
  final String title;
  final String subtitle;
  final Widget? badge;
  final Color accentColor;

  const AnalyticsHighlightItem({
    super.key,
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          leading,
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.9),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitle,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 10,
                    color: accentColor,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (badge != null) badge!,
        ],
      ),
    );
  }
}
