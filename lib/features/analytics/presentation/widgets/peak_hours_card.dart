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
            const SizedBox(height: 6),
            // Feedback
            _buildFeedbackText(context, topHour?['hour'] as int?),
          ],
        ],
      ),
    );
  }

  Widget _buildFeedbackText(BuildContext context, int? peakHour) {
    if (peakHour == null) return const SizedBox();
    
    final theme = Theme.of(context);
    String feedback;
    
    if (peakHour >= 12 && peakHour <= 14) {
      feedback = 'Horario de almuerzo muy activo';
    } else if (peakHour >= 19 && peakHour <= 21) {
      feedback = 'Horario nocturno con alta demanda';
    } else if (peakHour >= 9 && peakHour <= 11) {
      feedback = 'Buena actividad en la mañana';
    } else if (peakHour >= 15 && peakHour <= 18) {
      feedback = 'Tarde productiva';
    } else if (peakHour >= 6 && peakHour <= 8) {
      feedback = 'Actividad temprana destacada';
    } else {
      feedback = 'Horario inusual de ventas';
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

  static const _accentColor = AnalyticsColors.peakHours; // Rojo Coral

  String _getModalFeedback(List<Map<String, dynamic>> peakHours) {
    if (peakHours.isEmpty) return 'Sin datos de horas pico';
    
    final topHour = peakHours.first['hour'] as int;
    
    if (topHour >= 12 && topHour <= 14) {
      return 'Tu hora pico está en el almuerzo. Asegura suficiente personal y stock.';
    } else if (topHour >= 19 && topHour <= 21) {
      return 'Las noches son tu fuerte. Mantén inventario disponible en este horario.';
    } else if (topHour >= 9 && topHour <= 11) {
      return 'Las mañanas son activas. Abre temprano para aprovechar la demanda.';
    } else if (topHour >= 15 && topHour <= 18) {
      return 'Las tardes son productivas. Considera promociones en este horario.';
    } else {
      return 'Tu hora pico es inusual. Analiza el patrón para optimizar operaciones.';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Encontrar el máximo para normalizar
    double maxSales = 0;
    for (final hourData in salesByHour.values) {
      final sales = hourData['totalSales'] as double;
      if (sales > maxSales) maxSales = sales;
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      constraints: BoxConstraints(
        maxHeight: screenHeight * 0.85,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  pinned: true,
                  backgroundColor: colorScheme.surface,
                  surfaceTintColor: colorScheme.surface,
                  expandedHeight: 340,
                  toolbarHeight: 80,
                  automaticallyImplyLeading: false,
                  titleSpacing: 0,
                  title: Padding(
                    padding: const EdgeInsets.only(left: 20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _accentColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _accentColor.withValues(alpha: 0.2),
                              width: 1,
                            ),
                          ),
                          child: const Icon(
                            Icons.schedule_rounded,
                            color: _accentColor,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Análisis por Hora',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Distribución de ventas en 24 horas',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    Padding(
                      padding: const EdgeInsets.only(right: 20),
                      child: IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                        style: IconButton.styleFrom(
                          backgroundColor: colorScheme.surfaceContainerHighest,
                          foregroundColor: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    background: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 100, 20, 20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          _buildChart(context, maxSales),
                        ],
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                    child: Column(
                      children: [
                        // Feedback contextual
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _accentColor.withValues(alpha: 0.2),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.lightbulb_outline_rounded,
                                size: 16,
                                color: _accentColor,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _getModalFeedback(peakHours),
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
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
                                    style: theme.textTheme.labelMedium?.copyWith(
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
                                color: theme.colorScheme.outlineVariant
                                    .withValues(alpha: 0.3),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final hourData = peakHours[index];
                      final hour = hourData['hour'] as int;
                      final totalSales = hourData['totalSales'] as double;
                      final transactionCount =
                          hourData['transactionCount'] as int;
                      final position = index + 1;
                      final percentage =
                          maxSales > 0 ? (totalSales / maxSales * 100) : 0.0;

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: AnalyticsListItem(
                          position: position,
                          accentColor: _accentColor,
                          leading: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: position == 1
                                  ? _accentColor.withValues(alpha: 0.15)
                                  : theme.colorScheme.surfaceContainerHighest,
                              border: Border.all(
                                color: position == 1
                                    ? _accentColor.withValues(alpha: 0.4)
                                    : theme.colorScheme.outlineVariant
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
                                    : theme.colorScheme.onSurfaceVariant,
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
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '$transactionCount ventas',
                                style: theme.textTheme.labelSmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                              ),
                              const SizedBox(width: 8),
                              AnalyticsBadge(
                                text: NumberHelper.formatPercentage(percentage),
                                color: _accentColor,
                              ),
                            ],
                          ),
                          trailingWidgets: [
                            Text(
                              CurrencyHelper.formatCurrency(totalSales),
                              style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: _accentColor,
                                  ),
                            ),
                            Text(
                              'vendido',
                              style: theme.textTheme.labelSmall?.copyWith(
                                    color:
                                        theme.colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      );
                    },
                    childCount: peakHours.length.clamp(0, 5),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                      height: MediaQuery.of(context).padding.bottom + 20),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChart(BuildContext context, double maxSales) {
    return Column(
      children: [
        SizedBox(
          height: 150,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(24, (hour) {
              final hourData = salesByHour[hour];
              final sales = hourData?['totalSales'] as double? ?? 0.0;
              final normalizedHeight = maxSales > 0 ? (sales / maxSales) : 0.0;
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
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ))
              .toList(),
        ),
      ],
    );
  }

  String _formatHour(int hour) {
    if (hour == 0) return '12:00 AM';
    if (hour == 12) return '12:00 PM';
    if (hour < 12) return '$hour:00 AM';
    return '${hour - 12}:00 PM';
  }
}
