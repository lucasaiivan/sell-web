import 'package:flutter/material.dart';
import 'package:sellweb/core/core.dart';
import 'package:sellweb/features/catalogue/domain/entities/product_catalogue.dart';
import 'package:sellweb/core/presentation/widgets/combo_tag.dart';
import '../core/widgets.dart';

/// Widget: Card de Métrica de Productos
///
/// **Responsabilidad:**
/// - Mostrar el total de productos vendidos
/// - Mostrar el producto más vendido (avatar y descripción)
/// - Abrir modal con los 10 productos más vendidos al hacer tap
///
/// **Usa:** [AnalyticsBaseCard] como base visual consistente
class ProductsMetricCard extends StatelessWidget {
  /// Total de productos vendidos (soporta fraccionarios: 2.5 kg, etc.)
  final double totalProducts;

  /// Lista de productos más vendidos con estadísticas
  /// Estructura: [{ 'product': ProductCatalogue, 'quantitySold': double, 'totalRevenue': double }]
  final List<Map<String, dynamic>> topSellingProducts;

  /// Color de la tarjeta
  final Color color;

  /// Indica si no hay datos (cero)
  final bool isZero;

  /// Subtítulo opcional
  final String? subtitle;

  const ProductsMetricCard({
    super.key,
    required this.totalProducts,
    required this.topSellingProducts,
    required this.color,
    this.isZero = false,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    // IMPORTANTE: Usar isZero para determinar si hay datos válidos en el período
    // No solo verificar si la lista tiene elementos, ya que pueden ser datos
    // que no corresponden al período filtrado actual
    final hasValidData = !isZero && topSellingProducts.isNotEmpty;

    final topProduct = hasValidData
        ? topSellingProducts.first['product'] as ProductCatalogue
        : null;
    final topProductQuantity = hasValidData 
        ? (topSellingProducts.first['quantitySold'] as num).toDouble()
        : 0.0;

    return AnalyticsBaseCard(
      color: color,
      isZero: isZero,
      icon: Icons.inventory_2_rounded,
      title: 'Productos',
      subtitle: subtitle,
      showActionIndicator: hasValidData,
      onTap: hasValidData ? () => _showTopSellingProductsModal(context) : null,
      child: isZero
          ? const Center(child: AnalyticsEmptyState(message: 'Sin ventas'))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Valor principal - flexible para adaptarse
                Flexible(
                  flex: 2,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: AnalyticsMainValue(
                      value: NumberHelper.formatNumber(totalProducts.round()),
                      isZero: isZero,
                    ),
                  ),
                ),
                // Producto más vendido preview
                if (hasValidData && topProduct != null) ...[
                  const SizedBox(height: 6),
                  _buildTopProductPreview(
                      context, topProduct, topProductQuantity),
                ],
              ],
            ),
    );
  }

  /// Construye la vista previa del producto más vendido
  Widget _buildTopProductPreview(
    BuildContext context,
    ProductCatalogue product,
    double quantitySold,
  ) {
    return AnalyticsHighlightItem(
      accentColor: color,
      leading: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: ProductImage(
          imageUrl: product.image,
          size: 28,
          borderRadius: 14,
          productDescription: product.description,
        ),
      ),
      title: product.description,
      subtitle: '${product.copyWith(quantity: quantitySold).formattedQuantityWithUnit} vendidos',
      subtitleWidget: product.isCombo
          ? Padding(
              padding: const EdgeInsets.only(top: 2.0),
              child: Row(
                children: [
                   Flexible(
                     child: Text(
                      '${product.copyWith(quantity: quantitySold).formattedQuantityWithUnit} vendidos',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const ComboTag(isCompact: true),
                ],
              ),
            )
          : null,
      badge: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Text('🏆', style: TextStyle(fontSize: 10)),
      ),
    );
  }

  /// Muestra el modal con los 10 productos más vendidos
  void _showTopSellingProductsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TopSellingProductsModal(
        topSellingProducts: topSellingProducts.take(10).toList(),
      ),
    );
  }
}

