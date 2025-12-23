import 'package:flutter/material.dart';
import 'package:sellweb/core/core.dart';
import 'package:sellweb/features/catalogue/domain/entities/product_catalogue.dart';
import '../providers/catalogue_provider.dart';
import 'product_edit_catalogue_view.dart';

/// Vista de detalle de un producto del catálogo
///
/// Muestra información completa del producto incluyendo:
/// - Imagen y datos básicos
/// - Precios y márgenes de ganancia
/// - Información de inventario y proveedor
/// - Marca y categoría
/// - Estadísticas de ventas y actividad
class ProductCatalogueView extends StatefulWidget {
  final ProductCatalogue product;
  final CatalogueProvider catalogueProvider;
  final String accountId;

  const ProductCatalogueView({
    super.key,
    required this.product,
    required this.catalogueProvider,
    required this.accountId,
  });

  @override
  State<ProductCatalogueView> createState() => _ProductCatalogueViewState();
}

class _ProductCatalogueViewState extends State<ProductCatalogueView> {
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
    // Buscar en la lista principal de productos usando el ID
    final productId =
        _currentProduct.id.isNotEmpty ? _currentProduct.id : widget.product.id;

    ProductCatalogue? updatedProduct;

    // Buscar primero por ID
    for (final p in widget.catalogueProvider.products) {
      if (p.id == productId) {
        updatedProduct = p;
        break;
      }
    }

    // Si no se encontró por ID, buscar por código
    if (updatedProduct == null) {
      final code = _currentProduct.code.isNotEmpty
          ? _currentProduct.code
          : widget.product.code;
      updatedProduct = widget.catalogueProvider.getProductByCode(code);
    }

