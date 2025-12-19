import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sellweb/core/core.dart';
import 'package:sellweb/features/catalogue/domain/entities/product_catalogue.dart';

import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../providers/catalogue_provider.dart';
import 'package:sellweb/features/sales/presentation/providers/sales_provider.dart';
import 'package:sellweb/core/presentation/widgets/navigation/drawer.dart';
import 'package:sellweb/core/presentation/widgets/connectivity_indicator.dart';
import '../views/product_catalogue_view.dart';
import '../views/product_edit_catalogue_view.dart';
import '../widgets/catalogue_metrics_bar.dart';
import '../views/search_product_full_screen_view.dart';
import 'package:sellweb/features/catalogue/domain/entities/category.dart';
import 'package:sellweb/features/catalogue/domain/entities/provider.dart' as catalogue_provider_entity;
import '../views/dialogs/category_dialog.dart';
import '../views/dialogs/provider_dialog.dart';

/// Página dedicada para gestionar el catálogo de productos
/// Separada de la lógica de ventas para mejor organización
class CataloguePage extends StatefulWidget {
  const CataloguePage({super.key});

  @override
  State<CataloguePage> createState() => _CataloguePageState();
}

class _CataloguePageState extends State<CataloguePage>
    with SingleTickerProviderStateMixin {
  bool _isGridView = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      // Limpiar búsqueda y filtros cuando cambia de tab
      final catalogueProvider =
          Provider.of<CatalogueProvider>(context, listen: false);
      catalogueProvider.clearSearchResults();
      catalogueProvider.clearCategoryProviderFilter();
      _searchController.clear();
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
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
    return CustomAppBar(
      automaticallyImplyLeading: false,
      titleWidget: Row(
        children: [
          // Avatar y botón de drawer - usa Selector para escuchar cambios de cuenta
          Selector<SalesProvider, ({String image, String name})>(
            selector: (_, provider) => (
              image: provider.profileAccountSelected.image,
              name: provider.profileAccountSelected.name,
            ),
            builder: (context, accountData, _) => GestureDetector(
              onTap: () => Scaffold.of(context).openDrawer(),
              child: UserAvatar(
                imageUrl: accountData.image,
                text: accountData.name,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Campo de búsqueda
          Expanded(
            child: Consumer<CatalogueProvider>(
              builder: (context, catalogueProvider, _) {
                // Mostrar el nombre del filtro activo (categoría o proveedor)
                final activeFilterName =
                    catalogueProvider.selectedCategoryName ??
                        catalogueProvider.selectedProviderName;
                final hasActiveEntityFilter =
                    catalogueProvider.hasCategoryFilter ||
                        catalogueProvider.hasProviderFilter;

                // Si hay filtro de categoría/proveedor, actualizar el controller
                if (hasActiveEntityFilter &&
                    activeFilterName != null &&
                    _searchController.text != activeFilterName) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _searchController.text = activeFilterName;
                  });
                }

                return ProductSearchField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  hintText: 'Buscar producto',
                  products: catalogueProvider.products,
                  searchResultsCount: (catalogueProvider.isFiltering)
                      ? catalogueProvider.visibleProducts.length
                      : null,
                  onChanged: (query) {
                    // Si el usuario escribe, limpiar filtros de categoría/proveedor
                    if (catalogueProvider.hasCategoryFilter ||
                        catalogueProvider.hasProviderFilter) {
                      catalogueProvider.clearCategoryProviderFilter();
                    }
                    // Buscar productos según el query con debouncing
                    catalogueProvider.searchProductsWithDebounce(query: query);
                  },
                  onClear: () {
                    // Limpiar todos los filtros
                    catalogueProvider.clearAllFilters();
                  },
                );
              },
            ),
          ),
          const SizedBox(width: 12),
          // Indicador de conectividad
          const ConnectivityIndicator(),
          // Filtros
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
      bottom: TabBar(
        controller: _tabController,
        tabs: const [
          Tab(text: 'Productos'),
          Tab(text: 'Categorías'),
          Tab(text: 'Proveedores'),
        ],
      ),
    );
  }

  /// Construye el cuerpo de la página con TabBarView
  Widget _buildBody(BuildContext context) {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildProductsTab(),
        _buildCategoriesTab(),
        _buildProvidersTab(),
      ],
    );
  }

  /// Tab de productos
  Widget _buildProductsTab() {
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

        // Si no hay productos para mostrar, devolver directamente el estado vacío
        // sin la barra de métricas
        if (displayProducts.isEmpty) {
          return _buildProductsContent(
            context,
            displayProducts,
            hasSearch,
            hasFilter,
            catalogueProvider.activeFilter,
          );
        }

        // Lista de productos con métricas
        return Column(
          children: [
            // Barra de métricas (se ajusta según el filtro)
            CatalogueMetricsBar(
              metrics: catalogueProvider.catalogueMetrics,
            ),
            // Contenido principal (Lista)
            Expanded(
              child: _buildProductsContent(
                context,
                displayProducts,
                hasSearch,
                hasFilter,
                catalogueProvider.activeFilter,
              ),
            ),
          ],
        );
      },
    );
  }

  /// Construye el contenido de la lista de productos o el estado vacío
  Widget _buildProductsContent(
    BuildContext context,
    List<ProductCatalogue> displayProducts,
    bool hasSearch,
    bool hasFilter,
    CatalogueFilter activeFilter,
  ) {
    if (displayProducts.isEmpty) {
      if (hasSearch) {
        return _buildNoResultsState(context);
      }
      if (hasFilter) {
        return _buildFilteredEmptyState(context, activeFilter);
      }
      return _buildEmptyState(context);
    }

    return _isGridView
        ? _buildGridView(displayProducts)
        : _buildListView(displayProducts);
  }

  /// Tab de categorías
  Widget _buildCategoriesTab() {
    final catalogueProvider =
        Provider.of<CatalogueProvider>(context, listen: false);
    final salesProvider = Provider.of<SalesProvider>(context, listen: false);

    return CategoriesListView(
      accountId: salesProvider.profileAccountSelected.id,
      onCategoryTap: (categoryId, categoryName) {
        // Mostrar el nombre de la categoría en el buscador
        _searchController.text = categoryName;
        // Cambiar al tab de productos y filtrar
        _tabController.animateTo(0);
        catalogueProvider.filterByCategory(categoryId);
      },
    );
  }

  /// Tab de proveedores
  Widget _buildProvidersTab() {
    final catalogueProvider =
        Provider.of<CatalogueProvider>(context, listen: false);
    final salesProvider = Provider.of<SalesProvider>(context, listen: false);

    return ProvidersListView(
      accountId: salesProvider.profileAccountSelected.id,
      onProviderTap: (providerId, providerName) {
        // Mostrar el nombre del proveedor en el buscador
        _searchController.text = providerName;
        // Cambiar al tab de productos y filtrar
        _tabController.animateTo(0);
        catalogueProvider.filterByProvider(providerId);
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

  /// Botón flotante para agregar productos/categorías/proveedores
  Widget _buildFloatingActionButton(BuildContext context) {
    final catalogueProvider =
        Provider.of<CatalogueProvider>(context, listen: false);
    final salesProvider = Provider.of<SalesProvider>(context, listen: false);
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return isSmallScreen
        ? FloatingActionButton(
            heroTag: 'catalogue_add_fab',
            onPressed: () =>
                _handleFabAction(context, catalogueProvider, salesProvider),
            child: const Icon(Icons.add),
          )
        : FloatingActionButton.extended(
            heroTag: 'catalogue_add_fab',
            onPressed: () =>
                _handleFabAction(context, catalogueProvider, salesProvider),
            icon: const Icon(Icons.add),
            label: Text(_getFabLabel()),
          );
  }

  /// Maneja la acción del FAB según la vista activa
  void _handleFabAction(
    BuildContext context,
    CatalogueProvider catalogueProvider,
    SalesProvider salesProvider,
  ) {
    final currentTab = _tabController.index;

    switch (currentTab) {
      case 0: // Tab de Productos
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ProductSearchFullScreenView(
              catalogueProvider: catalogueProvider,
              salesProvider: salesProvider,
            ),
          ),
        );
        break;
      case 1: // Tab de Categorías
        showCategoryDialog(
          context,
          catalogueProvider: catalogueProvider,
          accountId: salesProvider.profileAccountSelected.id,
        );
        break;
      case 2: // Tab de Proveedores
        showProviderDialog(
          context,
          catalogueProvider: catalogueProvider,
          accountId: salesProvider.profileAccountSelected.id,
        );
        break;
    }
  }

  /// Obtiene la etiqueta del FAB según la vista activa
  String _getFabLabel() {
    switch (_tabController.index) {
      case 0:
        return 'Agregar';
      case 1:
        return 'Categoría';
      case 2:
        return 'Proveedor';
      default:
        return 'Agregar';
    }
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
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: ProductImage(
                imageUrl: product.image,
                size: 80,
                fit: BoxFit.cover,
                productDescription: product.description,
              ),
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
                  if (product.isVerified)
                    Icon(
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
            // Fecha de actualización
            Text(
              DateFormatter.getSimplePublicationDate(product.lastUpdateDate, DateTime.now()),
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontSize: 10,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
      // Precio y ganancia en el lado derecho
      Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          // Precio
          Text(
            CurrencyFormatter.formatPrice(value: product.salePrice),
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
              fontSize: 24,
            ),
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
                    product.description,
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
                    Icon(
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
                      product.nameCategory,
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
            if (product.category.isNotEmpty) const SizedBox(height: 6),
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
                      product.nameProvider,
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
            if (product.nameProvider.isNotEmpty) const SizedBox(height: 6),
            // Stock
            if (product.stock)
              _buildStockIndicator(
                context: context,
                quantityStock: product.quantityStock,
                alertStock: product.alertStock,
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
            Text(
              CurrencyFormatter.formatPrice(value: product.salePrice),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
                fontSize: 24,
              ),
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
                    productDescription: product.description,
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
                        if (product.isVerified)
                          Icon(
                            Icons.verified,
                            size: 12,
                            color: Colors.blue,
                          ),
                        if (product.isVerified) const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            product.nameMark,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: product.isVerified
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

/// Vista de listado de categorías
class CategoriesListView extends StatefulWidget {
  final String accountId;
  final Function(String categoryId, String categoryName)? onCategoryTap;

  const CategoriesListView({
    super.key,
    required this.accountId,
    this.onCategoryTap,
  });

  @override
  State<CategoriesListView> createState() => _CategoriesListViewState();
}
class _CategoriesListViewState extends State<CategoriesListView> {
  @override
  Widget build(BuildContext context) {
    return Consumer<CatalogueProvider>(
      builder: (context, catalogueProvider, _) {
        final categories = catalogueProvider.categories;

        if (catalogueProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (categories.isEmpty) {
          return _buildEmptyState(context);
        }

        return Stack(
          children: [
            ListView.separated(
              padding: const EdgeInsets.only(bottom: 80),
              itemCount: categories.length,
              separatorBuilder: (context, index) =>
                  const Divider(height: 0, thickness: 0.4),
              itemBuilder: (context, index) {
                final category = categories[index];
                return _buildCategoryTile(
                  category: category,
                  onTap: () {
                    if (widget.onCategoryTap != null) {
                      widget.onCategoryTap!(category.id, category.name);
                    }
                  },
                  onEdit: () => _showEditDialog(context, category),
                );
              },
            ),
            Positioned(
              bottom: 16,
              right: 16,
              child: FloatingActionButton(
                heroTag: 'categories_add_fab',
                onPressed: () => _showAddDialog(context),
                child: const Icon(Icons.add),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showAddDialog(BuildContext context) {
    final catalogueProvider =
        Provider.of<CatalogueProvider>(context, listen: false);

    showCategoryDialog(
      context,
      catalogueProvider: catalogueProvider,
      accountId: widget.accountId,
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.category_outlined,
            size: 80,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No hay categorías',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Agrega tu primera categoría',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, Category category) {
    final catalogueProvider =
        Provider.of<CatalogueProvider>(context, listen: false);

    showCategoryDialog(
      context,
      catalogueProvider: catalogueProvider,
      accountId: widget.accountId,
      category: category,
    );
  }

  Widget _buildCategoryTile({
    required Category category,
    VoidCallback? onTap,
    VoidCallback? onEdit,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Generar avatar con 2 primeros caracteres
    final avatarText = category.name.length >= 2
        ? category.name.substring(0, 2).toUpperCase()
        : category.name.toUpperCase();

    return InkWell(
      onTap: onTap,
      onLongPress: onEdit,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Avatar con iniciales
            CircleAvatar(
              radius: 20,
              backgroundColor: colorScheme.primaryContainer,
              child: Text(
                avatarText,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Nombre
            Expanded(
              child: Text(
                category.name,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Vista de listado de proveedores
class ProvidersListView extends StatefulWidget {
  final String accountId;
  final Function(String providerId, String providerName)? onProviderTap;

  const ProvidersListView({
    super.key,
    required this.accountId,
    this.onProviderTap,
  });

  @override
  State<ProvidersListView> createState() => _ProvidersListViewState();
}
class _ProvidersListViewState extends State<ProvidersListView> {
  @override
  Widget build(BuildContext context) {
    return Consumer<CatalogueProvider>(
      builder: (context, catalogueProvider, _) {
        final providers = catalogueProvider.providers;

        if (catalogueProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (providers.isEmpty) {
          return _buildEmptyState(context);
        }

        return Stack(
          children: [
            ListView.separated(
              padding: const EdgeInsets.only(bottom: 80),
              itemCount: providers.length,
              separatorBuilder: (context, index) =>
                  const Divider(height: 0, thickness: 0.4),
              itemBuilder: (context, index) {
                final provider = providers[index];
                return _buildProviderTile(
                  provider: provider,
                  onTap: () {
                    if (widget.onProviderTap != null) {
                      widget.onProviderTap!(provider.id, provider.name);
                    }
                  },
                  onEdit: () => _showEditDialog(context, provider),
                );
              },
            ),
            Positioned(
              bottom: 16,
              right: 16,
              child: FloatingActionButton(
                heroTag: 'providers_add_fab',
                onPressed: () => _showAddDialog(context),
                child: const Icon(Icons.add),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showAddDialog(BuildContext context) {
    final catalogueProvider =
        Provider.of<CatalogueProvider>(context, listen: false);

    showProviderDialog(
      context,
      catalogueProvider: catalogueProvider,
      accountId: widget.accountId,
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.local_shipping_outlined,
            size: 80,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No hay proveedores',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Agrega tu primer proveedor',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(
      BuildContext context, catalogue_provider_entity.Provider provider) {
    final catalogueProvider =
        Provider.of<CatalogueProvider>(context, listen: false);

    showProviderDialog(
      context,
      catalogueProvider: catalogueProvider,
      accountId: widget.accountId,
      provider: provider,
    );
  }

  Widget _buildProviderTile({
    required catalogue_provider_entity.Provider provider,
    VoidCallback? onTap,
    VoidCallback? onEdit,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Generar avatar con 2 primeros caracteres
    final avatarText = provider.name.length >= 2
        ? provider.name.substring(0, 2).toUpperCase()
        : provider.name.toUpperCase();

    return InkWell(
      onTap: onTap,
      onLongPress: onEdit,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Avatar con iniciales
            CircleAvatar(
              radius: 20,
              backgroundColor: colorScheme.secondaryContainer,
              child: Text(
                avatarText,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: colorScheme.onSecondaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Información del proveedor
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    provider.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (provider.phone != null || provider.email != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      [provider.phone, provider.email]
                          .where((e) => e != null && e.isNotEmpty)
                          .join(' • '),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
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
}