/// Modal: Top 10 Productos Más Vendidos
///
/// Muestra una lista detallada de los productos más vendidos
/// con avatar, descripción, cantidad vendida e ingresos generados.
class TopSellingProductsModal extends StatelessWidget {
  final List<Map<String, dynamic>> topSellingProducts;

  const TopSellingProductsModal({
    super.key,
    required this.topSellingProducts,
  });

  static const _accentColor = AnalyticsColors.products; // Azul Índigo

  @override
  Widget build(BuildContext context) {
    final topProduct = topSellingProducts.isNotEmpty
        ? topSellingProducts.first['product'] as ProductCatalogue
        : null;
    final topQuantitySold = topSellingProducts.isNotEmpty
        ? (topSellingProducts.first['quantitySold'] as num).toDouble()
        : 0.0;
    final topTotalRevenue = topSellingProducts.isNotEmpty
        ? topSellingProducts.first['totalRevenue'] as double
        : 0.0;

    return AnalyticsModal(
      accentColor: _accentColor,
      icon: Icons.emoji_events_rounded,
      title: 'Top Productos',
      subtitle: 'Los más vendidos del período',
      child: topSellingProducts.isEmpty
          ? const AnalyticsModalEmptyState(
              icon: Icons.inventory_2_outlined,
              title: 'No hay productos vendidos',
              subtitle: 'Realiza algunas ventas para ver el ranking',
            )
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              children: [
                // Destacar el producto más vendido
                AnalyticsStatusCard(
                  statusColor: _accentColor,
                  icon: Icons.emoji_events_rounded,
                  mainValue: topProduct?.description ?? '',
                  mainLabel: 'Producto más vendido',
                  leftMetric: AnalyticsMetric(
                    value: NumberHelper.formatNumber(topQuantitySold.round()),
                    label: 'Unidades vendidas',
                  ),
                  rightMetric: AnalyticsMetric(
                    value: CurrencyHelper.formatCurrency(topTotalRevenue),
                    label: 'Ingresos generados',
                  ),
                  feedbackIcon: Icons.star_rounded,
                  feedbackText: 'Este producto lidera tus ventas del período',
                ),
                const SizedBox(height: 24),

                // Título de la lista
                Text(
                  'Ranking completo',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),

                // Lista de productos
                ...List.generate(topSellingProducts.length, (index) {
                  final item = topSellingProducts[index];
                  final product = item['product'] as ProductCatalogue;
                  final quantitySold = item['quantitySold'] as double;
                  final totalRevenue = item['totalRevenue'] as double;
                  final position = index + 1;

                  return AnalyticsListItem(
                    position: position,
                    accentColor: _accentColor,
                    leading: Stack(
                      children: [
                        AnalyticsProductAvatar(
                          imageUrl: product.image,
                          fallbackIcon: Icons.inventory_2_outlined,
                          borderColor: _getPositionColor(position),
                        ),
                        if (product.isCombo)
                          const Positioned(
                            bottom: 0,
                            right: 0,
                            child: ComboTag(isCompact: true),
                          ),
                      ],
                    ),
                    title: product.description,
                    subtitleWidget: Row(
                      children: [
                        Expanded(
                          child: Text(
                            product.nameMark.isNotEmpty
                                ? product.nameMark
                                : product.nameCategory,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ), 
                      ],
                    ),
                    trailingWidgets: [
                      AnalyticsBadge(
                        text: product.copyWith(quantity: quantitySold).formattedQuantityWithUnit,
                        color: _accentColor,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        CurrencyHelper.formatCurrency(totalRevenue),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF059669),
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  );
                }),
              ],
            ),
    );
  }

  Color? _getPositionColor(int position) {
    switch (position) {
      case 1:
        return const Color(0xFFFFD700); // Oro
      case 2:
        return const Color(0xFFC0C0C0); // Plata
      case 3:
        return const Color(0xFFCD7F32); // Bronce
      default:
        return null;
    }
  }
}
