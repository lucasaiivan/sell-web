import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sellweb/core/core.dart';
import 'package:sellweb/domain/entities/catalogue.dart' hide Provider;
import '../providers/catalogue_provider.dart';
import '../providers/sell_provider.dart';
import '../widgets/navigation/drawer.dart';

/// Página dedicada para gestionar el catálogo de productos
/// Separada de la lógica de ventas para mejor organización
class CataloguePage extends StatefulWidget {
  const CataloguePage({super.key});

  @override
  State<CataloguePage> createState() => _CataloguePageState();
}

class _CataloguePageState extends State<CataloguePage> {
  bool _isGridView = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      drawer: const AppDrawer(),
      body: _buildBody(context),
      floatingActionButton: _buildFloatingActionButton(context),
    );
  }

  /// Construye el AppBar de la página de catálogo
  PreferredSizeWidget _buildAppBar(BuildContext context) { 

    // controllers
    final sellProvider = Provider.of<SellProvider>(context, listen: false);

    return AppBar(
      toolbarHeight: 70,
      titleSpacing: 0,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: Container(),
      flexibleSpace: SafeArea(
        child: Container(
          padding: const EdgeInsets.only(
            top: 20.0,
            bottom: 12,
            left: 12,
            right: 12,
          ),
          child: Row(
            children: [
              // Avatar y botón de drawer
              Builder(
                builder: (context) => GestureDetector(
                  onTap: () => Scaffold.of(context).openDrawer(),
                  child: UserAvatar(
                    imageUrl: sellProvider.profileAccountSelected.image,
                    text: sellProvider.profileAccountSelected.name, 
                  ),
                ),
              ), 
              const SizedBox(width: 12),
              SearchButton(
                label: 'Productos',
                onPressed: () {},
              ),  
              const SizedBox(width: 8),
              const Spacer(),
              // button : filtro de productos
              AppBarButtonCircle(
                icon: Icons.filter_list,
                tooltip: 'Filtrar',
                onPressed: () {},
              ),
              // Botón para alternar vista
              AppBarButtonCircle(
                icon: _isGridView ? Icons.view_list : Icons.grid_view,
                tooltip: _isGridView ? 'Vista de lista' : 'Vista de grilla',
                onPressed: () => setState(() => _isGridView = !_isGridView),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Construye el cuerpo de la página con la lista de productos
  Widget _buildBody(BuildContext context) {
    return Consumer<CatalogueProvider>(
      builder: (context, catalogueProvider, child) {
        // Estado de carga
        if (catalogueProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        // Sin productos
        if (catalogueProvider.products.isEmpty) {
          return _buildEmptyState(context);
        }

        // Lista de productos
        return _isGridView
            ? _buildGridView(catalogueProvider)
            : _buildListView(catalogueProvider);
      },
    );
  }

  /// Construye la vista en grilla
  Widget _buildGridView(CatalogueProvider catalogueProvider) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _getCrossAxisCount(context),
        crossAxisSpacing: 0,
        mainAxisSpacing: 0,
        childAspectRatio: 0.75,
      ),
      itemCount: catalogueProvider.products.length,
      itemBuilder: (context, index) {
        final product = catalogueProvider.products[index];
        return _ProductCatalogueCard(
          product: product,
          onTap: () {
            // TODO: Implementar navegación o acción al tocar el producto
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Seleccionado: ${product.description}')),
            );
          },
        );
      },
    );
  }

  /// Construye la vista en lista vertical
  Widget _buildListView(CatalogueProvider catalogueProvider) {
    return ListView.separated(
      padding: const EdgeInsets.all(0),
      itemCount: catalogueProvider.products.length,
      separatorBuilder: (context, index) => const Divider(height: 0, thickness: 0.4),
      itemBuilder: (context, index) {
        final product = catalogueProvider.products[index];
        return _ProductListTile(
          product: product,
          onTap: () {
            // TODO: Implementar navegación o acción al tocar el producto
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Seleccionado: ${product.description}')),
            );
          },
        );
      },
    );
  }

  /// Estado vacío cuando no hay productos
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 80,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No hay productos en el catálogo',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Agrega tu primer producto',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  /// Botón flotante para agregar productos
  Widget _buildFloatingActionButton(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () {
        // TODO: Implementar diálogo para agregar producto
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Agregar producto - Por implementar')),
        );
      },
      icon: const Icon(Icons.add),
      label: const Text('Agregar'),
    );
  }

  /// Calcula el número de columnas según el ancho de la pantalla
  int _getCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 600) return 2;
    if (width < 900) return 3;
    if (width < 1200) return 4;
    return 7;
  }
}

