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
  final bool isPrimary;

  const MetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Colores dinámicos
    final backgroundColor = isDark
        ? color.withValues(alpha: 0.15)
        : color.withValues(alpha: 0.08);
    
    final iconBackgroundColor = isDark
        ? color.withValues(alpha: 0.25)
        : color.withValues(alpha: 0.15);

    final textColor = isDark ? Colors.white : theme.colorScheme.onSurface;

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: color.withValues(alpha: 0.1),
          width: 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(24),
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Calculamos tamaños dinámicos basados en el espacio disponible
              final availableWidth = constraints.maxWidth;
              final availableHeight = constraints.maxHeight;
              
              // Tamaños de fuente adaptativos
              final titleFontSize = isPrimary 
                  ? (availableWidth * 0.05).clamp(14.0, 18.0)
                  : (availableWidth * 0.08).clamp(12.0, 14.0);
              
              final valueFontSize = isPrimary
                  ? (availableHeight * 0.15).clamp(28.0, 48.0)
                  : (availableHeight * 0.20).clamp(20.0, 32.0);
              
              final subtitleFontSize = (availableWidth * 0.04).clamp(10.0, 12.0);
              final iconSize = isPrimary ? 28.0 : 20.0;
              final padding = isPrimary ? 24.0 : 16.0;

              return Padding(
                padding: EdgeInsets.all(padding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    // Header: Icono (y título si es primary)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: EdgeInsets.all(isPrimary ? 12 : 8),
                          decoration: BoxDecoration(
                            color: iconBackgroundColor,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            icon,
                            color: color,
                            size: iconSize,
                          ),
                        ),
                        if (isPrimary) ...[
                          const SizedBox(width: 12),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                title,
                                style: TextStyle(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w500,
                                  fontSize: titleFontSize,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    
                    const Spacer(),
                    
                    // Content: Valor
                    if (!isPrimary) ...[
                      Text(
                        title,
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                          fontSize: titleFontSize,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                    ],
                    
                    // Valor principal con escala dinámica
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: availableWidth - (padding * 2),
                          ),
                          child: Text(
                            value,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: textColor,
                              fontSize: valueFontSize,
                              height: 1.0,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.visible,
                          ),
                        ),
                      ),
                    ),
                    
                    // Subtítulo opcional
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                          fontSize: subtitleFontSize,
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
      ),
    );
  }
}
