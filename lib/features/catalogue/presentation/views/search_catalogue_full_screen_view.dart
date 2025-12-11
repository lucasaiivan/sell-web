import 'package:sellweb/core/core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Core imports
import 'package:sellweb/features/catalogue/data/datasources/local_search_datasource.dart';

// Domain imports
import 'package:sellweb/features/catalogue/domain/entities/product_catalogue.dart';

// Presentation imports
import 'package:sellweb/features/catalogue/presentation/providers/catalogue_provider.dart';
import 'package:sellweb/features/sales/presentation/providers/sales_provider.dart';

/// Vista de pantalla completa para el catálogo de productos con búsqueda avanzada.
///
/// Implementa NestedScrollView con SliverAppBar optimizado siguiendo las mejores prácticas:
/// - `floatHeaderSlivers: true` para mejor coordinación de scroll entre header y body
/// - `SliverOverlapAbsorber` y `SliverOverlapInjector` para manejo de overlaps
/// - AppBar flotante/pinned/snap basado en el estado de búsqueda
/// - Animaciones suaves y transiciones optimizadas
/// - Soporte para refresh y stretch en iOS
///
/// Permite buscar y seleccionar productos del catálogo para agregar al ticket de venta.
/// Incluye algoritmo de búsqueda inteligente y filtrado en tiempo real.
class ProductCatalogueFullScreenView extends StatefulWidget {
  const ProductCatalogueFullScreenView({
    super.key,
    required this.products,
    required this.sellProvider,
  });

  final List<ProductCatalogue> products;
  final SalesProvider sellProvider;

  @override
  State<ProductCatalogueFullScreenView> createState() =>
      _ProductCatalogueFullScreenViewState();
}

