import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sellweb/core/core.dart';
import 'analytics_base_card.dart';
import 'analytics_modal.dart';

/// Widget: Tarjeta de Tendencia de Ventas
///
/// **Responsabilidad:**
/// - Mostrar gráfico de línea con evolución de ventas en el tiempo
/// - Visualizar tendencia (crecimiento/decrecimiento)
/// - Abrir modal con análisis detallado
class SalesTrendCard extends StatelessWidget {
  final Map<String, Map<String, dynamic>> salesByDay;
  final Color color;
  final bool isZero;
  final String? subtitle;

  const SalesTrendCard({
    super.key,
    required this.salesByDay,
    this.color = const Color(0xFF3B82F6),
    this.isZero = false,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final hasData = !isZero && salesByDay.isNotEmpty;
    final trend = _calculateTrend();

    return AnalyticsBaseCard(
      color: color,
      isZero: isZero || salesByDay.isEmpty,
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
            const Flexible(child: AnalyticsEmptyState(message: 'Sin datos'))
          else ...[
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: _buildLineChart(context),
              ),
            ),
            const SizedBox(height: 8),
            _buildTrendIndicator(context, trend),
          ],
        ],
      ),
    );
  }

  Widget _buildLineChart(BuildContext context) {
    final theme = Theme.of(context);
    final entries = salesByDay.entries.toList();

    if (entries.isEmpty) return const SizedBox();

    double maxY = 0;
    double minY = double.infinity;
    final spots = <FlSpot>[];

    for (int i = 0; i < entries.length; i++) {
      final sales = entries[i].value['totalSales'] as double? ?? 0.0;
      if (sales > maxY) maxY = sales;
      if (sales < minY) minY = sales;
      spots.add(FlSpot(i.toDouble(), sales));
    }

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
                if (index < 0 || index >= entries.length) return null;
                final date = entries[index].key;
                final sales = spot.y;
                return LineTooltipItem(
                  '${_formatDateShort(date)}\n${CurrencyHelper.formatCurrency(sales)}',
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
        maxX: (entries.length - 1).toDouble().clamp(0, double.infinity),
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
            shadow: Shadow(
              color: color.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendIndicator(BuildContext context, double trend) {
    final theme = Theme.of(context);
    final isPositive = trend >= 0;
    final trendColor =
        isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    final trendIcon =
        isPositive ? Icons.trending_up_rounded : Icons.trending_down_rounded;

    // Calcular total, promedio y estadísticas
    double totalSales = 0;
    for (final dayData in salesByDay.values) {
      totalSales += dayData['totalSales'] as double? ?? 0.0;
    }
    final avgSales = salesByDay.isNotEmpty
        ? (totalSales / salesByDay.length).toDouble()
        : 0.0;

    // Encontrar mejor y peor día
    double maxSales = 0;
    double minSales = double.infinity;
    for (final dayData in salesByDay.values) {
      final sales = dayData['totalSales'] as double? ?? 0.0;
      if (sales > maxSales) maxSales = sales;
      if (sales < minSales && sales > 0) minSales = sales;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Indicador de tendencia
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    trendColor.withValues(alpha: 0.15),
                    trendColor.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: trendColor.withValues(alpha: 0.4),
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: trendColor.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(trendIcon, size: 14, color: trendColor),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${isPositive ? '+' : ''}${trend.toStringAsFixed(1)}%',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: trendColor,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            // Días analizados
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.calendar_month_rounded,
                    size: 12,
                    color: color,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${NumberHelper.formatNumber(salesByDay.length)} días',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: color,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        // Promedio diario
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.show_chart_rounded,
                size: 11,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  '${CurrencyHelper.formatCurrency(avgSales)} promedio',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    fontSize: 10,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  double _calculateTrend() {
    if (salesByDay.length < 2) return 0.0;

    final entries = salesByDay.entries.toList();
    final midPoint = entries.length ~/ 2;

    double firstHalfTotal = 0;
    double secondHalfTotal = 0;

    for (int i = 0; i < midPoint; i++) {
      firstHalfTotal += entries[i].value['totalSales'] as double? ?? 0.0;
    }
    for (int i = midPoint; i < entries.length; i++) {
      secondHalfTotal += entries[i].value['totalSales'] as double? ?? 0.0;
    }

    if (firstHalfTotal == 0) return secondHalfTotal > 0 ? 100.0 : 0.0;
    return ((secondHalfTotal - firstHalfTotal) / firstHalfTotal) * 100;
  }

  String _formatDateShort(String dateKey) {
    try {
      final date = DateTime.parse(dateKey);
      return DateFormat('d MMM', 'es').format(date);
    } catch (_) {
      return dateKey;
    }
  }

  void _showTrendModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SalesTrendModal(salesByDay: salesByDay),
    );
  }
}

/// Modal: Análisis Detallado de Tendencia
class SalesTrendModal extends StatelessWidget {
  final Map<String, Map<String, dynamic>> salesByDay;

  const SalesTrendModal({super.key, required this.salesByDay});

  static const _accentColor = Color(0xFF3B82F6);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entries = salesByDay.entries.toList();

    double totalSales = 0;
    int totalTransactions = 0;
    double maxDaySales = 0;
    double minDaySales = double.infinity;
    String bestDay = '';
    String worstDay = '';

    for (final entry in entries) {
      final sales = entry.value['totalSales'] as double? ?? 0.0;
      final transactions = entry.value['transactionCount'] as int? ?? 0;
      totalSales += sales;
      totalTransactions += transactions;
      if (sales > maxDaySales) {
        maxDaySales = sales;
        bestDay = entry.key;
      }
      if (sales < minDaySales && sales > 0) {
        minDaySales = sales;
        worstDay = entry.key;
      }
    }

    final avgSales = entries.isNotEmpty ? totalSales / entries.length : 0.0;
    final avgTransactions =
        entries.isNotEmpty ? totalTransactions / entries.length : 0.0;

    // Calcular tendencia
    final trend = _calculateTrend();
    final isPositive = trend >= 0;
    final trendColor =
        isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444);

    return AnalyticsModal(
      title: 'Análisis de Tendencia',
      subtitle: '${NumberHelper.formatNumber(entries.length)} días analizados',
      accentColor: _accentColor,
      icon: Icons.trending_up_rounded,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Indicador de tendencia principal
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    trendColor.withValues(alpha: 0.15),
                    trendColor.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: trendColor.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: trendColor.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isPositive
                          ? Icons.trending_up_rounded
                          : Icons.trending_down_rounded,
                      color: trendColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${isPositive ? '+' : ''}${trend.toStringAsFixed(1)}%',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: trendColor,
                        ),
                      ),
                      Text(
                        isPositive
                            ? 'Crecimiento del período'
                            : 'Decrecimiento del período',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Resumen de estadísticas
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _accentColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildSummaryItem(
                          context,
                          'Total Período',
                          CurrencyHelper.formatCurrency(totalSales),
                          Icons.attach_money_rounded,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildSummaryItem(
                          context,
                          'Transacciones',
                          NumberHelper.formatNumber(totalTransactions),
                          Icons.receipt_long_rounded,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildSummaryItem(
                          context,
                          'Promedio/Día',
                          CurrencyHelper.formatCurrency(avgSales),
                          Icons.show_chart_rounded,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildSummaryItem(
                          context,
                          'Ventas/Día Prom.',
                          avgTransactions.toStringAsFixed(1),
                          Icons.analytics_rounded,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildSummaryItem(
                          context,
                          'Mejor Día',
                          CurrencyHelper.formatCurrency(maxDaySales),
                          Icons.star_rounded,
                          subtitle: _formatDateFull(bestDay),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildSummaryItem(
                          context,
                          'Día Más Bajo',
                          CurrencyHelper.formatCurrency(
                              minDaySales < double.infinity ? minDaySales : 0),
                          Icons.trending_down_rounded,
                          subtitle: worstDay.isNotEmpty
                              ? _formatDateFull(worstDay)
                              : '-',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Evolución Diaria',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: _buildDetailedChart(context, entries, maxDaySales),
            ),
            const SizedBox(height: 24),
            Text(
              'Detalle por Día',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...entries.reversed.map((entry) => _buildDayItem(
                  context,
                  entry.key,
                  entry.value,
                  maxDaySales,
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(
    BuildContext context,
    String label,
    String value,
    IconData icon, {
    String? subtitle,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: _accentColor),
            const SizedBox(width: 4),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              fontSize: 10,
            ),
          ),
        ],
      ],
    );
  }

  double _calculateTrend() {
    if (salesByDay.length < 2) return 0.0;

    final entries = salesByDay.entries.toList();
    final midPoint = entries.length ~/ 2;

    double firstHalfTotal = 0;
    double secondHalfTotal = 0;

    for (int i = 0; i < midPoint; i++) {
      firstHalfTotal += entries[i].value['totalSales'] as double? ?? 0.0;
    }
    for (int i = midPoint; i < entries.length; i++) {
      secondHalfTotal += entries[i].value['totalSales'] as double? ?? 0.0;
    }

    if (firstHalfTotal == 0) return secondHalfTotal > 0 ? 100.0 : 0.0;
    return ((secondHalfTotal - firstHalfTotal) / firstHalfTotal) * 100;
  }

  Widget _buildDetailedChart(
    BuildContext context,
    List<MapEntry<String, Map<String, dynamic>>> entries,
    double maxY,
  ) {
    final theme = Theme.of(context);
    if (entries.isEmpty) return const SizedBox();

    final spots = <FlSpot>[];
    for (int i = 0; i < entries.length; i++) {
      final sales = entries[i].value['totalSales'] as double? ?? 0.0;
      spots.add(FlSpot(i.toDouble(), sales));
    }

    maxY = maxY * 1.2;
    if (maxY == 0) maxY = 100;

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
              interval:
                  entries.length > 7 ? (entries.length / 7).ceilToDouble() : 1,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= entries.length) {
                  return const SizedBox();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _formatDateShort(entries[index].key),
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
                if (index < 0 || index >= entries.length) return null;
                final entry = entries[index];
                return LineTooltipItem(
                  '${_formatDateFull(entry.key)}\n${CurrencyHelper.formatCurrency(spot.y)}\n${entry.value['transactionCount']} ventas',
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
        maxX: (entries.length - 1).toDouble().clamp(0, double.infinity),
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
              show: entries.length <= 14,
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

  Widget _buildDayItem(
    BuildContext context,
    String dateKey,
    Map<String, dynamic> data,
    double maxSales,
  ) {
    final theme = Theme.of(context);
    final sales = data['totalSales'] as double? ?? 0.0;
    final transactions = data['transactionCount'] as int? ?? 0;
    final progress = maxSales > 0 ? sales / maxSales : 0.0;

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
                Text(
                  _formatDateFull(dateKey),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  CurrencyHelper.formatCurrency(sales),
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
                  '${NumberHelper.formatNumber(transactions)} ventas',
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

  String _formatDateShort(String dateKey) {
    try {
      final date = DateTime.parse(dateKey);
      return DateFormat('d/M', 'es').format(date);
    } catch (_) {
      return dateKey;
    }
  }

  String _formatDateFull(String dateKey) {
    try {
      final date = DateTime.parse(dateKey);
      return DateFormat('EEEE d MMM', 'es').format(date);
    } catch (_) {
      return dateKey;
    }
  }
}
