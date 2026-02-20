import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:sellweb/core/core.dart';
import 'package:sellweb/features/analytics/domain/entities/trend_data.dart';
import '../core/widgets.dart';

/// Widget: Tarjeta de Tendencia de Ventas
///
/// **Responsabilidad:**
/// - Mostrar gráfico de línea con evolución de ventas en el tiempo
/// - Visualizar tendencia (crecimiento/decrecimiento)
/// - Abrir modal con análisis detallado
/// - Adaptar visualización según granularidad (horas, días, meses)
class SalesTrendCard extends StatelessWidget {
  final TrendData trendData;
  final Color color;
  final bool isZero;
  final String? subtitle;

  const SalesTrendCard({
    super.key,
    required this.trendData,
    this.color = const Color(0xFF3B82F6),
    this.isZero = false,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final hasData = !isZero && trendData.hasData;

    return AnalyticsBaseCard(
      color: color,
      isZero: isZero || !trendData.hasData,
      icon: Icons.trending_up_rounded,
      title: 'Tendencia',
      subtitle: subtitle,
      showActionIndicator: hasData,
      onTap: hasData ? () => _showTrendModal(context) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            hasData ? MainAxisAlignment.end : MainAxisAlignment.center,
        children: [
          if (!hasData)
            const AnalyticsEmptyState(message: 'Sin datos')
          else ...[
            // view : Gráfico de línea
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 4),
                child: _buildLineChart(context),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(child: _buildFeedbackText(context)),
                const SizedBox(width: 12),
                _buildTrendBadge(context),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLineChart(BuildContext context) {
    final theme = Theme.of(context);
    final dataPoints = trendData.dataPoints;

    if (dataPoints.isEmpty) return const SizedBox();

    // Usar los valores precalculados del TrendData
    double maxY = trendData.maxValue;
    double minY = trendData.minValue;

    // Agregar margen superior e inferior para mejor visualización
    final range = maxY - minY;

    // Si todos los valores son iguales o el rango es muy pequeño
    if (range < 0.01) {
      minY = maxY > 0 ? maxY * 0.8 : 0;
      maxY = maxY > 0 ? maxY * 1.2 : 100;
    } else {
      maxY = maxY + (range * 0.15);
      minY = (minY - (range * 0.1)).clamp(0, double.infinity);
    }

    if (maxY == 0) maxY = 100;

    // Calcular intervalo horizontal seguro
    final interval = ((maxY - minY) / 3).clamp(1.0, double.infinity).toDouble();

    // Crear spots para el gráfico
    final spots = <FlSpot>[];
    for (int i = 0; i < dataPoints.length; i++) {
      spots.add(FlSpot(i.toDouble(), dataPoints[i].value));
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: interval,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
              strokeWidth: 1,
              dashArray: [5, 5],
            );
          },
        ),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            tooltipPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            tooltipMargin: 12,
            getTooltipColor: (_) => color.withValues(alpha: 0.95),
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final index = spot.x.toInt();
                if (index < 0 || index >= dataPoints.length) return null;
                final point = dataPoints[index];
                return LineTooltipItem(
                  '${point.label}\n${CurrencyHelper.formatCurrency(point.value)}',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                );
              }).toList();
            },
          ),
          getTouchedSpotIndicator: (barData, spotIndexes) {
            return spotIndexes.map((index) {
              return TouchedSpotIndicatorData(
                FlLine(
                  color: color.withValues(alpha: 0.5),
                  strokeWidth: 2,
                  dashArray: [3, 3],
                ),
                FlDotData(
                  getDotPainter: (spot, percent, barData, index) =>
                      FlDotCirclePainter(
                    radius: 6,
                    color: color,
                    strokeWidth: 3,
                    strokeColor: theme.colorScheme.surface,
                  ),
                ),
              );
            }).toList();
          },
        ),
        minX: 0,
        maxX: (dataPoints.length - 1).toDouble().clamp(0, double.infinity),
        minY: minY,
        maxY: maxY,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.35,
            color: color,
            barWidth: 3.5,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, bar, index) {
                // Resaltar primer y último punto
                final isEndPoint = index == 0 || index == spots.length - 1;
                return FlDotCirclePainter(
                  radius: isEndPoint ? 5 : 3,
                  color: isEndPoint ? color : Colors.transparent,
                  strokeWidth: isEndPoint ? 2.5 : 0,
                  strokeColor: theme.colorScheme.surface,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  color.withValues(alpha: 0.25),
                  color.withValues(alpha: 0.05),
                  color.withValues(alpha: 0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendBadge(BuildContext context) {
    final theme = Theme.of(context);
    final trend = trendData.trendPercentage;
    final isPositive = trend >= 0;
    final isSignificant = trendData.isTrendSignificant;

    // Color según significancia y tendencia
    final Color trendColor;
    if (!isSignificant) {
      // Gris para datos no significativos
      trendColor = theme.colorScheme.outline;
    } else {
      trendColor =
          isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    }

    // Texto del badge según contexto
    final String badgeText;
    if (!isSignificant) {
      // Mostrar cantidad de ventas en lugar de porcentaje no significativo
      badgeText =
          '${trendData.totalTransactions} venta${trendData.totalTransactions == 1 ? '' : 's'}';
    } else {
      badgeText =
          '${isPositive ? '+' : ''}${NumberHelper.formatPercentage(trend)}';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: trendColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: trendColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            badgeText,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: trendColor,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackText(BuildContext context) {
    final theme = Theme.of(context);
    final trend = trendData.trendPercentage;
    final isSignificant = trendData.isTrendSignificant;

    // Generar mensaje de feedback según el estado de la tendencia
    String feedbackText;
    if (!isSignificant) {
      // Datos insuficientes para una tendencia significativa
      if (trendData.totalTransactions == 1) {
        feedbackText = 'Primera venta';
      } else if (trendData.totalTransactions < 3) {
        feedbackText = 'Pocas ventas';
      } else {
        feedbackText = 'Datos iniciales';
      }
    } else if (trend.abs() < 5) {
      feedbackText = 'Estable';
    } else if (trend >= 0) {
      if (trend > 20) {
        feedbackText = 'Gran crecimiento';
      } else if (trend > 10) {
        feedbackText = 'Buen crecimiento';
      } else {
        feedbackText = 'Crecimiento';
      }
    } else {
      if (trend < -20) {
        feedbackText = 'Caída significativa';
      } else if (trend < -10) {
        feedbackText = 'Disminución notable';
      } else {
        feedbackText = 'Leve disminución';
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Comportamiento',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          feedbackText,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  void _showTrendModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SalesTrendModal(trendData: trendData),
    );
  }
}

/// Modal: Análisis Detallado de Tendencia
class SalesTrendModal extends StatelessWidget {
  final TrendData trendData;

  const SalesTrendModal({super.key, required this.trendData});

  static const _accentColor = AnalyticsColors.salesTrend;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dataPoints = trendData.dataPoints;

    // Obtener granularidad para títulos contextuales
    final granularityLabel = _getGranularityLabel(trendData.granularity);

    // Calcular tendencia y significancia
    final trend = trendData.trendPercentage;
    final isPositive = trend >= 0;
    final isSignificant = trendData.isTrendSignificant;

    // Color según significancia
    final Color trendColor;
    if (!isSignificant) {
      trendColor = theme.colorScheme.outline;
    } else {
      trendColor =
          isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    }

    // Valores y labels según contexto
    final String mainValue;
    final String mainLabel;
    final IconData mainIcon;

    if (!isSignificant) {
      mainValue =
          '${trendData.totalTransactions} venta${trendData.totalTransactions == 1 ? '' : 's'}';
      mainLabel = 'Datos insuficientes para análisis de tendencia';
      mainIcon = Icons.hourglass_empty_rounded;
    } else {
      mainValue = '${isPositive ? '+' : ''}${trend.toStringAsFixed(1)}%';
      mainLabel =
          isPositive ? 'Crecimiento del período' : 'Decrecimiento del período';
      mainIcon =
          isPositive ? Icons.trending_up_rounded : Icons.trending_down_rounded;
    }

    return AnalyticsModal(
      title: 'Análisis de Tendencia',
      subtitle:
          '${NumberHelper.formatNumber(dataPoints.length)} $granularityLabel analizados',
      accentColor: _accentColor,
      icon: Icons.trending_up_rounded,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tendencia del período
            AnalyticsStatusCard(
              mainValue: mainValue,
              mainLabel: mainLabel,
              icon: mainIcon,
              statusColor: trendColor,
              feedbackIcon: _getFeedbackIcon(trend, isSignificant),
              feedbackText: _getFeedbackText(trend, isPositive, isSignificant),
            ),
            const SizedBox(height: 24),

            // Banner explicativo según contexto
            if (!isSignificant) ...[
              AnalyticsFeedbackBanner(
                message: _getInsufficientDataMessage(),
                icon: const Icon(Icons.info_outline_rounded),
              ),
              const SizedBox(height: 24),
            ],

            Text(
              'Evolución ${_getEvolutionLabel(trendData.granularity)}',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 250,
              child: _buildDetailedChart(context),
            ),
            const SizedBox(height: 24),
            AnalyticsFeedbackBanner(
              message:
                  'La tendencia se calcula comparando las ventas de la primera mitad del período con la segunda mitad.',
            ),
            const SizedBox(height: 24),
            // resumen : total facturado y transacciones
            AnalyticsStatusCard(
              leftMetric: AnalyticsMetric(
                  label: 'Total Facturado',
                  value: CurrencyHelper.formatCurrency(trendData.totalSales)),
              rightMetric: AnalyticsMetric(
                  label: 'Transacciones',
                  value:
                      NumberHelper.formatNumber(trendData.totalTransactions)),
              statusColor: _accentColor,
            ),
            const SizedBox(height: 24),

            Text(
              'Detalle ${_getDetailLabel(trendData.granularity)}',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...dataPoints.reversed.map((point) => _buildDataPointItem(
                  context,
                  point,
                  trendData.maxValue,
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedChart(BuildContext context) {
    final theme = Theme.of(context);
    final dataPoints = trendData.dataPoints;

    if (dataPoints.isEmpty) return const SizedBox();

    final spots = <FlSpot>[];
    for (int i = 0; i < dataPoints.length; i++) {
      spots.add(FlSpot(i.toDouble(), dataPoints[i].value));
    }

    double maxY = trendData.maxValue * 1.2;
    if (maxY == 0) maxY = 100;

    // Determinar intervalo de etiquetas según cantidad de datos
    final labelInterval = _calculateLabelInterval(dataPoints.length);

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY / 4,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              interval: labelInterval,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= dataPoints.length) {
                  return const SizedBox();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    dataPoints[index].label,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 10,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 60,
              interval: maxY / 4,
              getTitlesWidget: (value, meta) {
                return Text(
                  CurrencyHelper.formatCurrency(value),
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 10,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                );
              },
            ),
          ),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            tooltipPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            getTooltipColor: (_) => theme.colorScheme.surfaceContainerHighest,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final index = spot.x.toInt();
                if (index < 0 || index >= dataPoints.length) return null;
                final point = dataPoints[index];
                return LineTooltipItem(
                  '${point.fullLabel}\n${CurrencyHelper.formatCurrency(spot.y)}\n${point.transactionCount} ventas',
                  TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                );
              }).toList();
            },
          ),
        ),
        minX: 0,
        maxX: (dataPoints.length - 1).toDouble().clamp(0, double.infinity),
        minY: 0,
        maxY: maxY,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.3,
            color: _accentColor,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: dataPoints.length <= 31,
              getDotPainter: (spot, percent, bar, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: _accentColor,
                  strokeWidth: 2,
                  strokeColor: theme.colorScheme.surface,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  _accentColor.withValues(alpha: 0.3),
                  _accentColor.withValues(alpha: 0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataPointItem(
    BuildContext context,
    TrendDataPoint point,
    double maxValue,
  ) {
    final theme = Theme.of(context);
    final progress = maxValue > 0 ? point.value / maxValue : 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color:
              theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    point.fullLabel,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  CurrencyHelper.formatCurrency(point.value),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: _accentColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: _accentColor.withValues(alpha: 0.15),
                      color: _accentColor,
                      minHeight: 6,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${NumberHelper.formatNumber(point.transactionCount)} ventas',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // === Helpers ===

  String _getGranularityLabel(TrendGranularity granularity) {
    switch (granularity) {
      case TrendGranularity.hour:
        return 'horas';
      case TrendGranularity.day:
        return 'días';
      case TrendGranularity.month:
        return 'meses';
    }
  }

  String _getEvolutionLabel(TrendGranularity granularity) {
    switch (granularity) {
      case TrendGranularity.hour:
        return 'por Hora';
      case TrendGranularity.day:
        return 'Diaria';
      case TrendGranularity.month:
        return 'Mensual';
    }
  }

  String _getDetailLabel(TrendGranularity granularity) {
    switch (granularity) {
      case TrendGranularity.hour:
        return 'por Hora';
      case TrendGranularity.day:
        return 'por Día';
      case TrendGranularity.month:
        return 'por Mes';
    }
  }

  double _calculateLabelInterval(int dataPointCount) {
    if (dataPointCount <= 7) return 1.0;
    if (dataPointCount <= 15) return 2.0;
    if (dataPointCount <= 31) return 3.0;
    return (dataPointCount / 7).ceilToDouble();
  }

  IconData _getFeedbackIcon(double trend, bool isSignificant) {
    // Si los datos no son significativos, mostrar icono neutral
    if (!isSignificant) {
      return Icons.hourglass_empty_rounded;
    }

    if (trend.abs() < 5) {
      return Icons.remove_rounded;
    } else if (trend >= 0) {
      if (trend > 20) {
        return Icons.rocket_launch_rounded;
      } else if (trend > 10) {
        return Icons.thumb_up_rounded;
      } else {
        return Icons.trending_up_rounded;
      }
    } else {
      if (trend < -20) {
        return Icons.warning_rounded;
      } else if (trend < -10) {
        return Icons.trending_down_rounded;
      } else {
        return Icons.arrow_downward_rounded;
      }
    }
  }

  String _getFeedbackText(double trend, bool isPositive, bool isSignificant) {
    // Si los datos no son significativos, dar feedback contextual
    if (!isSignificant) {
      if (trendData.totalTransactions == 1) {
        return '¡Primera venta del período! Aún no hay suficientes datos para analizar la tendencia.';
      } else if (trendData.totalTransactions < 3) {
        return 'Con solo ${trendData.totalTransactions} ventas, necesitas más actividad para un análisis de tendencia confiable.';
      } else if (trendData.firstHalfSales == 0) {
        return 'Las ventas se concentran al final del período. Espera más actividad para una comparación significativa.';
      } else {
        return 'Aún no hay suficientes datos distribuidos en el período para un análisis de tendencia preciso.';
      }
    }

    if (trend.abs() < 5) {
      return 'Tus ventas se mantienen estables en el período';
    } else if (isPositive) {
      if (trend > 20) {
        return '¡Excelente! Tus ventas están creciendo muy bien';
      } else if (trend > 10) {
        return 'Muy bien, tus ventas muestran buen crecimiento';
      } else {
        return 'Tus ventas están en crecimiento moderado';
      }
    } else {
      if (trend < -20) {
        return 'Atención: tus ventas han disminuido significativamente';
      } else if (trend < -10) {
        return 'Tus ventas muestran una disminución notable';
      } else {
        return 'Tus ventas han disminuido levemente';
      }
    }
  }

  /// Genera mensaje explicativo cuando los datos son insuficientes
  String _getInsufficientDataMessage() {
    if (trendData.totalTransactions == 1) {
      return 'El análisis de tendencia compara la primera mitad del período con la segunda mitad. Con una sola venta, aún no es posible calcular una tendencia significativa.';
    } else if (trendData.firstHalfSales == 0 && trendData.secondHalfSales > 0) {
      return 'Todas las ventas se concentran en la segunda mitad del período. El porcentaje técnico sería +100%, pero esto no representa un crecimiento real sino el inicio de la actividad.';
    } else if (trendData.activeDataPoints < 2) {
      return 'Las ventas están muy concentradas en un solo momento. Se necesita más distribución temporal para un análisis de tendencia confiable.';
    } else {
      return 'Se necesitan más transacciones distribuidas a lo largo del período para obtener un análisis de tendencia estadísticamente significativo.';
    }
  }
}
