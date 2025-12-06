import 'package:flutter/material.dart';
import 'package:sellweb/core/core.dart';
import 'package:sellweb/features/catalogue/domain/entities/product_catalogue.dart';
import '../core/widgets.dart';

/// Widget: Card de Métrica de Rentabilidad
///
/// **Responsabilidad:**
/// - Mostrar la ganancia total
/// - Mostrar el producto más rentable (avatar, descripción, ventas y ganancia)
/// - Abrir modal con los 10 productos más rentables al hacer tap
///
/// **Usa:** [AnalyticsBaseCard] como base visual consistente
class ProfitabilityMetricCard extends StatelessWidget {
  /// Ganancia total
  final double totalProfit;

  /// Lista de productos más rentables con estadísticas
  /// Estructura: [{ 'product': ProductCatalogue, 'quantitySold': int, 'totalProfit': double, 'profitPerUnit': double }]
  final List<Map<String, dynamic>> mostProfitableProducts;

  /// Color de la tarjeta
  final Color color;

  /// Indica si no hay datos (cero)
  final bool isZero;

  /// Subtítulo opcional
  final String? subtitle;

  const ProfitabilityMetricCard({
    super.key,
    required this.totalProfit,
    required this.mostProfitableProducts,
    required this.color,
    this.isZero = false,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    // Producto más rentable (si existe)
    final hasTopProduct = mostProfitableProducts.isNotEmpty;
    final topProduct = hasTopProduct
        ? mostProfitableProducts.first['product'] as ProductCatalogue
        : null;
    final topProductQuantity =
        hasTopProduct ? mostProfitableProducts.first['quantitySold'] as int : 0;
    final topProductProfit = hasTopProduct
        ? mostProfitableProducts.first['totalProfit'] as double
        : 0.0;

    return AnalyticsBaseCard(
      color: color,
      isZero: isZero,
      icon: Icons.diamond_rounded,
      title: 'Rentabilidad',
      subtitle: subtitle,
      showActionIndicator: hasTopProduct,
      onTap: hasTopProduct
          ? () => _showMostProfitableProductsModal(context)
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Valor principal (Ganancia Total) - flexible para adaptarse
          Flexible(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: AnalyticsMainValue(
                value: CurrencyHelper.formatCurrency(totalProfit),
                isZero: isZero,
              ),
            ),
          ),
          // Producto más rentable preview
          if (hasTopProduct && topProduct != null) ...[
            const SizedBox(height: 6),
            _buildTopProductPreview(
              context,
              topProduct,
              topProductQuantity,
              topProductProfit,
            ),
            const SizedBox(height: 6),
            _buildFeedbackText(context),
          ],
        ],
      ),
    );
  }

  Widget _buildFeedbackText(BuildContext context) {
    final theme = Theme.of(context);
    final productsCount = mostProfitableProducts.length;
    
    String feedback;
    if (productsCount >= 10) {
      feedback = 'Gran variedad de productos rentables';
    } else if (productsCount >= 5) {
      feedback = 'Buenos productos generando ganancias';
    } else if (productsCount >= 3) {
      feedback = 'Pocos productos rentables';
    } else {
      feedback = 'Amplía tu catálogo rentable';
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

  /// Construye la vista previa del producto más rentable
  Widget _buildTopProductPreview(
    BuildContext context,
    ProductCatalogue product,
    int quantitySold,
    double totalProfit,
  ) {
    final theme = Theme.of(context);

    return AnalyticsHighlightItem(
      accentColor: color,
      leading: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: theme.colorScheme.surfaceContainerHighest,
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
                  Icons.diamond_outlined,
                  size: 14,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
        ),
      ),
      title: product.description,
      subtitle:
          '$quantitySold uds • ${CurrencyHelper.formatCurrency(totalProfit)}',
      badge: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Text('💎', style: TextStyle(fontSize: 10)),
      ),
    );
  }

  /// Muestra el modal con los 10 productos más rentables
  void _showMostProfitableProductsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MostProfitableProductsModal(
        mostProfitableProducts: mostProfitableProducts.take(10).toList(),
      ),
    );
  }
}

/// Modal: Top 10 Productos Más Rentables
///
/// Muestra una lista detallada de los productos más rentables
/// con avatar, descripción, cantidad vendida y ganancia generada.
class MostProfitableProductsModal extends StatelessWidget {
  final List<Map<String, dynamic>> mostProfitableProducts;

  const MostProfitableProductsModal({
    super.key,
    required this.mostProfitableProducts,
  });

  static const _accentColor = AnalyticsColors.profitability; // Violeta

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnalyticsModal(
      accentColor: _accentColor,
      icon: Icons.diamond_rounded,
      title: 'Top Rentables',
      subtitle: 'Los que más ganancias generan',
      child: mostProfitableProducts.isEmpty
          ? const AnalyticsModalEmptyState(
              icon: Icons.diamond_outlined,
              title: 'No hay datos de rentabilidad',
              subtitle: 'Agrega precio de compra a tus productos',
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Container(
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
                          Icons.stars_rounded,
                          size: 16,
                          color: _accentColor,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _getModalFeedback(mostProfitableProducts.length),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: mostProfitableProducts.length,
                    itemBuilder: (context, index) {
                final item = mostProfitableProducts[index];
                final product = item['product'] as ProductCatalogue;
                final quantitySold = item['quantitySold'] as int;
                final totalProfit = item['totalProfit'] as double;
                final profitPerUnit = item['profitPerUnit'] as double;
                final position = index + 1;

                return AnalyticsListItem(
                  position: position,
                  accentColor: _accentColor,
                  leading: AnalyticsProductAvatar(
                    imageUrl: product.image,
                    fallbackIcon: Icons.diamond_outlined,
                    borderColor: _getPositionColor(position),
                  ),
                  title: product.description,
                  subtitleWidget: Row(
                    children: [
                      Text(
                        product.nameMark.isNotEmpty
                            ? product.nameMark
                            : product.nameCategory,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(width: 8),
                      AnalyticsBadge(
                        text:
                            '+${CurrencyHelper.formatCurrency(profitPerUnit)}/u',
                        color: _accentColor,
                      ),
                    ],
                  ),
                  trailingWidgets: [
                    Text(
                      CurrencyHelper.formatCurrency(totalProfit),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: _accentColor,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    AnalyticsBadge(
                      text: '$quantitySold vendidos',
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
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

  String _getModalFeedback(int productsCount) {
    if (productsCount >= 10) {
      return '¡Excelente! Tienes una gran variedad de productos rentables generando ganancias.';
    } else if (productsCount >= 5) {
      return 'Tienes varios productos rentables. Considera expandir tu catálogo top.';
    } else if (productsCount >= 3) {
      return 'Pocos productos generan la mayoría de tus ganancias. Diversifica tu oferta rentable.';
    } else {
      return 'Tu rentabilidad depende de muy pocos productos. Amplía tu catálogo con más opciones.';
    }
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
