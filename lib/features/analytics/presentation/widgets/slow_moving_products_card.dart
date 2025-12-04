import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sellweb/core/core.dart';
import 'package:sellweb/features/catalogue/domain/entities/product_catalogue.dart';

/// Widget: Tarjeta de Productos de Lenta Rotación
///
/// **Responsabilidad:**
/// - Mostrar productos con pocas ventas
/// - Alertar sobre inventario estancado
/// - Abrir modal con lista completa de productos lentos
///
/// **Propiedades:**
/// - [slowMovingProducts]: Lista de productos con baja rotación
/// - [color]: Color principal de la tarjeta
/// - [isZero]: Indica si no hay datos
/// - [subtitle]: Subtítulo opcional para modo desktop
class SlowMovingProductsCard extends StatelessWidget {
  final List<Map<String, dynamic>> slowMovingProducts;
  final Color color;
  final bool isZero;
  final String? subtitle;

  const SlowMovingProductsCard({
    super.key,
    required this.slowMovingProducts,
    this.color = const Color(0xFFEF4444),
    this.isZero = false,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final topProduct = slowMovingProducts.isNotEmpty
        ? slowMovingProducts.first['product'] as ProductCatalogue
        : null;
    final totalSlowProducts = slowMovingProducts.length;

    return GestureDetector(
      onTap: slowMovingProducts.isNotEmpty
          ? () => _showSlowMovingModal(context)
          : null,
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
                            Icons.warning_amber_rounded,
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
                                'Lenta Rotación',
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
                        if (slowMovingProducts.isNotEmpty)
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

                    // Producto con menos ventas
                    if (isZero || slowMovingProducts.isEmpty)
                      Text(
                        'Sin alertas',
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
                          Text(
                            topProduct?.description ?? 'Producto',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '$totalSlowProducts producto${totalSlowProducts != 1 ? 's' : ''} con pocas ventas',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: color,
                                    fontWeight: FontWeight.w600,
                                  ),
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

  void _showSlowMovingModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          SlowMovingProductsModal(slowMovingProducts: slowMovingProducts),
    );
  }
}

/// Modal: Lista Completa de Productos de Lenta Rotación
class SlowMovingProductsModal extends StatelessWidget {
  final List<Map<String, dynamic>> slowMovingProducts;

  const SlowMovingProductsModal({
    super.key,
    required this.slowMovingProducts,
  });

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.85;

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
                    color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    color: Color(0xFFEF4444),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Productos de Lenta Rotación',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        '${slowMovingProducts.length} productos con pocas ventas',
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

          // Info explicativa
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.lightbulb_outline_rounded,
                  color: Color(0xFFF59E0B),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Productos vendidos 5 o menos veces. Considera promociones o ajustes de precio.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF92400E),
                        ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 24),

          // Lista de productos
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: slowMovingProducts.length,
              itemBuilder: (context, index) {
                final productData = slowMovingProducts[index];
                final product = productData['product'] as ProductCatalogue;
                final quantitySold = productData['quantitySold'] as int;
                final totalRevenue = productData['totalRevenue'] as double;
                final lastSoldDate = productData['lastSoldDate'] as DateTime;

                return _buildProductItem(
                  context: context,
                  product: product,
                  quantitySold: quantitySold,
                  totalRevenue: totalRevenue,
                  lastSoldDate: lastSoldDate,
                );
              },
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildProductItem({
    required BuildContext context,
    required ProductCatalogue product,
    required int quantitySold,
    required double totalRevenue,
    required DateTime lastSoldDate,
  }) {
    // Calcular días desde última venta
    final daysSinceLastSale = DateTime.now().difference(lastSoldDate).inDays;
    final dateFormat = DateFormat('dd/MM/yyyy');

    // Color de alerta basado en días sin vender
    Color alertColor;
    String alertLabel;
    if (daysSinceLastSale > 30) {
      alertColor = const Color(0xFFEF4444); // Rojo - más de 30 días
      alertLabel = 'Crítico';
    } else if (daysSinceLastSale > 14) {
      alertColor = const Color(0xFFF59E0B); // Naranja - más de 14 días
      alertLabel = 'Atención';
    } else {
      alertColor = const Color(0xFF10B981); // Verde - reciente
      alertLabel = 'Reciente';
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: alertColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Avatar del producto
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: alertColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: product.image.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      product.image,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.inventory_2_outlined,
                        color: alertColor,
                        size: 24,
                      ),
                    ),
                  )
                : Icon(
                    Icons.inventory_2_outlined,
                    color: alertColor,
                    size: 24,
                  ),
          ),
          const SizedBox(width: 16),

          // Información del producto
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        product.description,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: alertColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        alertLabel,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: alertColor,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.shopping_cart_outlined,
                      size: 14,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$quantitySold vendido${quantitySold != 1 ? 's' : ''}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 14,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      dateFormat.format(lastSoldDate),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Ingresos
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                CurrencyHelper.formatCurrency(totalRevenue),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
              ),
              Text(
                'ingresos',
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
}
