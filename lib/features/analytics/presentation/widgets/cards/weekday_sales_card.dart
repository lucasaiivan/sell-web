import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:sellweb/core/core.dart';
import '../core/widgets.dart';

/// Widget: Tarjeta de Ventas por Día de la Semana
///
/// **Responsabilidad:**
/// - Mostrar qué días de la semana generan más ventas
/// - Visualizar con gráfico de barras horizontal
/// - Diferente de Horas Pico (que muestra horarios)
///
/// **Diferencia con PeakHoursCard:**
/// - Este widget agrupa por DÍA DE SEMANA (Lunes-Domingo)
/// - PeakHoursCard agrupa por HORA DEL DÍA (0:00-23:00)
class WeekdaySalesCard extends StatelessWidget {
  final Map<int, Map<String, dynamic>> salesByWeekday;
  final Color color;
  final bool isZero;
  final String? subtitle;

  const WeekdaySalesCard({
    super.key,
    required this.salesByWeekday,
    this.color = const Color(0xFF6366F1),
    this.isZero = false,
    this.subtitle,
  });

  // Nombres cortos de días
  static const List<String> _shortDayNames = [
    '',
    'L',
    'M',
    'X',
    'J',
    'V',
    'S',
    'D',
  ];

  @override
  Widget build(BuildContext context) {
    final hasData = !isZero && salesByWeekday.isNotEmpty;
    // Encontrar el día con más ventas
    final bestDay = _findBestDay();

    return AnalyticsBaseCard(
      color: color,
      isZero: isZero || salesByWeekday.isEmpty,
      icon: Icons.calendar_view_week_rounded,
      title: 'Días de Venta',
      subtitle: subtitle,
      showActionIndicator: hasData,
      onTap: hasData ? () => _showWeekdayModal(context) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            hasData ? MainAxisAlignment.end : MainAxisAlignment.center,
        children: [
          if (!hasData)
            const Flexible(child: AnalyticsEmptyState(message: 'Sin datos'))
          else ...[
            // Gráfico de barras compacto
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: _buildWeekdayBars(context),
              ),
            ),
            const SizedBox(height: 8),
            // Mejor día
            if (bestDay != null) _buildBestDayIndicator(context, bestDay),
            const SizedBox(height: 6),
            // Feedback
            _buildFeedbackText(context, bestDay),
          ],
        ],
      ),
    );
  }

  Widget _buildFeedbackText(BuildContext context, Map<String, dynamic>? bestDay) {
    final theme = Theme.of(context);
    if (bestDay == null) return const SizedBox();
    
    final dayNumber = bestDay['dayNumber'] as int? ?? 0;
    String feedback;
    
    if (dayNumber >= 6) {
      feedback = 'Fin de semana es tu mejor momento';
    } else if (dayNumber >= 2 && dayNumber <= 5) {
      feedback = 'Entre semana tienes buena actividad';
    } else {
      feedback = 'Los lunes son tu día fuerte';
    }
    
    return Text(
      feedback,
      style: theme.textTheme.bodySmall?.copyWith(
        fontWeight: FontWeight.w600,
        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
        fontSize: 11,
      ),
    );
  }

  Widget _buildWeekdayBars(BuildContext context) {
    final theme = Theme.of(context);

    // Encontrar el máximo para normalizar
    double maxSales = 0;
    for (final dayData in salesByWeekday.values) {
      final sales = dayData['totalSales'] as double? ?? 0.0;
      if (sales > maxSales) maxSales = sales;
    }

    if (maxSales == 0) return const SizedBox();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(7, (index) {
        final dayNumber = index + 1; // 1=Lunes ... 7=Domingo
        final dayData = salesByWeekday[dayNumber];
        final sales = dayData?['totalSales'] as double? ?? 0.0;
        final normalizedHeight = maxSales > 0 ? (sales / maxSales) : 0.0;
        final isWeekend = dayNumber >= 6;
        final isBestDay = sales == maxSales && sales > 0;

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Barra
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // Calcular altura máxima disponible
                      final maxAvailableHeight = constraints.maxHeight;
                      // Calcular altura de la barra
                      final barHeight = (normalizedHeight * maxAvailableHeight)
                          .clamp(4.0, maxAvailableHeight);

                      return Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          width: double.infinity,
                          height: barHeight,
                          decoration: BoxDecoration(
                            color: isBestDay
                                ? color
                                : sales > 0
                                    ? color.withValues(
                                        alpha: isWeekend ? 0.6 : 0.4,
                                      )
                                    : theme.colorScheme.onSurfaceVariant
                                        .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 4),
                // Etiqueta del día
                Text(
                  _shortDayNames[dayNumber],
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 9,
                    fontWeight: isBestDay ? FontWeight.bold : FontWeight.w500,
                    color: isBestDay
                        ? color
                        : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildBestDayIndicator(
    BuildContext context,
    Map<String, dynamic> bestDay,
  ) {
    final theme = Theme.of(context);
    final dayName = bestDay['dayName'] as String? ?? '';
    final totalSales = bestDay['totalSales'] as double? ?? 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.star_rounded,
            size: 14,
            color: const Color(0xFFFFD700),
          ),
          const SizedBox(width: 6),
          Text(
            dayName,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const Spacer(),
          Text(
            CurrencyHelper.formatCurrency(totalSales),
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic>? _findBestDay() {
    if (salesByWeekday.isEmpty) return null;

    Map<String, dynamic>? bestDay;
    double maxSales = 0;

    for (final dayData in salesByWeekday.values) {
      final sales = dayData['totalSales'] as double? ?? 0.0;
      if (sales > maxSales) {
        maxSales = sales;
        bestDay = dayData;
      }
    }

    return bestDay;
  }

  void _showWeekdayModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => WeekdaySalesModal(
        salesByWeekday: salesByWeekday,
      ),
    );
  }
}

/// Modal: Análisis Detallado por Día de la Semana
class WeekdaySalesModal extends StatelessWidget {
  final Map<int, Map<String, dynamic>> salesByWeekday;

  const WeekdaySalesModal({
    super.key,
    required this.salesByWeekday,
  });

  static const _accentColor = AnalyticsColors.weekdaySales; // Cian

  String _getModalFeedback(Map<int, Map<String, dynamic>> salesByWeekday) {
    if (salesByWeekday.isEmpty) return 'Sin datos de ventas semanales';
    
    double maxSales = 0;
    int bestDay = 0;
    
    for (final entry in salesByWeekday.entries) {
      final sales = entry.value['totalSales'] as double? ?? 0.0;
      if (sales > maxSales) {
        maxSales = sales;
        bestDay = entry.key;
      }
    }
    
    if (bestDay >= 6) {
      return 'Los fines de semana son tu fuerte. Mantén inventario completo y personal disponible.';
    } else if (bestDay >= 2 && bestDay <= 5) {
      return 'Entre semana tienes buena actividad. Aprovecha para promociones especiales.';
    } else {
      return 'Los lunes destacan en tus ventas. Inicia la semana con buena energía y stock.';
    }
  }

  static const List<String> _fullDayNames = [
    '',
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
    'Sábado',
    'Domingo',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Calcular totales
    double totalSales = 0;
    int totalTransactions = 0;
    double maxDaySales = 0; 

    for (final entry in salesByWeekday.entries) {
      final sales = entry.value['totalSales'] as double? ?? 0.0;
      final transactions = entry.value['transactionCount'] as int? ?? 0;
      totalSales += sales;
      totalTransactions += transactions;
      if (sales > maxDaySales) {
        maxDaySales = sales; 
      }
    }

    // Ordenar por ventas descendentes
    final sortedDays = salesByWeekday.entries.toList()
      ..sort((a, b) => (b.value['totalSales'] as double? ?? 0.0)
          .compareTo(a.value['totalSales'] as double? ?? 0.0));

    return AnalyticsModal(
      title: 'Ventas por Día',
      accentColor: _accentColor,
      icon: Icons.calendar_view_week_rounded,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Feedback contextual
            AnalyticsFeedbackBanner(
              icon: const Icon(Icons.calendar_today_rounded),
              message: _getModalFeedback(salesByWeekday),
              accentColor: _accentColor,
              margin: const EdgeInsets.only(top: 16, bottom: 24),
            ),
            const SizedBox(height: 16),
            // Gráfico de barras detallado
            SizedBox(
              height: 200,
              child: _buildDetailedBarChart(context, maxDaySales),
            ),
            const SizedBox(height: 24),

            // Resumen : mejor dia y cantidad de ventas 
            AnalyticsStatusCard(
              statusColor: _accentColor,
              leftMetric: AnalyticsMetric(
                value: CurrencyHelper.formatCurrency(totalSales),
                label: 'Total Semana',
              ),
              rightMetric: AnalyticsMetric(
                value: totalTransactions.toString(),
                label: 'Transacciones',
              ),
            ),
            const SizedBox(height: 24),

            // Ranking de días
            Text(
              'Ranking de Días',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            ...sortedDays.asMap().entries.map((entry) {
              final rank = entry.key + 1;
              final dayNumber = entry.value.key;
              final dayData = entry.value.value;
              return _buildDayRankItem(
                context,
                rank,
                dayNumber,
                dayData,
                maxDaySales,
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedBarChart(BuildContext context, double maxSales) {
    final theme = Theme.of(context);

    if (maxSales == 0) return const Center(child: Text('Sin datos'));

    final barGroups = <BarChartGroupData>[];

    for (int i = 1; i <= 7; i++) {
      final dayData = salesByWeekday[i];
      final sales = dayData?['totalSales'] as double? ?? 0.0;
      final isWeekend = i >= 6;

      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: sales,
              color: isWeekend
                  ? _accentColor
                  : _accentColor.withValues(alpha: 0.6),
              width: 28,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(6),
              ),
            ),
          ],
        ),
      );
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxSales * 1.2,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            tooltipPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            getTooltipColor: (_) => theme.colorScheme.surfaceContainerHighest,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final dayName = _fullDayNames[group.x];
              return BarTooltipItem(
                '$dayName\n${CurrencyHelper.formatCurrency(rod.toY)}',
                TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              getTitlesWidget: (value, meta) {
                final dayIndex = value.toInt();
                if (dayIndex < 1 || dayIndex > 7) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _fullDayNames[dayIndex].substring(0, 3),
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 11,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
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
              interval: maxSales / 4,
              getTitlesWidget: (value, meta) {
                return Text(
                  _formatAxisValue(value),
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
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxSales / 4,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
              strokeWidth: 1,
            );
          },
        ),
        borderData: FlBorderData(show: false),
        barGroups: barGroups,
      ),
    );
  }

  /// Formatea valores del eje Y sin decimales para montos redondos
  String _formatAxisValue(double value) {
    if (value == 0) return '\$0';
    
    // Si es un número muy grande, mostrar en K
    if (value >= 1000) {
      if (value % 1000 == 0) {
        return '\$${(value / 1000).toStringAsFixed(0)}K';
      } else {
        return '\$${(value / 1000).toStringAsFixed(1)}K';
      }
    }
    
    // Para números pequeños, mostrar sin decimales si son números redondos
    if (value == value.truncate()) {
      return '\$${value.toStringAsFixed(0)}';
    }
    
    // Si tiene decimales, mostrar con 0 decimales si es muy cercano a un entero
    final rounded = value.round();
    if ((value - rounded).abs() < 0.01) {
      return '\$${rounded.toStringAsFixed(0)}';
    }
    
    // Sino, usar el formato estándar
    return CurrencyHelper.formatCurrency(value);
  }

  Widget _buildDayRankItem(
    BuildContext context,
    int rank,
    int dayNumber,
    Map<String, dynamic> dayData,
    double maxSales,
  ) {
    final theme = Theme.of(context);
    final dayName = _fullDayNames[dayNumber];
    final totalSales = dayData['totalSales'] as double? ?? 0.0;
    final transactionCount = dayData['transactionCount'] as int? ?? 0;
    final progress = maxSales > 0 ? totalSales / maxSales : 0.0;
    final isWeekend = dayNumber >= 6;

    // Colores para ranking
    Color rankColor;
    IconData? rankIcon;
    switch (rank) {
      case 1:
        rankColor = const Color(0xFFFFD700);
        rankIcon = Icons.emoji_events_rounded;
        break;
      case 2:
        rankColor = const Color(0xFFC0C0C0);
        rankIcon = Icons.emoji_events_rounded;
        break;
      case 3:
        rankColor = const Color(0xFFCD7F32);
        rankIcon = Icons.emoji_events_rounded;
        break;
      default:
        rankColor = _accentColor;
        rankIcon = null;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: rankColor.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Ranking badge
                if (rankIcon != null)
                  Icon(rankIcon, size: 16, color: rankColor)
                else
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: _accentColor.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '$rank',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: _accentColor,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                // Nombre del día
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        dayName,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (isWeekend)
                        Container(
                          margin: const EdgeInsets.only(left: 6),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _accentColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'FIN DE SEMANA',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontSize: 8,
                              fontWeight: FontWeight.w600,
                              color: _accentColor,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                // Monto
                Text(
                  CurrencyHelper.formatCurrency(totalSales),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: rank <= 3 ? rankColor : _accentColor,
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
                      color: rank <= 3 ? rankColor : _accentColor,
                      minHeight: 6,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '$transactionCount ventas',
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
}
