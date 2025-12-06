import 'package:flutter/material.dart';
import 'package:sellweb/core/utils/helpers/currency_helper.dart';
import 'package:sellweb/features/analytics/domain/entities/sales_analytics.dart';
import 'package:sellweb/features/catalogue/domain/entities/product_catalogue.dart';
import 'analytics_modal.dart';

/// Widget: Modal de Ganancia Detallada
///
/// **Responsabilidad:**
/// - Mostrar desglose completo de la ganancia
/// - Visualizar productos más rentables
/// - Mostrar estadísticas de rentabilidad
class ProfitModal extends StatelessWidget {
  final SalesAnalytics analytics;

  const ProfitModal({
    super.key,
    required this.analytics,
  });

  static const _accentColor = Color(0xFF7C3AED);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Calcular margen de ganancia
    final profitMargin = analytics.totalSales > 0
        ? (analytics.totalProfit / analytics.totalSales * 100)
        : 0.0;

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
                  'Agrega precio de compra a tus productos para calcular ganancias',
            )
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              children: [
                // Resumen principal
                _buildProfitSummary(context, profitMargin),
                const SizedBox(height: 24),

                // Productos más rentables
                if (analytics.mostProfitableProducts.isNotEmpty) ...[
                  Text(
                    'Productos más rentables',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...analytics.mostProfitableProducts
                      .take(5)
                      .toList()
                      .asMap()
                      .entries
                      .map(
                        (entry) =>
                            _buildProductItem(context, entry.key, entry.value),
                      ),
                ],
              ],
            ),
    );
  }

  Widget _buildProfitSummary(BuildContext context, double profitMargin) {
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
          // Ganancia total grande
          Text(
            CurrencyHelper.formatCurrency(analytics.totalProfit),
            style: theme.textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: _accentColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Ganancia Total',
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
                  Icons.percent_rounded,
                  '${profitMargin.toStringAsFixed(1)}%',
                  'Margen',
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
                  Icons.attach_money_rounded,
                  CurrencyHelper.formatCurrency(analytics.totalSales),
                  'Ingresos Brutos',
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
        ),
      ],
    );
  }

  Widget _buildProductItem(
    BuildContext context,
    int index,
    Map<String, dynamic> productData,
  ) {
    final product = productData['product'] as ProductCatalogue;
    final totalProfit = productData['totalProfit'] as double? ?? 0.0;
    final quantitySold = productData['quantitySold'] as int? ?? 0;
    final position = index + 1;

    return AnalyticsListItem(
      position: position,
      accentColor: _accentColor,
      leading: AnalyticsProductAvatar(
        imageUrl: product.image,
        fallbackIcon: Icons.diamond_outlined,
        borderColor: _getPositionColor(position),
      ),
      title: product.description.isNotEmpty
          ? product.description
          : 'Producto sin nombre',
      subtitle: '$quantitySold unidades vendidas',
      trailingWidgets: [
        AnalyticsBadge(
          text: CurrencyHelper.formatCurrency(totalProfit),
          color: _accentColor,
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
void showProfitModal(BuildContext context, SalesAnalytics analytics) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => ProfitModal(analytics: analytics),
  );
}
