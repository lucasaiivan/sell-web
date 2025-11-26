import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sellweb/core/core.dart';
import 'package:sellweb/features/catalogue/domain/entities/product_catalogue.dart';

import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../providers/catalogue_provider.dart';
import 'package:sellweb/features/sales/presentation/providers/sales_provider.dart';
import 'package:sellweb/core/presentation/widgets/navigation/drawer.dart';
import '../widgets/product_catalogue_view.dart';
import '../widgets/product_edit_catalogue_view.dart';

/// Página dedicada para gestionar el catálogo de productos
/// Separada de la lógica de ventas para mejor organización
class CataloguePage extends StatefulWidget {
  const CataloguePage({super.key});

  @override
  State<CataloguePage> createState() => _CataloguePageState();
}

class _CataloguePageState extends State<CataloguePage> {
  bool _isGridView = true;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

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
    final sellProvider = Provider.of<SalesProvider>(context, listen: false);

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
              // Campo de búsqueda
              Flexible(
                child: Consumer<CatalogueProvider>(
                  builder: (context, catalogueProvider, _) {
                    return ProductSearchField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      hintText: 'Buscar producto',
                      products: catalogueProvider.products,
                      searchResultsCount: _searchController.text.isNotEmpty
                          ? catalogueProvider.visibleProducts.length
                          : null,
                      onChanged: (query) {
                        // Buscar productos según el query con debouncing
                        catalogueProvider.searchProductsWithDebounce(
                            query: query);
                      },
                      onClear: () {
                        // Limpiar búsqueda y mostrar todos los productos
                        catalogueProvider.clearSearchResults();
                      },
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Consumer<CatalogueProvider>(
                builder: (context, catalogueProvider, _) {
                  return PopupMenuButton<CatalogueFilter>(
                    tooltip: catalogueProvider.hasActiveFilter
                        ? 'Filtro: ${_getFilterLabel(catalogueProvider.activeFilter)}'
                        : 'Filtrar productos',
                    position: PopupMenuPosition.under,
                    offset: const Offset(0, 8),
                    initialValue: catalogueProvider.activeFilter,
                    onSelected: catalogueProvider.applyFilter,
                    itemBuilder: (context) => _buildFilterMenuEntries(
                      context,
                      catalogueProvider.activeFilter,
                    ),
                    child: IgnorePointer(
                      child: AppBarButtonCircle(
                        icon: catalogueProvider.hasActiveFilter
                            ? Icons.filter_alt_off_rounded
                            : Icons.filter_alt_rounded,
                        tooltip: catalogueProvider.hasActiveFilter
                            ? 'Quitar filtro: ${_getFilterLabel(catalogueProvider.activeFilter)}'
                            : 'Filtrar productos',
                        onPressed: () {},
                      ),
                    ),
                  );
                },
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

        // Determinar qué lista mostrar: filtrada o completa
        final displayProducts = catalogueProvider.visibleProducts;
        final hasSearch = catalogueProvider.currentSearchQuery.isNotEmpty;
        final hasFilter = catalogueProvider.hasActiveFilter;

        // Sin productos
        if (displayProducts.isEmpty) {
          if (hasSearch) {
            return _buildNoResultsState(context);
          }
          if (hasFilter) {
            return _buildFilteredEmptyState(
              context,
              catalogueProvider.activeFilter,
            );
          }
          return _buildEmptyState(context);
        }

        // Lista de productos
        return _isGridView
            ? _buildGridView(displayProducts)
            : _buildListView(displayProducts);
      },
    );
  }

  /// Construye la vista en grilla con efecto masonry
  Widget _buildGridView(List<ProductCatalogue> products) {
    return MasonryGridView.count(
      padding: const EdgeInsets.all(12),
      crossAxisCount: _getCrossAxisCount(context),
      crossAxisSpacing: 2,
      mainAxisSpacing: 6,
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        final catalogueProvider =
            Provider.of<CatalogueProvider>(context, listen: false);
        final sellProvider = Provider.of<SalesProvider>(context, listen: false);

        return _ProductCatalogueCard(
          product: product,
          catalogueProvider: catalogueProvider,
          accountId: sellProvider.profileAccountSelected.id,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => ProductCatalogueView(
                  product: product,
                  catalogueProvider: catalogueProvider,
                  accountId: sellProvider.profileAccountSelected.id,
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Construye la vista en lista vertical
  Widget _buildListView(List<ProductCatalogue> products) {
    return ListView.separated(
      padding: const EdgeInsets.all(0),
      itemCount: products.length,
      separatorBuilder: (context, index) =>
          const Divider(height: 0, thickness: 0.4),
      itemBuilder: (context, index) {
        final product = products[index];
        final catalogueProvider =
            Provider.of<CatalogueProvider>(context, listen: false);
        final sellProvider = Provider.of<SalesProvider>(context, listen: false);

        return _ProductListTile(
          product: product,
          catalogueProvider: catalogueProvider,
          accountId: sellProvider.profileAccountSelected.id,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => ProductCatalogueView(
                  product: product,
                  catalogueProvider: catalogueProvider,
                  accountId: sellProvider.profileAccountSelected.id,
                ),
              ),
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

  /// Estado cuando no hay resultados de búsqueda
  Widget _buildNoResultsState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 80,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'Sin resultados',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'No se encontraron productos para "${_searchController.text}"',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Estado cuando el filtro activo no tiene coincidencias
  Widget _buildFilteredEmptyState(
      BuildContext context, CatalogueFilter filter) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getFilterIcon(filter),
            size: 80,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'Sin coincidencias',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            _getFilterEmptyDescription(filter),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
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
        ScaffoldMessenger.of(context).clearSnackBars();
        final uniqueKey = UniqueKey();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            key: uniqueKey,
            behavior: SnackBarBehavior.floating,
            content: const Text('Agregar producto - Por implementar'),
          ),
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

  List<PopupMenuEntry<CatalogueFilter>> _buildFilterMenuEntries(
      BuildContext context, CatalogueFilter activeFilter) {
    return [
      _buildFilterMenuItem(
        context: context,
        filter: CatalogueFilter.none,
        label: 'Mostrar todos',
        icon: Icons.layers_clear,
        isSelected: activeFilter == CatalogueFilter.none,
      ),
      const PopupMenuDivider(height: 8),
      _buildFilterMenuItem(
        context: context,
        filter: CatalogueFilter.favorites,
        label: 'Favoritos',
        icon: Icons.star_rate_rounded,
        isSelected: activeFilter == CatalogueFilter.favorites,
      ),
      _buildFilterMenuItem(
        context: context,
        filter: CatalogueFilter.lowStock,
        label: 'Con bajo stock',
        icon: Icons.inventory_rounded,
        isSelected: activeFilter == CatalogueFilter.lowStock,
      ),
      _buildFilterMenuItem(
        context: context,
        filter: CatalogueFilter.outOfStock,
        label: 'Sin stock',
        icon: Icons.inventory_2_rounded,
        isSelected: activeFilter == CatalogueFilter.outOfStock,
      ),
    ];
  }

  PopupMenuEntry<CatalogueFilter> _buildFilterMenuItem({
    required BuildContext context,
    required CatalogueFilter filter,
    required String label,
    required IconData icon,
    required bool isSelected,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textStyle = Theme.of(context).textTheme.bodyMedium;

    return PopupMenuItem<CatalogueFilter>(
      value: filter,
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color:
                isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: textStyle?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
          if (isSelected)
            Icon(
              Icons.check,
              size: 18,
              color: colorScheme.primary,
            ),
        ],
      ),
    );
  }

  String _getFilterLabel(CatalogueFilter filter) {
    switch (filter) {
      case CatalogueFilter.favorites:
        return 'Favoritos';
      case CatalogueFilter.lowStock:
        return 'Con bajo stock';
      case CatalogueFilter.outOfStock:
        return 'Sin stock';
      case CatalogueFilter.none:
        return 'Todos';
    }
  }

  IconData _getFilterIcon(CatalogueFilter filter) {
    switch (filter) {
      case CatalogueFilter.favorites:
        return Icons.star_outline_rounded;
      case CatalogueFilter.lowStock:
        return Icons.report_problem_rounded;
      case CatalogueFilter.outOfStock:
        return Icons.inventory_2_outlined;
      case CatalogueFilter.none:
        return Icons.filter_alt_outlined;
    }
  }

  String _getFilterEmptyDescription(CatalogueFilter filter) {
    switch (filter) {
      case CatalogueFilter.favorites:
        return 'No tienes productos marcados como favoritos.';
      case CatalogueFilter.lowStock:
        return 'No hay productos con bajo stock según tus alertas.';
      case CatalogueFilter.outOfStock:
        return 'No hay productos sin stock disponible.';
      case CatalogueFilter.none:
        return 'No hay productos disponibles.';
    }
  }
}

/// Tarjeta para mostrar un producto en vista de lista
class _ProductListTile extends StatelessWidget {
  final ProductCatalogue product;
  final CatalogueProvider catalogueProvider;
  final String accountId;
  final VoidCallback? onTap;

  const _ProductListTile({
    required this.product,
    required this.catalogueProvider,
    required this.accountId,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
                      if (product.favorite) const SizedBox(width: 4),
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
                        if (product.verified) const SizedBox(width: 4),
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
                          DateFormatter.getSimplePublicationDate(
                              product.upgrade, DateTime.now()),
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
            // Ganancia en monto y porcentaje - Estilo minimalista (solo si hay precio de compra)
            if (product.purchasePrice > 0 &&
                product.getBenefits.isNotEmpty) ...[
              const SizedBox(width: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.green.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      product.getBenefits,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.trending_up,
                          size: 12,
                          color: Colors.green.shade600,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          product.getPorcentageFormat,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.green.shade600,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ]
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

/// Tarjeta para mostrar un producto del catálogo con altura adaptativa
class _ProductCatalogueCard extends StatelessWidget {
  final ProductCatalogue product;
  final CatalogueProvider catalogueProvider;
  final String accountId;
  final VoidCallback? onTap;

  const _ProductCatalogueCard({
    required this.product,
    required this.catalogueProvider,
    required this.accountId,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 1,
      color: Theme.of(context).colorScheme.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        onLongPress: () {
          // Navegar a la vista de edición al hacer long press
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ProductCatalogueView(
                product: product,
                catalogueProvider: catalogueProvider,
                accountId: accountId,
              ),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Imagen del producto con Stack para overlays
            AspectRatio(
              aspectRatio: 1.0,
              child: Stack(
                children: [
                  // Imagen de fondo
                  ProductImage(
                    imageUrl: product.image,
                    fit: BoxFit.cover,
                  ),

                  // Badge de categoría en la esquina superior izquierda
                  if (product.category.isNotEmpty)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          product.nameCategory,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),

                  // Badge de favorito en la esquina superior derecha
                  if (product.favorite)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade500,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.star_rounded,
                          size: 16,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 2,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Precio en la esquina inferior izquierda
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        CurrencyFormatter.formatPrice(value: product.salePrice),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onPrimary,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Información del producto
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Marca si existe
                  if (product.nameMark.isNotEmpty)
                    Row(
                      children: [
                        if (product.verified)
                          Icon(
                            Icons.verified,
                            size: 12,
                            color: Colors.blue,
                          ),
                        if (product.verified) const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            product.nameMark,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: product.verified
                                  ? Colors.blue
                                  : colorScheme.onSurfaceVariant,
                              fontSize: 10,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  if (product.nameMark.isNotEmpty) const SizedBox(height: 8),
                  // Descripción con altura dinámica
                  Text(
                    product.description,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  // Beneficio, porcentaje y stock - Estilo minimalista con wrap
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      // Beneficio y porcentaje (solo si hay precio de compra)
                      if (product.purchasePrice > 0 &&
                          product.getBenefits.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.green.withValues(alpha: 0.2),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                product.getBenefits,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.green.shade700,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.trending_up,
                                size: 10,
                                color: Colors.green.shade600,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                product.getPorcentageFormat,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.green.shade600,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Indicador de stock si está habilitado
                      if (product.stock)
                        _buildStockIndicatorCompact(
                          context: context,
                          quantityStock: product.quantityStock,
                          alertStock: product.alertStock,
                        ),
                    ],
                  ),

                  // Código si existe
                  if (product.code.isNotEmpty) ...[
                    const SizedBox(height: 6),
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Construye el indicador de stock compacto para mostrar junto a las ganancias
  Widget _buildStockIndicatorCompact({
    required BuildContext context,
    required int quantityStock,
    required int alertStock,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Determinar el estado del stock
    final bool isOutOfStock = quantityStock <= 0;
    final bool isLowStock = quantityStock > 0 && quantityStock <= alertStock;

    // Colores y contenido adaptativos
    Color backgroundColor;
    Color borderColor;
    Color textColor;
    String label;

    if (isOutOfStock) {
      backgroundColor = isDark
          ? Colors.red.shade900.withValues(alpha: 0.15)
          : Colors.red.withValues(alpha: 0.08);
      borderColor = Colors.red.withValues(alpha: 0.2);
      textColor = isDark ? Colors.red.shade300 : Colors.red.shade700;
      label = 'Sin stock';
    } else if (isLowStock) {
      backgroundColor = isDark
          ? Colors.orange.shade900.withValues(alpha: 0.15)
          : Colors.orange.withValues(alpha: 0.08);
      borderColor = Colors.orange.withValues(alpha: 0.2);
      textColor = isDark ? Colors.orange.shade300 : Colors.orange.shade700;
      label = 'Bajo stock $quantityStock';
    } else {
      backgroundColor = isDark
          ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4)
          : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5);
      borderColor = theme.colorScheme.outline.withValues(alpha: 0.2);
      textColor = isDark
          ? theme.colorScheme.onSurfaceVariant
          : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8);
      label = 'Stock $quantityStock';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: borderColor,
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: theme.textTheme.bodySmall?.copyWith(
          color: textColor,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }
}