/// Tarjeta para mostrar un producto en vista de lista
class _ProductListTile extends StatelessWidget {
  final ProductCatalogue product;
  final VoidCallback? onTap;

  const _ProductListTile({
    required this.product,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: onTap ?? () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Editar: ${product.description}')),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Imagen del producto
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: ProductImage(
                imageUrl: product.image,
                size: 80,
                fit: BoxFit.cover,
              ),
            ),

            const SizedBox(width: 16),

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
                      if (product.favorite)
                        const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          product.description,
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
                        if (product.verified)
                          Icon(
                            Icons.verified,
                            size: 14,
                            color: Colors.blue,
                          ),
                        if (product.verified)
                          const SizedBox(width: 4),
                        Text(
                          product.nameMark,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: (product.verified)
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
                      if (product.category.isNotEmpty)
                        Text(
                          product.nameCategory,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
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
                    // Precio y fecha de actualización
                    Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                      CurrencyFormatter.formatPrice(value: product.salePrice),
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                        fontSize: 24,
                      ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                      child: Text(
                        DateFormatter.getSimplePublicationDate(product.upgrade.toDate(),DateTime.now()),
                        style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 10,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      ),
                    ],
                    ),
                  const SizedBox(height: 8),

                  // text : stock
                  if (product.stock)
                    _buildStockIndicator(
                      context: context,
                      quantityStock: product.quantityStock,
                      alertStock: product.alertStock,
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // text : ganancia  en monto y procentaje 
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      product.getBenefits,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    Text(
                       product.getPorcentageFormat,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  /// Construye el indicador de stock con colores adaptativos
  Widget _buildStockIndicator({
    required BuildContext context,
    required int quantityStock,
    required int alertStock,
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
      label = 'Stock bajo ($quantityStock)';
    } else {
      backgroundColor = isDark 
        ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4)
        : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5);
      textColor = isDark 
        ? theme.colorScheme.onSurfaceVariant 
        : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8);
      label = 'Stock: $quantityStock';
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

/// Tarjeta para mostrar un producto del catálogo
class _ProductCatalogueCard extends StatelessWidget {
  final ProductCatalogue product;
  final VoidCallback? onTap;

  const _ProductCatalogueCard({
    required this.product,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap ?? () {
          // TODO: Implementar edición de producto
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Editar: ${product.description}')),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen del producto
            Expanded(
              flex: 3,
              child: ProductImage(
                imageUrl: product.image,
                fit: BoxFit.cover,
              ),
            ),

            // Información del producto
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Descripción
                    Text(
                      product.description,
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    // Precio y código
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          CurrencyFormatter.formatPrice(
                              value: product.salePrice),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                        if (product.code.isNotEmpty)
                          Text(
                            product.code,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 10,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Indicador de stock
            if (product.stock)
              _buildStockBanner(
                context: context,
                quantityStock: product.quantityStock,
                alertStock: product.alertStock,
              ),
          ],
        ),
      ),
    );
  }

  /// Construye el banner de stock con colores adaptativos
  Widget _buildStockBanner({
    required BuildContext context,
    required int quantityStock,
    required int alertStock,
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
        ? Colors.red.shade900.withValues(alpha: 0.4)
        : Colors.red.shade600;
      textColor = Colors.white;
      label = 'Sin stock';
    } else if (isLowStock) {
      backgroundColor = isDark 
        ? Colors.orange.shade900.withValues(alpha: 0.4)
        : Colors.orange.shade600;
      textColor = Colors.white;
      label = 'Stock bajo ($quantityStock)';
    } else {
      backgroundColor = isDark 
        ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6)
        : theme.colorScheme.surfaceContainerHigh;
      textColor = isDark 
        ? theme.colorScheme.onSurfaceVariant 
        : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.85);
      label = 'Stock: $quantityStock';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 4),
      color: backgroundColor,
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
