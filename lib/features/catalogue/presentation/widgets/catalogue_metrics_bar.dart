import 'package:flutter/material.dart';
import '../../domain/entities/catalogue_metric.dart';

/// Barra de métricas del catálogo que muestra chips con valor/nombre
///
/// Diseñada para ser extensible y mostrar métricas adicionales en el futuro.
/// Los datos se ajustan automáticamente según el filtro activo.
class CatalogueMetricsBar extends StatelessWidget {
  /// Métricas a mostrar
  final CatalogueMetrics metrics;

  /// Callback opcional cuando se toca una métrica
  final void Function(CatalogueMetric metric)? onMetricTap;

  const CatalogueMetricsBar({
    super.key,
    required this.metrics,
    this.onMetricTap,
  });

  @override
  Widget build(BuildContext context) {
    final metricsList = metrics.toMetricsList();

    return SizedBox(
      height: 50,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        scrollDirection: Axis.horizontal,
        itemCount: metricsList.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final metric = metricsList[index];
          return _MetricChip(
            metric: metric,
            onTap: onMetricTap != null ? () => onMetricTap!(metric) : null,
          );
        },
      ),
    );
  }
}

/// Chip individual con estilo "WhatsApp" (Pill shape)
class _MetricChip extends StatelessWidget {
  final CatalogueMetric metric;
  final VoidCallback? onTap;

  const _MetricChip({
    required this.metric,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                metric.formattedValue,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                metric.label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