    // Si se encontró el producto y hay cambios, actualizar
    if (updatedProduct != null &&
        mounted &&
        _hasProductChanged(updatedProduct)) {
      setState(() {
        _currentProduct = updatedProduct!;
      });
    }
  }

  /// Verifica si el producto ha cambiado comparando todos los campos relevantes
  bool _hasProductChanged(ProductCatalogue updatedProduct) {
    return updatedProduct.upgrade.millisecondsSinceEpoch !=
            _currentProduct.upgrade.millisecondsSinceEpoch ||
        updatedProduct.favorite != _currentProduct.favorite ||
        updatedProduct.salePrice != _currentProduct.salePrice ||
        updatedProduct.purchasePrice != _currentProduct.purchasePrice ||
        updatedProduct.description != _currentProduct.description ||
        updatedProduct.quantityStock != _currentProduct.quantityStock ||
        updatedProduct.unit != _currentProduct.unit ||
        updatedProduct.nameMark != _currentProduct.nameMark ||
        updatedProduct.nameCategory != _currentProduct.nameCategory ||
        updatedProduct.nameProvider != _currentProduct.nameProvider ||
        updatedProduct.stock != _currentProduct.stock ||
        updatedProduct.alertStock != _currentProduct.alertStock ||
        updatedProduct.image != _currentProduct.image;
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
        final uniqueKey = UniqueKey();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            key: uniqueKey,
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
          _currentProduct =
              _currentProduct.copyWith(favorite: !newFavoriteState);
        });

        final errorMessage = e.toString().replaceFirst('Exception: ', '');
        ScaffoldMessenger.of(context).clearSnackBars();
        final uniqueKey = UniqueKey();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            key: uniqueKey,
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
        title:
            Text(TextFormatter.capitalizeString(_currentProduct.description)),
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
        heroTag: 'product_catalogue_edit_fab',
        onPressed: () async {
          final result = await Navigator.of(context).push<ProductCatalogue?>(
            MaterialPageRoute(
              builder: (context) => ProductEditCatalogueView(
                product: _currentProduct,
                catalogueProvider: widget.catalogueProvider,
                accountId: widget.accountId,
              ),
            ),
          );

          // Si se retornó un producto actualizado, usarlo inmediatamente
          if (result != null && mounted) {
            setState(() {
              _currentProduct = result;
            });
          }
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
                      'value':
                          TextFormatter.capitalizeString(product.nameCategory),
                    },
                  // item : proveedor
                  if (product.nameProvider.isNotEmpty ||
                      product.provider.isNotEmpty)
                    {
                      'icon': Icons.local_shipping_outlined,
                      'label': 'Proveedor',
                      'value': TextFormatter.capitalizeString(
                          product.nameProvider.isNotEmpty
                              ? product.nameProvider
                              : product.provider),
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
            if (product.purchasePrice > 0 && product.getBenefitsValue > 0)
              {
                'label': 'Beneficio estimado',
                'valueColor': Colors.green.shade700,
                'value':
                    '${product.currencySign} ${product.getBenefitsValue.toStringAsFixed(2)} ganancia',
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
                product.creation,
                DateTime.now(),
              ),
              'icon': Icons.calendar_today_outlined,
            },
            {
              'label': 'Ultima actualización',
              'value': DateFormatter.getSimplePublicationDate(
                product.upgrade,
                DateTime.now(),
              ),
              'icon': Icons.update,
            },
          ],
        ),
      ),
      if (product.variants.isNotEmpty)
        _buildInfoCard(
          context: context,
          title: 'Variantes',
          icon: Icons.label_outline,
          child: Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: product.variants.entries.map((entry) {
              final value = entry.value;
              String displayValue = '';

              if (value is List) {
                if (value.isNotEmpty) {
                  displayValue = ': ${value.join(", ")}';
                }
              } else if (value != null && value.toString().isNotEmpty) {
                displayValue = ': $value';
              }

              return Chip(
                label: Text(
                  '${entry.key}$displayValue',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                side: BorderSide.none,
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
              );
            }).toList(),
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
      product.upgrade,
      DateTime.now(),
    );

    final summaryMobileContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Row superior: imagen + marca y descripción
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen del producto
            SizedBox(
              width: 100,
              child: AspectRatio(
                aspectRatio: 1,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: ProductImage(
                    imageUrl: product.image,
                    fit: BoxFit.cover,
                    productDescription: product.description,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Columna con marca y descripción
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Marca del producto
                  if (product.nameMark.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: product.isVerified
                            ? Colors.blue.withValues(alpha: 0.12)
                            : theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(999),
                        border: product.isVerified
                            ? Border.all(
                                color: Colors.blue.withValues(alpha: 0.3))
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (product.isVerified) ...[
                            Icon(
                              Icons.verified,
                              size: 14,
                              color: Colors.blue,
                            ),
                            const SizedBox(width: 4),
                          ],
                          Flexible(
                            child: Text(
                              TextFormatter.capitalizeString(product.nameMark),
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: product.isVerified
                                    ? Colors.blue
                                    : theme.colorScheme.onSurfaceVariant,
                                fontWeight:
                                    product.isVerified ? FontWeight.w600 : null,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 8),
                  // Descripción del producto
                  Text(
                    product.description.isNotEmpty
                        ? TextFormatter.capitalizeString(product.description)
                        : 'Producto sin nombre',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.3,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  // Chips de metadata (código, categoría, proveedor)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (product.code.isNotEmpty)
                        _buildMetaChip(
                          context,
                          icon: Icons.qr_code_2,
                          label: product.code,
                        ),
                      if (product.nameCategory.isNotEmpty)
                        _buildMetaChip(
                          context,
                          icon: Icons.category_outlined,
                          label: TextFormatter.capitalizeString(
                              product.nameCategory),
                        ),
                      if (product.provider.isNotEmpty)
                        _buildMetaChip(
                          context,
                          icon: Icons.local_shipping_outlined,
                          label: TextFormatter.capitalizeString(
                              product.nameProvider.isNotEmpty
                                  ? product.nameProvider
                                  : product.provider),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        // Información de precios
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    salePrice,
                    style: theme.textTheme.displaySmall?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '/${product.unit}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colorScheme.onPrimaryContainer.withValues(
                        alpha: 0.7,
                      ),
                    ),
                  ),
                ],
              ),
              if (product.purchasePrice > 0) ...[
                const SizedBox(height: 8),
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
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Chips de estado
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (product.favorite)
              _buildStatusChip(
                context,
                icon: Icons.star_rate_rounded,
                label: 'Favorito',
                color: Colors.amber.shade600,
              ),
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
    final summaryWebContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          product.description.isNotEmpty
              ? TextFormatter.capitalizeString(product.description)
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
              color: product.isVerified
                  ? Colors.blue.withValues(alpha: 0.12)
                  : theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(999),
              border: product.isVerified
                  ? Border.all(color: Colors.blue.withValues(alpha: 0.3))
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (product.isVerified) ...[
                  Icon(
                    Icons.verified,
                    size: 16,
                    color: Colors.blue,
                  ),
                  const SizedBox(width: 6),
                ],
                Text(
                  TextFormatter.capitalizeString(product.nameMark),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: product.isVerified
                        ? Colors.blue
                        : theme.colorScheme.onSurfaceVariant,
                    fontWeight: product.isVerified ? FontWeight.w600 : null,
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
                label: TextFormatter.capitalizeString(product.nameCategory),
              ),

            // text chip : marca
            if (product.provider.isNotEmpty)
              _buildMetaChip(
                context,
                icon: Icons.local_shipping_outlined,
                label: TextFormatter.capitalizeString(
                    product.nameProvider.isNotEmpty
                        ? product.nameProvider
                        : product.provider),
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        salePrice,
                        style: theme.textTheme.displaySmall?.copyWith(
                          color: colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '/${product.unit}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: colorScheme.onPrimaryContainer.withValues(
                            alpha: 0.7,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
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
      // Calcular tamaños responsivos
      final isMobile = !isWide && MediaQuery.of(context).size.width < 600;
      final imageSize = isWide
          ? 260.0
          : isMobile
              ? 150.0 // Mitad del tamaño en pantallas reducidas
              : 200.0;

      return SizedBox(
        width: imageSize,
        child: AspectRatio(
          aspectRatio: 1,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: ProductImage(
              imageUrl: product.image,
              fit: BoxFit.cover,
              productDescription: product.description,
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
                  Expanded(child: summaryWebContent),
                ],
              )
            : summaryMobileContent,
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

  /// Construye una lista de items informativos with dividers
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
