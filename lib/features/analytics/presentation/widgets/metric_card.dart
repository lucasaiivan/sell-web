import 'package:flutter/material.dart';
import 'analytics_base_card.dart';

/// Widget: Card de Métrica (Rediseñado - Sin desbordamiento)
///
/// **Responsabilidad:**
/// - Mostrar una métrica individual con diseño premium
/// - Adaptarse a diferentes tamaños de celda (Bento Box)
/// - Manejar valores largos sin desbordamiento
/// - Soportar tap para abrir modal con más detalles
///
/// **Usa:** [AnalyticsBaseCard] como base visual consistente
class MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? subtitle;
  final bool isZero;

  /// Si es true, muestra información adicional (tarjeta más grande)
  final bool moreInformation;

  /// Callback al hacer tap en la tarjeta
  final VoidCallback? onTap;

  /// Mostrar indicador de acción (chevron) para indicar que hay más contenido
  final bool showActionIndicator;

  /// Información de comparación con período anterior (ej: "+15.3%")
  final Map<String, dynamic>? comparisonData;

  /// Información de porcentaje adicional (ej: "45.2% margen")
  final String? percentageInfo;

  const MetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
    this.isZero = false,
    this.moreInformation = false,
    this.onTap,
    this.showActionIndicator = false,
    this.comparisonData,
    this.percentageInfo,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasComparison = comparisonData != null &&
        comparisonData!['percentage'] != null &&
        !isZero;
    final hasPercentageInfo = percentageInfo != null && !isZero;

    return AnalyticsBaseCard(
      color: color,
      isZero: isZero,
      icon: icon,
      title: title,
      subtitle: subtitle,
      moreInformation: moreInformation,
      onTap: onTap,
      showActionIndicator: showActionIndicator,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Valor principal grande - usa Flexible para expandirse
          Flexible(
            child: Align(
              alignment: Alignment.centerLeft,
              child: AnalyticsMainValue(
                value: value,
                isZero: isZero,
              ),
            ),
          ),
          // Comparación con día anterior o porcentaje adicional
          if (hasComparison || hasPercentageInfo) ...[
            const SizedBox(height: 6),
            if (hasComparison)
              _buildComparisonBadge(context, comparisonData!)
            else if (hasPercentageInfo)
              _buildPercentageBadge(context, percentageInfo!, theme),
          ],
        ],
      ),
    );
  }

  Widget _buildComparisonBadge(
      BuildContext context, Map<String, dynamic> data) {
    final theme = Theme.of(context);
    final percentage = data['percentage'] as double;
    final isPositive = percentage >= 0;
    final trendColor =
        isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    final trendIcon =
        isPositive ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: trendColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: trendColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(trendIcon, size: 12, color: trendColor),
          const SizedBox(width: 4),
          Text(
            '${isPositive ? '+' : ''}${percentage.toStringAsFixed(1)}%',
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: trendColor,
              fontSize: 11,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '${data['label'] ?? 'anterior'}',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPercentageBadge(
      BuildContext context, String text, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.percent_rounded, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: color,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
