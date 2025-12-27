import 'package:flutter/material.dart';
import 'package:sellweb/core/core.dart';
import 'package:sellweb/features/catalogue/domain/entities/product_catalogue.dart';
import '../providers/catalogue_provider.dart';
import '../views/product_edit_catalogue_view.dart';
import 'package:sellweb/core/presentation/widgets/combo_tag.dart';

/// Tarjeta para mostrar un producto en vista de lista
class ProductListTile extends StatelessWidget {
  final ProductCatalogue product;
  final CatalogueProvider catalogueProvider;
  final String accountId;
  final VoidCallback? onTap;

  const ProductListTile({
    super.key,
    required this.product,
    required this.catalogueProvider,
    required this.accountId,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth >= 600;

    return InkWell(
      onTap: onTap,
      onLongPress: () {
        // Navegar a la vista de edición al hacer long press
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ProductEditCatalogueView(
              product: product,
              catalogueProvider: catalogueProvider,
              accountId: accountId,
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Imagen del producto
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: ProductImage(
                    imageUrl: product.image,
                    size: 80,
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

            const SizedBox(width: 16),

            // Información del producto - Layout responsive
            if (isLargeScreen)
              ..._buildLargeScreenLayout(context, theme, colorScheme)
            else
              ..._buildSmallScreenLayout(context, theme, colorScheme),
          ],
        ),
      ),
    );
  }

  /// Layout para pantallas pequeñas (diseño original)
  List<Widget> _buildSmallScreenLayout(
      BuildContext context, ThemeData theme, ColorScheme colorScheme) {
    return [
      // Información del producto
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Descripción
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (product.favorite)
                  Icon(
                    Icons.star_rate_rounded,
                    size: 16,
                    color: Colors.yellow[700],
                  ),
                if (product.favorite) const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    TextFormatter.capitalizeString(product.description),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ), 
              ],
            ),
            // text : marca del producto y nombre de la categoría
            Row(
              children: [
                if (product.nameMark.isNotEmpty) ...[
                  if (product.isVerified)
                    const Icon(
                      Icons.verified,
                      size: 14,
                      color: Colors.blue,
                    ),
                  if (product.isVerified) const SizedBox(width: 4),
                  Text(
                    TextFormatter.capitalizeString(product.nameMark),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: (product.isVerified)
                          ? Colors.blue
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (product.category.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Text(
                        '•',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ],
                if (product.category.isNotEmpty) ...[
                  Text(
                    TextFormatter.capitalizeString(product.nameCategory),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                if (product.nameProvider.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Text(
                      '•',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Flexible(
                    child: Text(
                      TextFormatter.capitalizeString(product.nameProvider),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),

            // text : código
            if (product.code.isNotEmpty)
              Text(
                product.code,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            const SizedBox(height: 4),
            // Fecha de actualización
            Text(
              DateFormatter.getSimplePublicationDate(
                  product.lastUpdateDate, DateTime.now()),
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontSize: 10,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),

            // text : stock
            if (product.stock && product.quantityStock > 0)
              _buildStockIndicator(
                context: context,
                quantityStock: product.quantityStock,
                alertStock: product.alertStock,
                unit: product.unit,
              ),
          ],
        ),
      ),
      // Precio y ganancia en el lado derecho
      Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          // Precio con unidad
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                CurrencyFormatter.formatPrice(value: product.salePrice),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                  fontSize: 24,
                ),
              ),
              Text(
                '/${product.unitSymbol}',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colorScheme.primary.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          // Porcentaje de ganancia - Compacto
          if (product.purchasePrice > 0 && product.getBenefits.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.green.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Text(
                product.getPorcentageFormat,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  height: 1.2,
                ),
              ),
            ),
          ],
        ],
      ),
    ];
  }

  /// Layout para pantallas grandes (3 columnas)
  List<Widget> _buildLargeScreenLayout(
      BuildContext context, ThemeData theme, ColorScheme colorScheme) {
    return [
      // Columna 1: Descripción, Marca y Código
      Expanded(
        flex: 3,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Descripción
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (product.favorite)
                  Icon(
                    Icons.star_rate_rounded,
                    size: 16,
                    color: Colors.yellow[700],
                  ),
                if (product.favorite) const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    TextFormatter.capitalizeString(product.description),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

              ],
            ),
            const SizedBox(height: 4),
            // Marca/Proveedor
            if (product.nameMark.isNotEmpty)
              Row(
                children: [
                  if (product.isVerified)
                    const Icon(
                      Icons.verified,
                      size: 14,
                      color: Colors.blue,
                    ),
                  if (product.isVerified) const SizedBox(width: 4),
                  Text(
                    product.nameMark,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: (product.isVerified)
                          ? Colors.blue
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            if (product.nameMark.isNotEmpty) const SizedBox(height: 4),
            // Código
            if (product.code.isNotEmpty)
              Text(
                product.code,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            // Fecha de actualización
            const SizedBox(height: 4),
            Text(
              DateFormatter.getSimplePublicationDate(
                  product.lastUpdateDate, DateTime.now()),
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontSize: 10,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),

      const SizedBox(width: 16),

      // Columna 2 (Centro): Categoría, Proveedor y Stock
      Expanded(
        flex: 2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Mostrar "Sin datos" si no hay categoría ni proveedor
            if (product.category.isEmpty && product.nameProvider.isEmpty)
              Text(
                'Sin datos',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                  fontStyle: FontStyle.italic,
                ),
              ),

            // Categoría
            if (product.category.isNotEmpty)
              Row(
                children: [
                  Icon(
                    Icons.category_outlined,
                    size: 14,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      TextFormatter.capitalizeString(product.nameCategory),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            if (product.category.isNotEmpty && product.nameProvider.isNotEmpty)
              const SizedBox(height: 6),

            // Proveedor
            if (product.nameProvider.isNotEmpty)
              Row(
                children: [
                  Icon(
                    Icons.local_shipping_outlined,
                    size: 14,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      TextFormatter.capitalizeString(product.nameProvider),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            if ((product.category.isNotEmpty ||
                    product.nameProvider.isNotEmpty) &&
                product.stock)
              const SizedBox(height: 6),
            // Stock
            if (product.stock && product.quantityStock > 0)
              _buildStockIndicator(
                context: context,
                quantityStock: product.quantityStock,
                alertStock: product.alertStock,
                unit: product.unit,
              ),
          ],
        ),
      ),

      const SizedBox(width: 16),

      // Columna 3: Precio y ganancia
      Expanded(
        flex: 2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Precio
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  CurrencyFormatter.formatPrice(value: product.salePrice),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                    fontSize: 24,
                  ),
                ),
                Text(
                  '/${product.unitSymbol}',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colorScheme.primary.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
            // Porcentaje de ganancia - Compacto
            if (product.purchasePrice > 0 &&
                product.getBenefits.isNotEmpty) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.green.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Text(
                  product.getPorcentageFormat,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    ];
  }

  /// Construye el indicador de stock con colores adaptativos
  Widget _buildStockIndicator({
    required BuildContext context,
    required double quantityStock,
    required double alertStock,
    required String unit,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Determinar el estado del stock
    final bool isOutOfStock = quantityStock <= 0;
    final bool isLowStock = quantityStock > 0 && quantityStock <= alertStock;

    // Colores adaptativos según el brillo
    Color backgroundColor;
    Color textColor;
    String label;

    if (isOutOfStock) {
      backgroundColor = isDark
          ? Colors.red.shade900.withValues(alpha: 0.3)
          : Colors.red.shade50;
      textColor = isDark ? Colors.red.shade300 : Colors.red.shade700;
      label = 'Sin stock';
    } else if (isLowStock) {
      backgroundColor = isDark
          ? Colors.orange.shade900.withValues(alpha: 0.3)
          : Colors.orange.shade50;
      textColor = isDark ? Colors.orange.shade300 : Colors.orange.shade700;
      label =
          'Bajo stock (${UnitHelper.formatQuantityAdaptive(quantityStock, unit)})';
    } else {
      backgroundColor = isDark
          ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4)
          : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5);
      textColor = isDark
          ? theme.colorScheme.onSurfaceVariant
          : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8);
      label = UnitHelper.formatQuantityAdaptive(quantityStock, unit);
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: textColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
