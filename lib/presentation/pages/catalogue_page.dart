import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sellweb/core/core.dart';
import 'package:sellweb/domain/entities/catalogue.dart' hide Provider;
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
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
        final sellProvider = Provider.of<SellProvider>(context, listen: false);

        return _ProductCatalogueCard(
          product: product,
          catalogueProvider: catalogueProvider,
          accountId: sellProvider.profileAccountSelected.id,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => _ProductCatalogueView(
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
        final sellProvider = Provider.of<SellProvider>(context, listen: false);

        return _ProductListTile(
          product: product,
          catalogueProvider: catalogueProvider,
          accountId: sellProvider.profileAccountSelected.id,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => _ProductCatalogueView(
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text('Agregar producto - Por implementar'),
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
            builder: (context) => _ProductEditCatalogueView(
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
                              product.upgrade.toDate(), DateTime.now()),
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
              builder: (context) => _ProductEditCatalogueView(
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

/// Vista previa del producto del catálogo con diseño responsivo
class _ProductCatalogueView extends StatefulWidget {
  final ProductCatalogue product;
  final CatalogueProvider catalogueProvider;
  final String accountId;

  const _ProductCatalogueView({
    required this.product,
    required this.catalogueProvider,
    required this.accountId,
  });

  @override
  State<_ProductCatalogueView> createState() => _ProductCatalogueViewState();
}

class _ProductCatalogueViewState extends State<_ProductCatalogueView> {
  /// Indica si hay una operación de actualización de favorito en progreso
  bool _isUpdatingFavorite = false;

  /// Producto actual sincronizado con Firebase
  late ProductCatalogue _currentProduct;

  // ═══════════════════════════════════════════════════════════════
  // LIFECYCLE METHODS
  // ═══════════════════════════════════════════════════════════════
  @override
  void initState() {
    super.initState();
    _currentProduct = widget.product;
    widget.catalogueProvider.addListener(_onProviderUpdate);
  }

  @override
  void dispose() {
    widget.catalogueProvider.removeListener(_onProviderUpdate);
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════
  // EVENT HANDLERS - Gestión de favoritos
  // ═══════════════════════════════════════════════════════════════

  /// Sincroniza el producto completo cuando el provider detecta cambios en Firebase
  void _onProviderUpdate() {
    final updatedProduct = widget.catalogueProvider.products.firstWhere(
      (p) => p.id == widget.product.id,
      orElse: () => widget.product,
    );

    // Actualizar el producto si hay cambios en campos relevantes
    if (mounted && _hasProductChanged(updatedProduct)) {
      setState(() {
        _currentProduct = updatedProduct;
      });
    }
  }

  /// Verifica si el producto ha cambiado comparando campos relevantes
  bool _hasProductChanged(ProductCatalogue updatedProduct) {
    return updatedProduct.upgrade.millisecondsSinceEpoch !=
            _currentProduct.upgrade.millisecondsSinceEpoch ||
        updatedProduct.favorite != _currentProduct.favorite ||
        updatedProduct.salePrice != _currentProduct.salePrice ||
        updatedProduct.purchasePrice != _currentProduct.purchasePrice ||
        updatedProduct.description != _currentProduct.description ||
        updatedProduct.quantityStock != _currentProduct.quantityStock;
  }

  /// Alterna el estado de favorito del producto con manejo de errores
  Future<void> _toggleFavorite() async {
    if (_isUpdatingFavorite || !mounted) return;

    final newFavoriteState = !_currentProduct.favorite;

    // Actualizar estado local inmediatamente para feedback visual
    setState(() {
      _isUpdatingFavorite = true;
      _currentProduct = _currentProduct.copyWith(favorite: newFavoriteState);
    });

    try {
      await widget.catalogueProvider.updateProductFavorite(
        widget.accountId,
        widget.product.id,
        newFavoriteState,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  newFavoriteState ? Icons.star : Icons.star_border,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    newFavoriteState
                        ? 'Producto agregado a favoritos'
                        : 'Producto quitado de favoritos',
                  ),
                ),
              ],
            ),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      // Revertir el cambio local si hubo error
      if (mounted) {
        setState(() {
          _currentProduct = _currentProduct.copyWith(favorite: !newFavoriteState);
        });

        final errorMessage = e.toString().replaceFirst('Exception: ', '');
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    errorMessage.contains('Error al actualizar favorito')
                        ? 'No se pudo actualizar. Intenta nuevamente.'
                        : errorMessage,
                  ),
                ),
              ],
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Reintentar',
              textColor: Colors.white,
              onPressed: _toggleFavorite,
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingFavorite = false;
        });
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // BUILD METHOD - Construcción de la UI principal
  // ═══════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentProduct.description),
        centerTitle: false,
        actionsPadding: const EdgeInsets.all(8),
        actions: [
          // button : agregar a favoritos
          AppBarButtonCircle(
            icon: _currentProduct.favorite
                ? Icons.star_rate_rounded
                : Icons.star_outline_rounded,
            tooltip: _currentProduct.favorite
                ? 'Quitar de favoritos'
                : 'Agregar a favoritos',
            onPressed: _isUpdatingFavorite ? null : _toggleFavorite,
            isLoading: _isUpdatingFavorite,
            colorAccent:
                _currentProduct.favorite ? Colors.amber.shade600 : null,
            backgroundColor: _currentProduct.favorite
                ? Colors.amber.withValues(alpha: 0.2)
                : null,
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          const double maxContentWidth = 1200;
          final double effectiveWidth = constraints.maxWidth > maxContentWidth
              ? maxContentWidth
              : constraints.maxWidth;
          final bool isDesktop = effectiveWidth >= 1000;
          final bool isTablet = effectiveWidth >= 720;
          final int columns = isDesktop
              ? 3
              : isTablet
                  ? 2
                  : 1;
          final double horizontalPadding = isTablet ? 32 : 20;
          final double gap = 16;
          final double gridWidth = (effectiveWidth - horizontalPadding * 2)
              .clamp(320.0, effectiveWidth)
              .toDouble();
          final double cardWidth = _calculateCardWidth(gridWidth, columns, gap);

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: 24,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: maxContentWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildSummaryCard(context, isDesktop),
                    const SizedBox(height: 24),
                    Wrap(
                      spacing: gap,
                      runSpacing: gap,
                      children: _buildInfoCards(context).map((card) {
                        return SizedBox(
                          width: columns == 1 ? double.infinity : cardWidth,
                          child: card,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 50),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => _ProductEditCatalogueView(
                product: _currentProduct,
                catalogueProvider: widget.catalogueProvider,
                accountId: widget.accountId,
              ),
            ),
          );
        },
        icon: const Icon(Icons.edit),
        label: const Text('Editar'),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // UI BUILDERS - Cards de información
  // ═══════════════════════════════════════════════════════════════

  /// Construye las tarjetas de información del producto (stock, precios, actividad)
  List<Widget> _buildInfoCards(BuildContext context) {
    final product = _currentProduct;
    final cards = <Widget>[
      if (product.nameCategory.isNotEmpty ||
          product.provider.isNotEmpty ||
          product.nameProvider.isNotEmpty ||
          product.stock)
        _buildInfoCard(
          context: context,
          title: 'Inventario y proveedor',
          icon: Icons.inventory_2_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoList(
                context,
                [
                  // item : categoría
                  if (product.nameCategory.isNotEmpty)
                    {
                      'icon': Icons.category_outlined,
                      'label': 'Categoría',
                      'value': product.nameCategory,
                    },
                  // item : proveedor
                  if (product.nameProvider.isNotEmpty ||
                      product.provider.isNotEmpty)
                    {
                      'icon': Icons.local_shipping_outlined,
                      'label': 'Proveedor',
                      'value': product.nameProvider.isNotEmpty
                          ? product.nameProvider
                          : product.provider,
                    },
                  if (product.stock) ...[
                    {
                      'label': 'Cantidad disponible',
                      'value': product.quantityStock.toString(),
                      'icon': Icons.inventory_outlined,
                    },
                    {
                      'label': 'Alerta configurada',
                      'value': product.alertStock.toString(),
                      'icon': Icons.notification_important_outlined,
                    },
                  ] else
                    {
                      'label': 'Control de stock',
                      'value': 'Sin control',
                      'icon': Icons.inventory_outlined,
                    },
                ],
              ),
              if (product.stock &&
                  product.quantityStock <= product.alertStock) ...[
                const SizedBox(height: 12),
                _buildStockAlert(context),
              ],
            ],
          ),
        ),
      _buildInfoCard(
        context: context,
        title: 'Precios y margen',
        icon: Icons.attach_money_rounded,
        child: _buildInfoList(
          context,
          [
            {
              'label': 'Venta al público',
              'value': CurrencyFormatter.formatPrice(value: product.salePrice),
              'icon': Icons.local_offer_outlined,
            },
            {
              'label': 'Compra',
                'value': product.purchasePrice > 0
                  ? CurrencyFormatter.formatPrice(
                    value: product.purchasePrice,
                  )
                  : 'No definido',
                'icon': Icons.local_shipping_outlined,
            },
            if (product.purchasePrice > 0 &&
                product.getPorcentageFormat.isNotEmpty)
                {
                'label': 'Margen',
                'valueColor': Colors.green.shade700,
                'value': product.getPorcentageFormat,
                'icon': Icons.trending_up,
              },
            if (product.purchasePrice > 0 && product.getBenefits.isNotEmpty)
              {
                'label': 'Beneficio estimado',
                'valueColor': Colors.green.shade700,
                'value': product.getBenefits,
                'icon': Icons.ssid_chart_outlined,
              },
             
          ],
        ),
      ),
      _buildInfoCard(
        context: context,
        title: 'Actividad',
        icon: Icons.timeline_outlined,
        child: _buildInfoList(
          context,
          [
            {
              'label': 'Ventas',
              'value': product.sales.toString(),
              'icon': Icons.receipt_long_outlined,
            },
            {
              'label': 'Creado',
              'value': DateFormatter.getSimplePublicationDate(
                product.creation.toDate(),
                DateTime.now(),
              ),
              'icon': Icons.calendar_today_outlined,
            },
            {
              'label': 'Ultima actualización',
              'value': DateFormatter.getSimplePublicationDate(
                product.upgrade.toDate(),
                DateTime.now(),
              ),
              'icon': Icons.update,
            },
          ],
        ),
      ),
    ];

    return cards;
  }

  /// Construye el card de resumen principal con imagen y datos destacados
  Widget _buildSummaryCard(BuildContext context, bool isWide) {
    final product = _currentProduct;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final salePrice = CurrencyFormatter.formatPrice(value: product.salePrice);
    final purchasePrice = product.purchasePrice > 0
        ? CurrencyFormatter.formatPrice(value: product.purchasePrice)
        : 'Sin dato';
    final updatedLabel = DateFormatter.getSimplePublicationDate(
      product.upgrade.toDate(),
      DateTime.now(),
    );

    final summaryContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          product.description.isNotEmpty
              ? product.description
              : 'Producto sin nombre',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        // marca del producto
        if (product.nameMark.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: product.verified
                  ? Colors.blue.withValues(alpha: 0.12)
                  : theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(999),
              border: product.verified
                  ? Border.all(color: Colors.blue.withValues(alpha: 0.3))
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (product.verified) ...[
                  Icon(
                    Icons.verified,
                    size: 16,
                    color: Colors.blue,
                  ),
                  const SizedBox(width: 6),
                ],
                Text(
                  product.nameMark,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: product.verified
                        ? Colors.blue
                        : theme.colorScheme.onSurfaceVariant,
                    fontWeight: product.verified ? FontWeight.w600 : null,
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            // text chip : código
            if (product.code.isNotEmpty)
              _buildMetaChip(
                context,
                icon: Icons.qr_code_2,
                label: product.code,
              ),
            // text chip : categoría
            if (product.nameCategory.isNotEmpty)
              _buildMetaChip(
                context,
                icon: Icons.category_outlined,
                label: product.nameCategory,
              ),

            // text chip : marca
            if (product.provider.isNotEmpty)
              _buildMetaChip(
                context,
                icon: Icons.local_shipping_outlined,
                label: product.nameProvider.isNotEmpty
                    ? product.nameProvider
                    : product.provider,
              ),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Text(
                salePrice,
                style: theme.textTheme.displaySmall?.copyWith(
                  color: colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 16),
              if (product.purchasePrice > 0)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Compra: $purchasePrice',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: colorScheme.onPrimaryContainer.withValues(
                          alpha: 0.8,
                        ),
                      ),
                    ),
                    if (product.getPorcentageFormat.isNotEmpty)
                      Text(
                        'Margen ${product.getPorcentageFormat}',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            // status chip : favorito
            if (product.favorite)
              _buildStatusChip(
                context,
                icon: Icons.star_rate_rounded,
                label: 'Favorito',
                color: Colors.amber.shade600,
              ),
            // status chip : stock con estados
            if (product.stock)
              _buildStatusChip(
                context,
                icon: product.quantityStock <= 0
                    ? Icons.inventory_2_outlined
                    : product.quantityStock <= product.alertStock
                        ? Icons.warning_amber_rounded
                        : Icons.inventory_outlined,
                label: product.quantityStock <= 0
                    ? 'Sin stock'
                    : product.quantityStock <= product.alertStock
                        ? 'Bajo stock (${product.quantityStock})'
                        : 'Stock: ${product.quantityStock}',
                color: product.quantityStock <= 0
                    ? Colors.red
                    : product.quantityStock <= product.alertStock
                        ? Colors.orange
                        : Colors.green,
                filled: true,
              )
            else
              _buildStatusChip(
                context,
                icon: Icons.inventory_outlined,
                label: 'Sin control de stock',
                color: colorScheme.outline,
                filled: false,
              ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Actualizado $updatedLabel',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );

    Widget imagePreview(BuildContext context) {
      return SizedBox(
        width: isWide ? 260 : double.infinity,
        child: AspectRatio(
          aspectRatio: 1,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: product.image.isNotEmpty
                ? ProductImage(
                    imageUrl: product.image,
                    fit: BoxFit.cover,
                  )
                : Container(
                    color: colorScheme.surfaceContainerHighest,
                    child: Icon(
                      Icons.inventory_2_outlined,
                      size: 72,
                      color: colorScheme.outline,
                    ),
                  ),
          ),
        ),
      );
    }

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
      ),
      child: Padding(
        padding: EdgeInsets.all(isWide ? 32 : 20),
        child: isWide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  imagePreview(context),
                  const SizedBox(width: 32),
                  Expanded(child: summaryContent),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  imagePreview(context),
                  const SizedBox(height: 24),
                  summaryContent,
                ],
              ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // UI HELPERS - Componentes reutilizables
  // ═══════════════════════════════════════════════════════════════

  /// Construye un card genérico con título e ícono
  Widget _buildInfoCard({
    required BuildContext context,
    required String title,
    required Widget child,
    IconData? icon,
  }) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.25),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                ],
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  /// Construye una lista de items informativos con dividers
  Widget _buildInfoList(
      BuildContext context, List<Map<String, dynamic>> items) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        for (int index = 0; index < items.length; index++) ...[
          _buildInfoRow(
            context,
            label: items[index]['label'] as String,
            value: items[index]['value'] as String,
            icon: items[index]['icon'] as IconData?,
            valueColor: items[index]['valueColor'] as Color?,
            selectable: items[index]['selectable'] as bool? ?? false,
          ),
          if (index != items.length - 1)
            const Divider(height: 16, thickness: 0.4),
        ],
      ],
    );
  }

  /// Construye una fila informativa con label, valor e ícono opcional
  Widget _buildInfoRow(
    BuildContext context, {
    required String label,
    required String value,
    IconData? icon,
    Color? valueColor,
    bool selectable = false,
  }) {
    final theme = Theme.of(context);
    final displayValue = value.isNotEmpty ? value : 'No especificado';
    final textStyle = theme.textTheme.titleSmall?.copyWith(
      fontWeight: FontWeight.w600,
      height: 1.2,
      color: valueColor,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              selectable
                  ? SelectableText(displayValue, style: textStyle)
                  : Text(displayValue, style: textStyle),
            ],
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // UTILITY METHODS - Cálculos y helpers
  // ═══════════════════════════════════════════════════════════════

  /// Calcula el ancho de cada card en el grid responsivo
  double _calculateCardWidth(double availableWidth, int columns, double gap) {
    if (columns <= 1 || availableWidth <= 0) return availableWidth;

    final double totalSpacing = gap * (columns - 1);
    final double width = (availableWidth - totalSpacing) / columns;
    return width < 260 ? availableWidth : width;
  }

  // ═══════════════════════════════════════════════════════════════
  // UI BUILDERS - Chips y badges
  // ═══════════════════════════════════════════════════════════════

  /// Construye un chip de metadata (código, categoría, proveedor)
  Widget _buildMetaChip(
    BuildContext context, {
    required IconData icon,
    required String label,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  /// Construye un chip de estado (favorito, stock)
  Widget _buildStatusChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    bool filled = true,
  }) {
    final theme = Theme.of(context);
    final Color baseColor = filled ? color : color.withValues(alpha: 0.6);
    final background =
        filled ? baseColor.withValues(alpha: 0.18) : Colors.transparent;
    final borderColor =
        filled ? Colors.transparent : baseColor.withValues(alpha: 0.3);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: baseColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: baseColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// Construye una alerta de stock bajo o sin stock
  Widget _buildStockAlert(BuildContext context) {
    final product = _currentProduct;
    final theme = Theme.of(context);
    final isCritical = product.quantityStock <= 0;
    final alertColor = isCritical ? Colors.red : Colors.orange;
    final alertLabel = isCritical
        ? 'Producto sin stock disponible'
        : 'Stock bajo • Se recomienda reponer';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: alertColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: alertColor.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(
            isCritical ? Icons.error_outline : Icons.warning_amber_rounded,
            color: alertColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              alertLabel,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: alertColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Formulario de edición de producto con validación y estado local
class _ProductEditCatalogueView extends StatefulWidget {
  final ProductCatalogue product;
  final CatalogueProvider catalogueProvider;
  final String accountId;

  const _ProductEditCatalogueView({
    required this.product,
    required this.catalogueProvider,
    required this.accountId,
  });

  @override
  State<_ProductEditCatalogueView> createState() =>
      _ProductEditCatalogueViewState();
}

class _ProductEditCatalogueViewState extends State<_ProductEditCatalogueView> {
  // Form state
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;
  bool _stockEnabled = false;
  bool _favoriteEnabled = false;

  // Controllers
  late final TextEditingController _descriptionController;
  late final TextEditingController _salePriceController;
  late final TextEditingController _purchasePriceController;
  late final TextEditingController _quantityStockController;
  late final TextEditingController _alertStockController;
  late final TextEditingController _categoryController;
  late final TextEditingController _providerController;
  late final TextEditingController _markController;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _initializeState();
    _setupListeners();
  }

  /// Inicializa los controllers con valores del producto
  void _initializeControllers() {
    final product = widget.product;
    _descriptionController = TextEditingController(text: product.description);
    _salePriceController = TextEditingController(
      text: product.salePrice > 0 ? product.salePrice.toString() : '',
    );
    _purchasePriceController = TextEditingController(
      text: product.purchasePrice > 0 ? product.purchasePrice.toString() : '',
    );
    _quantityStockController = TextEditingController(
      text: product.quantityStock.toString(),
    );
    _alertStockController = TextEditingController(
      text: product.alertStock.toString(),
    );
    _categoryController = TextEditingController(text: product.nameCategory);
    _providerController = TextEditingController(text: product.nameProvider);
    _markController = TextEditingController(text: product.nameMark);
  }

  /// Inicializa el estado del formulario
  void _initializeState() {
    _stockEnabled = widget.product.stock;
    _favoriteEnabled = widget.product.favorite;
  }

  /// Configura listeners para recalcular beneficios
  void _setupListeners() {
    _salePriceController.addListener(() => setState(() {}));
    _purchasePriceController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _salePriceController.dispose();
    _purchasePriceController.dispose();
    _quantityStockController.dispose();
    _alertStockController.dispose();
    _categoryController.dispose();
    _providerController.dispose();
    _markController.dispose();
    super.dispose();
  }

  /// Valida y guarda los cambios del producto en Firebase
  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final updatedProduct = _buildUpdatedProduct();
      // Detectar si cambiaron los precios para actualizar el timestamp upgrade
      final pricesChanged = _havePricesChanged();
      await widget.catalogueProvider.addAndUpdateProductToCatalogue(
        updatedProduct,
        widget.accountId,
        shouldUpdateUpgrade: pricesChanged,
      );

      if (mounted) {
        _showSuccessMessage();
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) _showErrorMessage(e.toString());
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  /// Construye el producto actualizado con los valores del formulario
  ProductCatalogue _buildUpdatedProduct() {
    return widget.product.copyWith(
      description: widget.product.verified
          ? widget.product.description
          : _descriptionController.text.trim(),
      salePrice: _parsePriceFromController(_salePriceController),
      purchasePrice: _parsePriceFromController(_purchasePriceController),
      quantityStock: int.tryParse(_quantityStockController.text) ?? 0,
      alertStock: int.tryParse(_alertStockController.text) ?? 5,
      nameCategory: _categoryController.text.trim(),
      nameProvider: _providerController.text.trim(),
      nameMark: _markController.text.trim(),
      stock: _stockEnabled,
      favorite: _favoriteEnabled,
    );
  }

  /// Parsea el precio desde un controller limpiando formato
  double _parsePriceFromController(TextEditingController controller) {
    final cleanValue = controller.text.replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(cleanValue) ?? 0.0;
  }

  /// Verifica si los precios de compra o venta han cambiado
  bool _havePricesChanged() {
    final newSalePrice = _parsePriceFromController(_salePriceController);
    final newPurchasePrice = _parsePriceFromController(_purchasePriceController);
    return newSalePrice != widget.product.salePrice ||
        newPurchasePrice != widget.product.purchasePrice;
  }

  /// Muestra mensaje de éxito al guardar
  void _showSuccessMessage() {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('Producto actualizado correctamente'),
            ),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Muestra mensaje de error al guardar
  void _showErrorMessage(String error) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text('Error al guardar: $error'),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildForm(),
      floatingActionButton: _buildFab(),
    );
  }

  /// Construye el AppBar con indicador de carga
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Editar producto'),
      centerTitle: false,
      actions: [
        if (_isSaving)
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
      ],
    );
  }

  /// Construye el formulario completo con todas las secciones
  Widget _buildForm() {
    final colorScheme = Theme.of(context).colorScheme;
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildImageSection(),
                const SizedBox(height: 24),
                _buildBasicInfoSection(colorScheme),
                const SizedBox(height: 24),
                _buildPricingSection(),
                const SizedBox(height: 24),
                _buildInventorySection(colorScheme),
                const SizedBox(height: 24),
                _buildPreferencesSection(colorScheme),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Construye sección de imagen del producto
  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionHeader(
          context: context,
          title: 'Imagen del producto',
          icon: Icons.image_outlined,
        ),
        const SizedBox(height: 12),
        _buildCard(
          context: context,
          child: Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: ProductImage(
                imageUrl: widget.product.image,
                size: 75,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Construye sección de información básica (descripción y código)
  Widget _buildBasicInfoSection(ColorScheme colorScheme) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionHeader(
          context: context,
          title: 'Información básica',
          icon: Icons.info_outline,
        ),
        const SizedBox(height: 12),
        Column(
          children: [
            // Marca del producto
            if (widget.product.nameMark.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: widget.product.verified
                        ? Colors.blue.withValues(alpha: 0.3)
                        : colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      widget.product.verified
                          ? Icons.verified
                          : Icons.branding_watermark,
                      color: widget.product.verified
                          ? Colors.blue
                          : colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Marca',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: widget.product.verified
                                  ? Colors.blue.withValues(alpha: 0.8)
                                  : colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.product.nameMark,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: widget.product.verified
                                  ? Colors.blue
                                  : colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (widget.product.verified)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Verificado',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Campo de descripción (solo lectura)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Descripción',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.product.description.isNotEmpty
                          ? widget.product.description
                          : 'Producto sin nombre',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),
            ] else ...[
              // Campo de descripción (editable)
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Descripción del producto *',
                  hintText: 'Ej: Coca Cola 2L',
                  prefixIcon: const Icon(Icons.description_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                maxLength: 100,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'La descripción es requerida';
                  }
                  return null;
                },
              ),
            ],
            const SizedBox(height: 16),
            // Campo de código de barras (solo lectura)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.qr_code_2,
                    color: colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Código de barras',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.product.code.isNotEmpty
                              ? widget.product.code
                              : 'Sin código',
                          style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              fontFamily: 'monospace',
                              fontSize: 18),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Construye sección de precios con preview de beneficio
  Widget _buildPricingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionHeader(
          context: context,
          title: 'Precios y márgenes',
          icon: Icons.attach_money,
        ),
        const SizedBox(height: 12),
        _buildSalePriceField(),
        const SizedBox(height: 16),
        _buildPurchasePriceField(),
        if (_salePriceController.text.isNotEmpty &&
            _purchasePriceController.text.isNotEmpty)
          _buildProfitPreview(),
      ],
    );
  }

  /// Campo de precio de venta con validación
  Widget _buildSalePriceField() {
    return TextFormField(
      controller: _salePriceController,
      decoration: InputDecoration(
        labelText: 'Precio de venta *',
        hintText: '0.00',
        prefixIcon: const Icon(Icons.trending_up),
        prefixText: '\$ ',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [AppMoneyInputFormatter(symbol: '')],
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'El precio de venta es requerido';
        }
        final price = _parsePriceFromController(_salePriceController);
        if (price <= 0) return 'Ingrese un precio válido mayor a 0';
        return null;
      },
    );
  }

  /// Campo de precio de compra
  Widget _buildPurchasePriceField() {
    return TextFormField(
      controller: _purchasePriceController,
      decoration: InputDecoration(
        labelText: 'Precio de compra',
        hintText: '0.00',
        prefixIcon: const Icon(Icons.shopping_basket_outlined),
        prefixText: '\$ ',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [AppMoneyInputFormatter(symbol: '')],
    );
  }

  /// Construye sección de inventario y control de stock
  Widget _buildInventorySection(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionHeader(
          context: context,
          title: 'Inventario y stock',
          icon: Icons.inventory_2_outlined,
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.3),
            ),
          ),
          child: SwitchListTile(
            value: _stockEnabled,
            onChanged: (value) => setState(() => _stockEnabled = value),
            title: const Text('Control de stock'),
            subtitle: const Text('Activa para rastrear cantidad disponible'),
            secondary: Icon(
              _stockEnabled ? Icons.inventory : Icons.inventory_outlined,
              color: _stockEnabled ? colorScheme.primary : null,
            ),
          ),
        ),
        if (_stockEnabled) ...[
          const SizedBox(height: 16),
          _buildQuantityField(),
          const SizedBox(height: 16),
          _buildAlertStockField(),
        ],
      ],
    );
  }

  /// Campo de cantidad en stock con validación
  Widget _buildQuantityField() {
    return TextFormField(
      controller: _quantityStockController,
      decoration: InputDecoration(
        labelText: 'Cantidad disponible',
        hintText: '0',
        prefixIcon: const Icon(Icons.numbers),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      keyboardType: TextInputType.number,
      validator: _stockEnabled
          ? (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Ingrese la cantidad';
              }
              final qty = int.tryParse(value);
              if (qty == null || qty < 0) return 'Ingrese una cantidad válida';
              return null;
            }
          : null,
    );
  }

  /// Campo de alerta de stock bajo
  Widget _buildAlertStockField() {
    return TextFormField(
      controller: _alertStockController,
      decoration: InputDecoration(
        labelText: 'Alerta de stock bajo',
        hintText: '5',
        prefixIcon: const Icon(Icons.notification_important_outlined),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        helperText: 'Se mostrará una alerta cuando el stock esté en este nivel',
      ),
      keyboardType: TextInputType.number,
    );
  }

  /// Construye sección de preferencias (categoría, proveedor, marca, favorito)
  Widget _buildPreferencesSection(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionHeader(
          context: context,
          title: 'Preferencias',
          icon: Icons.tune,
        ),
        const SizedBox(height: 20),
        _buildCategoryField(),
        const SizedBox(height: 16),
        _buildProviderField(),
        const SizedBox(height: 16),
        _buildMarkField(),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.3),
            ),
          ),
          child: SwitchListTile(
            value: _favoriteEnabled,
            onChanged: (value) => setState(() => _favoriteEnabled = value),
            title: const Text('Producto favorito'),
            subtitle: const Text('Marca como favorito para acceso rápido'),
            secondary: Icon(
              _favoriteEnabled ? Icons.star : Icons.star_border,
              color: _favoriteEnabled ? Colors.amber.shade600 : null,
            ),
          ),
        ),
      ],
    );
  }

  /// Campo de categoría
  Widget _buildCategoryField() {
    return TextFormField(
      controller: _categoryController,
      decoration: InputDecoration(
        labelText: 'Categoría',
        hintText: 'Ej: Bebidas',
        prefixIcon: const Icon(Icons.category_outlined),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  /// Campo de proveedor
  Widget _buildProviderField() {
    return TextFormField(
      controller: _providerController,
      decoration: InputDecoration(
        labelText: 'Proveedor',
        hintText: 'Ej: Coca Cola Company',
        prefixIcon: const Icon(Icons.local_shipping_outlined),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  /// Campo de marca
  Widget _buildMarkField() {
    return TextFormField(
      controller: _markController,
      decoration: InputDecoration(
        labelText: 'Marca',
        hintText: 'Ej: Coca Cola',
        prefixIcon: const Icon(Icons.branding_watermark),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  /// Botón flotante de guardar
  Widget? _buildFab() {
    if (_isSaving) return null;
    return FloatingActionButton.extended(
      onPressed: _saveProduct,
      label: const Text('Guardar'),
    );
  }

  /// Encabezado de sección con ícono y título
  Widget _buildSectionHeader({
    required BuildContext context,
    required String title,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }

  /// Tarjeta contenedora con bordes redondeados
  Widget _buildCard({
    required BuildContext context,
    required Widget child,
  }) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context)
              .colorScheme
              .outlineVariant
              .withValues(alpha: 0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: child,
      ),
    );
  }

  /// Calcula el beneficio y porcentaje de ganancia
  ({double profit, double percentage, bool isProfitable})? _calculateProfit() {
    final salePrice = _parsePriceFromController(_salePriceController);
    final purchasePrice = _parsePriceFromController(_purchasePriceController);

    if (salePrice <= 0 || purchasePrice <= 0) return null;

    final profit = salePrice - purchasePrice;
    final percentage = (profit / purchasePrice) * 100;

    return (
      profit: profit,
      percentage: percentage,
      isProfitable: profit > 0,
    );
  }

  /// Preview del beneficio calculado con indicadores visuales
  Widget _buildProfitPreview() {
    final calculation = _calculateProfit();
    if (calculation == null) return const SizedBox.shrink();

    final profit = calculation.profit;
    final percentage = calculation.percentage;
    final isProfitable = calculation.isProfitable;

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isProfitable
            ? Colors.green.withValues(alpha: 0.08)
            : Colors.red.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isProfitable
              ? Colors.green.withValues(alpha: 0.3)
              : Colors.red.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isProfitable ? Icons.trending_up : Icons.trending_down,
            color: isProfitable ? Colors.green.shade700 : Colors.red.shade700,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isProfitable ? 'Beneficio estimado' : 'Pérdida estimada',
                  style: TextStyle(
                    fontSize: 12,
                    color: isProfitable
                        ? Colors.green.shade700
                        : Colors.red.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  CurrencyFormatter.formatPrice(value: profit.abs()),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isProfitable
                        ? Colors.green.shade700
                        : Colors.red.shade700,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isProfitable ? Colors.green : Colors.red,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${isProfitable ? '+' : ''}${percentage.toStringAsFixed(1)}%',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