class _ProductCatalogueFullScreenViewState
    extends State<ProductCatalogueFullScreenView> {
  late TextEditingController _searchController;
  late FocusNode _searchFocusNode;

  List<ProductCatalogue> _filteredProducts = [];
  bool _isGridView = false; // Estado para controlar vista lista/cuadrícula

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchFocusNode = FocusNode();
    _filteredProducts = widget.products;

    // Listener para cambios en el texto de búsqueda
    _searchController.addListener(_onSearchChanged);
    _searchFocusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchFocusNode.removeListener(_onFocusChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  /// Método que se llama cuando cambia el texto de búsqueda.
  /// Utiliza el algoritmo avanzado de búsqueda para filtrar productos.
  void _onSearchChanged() {
    final query = _searchController.text.trim();

    setState(() {
      if (query.isEmpty) {
        _filteredProducts = widget.products;
      } else {
        try {
          // Usar el algoritmo avanzado de búsqueda
          final catalogueProvider =
              Provider.of<CatalogueProvider>(context, listen: false);

          // Usar productos directos si el provider no tiene productos
          _filteredProducts = catalogueProvider.searchProducts(
            query: query,
            maxResults: 50, // Limitar a 50 resultados para mejor rendimiento
          );

          // Si el provider no tiene productos, usar búsqueda directa con el algoritmo
          if (_filteredProducts.isEmpty &&
              catalogueProvider.products.isEmpty &&
              widget.products.isNotEmpty) {
            _filteredProducts = LocalSearchDataSource.searchProducts(
              products: widget.products,
              query: query,
              maxResults: 50,
            );
          }

          // Si no hay resultados con el algoritmo avanzado, usar búsqueda simple como fallback
          if (_filteredProducts.isEmpty) {
            _filteredProducts = widget.products.where((product) {
              final queryLower = query.toLowerCase();
              return product.description.toLowerCase().contains(queryLower) ||
                  product.nameMark.toLowerCase().contains(queryLower) ||
                  product.code.toLowerCase().contains(queryLower);
            }).toList();
          }
        } catch (e) {
          // Fallback a búsqueda simple
          _filteredProducts = widget.products.where((product) {
            final queryLower = query.toLowerCase();
            return product.description.toLowerCase().contains(queryLower) ||
                product.nameMark.toLowerCase().contains(queryLower) ||
                product.code.toLowerCase().contains(queryLower);
          }).toList();
        }
      }
    });
  }

  void _onFocusChanged() {
    // Solo cambiar a modo búsqueda si hay texto escrito
    // El foco por sí solo no debe cambiar la vista
  }

  /// Obtiene la cantidad total de productos seleccionados en el ticket (suma de cantidades)
  int _getSelectedProductsCount() {
    return widget.sellProvider.ticket.products
        .where((product) => product.quantity > 0)
        .fold(0, (total, product) => total + product.quantity);
  }

  /// Disminuye la cantidad de un producto en el ticket o lo elimina si la cantidad llega a 0
  void _decreaseProductQuantity(ProductCatalogue product) {
    final ticketProducts = widget.sellProvider.ticket.products;

    // Buscar el producto en el ticket
    final productIndex = ticketProducts.indexWhere((p) => p.id == product.id);

    if (productIndex != -1) {
      final currentProduct = ticketProducts[productIndex];

      if (currentProduct.quantity > 1) {
        // Si tiene más de 1, agregar con cantidad -1 (disminuye en 1)
        final decreasedProduct =
            currentProduct.copyWith(quantity: currentProduct.quantity - 1);
        widget.sellProvider
            .addProductsticket(decreasedProduct, replaceQuantity: true);
      } else {
        // Si tiene 1 o menos, remover completamente del ticket
        widget.sellProvider.removeProduct(currentProduct);
      }
    }
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _filteredProducts = widget.products;
    });
    // Mantener el foco en el campo de búsqueda
    _searchFocusNode.requestFocus();
  }

  /// Construye el estado vacío como sliver para mejor integración con NestedScrollView
  /// Construye la lista de productos como sliver optimizado para NestedScrollView
  Widget _buildProductListAsSliver() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_filteredProducts.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off_rounded,
                size: 48,
                color: colorScheme.onSurface.withValues(alpha: 0.4),
              ),
              const SizedBox(height: 16),
              Text(
                _searchController.text.isEmpty
                    ? 'No hay productos disponibles'
                    : 'Sin resultados',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              if (_searchController.text.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Prueba con otros términos de búsqueda',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    // Elegir entre vista de lista o cuadrícula basado en el estado
    if (_isGridView) {
      return _buildProductGridAsSliver();
    } else {
      return _buildProductListSliver();
    }
  }

  /// Construye la vista de lista tradicional con SliverList
  Widget _buildProductListSliver() {
    return SliverList.separated(
      itemCount: _filteredProducts.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final product = _filteredProducts[index];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: _buildProductListItem(product),
        );
      },
    );
  }

  /// Construye la vista de cuadrícula con SliverGrid
  Widget _buildProductGridAsSliver() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: _getCrossAxisCount(),
          childAspectRatio: 1.0, // Relación 1:1 para items cuadrados
          crossAxisSpacing: 2,
          mainAxisSpacing: 2,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final product = _filteredProducts[index];
            return _buildProductGridItem(product);
          },
          childCount: _filteredProducts.length,
        ),
      ),
    );
  }

  /// Determina el número de columnas basado en el ancho de pantalla y tamaño óptimo de items
  int _getCrossAxisCount() {
    final width = MediaQuery.of(context).size.width;

    // Tamaño mínimo deseado para cada item (ancho)
    const double minItemWidth = 160.0;

    // Padding horizontal total (16px cada lado) + espaciado entre items
    const double horizontalPadding = 32.0;
    const double itemSpacing = 12.0;

    // Calcular el ancho disponible para items
    final availableWidth = width - horizontalPadding;

    // Calcular número de columnas que caben con el tamaño mínimo
    int columns = (availableWidth / (minItemWidth + itemSpacing)).floor();

    // Aplicar límites según el tipo de dispositivo
    if (width > 1200) {
      // Desktop grande: máximo 6 columnas, mínimo 4
      columns = columns.clamp(4, 6);
    } else if (width > 900) {
      // Desktop/tablet grande: máximo 5 columnas, mínimo 3
      columns = columns.clamp(3, 5);
    } else if (width > 600) {
      // Tablet: máximo 4 columnas, mínimo 3
      columns = columns.clamp(3, 4);
    } else if (width > 480) {
      // Móvil grande: máximo 4 columnas, mínimo 3
      columns = columns.clamp(3, 4);
    } else {
      // Móvil pequeño: máximo 3 columnas, mínimo 3
      columns = columns.clamp(3, 3);
    }

    // Asegurar que nunca sea menor a 3
    return columns.clamp(3, 6);
  }

  /// Construye un item de producto optimizado para la vista de cuadrícula
  Widget _buildProductGridItem(ProductCatalogue product) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Verificar si el producto está en el ticket
    final ticketProducts = widget.sellProvider.ticket.products;
    ProductCatalogue? selectedProduct;
    try {
      selectedProduct = ticketProducts
          .firstWhere((p) => p.id == product.id && p.quantity > 0);
    } catch (_) {
      selectedProduct = null;
    }

    return AnimatedScale(
        scale: selectedProduct != null ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOutCubic,
        child: Card(
          color: Colors.white,
          elevation: selectedProduct != null ? 4 : 2,
          shadowColor: selectedProduct != null
              ? colorScheme.primary.withValues(alpha: 0.3)
              : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
            side: selectedProduct != null
                ? BorderSide(
                    color: colorScheme.primary,
                    width: 2,
                  )
                : BorderSide.none,
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              // Layout principal del producto
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Imagen del producto que ocupa la mayor parte
                  Expanded(
                    flex: 2,
                    child: ProductImage(
                      imageUrl: product.image,
                      fit: BoxFit.cover,
                    ),
                  ),
                  // Información del producto
                  _buildProductInfo(product, theme, colorScheme),
                ],
              ),
              // Área táctil para seleccionar el producto
              Positioned.fill(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      widget.sellProvider.addProductsticket(product.copyWith());
                      setState(() {}); // Actualizar la vista al seleccionar
                    },
                  ),
                ),
              ),
              // Contador de cantidad en la esquina superior derecha
              if (selectedProduct != null && selectedProduct.quantity > 1)
                Positioned(
                  top: 5,
                  right: 5,
                  child: CircleAvatar(
                    backgroundColor: Colors.black87,
                    child: Padding(
                      padding: const EdgeInsets.all(1.0),
                      child: CircleAvatar(
                        backgroundColor: Colors.white,
                        child: Text(
                          selectedProduct.quantity.toString(),
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              // Botón de disminuir cantidad cuando el producto está seleccionado
              if (selectedProduct != null)
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () {
                      _decreaseProductQuantity(product);
                      setState(() {});
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color:
                            colorScheme.errorContainer.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Icon(
                        Icons.remove,
                        size: 16,
                        color: colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ));
  }

  /// Construye la información del producto (descripción, marca, precio)
  Widget _buildProductInfo(
      ProductCatalogue product, ThemeData theme, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.all(6.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Descripción del producto
          Text(
            product.description,
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.normal,
              overflow: TextOverflow.ellipsis,
            ),
            maxLines: 1,
          ),
          // Marca del producto (si existe)
          if (product.nameMark.isNotEmpty) ...[
            Text(
              product.nameMark,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 10,
                color: product.isVerified ? Colors.blue : null,
                overflow: TextOverflow.ellipsis,
              ),
              maxLines: 1,
            ),
          ],
          // Precio del producto
          Text(
            CurrencyFormatter.formatPrice(value: product.salePrice),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 17.0,
              color: Colors.black,
            ),
            overflow: TextOverflow.clip,
            softWrap: false,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: NestedScrollView(
          // Habilitar floating headers para mejor comportamiento de coordinación de scroll
          floatHeaderSlivers: true,
          // Mejorar el comportamiento de scroll en móviles
          physics: const BouncingScrollPhysics(),
          headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
            return [
              // Primer SliverAppBar: Búsqueda y acciones (floating, desaparece al scroll)
              SliverAppBar(
                floating: true,
                snap: true,
                pinned: false,
                toolbarHeight: 64,
                backgroundColor: colorScheme.surface,
                surfaceTintColor: colorScheme.surface,
                elevation: 0,
                scrolledUnderElevation: 0,
                automaticallyImplyLeading: false,
                title: _buildSearchField(),
                leading: IconButton(
                  icon: Icon(
                    Icons.arrow_back_rounded,
                    color: colorScheme.onSurface,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: 'Volver',
                ),
                actions: [
                  // Botón toggle para cambiar vista lista/cuadrícula
                  AppBarButtonCircle(
                    icon: _isGridView
                        ? Icons.view_list_rounded
                        : Icons.grid_view_rounded,
                    onPressed: () {
                      setState(() {
                        _isGridView = !_isGridView;
                      });
                    },
                    tooltip:
                        _isGridView ? 'Vista de lista' : 'Vista de cuadrícula',
                  ),
                  const SizedBox(width: 8),
                  AppBarButtonCircle(
                    icon: Icons.close_rounded,
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Cerrar',
                  ),
                  const SizedBox(width: 16),
                ],
              ),
              // Segundo SliverAppBar: Chips de marcas (pinned, siempre visible)
              SliverOverlapAbsorber(
                handle:
                    NestedScrollView.sliverOverlapAbsorberHandleFor(context),
                sliver: SliverAppBar(
                  pinned: true,
                  toolbarHeight: 0,
                  collapsedHeight: 48,
                  expandedHeight: 48,
                  backgroundColor: colorScheme.surface,
                  surfaceTintColor: colorScheme.surface,
                  elevation: 0,
                  scrolledUnderElevation: innerBoxIsScrolled ? 1 : 0,
                  automaticallyImplyLeading: false,
                  flexibleSpace: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    alignment: Alignment.centerLeft,
                    child: _buildSuggestionChips(),
                  ),
                ),
              ),
            ];
          },
          body: Builder(
            builder: (BuildContext context) {
              return CustomScrollView(
                // Inyectar el overlap para mantener consistencia
                slivers: [
                  SliverOverlapInjector(
                      handle: NestedScrollView.sliverOverlapAbsorberHandleFor(
                          context)),
                  // Siempre mostrar la lista de productos (filtrados o todos)
                  _buildProductListAsSliver(),

                  // Espacio adicional para el FloatingActionButton
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 80),
                  ),
                ],
              );
            },
          ),
        ),
      ),
      floatingActionButton: AnimatedSlide(
        offset: Offset.zero, // Siempre visible
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
        child: AnimatedOpacity(
          opacity: 1.0, // Siempre visible
          duration: const Duration(milliseconds: 300),
          child: _getSelectedProductsCount() > 0
              ? Badge(
                  label: Text(
                    '${_getSelectedProductsCount()}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  backgroundColor: colorScheme.tertiary,
                  textColor: colorScheme.onTertiary,
                  largeSize: 24,
                  offset: const Offset(4, -4),
                  child: FloatingActionButton.extended(
                    heroTag: "product_catalogue_fab",
                    onPressed: () => Navigator.of(context).pop(),
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    elevation: 4,
                    highlightElevation: 8,
                    label: const Text(
                      'Continuar',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                )
              : FloatingActionButton.extended(
                  heroTag: "product_catalogue_fab",
                  onPressed: () => Navigator.of(context).pop(),
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  elevation: 4,
                  highlightElevation: 8,
                  label: const Text(
                    'Continuar',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return ProductSearchField(
      controller: _searchController,
      focusNode: _searchFocusNode,
      hintText: 'Buscar por nombre, marca, código...',
      autofocus: true,
      products: widget.products, // Pasar productos para las sugerencias
      onChanged: (query) {
        // El método _onSearchChanged ya maneja la lógica de filtrado
        _onSearchChanged();
      },
      onClear: _clearSearch,
    );
  }

  /// Construye los chips de sugerencias con las marcas disponibles en el catálogo
  /// Calcula dinámicamente cuántos chips caben en la primera línea según el ancho de pantalla
  Widget _buildSuggestionChips() {
    // Obtener marcas únicas de los productos
    final Set<String> uniqueBrands = widget.products
        .where((product) => product.nameMark.isNotEmpty)
        .map((product) => product.nameMark.trim())
        .toSet();

    // Convertir a lista y ordenar alfabéticamente
    final List<String> sortedBrands = uniqueBrands.toList()..sort();

    // Si no hay marcas, no mostrar nada
    if (sortedBrands.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;

        // Calcular cuántos chips caben en la primera línea
        final chipSpacing = 8.0;
        final horizontalPadding = 32.0; // 16px de cada lado
        final availableWidth = constraints.maxWidth - horizontalPadding;

        // Estimar ancho promedio de un chip (incluye padding, texto y bordes)
        final estimatedChipWidth = _estimateChipWidth(theme);
        final maxChipsPerLine = ((availableWidth + chipSpacing) /
                (estimatedChipWidth + chipSpacing))
            .floor();

        // Asegurar al menos 2 chips y máximo la cantidad que cabe
        final int totalBrands = sortedBrands.length;
        final int minVisible = totalBrands < 2 ? totalBrands : 2;
        final maxVisibleBrands =
            (maxChipsPerLine - 1).clamp(minVisible, totalBrands);

        // Lista de marcas que se mostrarán
        final List<String> visibleBrands =
            sortedBrands.take(maxVisibleBrands).toList();
        final bool hasMoreBrands = sortedBrands.length > maxVisibleBrands;

        return Wrap(
          spacing: chipSpacing,
          runSpacing: 6,
          children: [
            // Chips de marcas visibles (llenan la primera línea)
            ...visibleBrands.map((brand) {
              return ActionChip(
                label: Text(
                  brand,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onPressed: () {
                  // Agregar la marca al campo de búsqueda
                  _searchController.text = brand;
                  _onSearchChanged();
                  // Mantener el foco en el campo de búsqueda
                  _searchFocusNode.requestFocus();
                },
                backgroundColor:
                    colorScheme.secondaryContainer.withValues(alpha: 0.3),
                side: BorderSide(
                  color: colorScheme.outline.withValues(alpha: 0.2),
                  width: 0.5,
                ),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              );
            }),

            // Chip "Ver más" si hay más marcas (se ajusta al espacio restante)
            if (hasMoreBrands)
              ActionChip(
                label: Text(
                  'Ver más (+${sortedBrands.length - maxVisibleBrands})',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onPressed: () => _showAllBrandsDialog(sortedBrands),
                backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
                side: BorderSide(
                  color: colorScheme.primary.withValues(alpha: 0.3),
                  width: 1,
                ),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
                avatar: Icon(
                  Icons.expand_more,
                  size: 16,
                  color: colorScheme.primary,
                ),
              ),
          ],
        );
      },
    );
  }

  /// Estima el ancho promedio de un chip basado en el texto y estilo
  double _estimateChipWidth(ThemeData theme) {
    // Ancho base del chip (padding interno, bordes, etc.)
    const double chipPadding = 24.0; // 12px de cada lado
    const double iconSpace = 20.0; // Espacio para el ícono cuando aplique

    // Ancho promedio basado en caracteres comunes de marcas
    // La mayoría de marcas tienen entre 4-8 caracteres
    const double averageCharWidth = 8.0;
    const double averageTextLength = 6.0; // caracteres promedio
    const double estimatedTextWidth = averageCharWidth * averageTextLength;

    return chipPadding + estimatedTextWidth + iconSpace;
  }

  /// Muestra un diálogo con todas las marcas disponibles y permite filtrar por ellas
  void _showAllBrandsDialog(List<String> allBrands) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return _BrandSelectionDialog(
          brands: allBrands,
          onBrandSelected: (selectedBrand) {
            // Aplicar la marca seleccionada al campo de búsqueda
            _searchController.text = selectedBrand;
            _onSearchChanged();
            _searchFocusNode.requestFocus();
            Navigator.of(dialogContext).pop();
          },
        );
      },
    );
  }

  Widget _buildProductListItem(ProductCatalogue product) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Verificar si el producto está en el ticket
    final ticketProducts = widget.sellProvider.ticket.products;
    ProductCatalogue? selectedProduct;
    try {
      selectedProduct = ticketProducts
          .firstWhere((p) => p.id == product.id && p.quantity > 0);
    } catch (_) {
      selectedProduct = null;
    }

    return Material(
      color: selectedProduct != null
          ? colorScheme.primary.withValues(alpha: 0.12)
          : colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(12),
      elevation: selectedProduct != null ? 3 : 1,
      shadowColor: selectedProduct != null
          ? colorScheme.primary.withValues(alpha: 0.2)
          : colorScheme.shadow.withValues(alpha: 0.1),
      child: Container(
        decoration: selectedProduct != null
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.primary.withValues(alpha: 0.4),
                  width: 1.5,
                ),
              )
            : null,
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          leading: ProductImage(
            imageUrl: product.image,
            size: 56,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product.description,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (product.nameMark.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    product.nameMark,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: product.isVerified ? Colors.blue : null,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              product.code,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.secondary,
              ),
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // text : Precio de venta
              Text(
                CurrencyFormatter.formatPrice(value: product.salePrice),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(width: 12),
              if (selectedProduct != null) ...[
                // Botón para disminuir cantidad - con estilo similar al contador
                CircleAvatar(
                  radius: 16,
                  backgroundColor:
                      colorScheme.errorContainer.withValues(alpha: 0.8),
                  child: InkWell(
                    onTap: () {
                      // Disminuir cantidad del producto en el ticket
                      _decreaseProductQuantity(product);
                      setState(() {}); // Actualizar la vista
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Icon(
                      Icons.remove,
                      size: 16,
                      color: colorScheme.onErrorContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Cantidad seleccionada como CircleAvatar
                CircleAvatar(
                  radius: 18,
                  backgroundColor: colorScheme.primary,
                  child: Text(
                    selectedProduct.quantity.toString(),
                    style: TextStyle(
                      color: colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ],
          ),
          onTap: () {
            widget.sellProvider.addProductsticket(product.copyWith());
            setState(() {}); // Actualizar la vista al seleccionar
          },
        ),
      ),
    );
  }
}

/// Diálogo para seleccionar marcas con funcionalidad de búsqueda y filtrado
class _BrandSelectionDialog extends StatefulWidget {
  const _BrandSelectionDialog({
    required this.brands,
    required this.onBrandSelected,
  });

  final List<String> brands;
  final ValueChanged<String> onBrandSelected;

  @override
  State<_BrandSelectionDialog> createState() => _BrandSelectionDialogState();
}

class _BrandSelectionDialogState extends State<_BrandSelectionDialog> {
  late TextEditingController _searchController;
  late List<String> _filteredBrands;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _filteredBrands = widget.brands;
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      if (query.isEmpty) {
        _filteredBrands = widget.brands;
      } else {
        _filteredBrands = widget.brands
            .where((brand) => brand.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  Widget _buildBrandListItem(
      String brand, ThemeData theme, ColorScheme colorScheme) {
    return ListTile(
      title: Text(brand,
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w600)),
      onTap: () => widget.onBrandSelected(brand),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return BaseDialog(
      title: 'Seleccionar Marca',
      subtitle:
          '${_filteredBrands.length} resultado${_filteredBrands.length != 1 ? 's' : ''}',
      icon: Icons.local_offer_outlined,
      width: 400,
      maxHeight: 600,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Campo de búsqueda
          TextField(
            controller: _searchController,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Buscar',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _onSearchChanged();
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (_) => _onSearchChanged(),
          ),
          const SizedBox(height: 16),

          // Lista de marcas
          _filteredBrands.isEmpty
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.search_off,
                      size: 48,
                      color: colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No se encontraron marcas',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Intenta con otros términos de búsqueda',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                )
              : DialogComponents.itemList(
                  useFillStyle: true,
                  context: context,
                  padding: EdgeInsets.zero,
                  items: _filteredBrands
                      .map((brand) =>
                          _buildBrandListItem(brand, theme, colorScheme))
                      .toList(),
                  showDividers: true,
                ),
        ],
      ),
    );
  }
}
