import 'package:flutter/material.dart';
import 'package:sellweb/core/constants/analytics_colors.dart';
import 'package:sellweb/core/utils/helpers/currency_helper.dart';
import 'package:sellweb/features/analytics/domain/entities/date_filter.dart';
import 'package:sellweb/features/analytics/domain/entities/sales_analytics.dart';
import 'package:sellweb/features/catalogue/domain/entities/product_catalogue.dart';
import '../core/widgets.dart';

/// Widget: Modal de Ganancia Detallada
///
/// **Responsabilidad:**
/// - Mostrar desglose completo de la ganancia
/// - Visualizar productos más rentables
/// - Mostrar estadísticas de rentabilidad
class ProfitModal extends StatelessWidget {
  final SalesAnalytics analytics;
  final DateFilter? filter;

  const ProfitModal({
    super.key,
    required this.analytics,
    this.filter,
  });

  static const _accentColor = AnalyticsColors.profit; // Verde Esmeralda

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Obtener totales del período filtrado (igual que la tarjeta)
    final periodTotals = filter != null
        ? analytics.getTotalsForFilter(filter!)
        : (
            totalSales: analytics.totalSales,
            totalProfit: analytics.totalProfit,
            totalTransactions: analytics.totalTransactions,
            averageProfitPerTransaction: analytics.averageProfitPerTransaction,
            averageTicket: analytics.totalTransactions > 0
                ? analytics.totalSales / analytics.totalTransactions
                : 0.0,
          );

    // Obtener productos más rentables según el filtro aplicado
    final profitableProducts = filter != null
        ? analytics.getMostProfitableProductsForFilter(filter!)
        : analytics.mostProfitableProducts;

    // Usar totales del período filtrado
    final totalProfit = periodTotals.totalProfit;
    final totalSales = periodTotals.totalSales;
    final profitMargin =
        totalSales > 0 ? (totalProfit / totalSales * 100) : 0.0;

    return AnalyticsModal(
      accentColor: _accentColor,
      icon: Icons.trending_up_rounded,
      title: 'Ganancia',
      subtitle: 'Análisis de rentabilidad',
      child: analytics.totalProfit == 0
          ? const AnalyticsModalEmptyState(
              icon: Icons.trending_up_rounded,
              title: 'Sin ganancias registradas',
              subtitle:
                  'Agrega precio de coste a tus productos para calcular ganancias',
            )
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              children: [
                // Resumen principal
                AnalyticsStatusCard(
                  statusColor: _accentColor,
                  leftMetric: AnalyticsMetric(
                    value: CurrencyHelper.formatCurrency(totalProfit),
                    label: 'Ganancia Total',
                  ),
                  rightMetric: AnalyticsMetric(
                    value: '${profitMargin.toStringAsFixed(2)}%',
                    label: 'Margen',
                  ),
                ),
                AnalyticsFeedbackBanner(
                  icon: const Icon(Icons.info_outline_rounded),
                  message:
                      'Los datos muestran la ganancia del periodo filtrado. Registra el precio de coste en productos para calcular ganancias y márgenes exactos.',
                  accentColor: _accentColor,
                  margin: const EdgeInsets.only(top: 16),
                ),
                const SizedBox(height: 24),

                // Productos más rentables
                if (profitableProducts.isNotEmpty) ...[
                  Text(
                    'Productos más rentables',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...profitableProducts.take(5).toList().asMap().entries.map(
                        (entry) =>
                            _buildProductItem(context, entry.key, entry.value),
                      ),
                ],
              ],
            ),
    );
  }

  Widget _buildProductItem(
    BuildContext context,
    int index,
    Map<String, dynamic> productData,
  ) {
    final product = productData['product'] as ProductCatalogue;
    final totalProfit = productData['totalProfit'] as double? ?? 0.0;
    final totalSales = product.salePrice;
    final totalCost = product.purchasePrice;
    final quantitySold = productData['quantitySold'] as double? ?? 0;
    final position = index + 1;

    return AnalyticsListItem(
      position: position,
      accentColor: _accentColor,
      leading: AnalyticsProductAvatar(
        imageUrl: product.image,
        fallbackIcon: Icons.diamond_outlined,
        borderColor: _getPositionColor(position),
      ),
      titlePrefix: product.isQuickSale
          ? Icon(
              Icons.bolt_rounded,
              size: 16,
              color: _accentColor,
            )
          : null,
      title: product.description.isNotEmpty
          ? product.description
          : 'Producto sin nombre',
      subtitle: '$quantitySold unidades vendidas',
      trailingWidgets: [
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // text : costo
            Text(
              'Compra: ${CurrencyHelper.formatCurrency(totalCost * quantitySold)}',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurfaceVariant
                        .withValues(alpha: 0.7),
                  ),
            ),
            // text : ventas
            Text(
              'Ventas: ${CurrencyHelper.formatCurrency(totalSales * quantitySold)}',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurfaceVariant
                        .withValues(alpha: 0.7),
                  ),
            ),
            const SizedBox(height: 4),
            // Ganancia destacada en caja compacta
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: _accentColor.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Text(
                CurrencyHelper.formatCurrency(totalProfit),
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: _accentColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Color _getPositionColor(int position) {
    switch (position) {
      case 1:
        return const Color(0xFFFFD700); // Oro
      case 2:
        return const Color(0xFFC0C0C0); // Plata
      case 3:
        return const Color(0xFFCD7F32); // Bronce
      default:
        return _accentColor;
    }
  }
}

/// Muestra el modal de ganancia
void showProfitModal(BuildContext context, SalesAnalytics analytics,
    {DateFilter? filter}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => ProfitModal(analytics: analytics, filter: filter),
  );
}
