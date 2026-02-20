import 'package:flutter/material.dart';
import 'package:sellweb/features/catalogue/domain/entities/product_catalogue.dart';
import 'package:sellweb/features/catalogue/domain/entities/catalogue_metric.dart';
import '../providers/catalogue_provider.dart';
import 'product_table_row.dart';
import '../views/product_catalogue_view.dart';
import 'package:provider/provider.dart';
import 'package:sellweb/features/sales/presentation/providers/sales_provider.dart';
import 'package:sellweb/core/core.dart'; // Import core for formatters

class ProductTableView extends StatelessWidget {
  final List<ProductCatalogue> products;
  final CatalogueProvider catalogueProvider;
  final CatalogueMetrics metrics;

  const ProductTableView({
    super.key,
    required this.products,
    required this.catalogueProvider,
    required this.metrics,
    this.scrollController,
  });

  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    // Determinar si debemos mostrar la columna de stock separada
    // Breakpoint: 900px
    final width = MediaQuery.of(context).size.width;
    final showStockColumn = width >= 900;
    final salesProvider = Provider.of<SalesProvider>(context, listen: false);

    return Column(
      children: [
        _buildHeader(context, showStockColumn, metrics),
        Expanded(
          child: ListView.builder(
            controller: scrollController,
            itemCount: products.length,
            padding: const EdgeInsets.only(bottom: 80), // Espacio para FAB
            itemBuilder: (context, index) {
              final product = products[index];
              return ProductTableRow(
                product: product,
                catalogueProvider: catalogueProvider,
                accountId: salesProvider.profileAccountSelected.id,
                showStockColumn: showStockColumn,
                 onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ProductCatalogueView(
                          product: product,
                          catalogueProvider: catalogueProvider,
                          accountId: salesProvider.profileAccountSelected.id,
                        ),
                      ),
                    );
                  },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, bool showStockColumn, CatalogueMetrics metrics) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textStyle = theme.textTheme.labelMedium?.copyWith(
      color: colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.bold,
    );

    // Formatters
    final articlesCount = metrics.articles;
    // For inventory, we can use formatQuantity from UnitHelper if available or simple toString
    // Assuming metrics.inventory is double.
    final inventoryCount = UnitHelper.formatQuantityAdaptive(metrics.inventory, 'UN'); 
    final inventoryValue = CurrencyFormatter.formatPrice(value: metrics.inventoryValue);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.1),
        border: Border(
          bottom: BorderSide(color: colorScheme.outlineVariant, width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text('Artículos ($articlesCount)', style: textStyle),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: showStockColumn ? 2 : 3,
            child: Text(
              showStockColumn 
                  ? 'Categoría y Proveedor' 
                  : 'Categoría, Proveedor y Cantidad ($inventoryCount)', 
              style: textStyle
            ),
          ),
          const SizedBox(width: 16),
          if (showStockColumn) ...[
            Expanded(
              flex: 2,
              child: Text(
                'Cantidad ($inventoryCount)', 
                style: textStyle
              ),
            ),
            const SizedBox(width: 16),
          ],
          Expanded(
            flex: 2,
            child: Text(
              'Precio/Ganancia (Total:$inventoryValue)', 
              style: textStyle, 
              textAlign: TextAlign.end
            ),
          ),
        ],
      ),
    );
  }
}
