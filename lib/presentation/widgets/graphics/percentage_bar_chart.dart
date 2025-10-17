import 'package:flutter/material.dart';

/// Widget reutilizable que muestra un gráfico de barras horizontales divididas
/// con porcentajes, ideal para visualizar distribuciones de datos.
/// 
/// Características:
/// - Barras divididas con esquinas redondeadas
/// - Responsive (mobile y desktop)
/// - Filtro automático de segmentos pequeños (<5%)
/// - Etiquetas con puntos de color
/// - Personalizable (altura, espaciado, colores, etc.)
/// 
/// Ejemplo de uso:
/// ```dart
/// PercentageBarChart(
///   title: 'Métodos de pago',
///   data: [
///     PercentageBarData(
///       label: 'Efectivo',
///       percentage: 45.0,
///       color: Colors.orange.shade700,
///     ),
///     PercentageBarData(
///       label: 'Tarjeta',
///       percentage: 35.0,
///       color: Colors.purple.shade700,
///     ),
///   ],
///   isMobile: isMobile(context),
/// )
/// ```
class PercentageBarChart extends StatelessWidget {
  /// Título del gráfico (opcional)
  final String? title;
  
  /// Datos para las barras del gráfico
  final List<PercentageBarData> data;
  
  /// Si está en modo móvil (afecta tamaños y espaciados)
  final bool isMobile;
  
  /// Altura de la barra principal
  final double? barHeight;
  
  /// Radio de las esquinas redondeadas de las barras
  final double? barBorderRadius;
  
  /// Espaciado entre barras individuales
  final double? barSpacing;
  
  /// Porcentaje mínimo para mostrar un segmento (por defecto 5%)
  final double minPercentageToShow;
  
  /// Color de fondo del contenedor (opcional)
  final Color? backgroundColor;
  
  /// Color del borde del contenedor (opcional)
  final Color? borderColor;
  
  /// Ancho del borde del contenedor
  final double borderWidth;
  
  /// Padding interno del contenedor
  final EdgeInsets? padding;
  
  /// Mostrar etiquetas con puntos de color debajo de la barra
  final bool showLabels;
  
  /// Espaciado entre la barra y las etiquetas
  final double? labelSpacing;

  const PercentageBarChart({
    super.key,
    this.title,
    required this.data,
    required this.isMobile,
    this.barHeight,
    this.barBorderRadius,
    this.barSpacing,
    this.minPercentageToShow = 5.0,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth = 0.5,
    this.padding,
    this.showLabels = true,
    this.labelSpacing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Valores por defecto responsive
    final effectiveBarHeight = barHeight ?? (isMobile ? 14.0 : 16.0);
    final effectiveBarBorderRadius = barBorderRadius ?? 4.0;
    final effectiveBarSpacing = barSpacing ?? (isMobile ? 1.0 : 3.0);
    final effectivePadding = padding ?? EdgeInsets.all(12);
    final effectiveLabelSpacing = labelSpacing ?? (isMobile ? 8.0 : 10.0);
    final effectiveBackgroundColor = backgroundColor ??  Colors.transparent;
    final effectiveBorderColor = borderColor ?? 
        theme.dividerColor.withValues(alpha: 0.3);

    // Filtrar datos por porcentaje mínimo
    final visibleData = data.where((item) => item.percentage >= minPercentageToShow).toList();

    if (visibleData.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: effectivePadding,
      decoration: BoxDecoration(
        color: effectiveBackgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: effectiveBorderColor,
          width: borderWidth,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título (si existe)
          if (title != null && title!.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                title!,
                style: (isMobile
                        ? theme.textTheme.labelMedium
                        : theme.textTheme.labelLarge)
                    ?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ),
          ],
          
          // Barra de progreso horizontal con barras divididas
          _buildBarChart(
            visibleData: visibleData,
            effectiveBarHeight: effectiveBarHeight,
            effectiveBarBorderRadius: effectiveBarBorderRadius,
            effectiveBarSpacing: effectiveBarSpacing,
            theme: theme,
          ),
          
          // Etiquetas con puntos de color
          if (showLabels) ...[
            SizedBox(height: effectiveLabelSpacing),
            _buildLabels(
              visibleData: visibleData,
              theme: theme,
            ),
          ],
        ],
      ),
    );
  }

  /// Construye la barra de progreso con segmentos divididos
  Widget _buildBarChart({
    required List<PercentageBarData> visibleData,
    required double effectiveBarHeight,
    required double effectiveBarBorderRadius,
    required double effectiveBarSpacing,
    required ThemeData theme,
  }) {
    return SizedBox(
      height: effectiveBarHeight,
      child: Row(
        children: visibleData.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          
          return Expanded(
            flex: (item.percentage * 100).toInt(),
            child: Padding(
              padding: EdgeInsets.only(
                right: index < visibleData.length - 1 
                  ? effectiveBarSpacing 
                  : 0,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: item.opacity ?? 0.9),
                  borderRadius: BorderRadius.circular(effectiveBarBorderRadius),
                ),
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 2 : 4,
                    ),
                    child: Text(
                      '${item.percentage.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontWeight: FontWeight.w400,
                        color: item.textColor ?? Colors.white,
                        fontSize: isMobile ? 9 : 12,
                        height: 1.0,
                      ),
                      maxLines: 1,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Construye las etiquetas con puntos de color
  Widget _buildLabels({
    required List<PercentageBarData> visibleData,
    required ThemeData theme,
  }) {
    return Wrap(
      spacing: isMobile ? 12 : 16,
      runSpacing: isMobile ? 6 : 8,
      children: visibleData.map((item) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Punto de color
            Container(
              width: isMobile ? 8 : 10,
              height: isMobile ? 8 : 10,
              decoration: BoxDecoration(
                color: item.color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            // Etiqueta
            Text(
              item.label,
              style: (isMobile
                      ? theme.textTheme.labelSmall
                      : theme.textTheme.labelMedium)
                  ?.copyWith(
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                fontSize: isMobile ? 11 : 12,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}

/// Modelo de datos para cada barra del gráfico
class PercentageBarData {
  /// Etiqueta descriptiva del segmento
  final String label;
  
  /// Porcentaje del segmento (0-100)
  final double percentage;
  
  /// Color de la barra
  final Color color;
  
  /// Opacidad de la barra (opcional, por defecto 0.9)
  final double? opacity;
  
  /// Color del texto del porcentaje (opcional, por defecto blanco)
  final Color? textColor;
  
  /// Icono asociado al segmento (opcional, para uso externo)
  final IconData? icon;

  const PercentageBarData({
    required this.label,
    required this.percentage,
    required this.color,
    this.opacity,
    this.textColor,
    this.icon,
  });

  /// Crea una copia del objeto con valores modificados
  PercentageBarData copyWith({
    String? label,
    double? percentage,
    Color? color,
    double? opacity,
    Color? textColor,
    IconData? icon,
  }) {
    return PercentageBarData(
      label: label ?? this.label,
      percentage: percentage ?? this.percentage,
      color: color ?? this.color,
      opacity: opacity ?? this.opacity,
      textColor: textColor ?? this.textColor,
      icon: icon ?? this.icon,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is PercentageBarData &&
      other.label == label &&
      other.percentage == percentage &&
      other.color == color &&
      other.opacity == opacity &&
      other.textColor == textColor &&
      other.icon == icon;
  }

  @override
  int get hashCode {
    return label.hashCode ^
      percentage.hashCode ^
      color.hashCode ^
      opacity.hashCode ^
      textColor.hashCode ^
      icon.hashCode;
  }
}
