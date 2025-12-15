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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: metricsList.map((metric) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _MetricChip(
                metric: metric,
                onTap: onMetricTap != null ? () => onMetricTap!(metric) : null,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

/// Chip individual que muestra una métrica (valor/nombre)
class _MetricChip extends StatelessWidget {
  final CatalogueMetric metric;
  final VoidCallback? onTap;

  const _MetricChip({
    required this.metric,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                metric.formattedValue,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                metric.label,
                style: textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
