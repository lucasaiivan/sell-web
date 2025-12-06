import 'package:flutter/material.dart';
import 'package:sellweb/core/utils/helpers/currency_helper.dart';
import 'package:sellweb/features/analytics/domain/entities/sales_analytics.dart';
import 'analytics_modal.dart';

/// Widget: Modal de Ticket Promedio
///
/// **Responsabilidad:**
/// - Mostrar análisis del ticket promedio
/// - Comparar con métricas relacionadas
/// - Mostrar tendencias de ticket
class AverageTicketModal extends StatelessWidget {
  final SalesAnalytics analytics;

  const AverageTicketModal({
    super.key,
    required this.analytics,
  });

  static const _accentColor = Color(0xFF0891B2);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final averageTicket = analytics.averageProfitPerTransaction;
    final productsPerTransaction = analytics.totalTransactions > 0
        ? analytics.totalProductsSold / analytics.totalTransactions
        : 0.0;

    return AnalyticsModal(
      accentColor: _accentColor,
      icon: Icons.analytics_rounded,
      title: 'Ticket Promedio',
      subtitle: 'Análisis de ventas por transacción',
      child: analytics.totalTransactions == 0
          ? const AnalyticsModalEmptyState(
              icon: Icons.analytics_rounded,
              title: 'Sin transacciones',
              subtitle: 'Realiza algunas ventas para ver el análisis',
            )
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              children: [
                // Resumen principal
                _buildTicketSummary(
                    context, averageTicket, productsPerTransaction),
                const SizedBox(height: 24),

                // Desglose por vendedor (si hay datos)
                if (analytics.salesBySeller.isNotEmpty) ...[
                  Text(
                    'Ticket promedio por vendedor',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...analytics.salesBySeller.take(5).map(
                        (seller) => _buildSellerTicketItem(context, seller),
                      ),
                ],
              ],
            ),
    );
  }

  Widget _buildTicketSummary(
    BuildContext context,
    double averageTicket,
    double productsPerTransaction,
  ) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _accentColor.withValues(alpha: 0.15),
            _accentColor.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _accentColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Ticket promedio grande
          Text(
            CurrencyHelper.formatCurrency(averageTicket),
            style: theme.textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: _accentColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Promedio por Venta',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          // Estadísticas adicionales
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  context,
                  Icons.receipt_long_rounded,
                  '${analytics.totalTransactions}',
                  'Transacciones',
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
              ),
              Expanded(
                child: _buildStatItem(
                  context,
                  Icons.shopping_cart_rounded,
                  productsPerTransaction.toStringAsFixed(1),
                  'Prods/Venta',
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
              ),
              Expanded(
                child: _buildStatItem(
                  context,
                  Icons.inventory_2_rounded,
                  '${analytics.totalProductsSold}',
                  'Total Prods',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    IconData icon,
    String value,
    String label,
  ) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Icon(
          icon,
          size: 20,
          color: _accentColor,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
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

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Avatar del vendedor
          Container(
            width: 44,
            height: 44,
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
          const SizedBox(width: 14),
          // Nombre y transacciones
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sellerName,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$transactionCount ventas',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          // Ticket promedio
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
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
          ),
        ],
      ),
    );
  }
}

/// Muestra el modal de ticket promedio
void showAverageTicketModal(BuildContext context, SalesAnalytics analytics) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => AverageTicketModal(analytics: analytics),
  );
}
