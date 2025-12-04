import 'package:flutter/material.dart';
import 'package:sellweb/core/core.dart';
import 'package:sellweb/features/catalogue/domain/entities/product_catalogue.dart';
import 'analytics_base_card.dart';
import 'analytics_modal.dart';

/// Widget: Card de Métrica de Productos
///
/// **Responsabilidad:**
/// - Mostrar el total de productos vendidos
/// - Mostrar el producto más vendido (avatar y descripción)
/// - Abrir modal con los 10 productos más vendidos al hacer tap
///
/// **Usa:** [AnalyticsBaseCard] como base visual consistente
class ProductsMetricCard extends StatelessWidget {
  /// Total de productos vendidos
  final int totalProducts;

  /// Lista de productos más vendidos con estadísticas
  /// Estructura: [{ 'product': ProductCatalogue, 'quantitySold': int, 'totalRevenue': double }]
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
    // Producto más vendido (si existe)
    final hasTopProduct = topSellingProducts.isNotEmpty;
    final topProduct = hasTopProduct
        ? topSellingProducts.first['product'] as ProductCatalogue
        : null;
    final topProductQuantity =
        hasTopProduct ? topSellingProducts.first['quantitySold'] as int : 0;

    return AnalyticsBaseCard(
      color: color,
      isZero: isZero,
      icon: Icons.inventory_2_rounded,
      title: 'Productos',
      subtitle: subtitle,
      showActionIndicator: hasTopProduct,
      onTap: hasTopProduct ? () => _showTopSellingProductsModal(context) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Valor principal - flexible para adaptarse
          Flexible(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: AnalyticsMainValue(
                value: totalProducts.toString(),
                isZero: isZero,
              ),
            ),
          ),
          // Producto más vendido preview
          if (hasTopProduct && topProduct != null) ...[
            const SizedBox(height: 6),
            _buildTopProductPreview(context, topProduct, topProductQuantity),
          ],
        ],
      ),
    );
  }

  /// Construye la vista previa del producto más vendido
  Widget _buildTopProductPreview(
    BuildContext context,
    ProductCatalogue product,
    int quantitySold,
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
        child: ClipOval(
          child: product.image.isNotEmpty
              ? ProductImage(
                  imageUrl: product.image,
                  size: 28,
                  borderRadius: 14,
                )
              : Icon(
                  Icons.inventory_2_outlined,
                  size: 14,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.5),
                ),
        ),
      ),
      title: product.description,
      subtitle: '$quantitySold vendidos',
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

  static const _accentColor = Color(0xFFD97706);

  @override
  Widget build(BuildContext context) {
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
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: topSellingProducts.length,
              itemBuilder: (context, index) {
                final item = topSellingProducts[index];
                final product = item['product'] as ProductCatalogue;
                final quantitySold = item['quantitySold'] as int;
                final totalRevenue = item['totalRevenue'] as double;
                final position = index + 1;

                return AnalyticsListItem(
                  position: position,
                  accentColor: _accentColor,
                  leading: AnalyticsProductAvatar(
                    imageUrl: product.image,
                    fallbackIcon: Icons.inventory_2_outlined,
                    borderColor: _getPositionColor(position),
                  ),
                  title: product.description,
                  subtitle: product.nameMark.isNotEmpty
                      ? product.nameMark
                      : product.nameCategory,
                  trailingWidgets: [
                    AnalyticsBadge(
                      text: '$quantitySold uds',
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
              },
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
