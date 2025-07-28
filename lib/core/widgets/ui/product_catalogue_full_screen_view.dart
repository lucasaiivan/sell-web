import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Core imports
import 'package:sellweb/core/utils/fuctions.dart';
import 'package:sellweb/core/utils/product_search_algorithm.dart';
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

  bool _isSearching = false;
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
        _isSearching = false;
        _filteredProducts = widget.products;
      } else {
        _isSearching = true;
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
            _filteredProducts = ProductSearchAlgorithm.searchProducts(
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

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _isSearching = false;
      _filteredProducts = widget.products;
    });
    // Mantener el foco en el campo de búsqueda
    _searchFocusNode.requestFocus();
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_rounded,
              size: 64,
              color: colorScheme.primary.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 24),
            Text(
              'Buscar productos',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '${Publications.getFormatAmount(value: widget.products.length)} productos disponibles',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
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
        child: Column(
          children: [
            // Header con título y botón cerrar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                border: Border(
                  bottom: BorderSide(
                    color: colorScheme.outline.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    'Catálogo',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                    style: IconButton.styleFrom(
                      backgroundColor: colorScheme.surfaceContainerHighest,
                      foregroundColor: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),

            // Campo de búsqueda fijo en la parte superior
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSearchField(),
                  const SizedBox(height: 12),
                  _buildSuggestionChips(),
                ],
              ),
            ),

            // Contenido principal
            Expanded(
              child: _isSearching ? _buildProductList() : _buildEmptyState(),
            ),
          ],
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

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Limitar a 7 marcas visibles
    const int maxVisibleBrands = 7;
    final List<String> visibleBrands = sortedBrands.take(maxVisibleBrands).toList();
    final bool hasMoreBrands = sortedBrands.length > maxVisibleBrands;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Marcas disponibles',
          style: theme.textTheme.labelMedium?.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.7),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            // Chips de marcas visibles
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
                backgroundColor: colorScheme.secondaryContainer.withValues(alpha: 0.3),
                side: BorderSide(
                  color: colorScheme.outline.withValues(alpha: 0.2),
                  width: 0.5,
                ),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact, 
              );
            }),
            
            // Chip "Ver más" si hay más marcas
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
        ),
      ],
    );
  }

  Widget _buildProductList() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_filteredProducts.isEmpty) {
      return Center(
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
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredProducts.length,
      itemBuilder: (context, index) {
        final product = _filteredProducts[index];
        return _buildProductListItem(product);
      },
    );
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

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Card(
        elevation: 0,
        color: selectedProduct != null
            ? colorScheme.primaryContainer.withValues(alpha: 0.18)
            : colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: selectedProduct != null
              ? BorderSide(color: colorScheme.primary, width: 1.2)
              : BorderSide(
                  color: colorScheme.outline.withValues(alpha: 0.2),
                  width: 1,
                ),
        ),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          leading: ProductImage(
            imageUrl: product.image,
            size: 56,
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product.description,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
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
              Text(
                Publications.getFormatoPrecio(value: product.salePrice),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                  fontSize: 17,
                ),
              ),
              const SizedBox(width: 12),
              if (selectedProduct != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
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
          ),
          onTap: () {
            widget.sellProvider.addProductsticket(product.copyWith());
            setState(() {}); // Actualizar la vista al seleccionar
          },
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
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

  Widget _buildBrandListItem(String brand, ThemeData theme, ColorScheme colorScheme) {
    return ListTile( 
      title: Text(brand, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
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
                      ),
                    )
                  : DialogComponents.itemList( 
                    context: context,
                    showDividers: true,
                    maxVisibleItems: 20, // Mostrar más elementos antes de expandir
                    expandText: 'Ver todas las marcas',
                    collapseText: 'Mostrar menos',
                    items: _filteredBrands.map((brand) {
                      return _buildBrandListItem(brand, theme, colorScheme);
                    }).toList(),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
