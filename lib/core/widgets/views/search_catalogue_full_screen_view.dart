import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Core imports
import 'package:sellweb/core/utils/fuctions.dart';
import 'package:sellweb/core/services/catalogue_search_service.dart';
import 'package:sellweb/core/widgets/inputs/product_search_field.dart';
import 'package:sellweb/core/widgets/component/image.dart';
import 'package:sellweb/core/widgets/dialogs/components/dialog_components.dart';

// Domain imports
import 'package:sellweb/domain/entities/catalogue.dart' hide Provider;

// Presentation imports
import 'package:sellweb/presentation/providers/catalogue_provider.dart';
import 'package:sellweb/presentation/providers/sell_provider.dart';

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
  final SellProvider sellProvider;

  @override
  State<ProductCatalogueFullScreenView> createState() =>
      _ProductCatalogueFullScreenViewState();
}

class _ProductCatalogueFullScreenViewState
    extends State<ProductCatalogueFullScreenView> {
  late TextEditingController _searchController;
  late FocusNode _searchFocusNode;

  List<ProductCatalogue> _filteredProducts = [];

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
            _filteredProducts = CatalogueSearchService.searchProducts(
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

    // Usar SliverList.separated para mejor rendimiento y separadores automáticos
    return SliverList.separated(
      itemCount: _filteredProducts.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final product = _filteredProducts[index];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _buildProductListItem(product),
        );
      },
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
              SliverOverlapAbsorber(
                // Absorber el overlap para evitar problemas de posicionamiento
                handle:
                    NestedScrollView.sliverOverlapAbsorberHandleFor(context),
                sliver: SliverAppBar(
                  // Configuración optimizada del SliverAppBar para NestedScrollView
                  floating: true,
                  pinned: true,
                  snap: true,
                  expandedHeight:
                      210, // Altura fija para siempre mostrar búsqueda y chips
                  backgroundColor: colorScheme.surface,
                  surfaceTintColor: colorScheme.surface,
                  elevation: 0,
                  scrolledUnderElevation: innerBoxIsScrolled ? 2 : 0,
                  forceElevated: innerBoxIsScrolled,
                  leading: const SizedBox.shrink(),
                  // Usar stretch para mejor UX en iOS y permitir over-scroll
                  stretch: true,
                  onStretchTrigger: () async {
                    // Opcional: agregar funcionalidad de pull-to-refresh
                  },
                  flexibleSpace: FlexibleSpaceBar(
                    stretchModes: const [
                      StretchMode.zoomBackground,
                      StretchMode.fadeTitle,
                    ],
                    titlePadding: EdgeInsets.zero,
                    title: AnimatedOpacity(
                      opacity: innerBoxIsScrolled ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOutCubic,
                      child: Container(
                        padding: const EdgeInsets.only(
                            left: 16, right: 16, bottom: 2, top: 20),
                        child: Row(
                          children: [
                            // text flexibleSpace : información del catálogo
                            Expanded(
                              child: Text(
                                'Catálogo • ${Publications.getFormatAmount(value: _filteredProducts.length)} resultados',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onSurface,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    background: Container(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header principal con título y botón de cierre
                          Row(
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Text(
                                      'Catálogo',
                                      style: theme.textTheme.headlineSmall
                                          ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: colorScheme.onSurface,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    if (_getSelectedProductsCount() > 0)
                                      AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 300),
                                        curve: Curves.elasticOut,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: colorScheme.primary,
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          '${_getSelectedProductsCount()}',
                                          style: TextStyle(
                                            color: colorScheme.onPrimary,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close_rounded),
                                onPressed: () => Navigator.of(context).pop(),
                                style: IconButton.styleFrom(
                                  backgroundColor:
                                      colorScheme.surfaceContainerHighest,
                                  foregroundColor: colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Campo de búsqueda - siempre visible
                          _buildSearchField(),

                          // Chips de sugerencias - siempre visibles
                          const SizedBox(height: 12),
                          _buildSuggestionChips(),
                        ],
                      ),
                    ),
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
                        context),
                  ),
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
          child: FloatingActionButton.extended(
            heroTag:
                "product_catalogue_fab", // Hero tag único para evitar conflictos
            onPressed: () => Navigator.of(context).pop(),
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            elevation: 4,
            highlightElevation: 8,
            label: Text(
              'Continuar',
              style: const TextStyle(fontWeight: FontWeight.w600),
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
        final maxVisibleBrands =
            (maxChipsPerLine - 1).clamp(2, sortedBrands.length);

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
          ? colorScheme.primaryContainer.withValues(alpha: 0.3)
          : colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(12),
      elevation: selectedProduct != null ? 2 : 1,
      shadowColor: colorScheme.shadow.withValues(alpha: 0.1),
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
                    color: colorScheme.primary,
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
              Publications.getFormatoPrecio(value: product.salePrice),
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

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 400,
        height: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.local_offer_outlined,
                  color: colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Seleccionar Marca',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                  style: IconButton.styleFrom(
                    backgroundColor: colorScheme.surfaceContainerHighest,
                    foregroundColor: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Campo de búsqueda
            TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Buscar marca...',
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

            // Contador de resultados
            Text(
              '${_filteredBrands.length} marca${_filteredBrands.length != 1 ? 's' : ''} encontrada${_filteredBrands.length != 1 ? 's' : ''}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 12),

            // Lista de marcas
            Expanded(
              child: _filteredBrands.isEmpty
                  ? Center(
                      child: Column(
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
                              color:
                                  colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Intenta con otros términos de búsqueda',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color:
                                  colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    )
                  : DialogComponents.itemList(
                      context: context,
                      items: _filteredBrands
                          .map((brand) =>
                              _buildBrandListItem(brand, theme, colorScheme))
                          .toList(),
                      showDividers: true,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
