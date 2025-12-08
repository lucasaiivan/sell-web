import 'package:flutter/material.dart';
import 'package:sellweb/core/constants/analytics_colors.dart';
import 'package:sellweb/core/utils/helpers/currency_helper.dart';
import 'package:sellweb/features/analytics/domain/entities/date_filter.dart';
import 'package:sellweb/features/analytics/domain/entities/sales_analytics.dart';
import '../core/widgets.dart';

/// Widget: Modal de Ticket Promedio
///
/// **Responsabilidad:**
/// - Mostrar análisis del ticket promedio filtrado por el período actual
/// - Comparar con métricas relacionadas
/// - Mostrar tendencias de ticket
class AverageTicketModal extends StatelessWidget {
  final SalesAnalytics analytics;
  final DateFilter currentFilter;

  const AverageTicketModal({
    super.key,
    required this.analytics,
    required this.currentFilter,
  });

  static const _accentColor = AnalyticsColors.averageTicket; // Turquesa

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Usar los totales del período filtrado (igual que la tarjeta)
    final periodTotals = analytics.getTotalsForFilter(currentFilter);
    final averageTicket = periodTotals.averageTicket;
    final productsPerTransaction = periodTotals.totalTransactions > 0
        ? analytics.totalProductsSold / periodTotals.totalTransactions
        : 0.0;

    return AnalyticsModal(
      accentColor: _accentColor,
      icon: Icons.analytics_rounded,
      title: 'Ticket Promedio',
      subtitle: 'Análisis de ventas por transacción',
      child: periodTotals.totalTransactions == 0
          ? const AnalyticsModalEmptyState(
              icon: Icons.analytics_rounded,
              title: 'Sin transacciones',
              subtitle: 'Realiza algunas ventas para ver el análisis',
            )
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              children: [
                // Resumen principal con AnalyticsStatusCard
                AnalyticsStatusCard(
                  statusColor: _accentColor,
                  icon: Icons.analytics_rounded,
                  mainValue: CurrencyHelper.formatCurrency(averageTicket),
                  mainLabel: 'Promedio por Venta',
                  leftMetric: AnalyticsMetric(
                    value: '${periodTotals.totalTransactions}',
                    label: 'Transacciones',
                  ),
                  rightMetric: AnalyticsMetric(
                    value: productsPerTransaction.toStringAsFixed(1),
                    label: 'Productos/Venta',
                  ),
                  feedbackIcon: Icons.info_rounded,
                  feedbackText:
                      'Total de ${analytics.totalProductsSold} productos vendidos en el período',
                ),
                const SizedBox(height: 24),

                // Desglose por vendedor (si hay datos del período filtrado)
                if (periodTotals.totalTransactions > 0) ...[
                  Text(
                    'Ticket promedio por vendedor',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._getFilteredSellerStats(analytics, currentFilter)
                      .take(5)
                      .map(
                        (seller) => _buildSellerTicketItem(context, seller),
                      ),
                ],
              ],
            ),
    );
  }

  /// Filtra y calcula las estadísticas de vendedores para el período actual
  List<Map<String, dynamic>> _getFilteredSellerStats(
    SalesAnalytics analytics,
    DateFilter filter,
  ) {
    // Obtener el rango de fechas del filtro
    final now = DateTime.now();
    DateTime rangeStart;
    DateTime rangeEnd;

    switch (filter) {
      case DateFilter.today:
        rangeStart = DateTime(now.year, now.month, now.day);
        rangeEnd = rangeStart.add(const Duration(days: 1));
        break;
      case DateFilter.yesterday:
        rangeStart = DateTime(now.year, now.month, now.day - 1);
        rangeEnd = DateTime(now.year, now.month, now.day);
        break;
      case DateFilter.thisMonth:
        rangeStart = DateTime(now.year, now.month, 1);
        rangeEnd = DateTime(now.year, now.month + 1, 1);
        break;
      case DateFilter.lastMonth:
        rangeStart = DateTime(now.year, now.month - 1, 1);
        rangeEnd = DateTime(now.year, now.month, 1);
        break;
      case DateFilter.thisYear:
        rangeStart = DateTime(now.year, 1, 1);
        rangeEnd = DateTime(now.year + 1, 1, 1);
        break;
      case DateFilter.lastYear:
        rangeStart = DateTime(now.year - 1, 1, 1);
        rangeEnd = DateTime(now.year, 1, 1);
        break;
    }

    // Filtrar transacciones del período
    final filteredTransactions = analytics.transactions.where((ticket) {
      final ticketDate = ticket.creation.toDate();
      return !ticketDate.isBefore(rangeStart) && ticketDate.isBefore(rangeEnd);
    }).toList();

    // Calcular estadísticas por vendedor
    final Map<String, Map<String, dynamic>> sellerStats = {};

    for (final ticket in filteredTransactions) {
      if (ticket.annulled) continue; // Excluir anulados

      final sellerId = ticket.sellerId.isEmpty ? 'unknown' : ticket.sellerId;
      final sellerName =
          ticket.sellerName.isEmpty ? 'Sin vendedor' : ticket.sellerName;

      if (!sellerStats.containsKey(sellerId)) {
        sellerStats[sellerId] = {
          'sellerId': sellerId,
          'sellerName': sellerName,
          'totalSales': 0.0,
          'transactionCount': 0,
        };
      }

      sellerStats[sellerId]!['totalSales'] =
          (sellerStats[sellerId]!['totalSales'] as double) + ticket.priceTotal;
      sellerStats[sellerId]!['transactionCount'] =
          (sellerStats[sellerId]!['transactionCount'] as int) + 1;
    }

    // Ordenar por ventas totales
    final sortedSellers = sellerStats.values.toList()
      ..sort((a, b) =>
          (b['totalSales'] as double).compareTo(a['totalSales'] as double));

    return sortedSellers;
  }

  Widget _buildSellerTicketItem(
    BuildContext context,
    Map<String, dynamic> sellerData,
  ) {
    final theme = Theme.of(context);
    final sellerName = sellerData['sellerName'] as String? ?? 'Sin nombre';
    final totalSales = sellerData['totalSales'] as double? ?? 0.0;
    final transactionCount = sellerData['transactionCount'] as int? ?? 0;
    final averageTicket =
        transactionCount > 0 ? totalSales / transactionCount : 0.0;

    return AnalyticsListItem(
      accentColor: _accentColor,
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: _accentColor.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            sellerName.isNotEmpty ? sellerName[0].toUpperCase() : '?',
            style: theme.textTheme.titleMedium?.copyWith(
              color: _accentColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      title: sellerName,
      subtitle: '$transactionCount ventas',
      trailingWidgets: [
        Text(
          CurrencyHelper.formatCurrency(averageTicket),
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: _accentColor,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'ticket prom.',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// Muestra el modal de ticket promedio
void showAverageTicketModal(
  BuildContext context,
  SalesAnalytics analytics,
  DateFilter currentFilter,
) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => AverageTicketModal(
      analytics: analytics,
      currentFilter: currentFilter,
    ),
  );
}
