import 'package:flutter/material.dart';
import 'package:sellweb/core/core.dart';

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

    return GestureDetector(
      onTap: peakHours.isNotEmpty ? () => _showPeakHoursModal(context) : null,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // Fondo con gradiente sutil
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        color.withValues(alpha: 0.08),
                        color.withValues(alpha: 0.02),
                      ],
                    ),
                  ),
                ),
              ),

              // Contenido
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header con ícono y título
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.schedule_rounded,
                            color: color,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Horas Pico',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelMedium
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                              if (subtitle != null)
                                Text(
                                  subtitle!,
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant
                                            .withValues(alpha: 0.7),
                                      ),
                                ),
                            ],
                          ),
                        ),
                        if (peakHours.isNotEmpty)
                          Icon(
                            Icons.chevron_right_rounded,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant
                                .withValues(alpha: 0.5),
                            size: 20,
                          ),
                      ],
                    ),

                    const Spacer(),

                    // Mini gráfico de barras
                    if (!isZero && peakHours.isNotEmpty)
                      SizedBox(
                        height: 32,
                        child: _buildMiniBarChart(context),
                      ),

                    const SizedBox(height: 8),

                    // Hora pico principal
                    if (isZero || peakHours.isEmpty)
                      Text(
                        'Sin datos',
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant
                                      .withValues(alpha: 0.5),
                                ),
                      )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.trending_up_rounded,
                                color: color,
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                peakHourLabel,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            CurrencyHelper.formatCurrency(peakSales),
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
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
            height: 32 * normalizedHeight.clamp(0.05, 1.0),
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

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.85;

    // Encontrar el máximo para normalizar
    double maxSales = 0;
    for (final hourData in salesByHour.values) {
      final sales = hourData['totalSales'] as double;
      if (sales > maxSales) maxSales = sales;
    }

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .onSurfaceVariant
                  .withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.schedule_rounded,
                    color: Color(0xFFF59E0B),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Análisis por Hora',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        'Distribución de ventas en 24 horas',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Gráfico de barras grande
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
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
                          color: isPeak
                              ? const Color(0xFFF59E0B)
                              : sales > 0
                                  ? const Color(0xFFF59E0B)
                                      .withValues(alpha: 0.3)
                                  : Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant
                                      .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),

          // Etiquetas de hora
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('00:00',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        )),
                Text('06:00',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        )),
                Text('12:00',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        )),
                Text('18:00',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        )),
                Text('23:00',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        )),
              ],
            ),
          ),

          const Divider(height: 32),

          // Lista de horas pico
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text(
                  'Top 5 Horas Pico',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
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
              itemCount: peakHours.length,
              itemBuilder: (context, index) {
                final hourData = peakHours[index];
                final hour = hourData['hour'] as int;
                final totalSales = hourData['totalSales'] as double;
                final transactionCount = hourData['transactionCount'] as int;

                return _buildHourItem(
                  context: context,
                  position: index + 1,
                  hour: hour,
                  totalSales: totalSales,
                  transactionCount: transactionCount,
                  maxSales: maxSales,
                );
              },
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildHourItem({
    required BuildContext context,
    required int position,
    required int hour,
    required double totalSales,
    required int transactionCount,
    required double maxSales,
  }) {
    final percentage = maxSales > 0 ? (totalSales / maxSales * 100) : 0.0;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: position == 1
            ? Border.all(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                width: 1.5)
            : null,
      ),
      child: Row(
        children: [
          // Badge de posición
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: position == 1
                  ? const Color(0xFFF59E0B).withValues(alpha: 0.2)
                  : Theme.of(context).colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: position == 1
                  ? const Icon(Icons.schedule_rounded,
                      color: Color(0xFFF59E0B), size: 22)
                  : Text(
                      '$position',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
            ),
          ),
          const SizedBox(width: 16),

          // Información de la hora
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatHour(hour),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 4),
                Row(
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
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${percentage.toStringAsFixed(0)}%',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: const Color(0xFFF59E0B),
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Total vendido
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                CurrencyHelper.formatCurrency(totalSales),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFF59E0B),
                    ),
              ),
              Text(
                'vendido',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
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
