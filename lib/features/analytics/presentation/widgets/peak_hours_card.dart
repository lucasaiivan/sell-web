import 'package:flutter/material.dart';
import 'package:sellweb/core/core.dart';
import 'analytics_base_card.dart';
import 'analytics_modal.dart';

/// Widget: Tarjeta de Horas Pico
///
/// **Responsabilidad:**
/// - Mostrar la hora con más ventas
/// - Visualizar distribución de ventas por hora con mini gráfico
/// - Abrir modal con análisis detallado por hora
///
/// **Propiedades:**
/// - [salesByHour]: Mapa de ventas por hora (0-23)
/// - [peakHours]: Lista de horas pico ordenadas por ventas
/// - [color]: Color principal de la tarjeta
/// - [isZero]: Indica si no hay datos
/// - [subtitle]: Subtítulo opcional para modo desktop
class PeakHoursCard extends StatelessWidget {
  final Map<int, Map<String, dynamic>> salesByHour;
  final List<Map<String, dynamic>> peakHours;
  final Color color;
  final bool isZero;
  final String? subtitle;

  const PeakHoursCard({
    super.key,
    required this.salesByHour,
    required this.peakHours,
    this.color = const Color(0xFFF59E0B),
    this.isZero = false,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final topHour = peakHours.isNotEmpty ? peakHours.first : null;
    final peakHourLabel =
        topHour != null ? _formatHour(topHour['hour'] as int) : 'Sin datos';
    final peakSales = topHour?['totalSales'] as double? ?? 0.0;
    final hasData = !isZero && peakHours.isNotEmpty;

    return AnalyticsBaseCard(
      color: color,
      isZero: isZero || peakHours.isEmpty,
      icon: Icons.schedule_rounded,
      title: 'Horas Pico',
      subtitle: subtitle,
      showActionIndicator: hasData,
      onTap: hasData ? () => _showPeakHoursModal(context) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            hasData ? MainAxisAlignment.end : MainAxisAlignment.center,
        children: [
          if (!hasData)
            const Flexible(child: AnalyticsEmptyState(message: 'Sin datos'))
          else ...[
            // Mini gráfico de barras
            SizedBox(
              height: 28,
              child: _buildMiniBarChart(context),
            ),
            const SizedBox(height: 8),
            // Hora pico principal con valor (simplificado)
            _buildPeakHourPreview(context, peakHourLabel, peakSales),
          ],
        ],
      ),
    );
  }

  /// Preview simplificado de la hora pico
  Widget _buildPeakHourPreview(
      BuildContext context, String hourLabel, double totalSales) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
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
          // Icono de reloj pequeño
          Icon(
            Icons.schedule_rounded,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 8),
          // Hora
          Text(
            hourLabel,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const Spacer(),
          // Ventas compacto
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

  /// Construye un mini gráfico de barras con las 24 horas
  Widget _buildMiniBarChart(BuildContext context) {
    // Encontrar el máximo para normalizar
    double maxSales = 0;
    for (final hourData in salesByHour.values) {
      final sales = hourData['totalSales'] as double;
      if (sales > maxSales) maxSales = sales;
    }

    if (maxSales == 0) return const SizedBox();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(24, (hour) {
        final hourData = salesByHour[hour];
        final sales = hourData?['totalSales'] as double? ?? 0.0;
        final normalizedHeight = maxSales > 0 ? (sales / maxSales) : 0.0;
        final isPeak =
            peakHours.isNotEmpty && peakHours.first['hour'] as int == hour;

        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 0.5),
            height: 28 * normalizedHeight.clamp(0.05, 1.0),
            decoration: BoxDecoration(
              color: isPeak
                  ? color
                  : sales > 0
                      ? color.withValues(alpha: 0.3)
                      : Theme.of(context)
                          .colorScheme
                          .onSurfaceVariant
                          .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }

  String _formatHour(int hour) {
    if (hour == 0) return '12:00 AM';
    if (hour == 12) return '12:00 PM';
    if (hour < 12) return '$hour:00 AM';
    return '${hour - 12}:00 PM';
  }

  void _showPeakHoursModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PeakHoursModal(
        salesByHour: salesByHour,
        peakHours: peakHours,
      ),
    );
  }
}

/// Modal: Análisis Detallado por Hora
class PeakHoursModal extends StatelessWidget {
  final Map<int, Map<String, dynamic>> salesByHour;
  final List<Map<String, dynamic>> peakHours;

