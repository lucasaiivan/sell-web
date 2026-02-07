import 'package:flutter/material.dart';
import 'package:sellweb/core/core.dart';
import 'package:sellweb/features/catalogue/domain/entities/product_catalogue.dart';
import '../providers/catalogue_provider.dart';
import 'package:sellweb/core/presentation/widgets/ui/tags/combo_tag.dart';

class ProductTableRow extends StatelessWidget {
  final ProductCatalogue product;
  final CatalogueProvider catalogueProvider;
  final String accountId;
  final VoidCallback? onTap;
  final bool showStockColumn;

  const ProductTableRow({
    super.key,
    required this.product,
    required this.catalogueProvider,
    required this.accountId,
    this.onTap,
    this.showStockColumn = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      hoverColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: colorScheme.outlineVariant.withValues(alpha: 0.4),
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            // 1. PRODUCTO (Flex 4)
            Expanded(
              flex: 4,
              child: Row(
                children: [
                  // Imagen
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: ProductImage(
                          imageUrl: product.image,
                          size: 56, // Más pequeña que en la lista
                          fit: BoxFit.cover,
                          productDescription: product.description,
                        ),
                      ),
                      if (product.isCombo)
                        const Positioned(
                          bottom: 0,
                          right: 0,
                          child: ComboTag(isCompact: true),
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  // Info Texto
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Descripción
                        Row(
                          children: [
                            if (product.favorite)
                              Padding(
                                padding: const EdgeInsets.only(right: 4),
                                child: Icon(
                                  Icons.star_rate_rounded,
                                  size: 14,
                                  color: Colors.yellow[700],
                                ),
                              ),
                            Expanded(
                              child: Text(
                                TextFormatter.capitalizeString(product.description),
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        // Marca y Código
                        const SizedBox(height: 2),
                        Wrap(
                          spacing: 8,
                          runSpacing: 2,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            if (product.nameMark.isNotEmpty)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (product.isVerified)
                                    const Padding(
                                      padding: EdgeInsets.only(right: 2),
                                      child: Icon(
                                        Icons.verified,
                                        size: 12,
                                        color: Colors.blue,
                                      ),
                                    ),
                                  Text(
                                    product.nameMark,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: product.isVerified
                                          ? Colors.blue
                                          : colorScheme.onSurfaceVariant,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            if (product.code.isNotEmpty)
                              Text(
                                product.code,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  fontSize: 11,
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

            const SizedBox(width: 16),

            // 2. CATEGORÍA Y PROVEEDOR (Flex 2 o 3)
            Expanded(
              flex: showStockColumn ? 2 : 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Wrap(
                     spacing: 6,
                     runSpacing: 6,
                     children: [
                        if (product.category.isNotEmpty)
                          _buildChip(
                             context, 
                             label: TextFormatter.capitalizeString(product.nameCategory),
                             icon: Icons.category_outlined,
                          ),
                        if (product.nameProvider.isNotEmpty)
                           _buildChip(
                             context, 
                             label: TextFormatter.capitalizeString(product.nameProvider),
                             icon: Icons.local_shipping_outlined,
                          ),
                        // Si NO mostramos columna de stock aparte, lo mostramos aquí como chip
                        if (!showStockColumn && product.stock && product.quantityStock > 0)
                           _buildStockChip(
                              context,
                              quantityStock: product.quantityStock,
                              alertStock: product.alertStock,
                              unit: product.unit,
                           )

                     ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 16),

            // 3. CANTIDAD (Flex 2) - Opcional
            if (showStockColumn)
              Expanded(
                flex: 2,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: product.stock && product.quantityStock > 0
                      ? _buildStockChip(
                          context,
                          quantityStock: product.quantityStock,
                          alertStock: product.alertStock,
                          unit: product.unit,
                        )
                      : Text(
                          '-',
                          style: theme.textTheme.bodySmall?.copyWith(
                             color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                          ),
                        ),
                ),
              ),

             if (showStockColumn) const SizedBox(width: 16),

            // 4. PRECIO/GANANCIA (Flex 2)
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    CurrencyFormatter.formatPrice(value: product.salePrice),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                  if (product.purchasePrice > 0 && product.getBenefits.isNotEmpty) ...[
                    const SizedBox(height: 4),
                     Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        product.getPorcentageFormat, // e.g. "30%"
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(BuildContext context, {required String label, required IconData icon}) {
      final theme = Theme.of(context);
      final colorScheme = theme.colorScheme;
      
      return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                  width: 0.5,
              ),
          ),
          child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                  Icon(icon, size: 12, color: colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Flexible(
                      child: Text(
                          label,
                          style: theme.textTheme.bodySmall?.copyWith(
                             fontSize: 11,
                             color: colorScheme.onSurface,
                             fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                      ),
                  ),
              ],
          ),
      );
  }

  Widget _buildStockChip(
    BuildContext context, {
    required double quantityStock,
    required double alertStock,
    required String unit,
  }) {
    final theme = Theme.of(context);

    
    final bool isOutOfStock = quantityStock <= 0;
    final bool isLowStock = quantityStock > 0 && quantityStock <= alertStock;

    Color backgroundColor;
    Color textColor;
    String label;

    if (isOutOfStock) {
      backgroundColor = Colors.red.withValues(alpha: 0.1);
      textColor = Colors.red.shade700;
      label = 'Sin stock';
    } else if (isLowStock) {
      backgroundColor = Colors.orange.withValues(alpha: 0.1);
      textColor = Colors.orange.shade800;
      label = '${UnitHelper.formatQuantityAdaptive(quantityStock, unit)} (Bajo)';
    } else {
      backgroundColor = theme.colorScheme.primaryContainer.withValues(alpha: 0.3);
      textColor = theme.colorScheme.onSurface;
      label = UnitHelper.formatQuantityAdaptive(quantityStock, unit);
    }
    
    return Container(
         padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
         decoration: BoxDecoration(
             color: backgroundColor,
             borderRadius: BorderRadius.circular(8),
             border: Border.all(
                 color: textColor.withValues(alpha: 0.2),
                 width: 0.5,
             ),
         ),
         child: Text(
             label,
             style: theme.textTheme.bodySmall?.copyWith(
                 color: textColor,
                 fontWeight: FontWeight.w600,
                 fontSize: 11,
             ),
             maxLines: 1,
             overflow: TextOverflow.ellipsis,
         ),
    );
  }
}