  const PeakHoursModal({
    super.key,
    required this.salesByHour,
    required this.peakHours,
  });

  static const _accentColor = Color(0xFFF59E0B);

  @override
  Widget build(BuildContext context) {
    // Encontrar el máximo para normalizar
    double maxSales = 0;
    for (final hourData in salesByHour.values) {
      final sales = hourData['totalSales'] as double;
      if (sales > maxSales) maxSales = sales;
    }

    return AnalyticsModal(
      accentColor: _accentColor,
      icon: Icons.schedule_rounded,
      title: 'Análisis por Hora',
      subtitle: 'Distribución de ventas en 24 horas',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Gráfico de barras grande
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                SizedBox(
                  height: 150,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(24, (hour) {
                      final hourData = salesByHour[hour];
                      final sales = hourData?['totalSales'] as double? ?? 0.0;
                      final normalizedHeight =
                          maxSales > 0 ? (sales / maxSales) : 0.0;
                      final isPeak = peakHours.isNotEmpty &&
                          peakHours.any((p) => p['hour'] as int == hour);

                      return Expanded(
                        child: Tooltip(
                          message:
                              '${_formatHour(hour)}\n${CurrencyHelper.formatCurrency(sales)}',
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 1),
                            height: 150 * normalizedHeight.clamp(0.02, 1.0),
                            decoration: BoxDecoration(
                              gradient: isPeak
                                  ? const LinearGradient(
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                      colors: [
                                        _accentColor,
                                        Color(0xFFFFB938),
                                      ],
                                    )
                                  : null,
                              color: isPeak
                                  ? null
                                  : sales > 0
                                      ? _accentColor.withValues(alpha: 0.3)
                                      : Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant
                                          .withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 8),
                // Etiquetas de hora
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: ['00:00', '06:00', '12:00', '18:00', '23:00']
                      .map((label) => Text(
                            label,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                          ))
                      .toList(),
                ),
              ],
            ),
          ),

          // Divider con título
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _accentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.local_fire_department_rounded,
                          color: _accentColor, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'Top 5 Horas Pico',
                        style:
                            Theme.of(context).textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: _accentColor,
                                ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    height: 1,
                    color: Theme.of(context)
                        .colorScheme
                        .outlineVariant
                        .withValues(alpha: 0.3),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Lista de horas pico
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: peakHours.length.clamp(0, 5),
              itemBuilder: (context, index) {
                final hourData = peakHours[index];
                final hour = hourData['hour'] as int;
                final totalSales = hourData['totalSales'] as double;
                final transactionCount = hourData['transactionCount'] as int;
                final position = index + 1;
                final percentage =
                    maxSales > 0 ? (totalSales / maxSales * 100) : 0.0;

                return AnalyticsListItem(
                  position: position,
                  accentColor: _accentColor,
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: position == 1
                          ? _accentColor.withValues(alpha: 0.15)
                          : Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                      border: Border.all(
                        color: position == 1
                            ? _accentColor.withValues(alpha: 0.4)
                            : Theme.of(context)
                                .colorScheme
                                .outlineVariant
                                .withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        position == 1
                            ? Icons.whatshot_rounded
                            : Icons.schedule_rounded,
                        color: position == 1
                            ? _accentColor
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                        size: 22,
                      ),
                    ),
                  ),
                  title: _formatHour(hour),
                  subtitleWidget: Row(
                    children: [
                      Icon(
                        Icons.receipt_long_rounded,
                        size: 14,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$transactionCount ventas',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(width: 8),
                      AnalyticsBadge(
                        text: '${percentage.toStringAsFixed(0)}%',
                        color: _accentColor,
                      ),
                    ],
                  ),
                  trailingWidgets: [
                    Text(
                      CurrencyHelper.formatCurrency(totalSales),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: _accentColor,
                          ),
                    ),
                    Text(
                      'vendido',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formatHour(int hour) {
    if (hour == 0) return '12:00 AM';
    if (hour == 12) return '12:00 PM';
    if (hour < 12) return '$hour:00 AM';
    return '${hour - 12}:00 PM';
  }
}
