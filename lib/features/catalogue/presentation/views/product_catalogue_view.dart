import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:sellweb/core/core.dart';
import 'package:sellweb/core/presentation/widgets/ui/tags/combo_tag.dart';
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

  /// Índices de tarjetas expandidas (por defecto la primera: 'Precios y margen')
  final Set<int> _expandedCards = {0};

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

  /// Muestra diálogo de confirmación para eliminar
  Future<void> _showDeleteConfirmation(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar producto?'),
        content: const Text(
          'Esta acción no se puede deshacer. El producto se eliminará de tu catálogo permanentemente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await widget.catalogueProvider.deleteProduct(
          product: _currentProduct,
          accountId: widget.accountId,
        );
        
        if (mounted) {
          Navigator.pop(context); // Volver al catálogo
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Producto eliminado correctamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al eliminar: ${e.toString().replaceAll("Exception:", "")}'),
              backgroundColor: Colors.red,
            ),
          );
        }
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
          // button : eliminar producto
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            tooltip: 'Eliminar producto',
            color: Colors.red.shade400,
            onPressed: () => _showDeleteConfirmation(context),
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
                      children: _buildInfoCards(context, columns).map((card) {
                        return SizedBox(
                          width: columns == 1 ? double.infinity : cardWidth,
                          child: card,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 40),
                    // Secciones relacionadas
                    _buildRelatedSections(context),
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

  // ═══════════════════════════════════════════════════════════════
  // UI BUILDERS - Cards de información
  // ═══════════════════════════════════════════════════════════════

  /// Construye las tarjetas de información del producto (stock, precios, actividad)
  List<Widget> _buildInfoCards(BuildContext context, int columns) {
    final product = _currentProduct;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Definir todas las tarjetas como datos (título, ícono, child)
    final cardDefs = <Map<String, dynamic>>[];

    // 1. ITEMS DE PRECIO (Filtrar vacíos)
    final priceItems = <Map<String, dynamic>>[];
    
    // Venta al público (Dato principal - siempre va)
    priceItems.add({
      'label': 'Venta al público',
      'value': CurrencyFormatter.formatPrice(value: product.salePrice),
      'icon': Icons.local_offer_outlined,
      'isHighlight': true, // Marcador para destacar
    });

    // Compra (Solo si > 0)
    if (product.purchasePrice > 0) {
      priceItems.add({
        'label': 'Costo de compra',
        'value': CurrencyFormatter.formatPrice(value: product.purchasePrice),
        'icon': Icons.local_shipping_outlined,
      });
    }

    // Margen (Solo si > 0 y válido)
    if (product.purchasePrice > 0 && product.getPorcentageFormat.isNotEmpty) {
      priceItems.add({
        'label': 'Margen de ganancia',
        'valueColor': Colors.green.shade700,
        'value': product.getPorcentageFormat,
        'icon': Icons.trending_up,
      });
    }

    // Beneficio (Solo si > 0)
    if (product.purchasePrice > 0 && product.getBenefitsValue > 0) {
      priceItems.add({
        'label': 'Beneficio estimado',
        'valueColor': Colors.green.shade700,
        'value':
            '${CurrencyFormatter.formatPrice(value: product.getBenefitsValue, moneda: product.currencySign)}',
        'icon': Icons.ssid_chart_outlined,
      });
    }

    // Card: Precios y margen (siempre presente, índice 0 → expandido por defecto)
    cardDefs.add({
      'title': 'Precios y margen',
      'icon': Icons.attach_money_rounded,
      'child': _buildInfoList(context, priceItems),
      'preview': Text(
        CurrencyFormatter.formatPrice(value: product.salePrice),
        style: theme.textTheme.titleMedium?.copyWith(
          color: colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    });

    // Card: Combo (se inserta al inicio si aplica)
    if (product.isCombo && product.comboItems.isNotEmpty) {
      cardDefs.insert(0, {
        'title': 'Contenido del Combo',
        'icon': Icons.layers_outlined,
        'child': Column(
          children: product.comboItems.map((item) {
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                radius: 16,
                backgroundColor: colorScheme.surfaceContainerHighest,
                child: Text(
                  item.name.isNotEmpty ? item.name[0].toUpperCase() : '?',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              title: Text(item.name, style: theme.textTheme.bodyMedium),
              trailing: Text(
                'x${item.quantity.toInt()}',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            );
          }).toList(),
        ),
        'preview': Text(
          '${product.comboItems.length} items',
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
      });
    }

    // 2. ITEMS DE INVENTARIO (Filtrar vacíos)
    final inventoryItems = <Map<String, dynamic>>[];

    if (product.nameCategory.isNotEmpty) {
      inventoryItems.add({
        'icon': Icons.category_outlined,
        'label': 'Categoría',
        'value': TextFormatter.capitalizeString(product.nameCategory),
      });
    }

    if (product.nameProvider.isNotEmpty || product.provider.isNotEmpty) {
      inventoryItems.add({
        'icon': Icons.local_shipping_outlined,
        'label': 'Proveedor',
        'value': TextFormatter.capitalizeString(product.nameProvider.isNotEmpty
            ? product.nameProvider
            : product.provider),
      });
    }

    if (product.stock) {
      inventoryItems.add({
        'label': 'Cantidad disponible',
        'value': product.quantityStock % 1 == 0
            ? product.quantityStock.toInt().toString()
            : product.quantityStock.toString(),
        'icon': Icons.inventory_outlined,
      });

      // Solo mostrar alerta si es relevante (valor > 0 o diferente default)
      if (product.alertStock > 0) {
        inventoryItems.add({
          'label': 'Alerta mínima',
          'value': product.alertStock % 1 == 0
              ? product.alertStock.toInt().toString()
              : product.alertStock.toString(),
          'icon': Icons.notification_important_outlined,
        });
      }
    } else {
      // Si no hay stock, mostrar que no tiene control
      inventoryItems.add({
        'label': 'Control de stock',
        'value': 'Desactivado',
        'icon': Icons.inventory_outlined,
      });
    }

    // Card: Inventario y proveedor (Solo si hay items)
    if (inventoryItems.isNotEmpty) {
      // Preview logic
      String previewText = '';
      if (product.stock) {
        previewText =
            'Stock: ${UnitHelper.formatQuantityAdaptive(product.quantityStock, product.unit)}';
      } else if (product.nameProvider.isNotEmpty) {
        previewText = product.nameProvider;
      } else if (product.nameCategory.isNotEmpty) {
        previewText = product.nameCategory;
      }

      cardDefs.add({
        'title': 'Inventario y proveedor',
        'icon': Icons.inventory_2_outlined,
        'child': Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoList(context, inventoryItems),
            if (product.stock &&
                product.quantityStock <= product.alertStock) ...[
              const SizedBox(height: 12),
              _buildStockAlert(context),
            ],
          ],
        ),
        'preview': previewText.isNotEmpty
            ? Text(
                previewText,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: colorScheme.onSurfaceVariant),
              )
            : null,
      });
    }

    // 3. ITEMS DE ACTIVIDAD
    final activityItems = <Map<String, dynamic>>[];
    
    // Ventas (Solo si > 0)
    if (product.sales > 0) {
      activityItems.add({
        'label': 'Ventas totales',
        'value': product.sales.round().toString(),
        'icon': Icons.receipt_long_outlined,
      });
    }

    // Fechas siempre relevantes
    activityItems.add({
      'label': 'Creado',
      'value': DateFormatter.getSimplePublicationDate(
        product.creation,
        DateTime.now(),
      ),
      'icon': Icons.calendar_today_outlined,
    });

    if (product.upgrade != product.creation) {
      activityItems.add({
        'label': 'Última edicion',
        'value': DateFormatter.getSimplePublicationDate(
          product.upgrade,
          DateTime.now(),
        ),
        'icon': Icons.update,
      });
    }

    // Card: Actividad
    cardDefs.add({
      'title': 'Actividad',
      'icon': Icons.timeline_outlined,
      'child': _buildInfoList(context, activityItems),
      'preview': product.sales > 0
          ? Text(
              '${product.sales.round()} ventas',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: colorScheme.onSurfaceVariant),
            )
          : null,
    });

    // Card: Variantes (Solo si existen)
    if (product.variants.isNotEmpty) {
      cardDefs.add({
        'title': 'Variantes',
        'icon': Icons.label_outline,
        'child': Wrap(
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
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              backgroundColor: colorScheme.surfaceContainerHighest,
              side: BorderSide.none,
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
            );
          }).toList(),
        ),
        'preview': Text(
          '${product.variants.length} variantes',
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
      });
    }

    // Construir widgets con estado expandible
    final bool isMobile = columns == 1;
    return List.generate(cardDefs.length, (index) {
      final def = cardDefs[index];
      // En pantallas grandes (columns > 1), siempre expandido
      // En móvil (columns == 1), usar estado de _expandedCards
      final bool shouldBeExpanded =
          isMobile ? _expandedCards.contains(index) : true;

      return _buildInfoCard(
        context: context,
        title: def['title'] as String,
        icon: def['icon'] as IconData?,
        child: def['child'] as Widget,
        preview: isMobile && !shouldBeExpanded ? def['preview'] as Widget? : null,
        isExpanded: shouldBeExpanded,
        // Solo permitir toggle en móvil
        onToggle: isMobile
            ? () {
                setState(() {
                  if (_expandedCards.contains(index)) {
                    _expandedCards.remove(index);
                  } else {
                    _expandedCards.add(index);
                  }
                });
              }
            : null,
      );
    });
  }

  /// Construye el card de resumen principal con imagen y datos destacados
  Widget _buildSummaryCard(BuildContext context, bool isWide) {
    final product = _currentProduct;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final updatedLabel = DateFormatter.getSimplePublicationDate(
      product.upgrade,
      DateTime.now(),
    );

    // Contenido para móvil
    final summaryMobileContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen del producto
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Stack(
                  children: [
                    ProductImage(
                      imageUrl: product.image,
                      fit: BoxFit.cover,
                      productDescription: product.description,
                    ),
                    if (product.isCombo)
                      const Positioned(
                        bottom: 4,
                        right: 4,
                        child: ComboTag(isCompact: true),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 20),
            // Información principal
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // SKU / Código
                  if (product.code.isNotEmpty) ...[
                    Text(
                      'SKU: ${product.code}',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  // Marca con verificación visible
                  if (product.nameMark.isNotEmpty) ...[
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          product.nameMark.toUpperCase(),
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        if (product.isVerified) ...[
                          const SizedBox(width: 6),
                          Icon(
                            Icons.verified,
                            size: 18,
                            color: colorScheme.primary,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                  // Nombre del producto
                  Text(
                    product.description.isNotEmpty
                        ? TextFormatter.capitalizeString(product.description)
                        : 'Producto sin nombre',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                      height: 1.2,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  // Precio destacado
                  Text(
                    CurrencyFormatter.formatPrice(value: product.salePrice),
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        // Botón de favorito + Estados
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            // Botón de favorito
            Material(
              color: _currentProduct.favorite
                  ? Colors.amber.withValues(alpha: 0.15)
                  : colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: _isUpdatingFavorite ? null : _toggleFavorite,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_isUpdatingFavorite)
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.amber.shade600,
                          ),
                        )
                      else
                        Icon(
                          _currentProduct.favorite
                              ? Icons.star_rate_rounded
                              : Icons.star_outline_rounded,
                          size: 20,
                          color: _currentProduct.favorite
                              ? Colors.amber.shade600
                              : colorScheme.onSurfaceVariant,
                        ),
                      const SizedBox(width: 8),
                      Text(
                        _currentProduct.favorite
                            ? 'Favorito'
                            : 'Añadir a favoritos',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: _currentProduct.favorite
                              ? Colors.amber.shade700
                              : colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Chip de stock
            if (product.stock && product.quantityStock > 0)
              _buildStatusChip(
                context,
                icon: product.quantityStock <= product.alertStock
                    ? Icons.warning_amber_rounded
                    : Icons.inventory_outlined,
                label: product.quantityStock <= product.alertStock
                    ? 'Bajo stock (${UnitHelper.formatQuantityAdaptive(product.quantityStock, product.unit)})'
                    : UnitHelper.formatQuantityAdaptive(
                        product.quantityStock, product.unit),
                color: product.quantityStock <= product.alertStock
                    ? Colors.orange
                    : Colors.green,
                filled: true,
              )
            else if (product.stock && product.quantityStock <= 0)
              _buildStatusChip(
                context,
                icon: Icons.inventory_2_outlined,
                label: 'Sin stock',
                color: Colors.red,
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
            // Chip de categoría
            if (product.nameCategory.isNotEmpty)
              _buildStatusChip(
                context,
                icon: Icons.category_outlined,
                label: product.nameCategory,
                color: colorScheme.primary,
                filled: false,
              ),
            // Chip de proveedor
            if (product.nameProvider.isNotEmpty)
              _buildStatusChip(
                context,
                icon: Icons.local_shipping_outlined,
                label: product.nameProvider,
                color: colorScheme.primary,
                filled: false,
              ),
          ],
        ),
        const SizedBox(height: 16),
        // Footer: fecha actualización
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            'Actualizado $updatedLabel',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );

    // Contenido para Web
    final summaryWebContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // SKU / Código
        if (product.code.isNotEmpty) ...[
          Text(
            'SKU: ${product.code}',
            style: theme.textTheme.labelLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
        ],
        // Marca con verificación visible
        if (product.nameMark.isNotEmpty) ...[
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                product.nameMark.toUpperCase(),
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              if (product.isVerified) ...[
                const SizedBox(width: 8),
                Icon(
                  Icons.verified,
                  size: 22,
                  color: colorScheme.primary,
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
        ],
        // Título
        Text(
          product.description.isNotEmpty
              ? TextFormatter.capitalizeString(product.description)
              : 'Producto sin nombre',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
            color: colorScheme.onSurface,
            height: 1.2,
          ),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 16),
        // Precio destacado
        Text(
          CurrencyFormatter.formatPrice(value: product.salePrice),
          style: theme.textTheme.headlineLarge?.copyWith(
            color: colorScheme.primary,
            fontWeight: FontWeight.bold,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 24),
        // Botón de favorito + Estados Web
        Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            // Botón de favorito
            Material(
              color: _currentProduct.favorite
                  ? Colors.amber.withValues(alpha: 0.15)
                  : colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: _isUpdatingFavorite ? null : _toggleFavorite,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_isUpdatingFavorite)
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.amber.shade600,
                          ),
                        )
                      else
                        Icon(
                          _currentProduct.favorite
                              ? Icons.star_rate_rounded
                              : Icons.star_outline_rounded,
                          size: 22,
                          color: _currentProduct.favorite
                              ? Colors.amber.shade600
                              : colorScheme.onSurfaceVariant,
                        ),
                      const SizedBox(width: 10),
                      Text(
                        _currentProduct.favorite
                            ? 'Favorito'
                            : 'Añadir a favoritos',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: _currentProduct.favorite
                              ? Colors.amber.shade700
                              : colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Chip de stock
            if (product.stock && product.quantityStock > 0)
              _buildStatusChip(
                context,
                icon: product.quantityStock <= product.alertStock
                    ? Icons.warning_amber_rounded
                    : Icons.inventory_outlined,
                label: product.quantityStock <= product.alertStock
                    ? 'Bajo stock (${UnitHelper.formatQuantityAdaptive(product.quantityStock, product.unit)})'
                    : UnitHelper.formatQuantityAdaptive(
                        product.quantityStock, product.unit),
                color: product.quantityStock <= product.alertStock
                    ? Colors.orange
                    : Colors.green,
                filled: true,
              )
            else if (product.stock && product.quantityStock <= 0)
              _buildStatusChip(
                context,
                icon: Icons.inventory_2_outlined,
                label: 'Sin stock',
                color: Colors.red,
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
            // Chip de categoría
            if (product.nameCategory.isNotEmpty)
              _buildStatusChip(
                context,
                icon: Icons.category_outlined,
                label: product.nameCategory,
                color: colorScheme.primary,
                filled: false,
              ),
            // Chip de proveedor
            if (product.nameProvider.isNotEmpty)
              _buildStatusChip(
                context,
                icon: Icons.local_shipping_outlined,
                label: product.nameProvider,
                color: colorScheme.primary,
                filled: false,
              ),
          ],
        ),
        const SizedBox(height: 20),
        // Footer: fecha actualización
        Text(
          'Actualizado $updatedLabel',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );

    // Contenedor Principal M3 (Surface Tonal)
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isWide ? 32 : 20), 
      child: isWide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Imagen grande en web
                Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: ProductImage(
                      imageUrl: product.image,
                      fit: BoxFit.cover,
                      productDescription: product.description,
                    ),
                  ),
                ),
                const SizedBox(width: 40),
                Expanded(child: summaryWebContent),
              ],
            )
          : summaryMobileContent,
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // UI HELPERS - Componentes reutilizables
  // ═══════════════════════════════════════════════════════════════

  /// Construye un card genérico expandible con título e ícono
  Widget _buildInfoCard({
    required BuildContext context,
    required String title,
    required Widget child,
    IconData? icon,
    Widget? preview, // Widget opcional para mostrar cuando está colapsado
    bool isExpanded = false,
    VoidCallback? onToggle,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bool isInteractive = onToggle != null;

    return Container(
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header (interactivo solo en móvil)
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isInteractive ? onToggle : null,
              borderRadius: isExpanded
                  ? const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    )
                  : BorderRadius.circular(16),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    if (icon != null) ...[
                      Icon(
                        icon,
                        size: 20,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: Row(
                        children: [
                          Text(
                            title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          // Si hay preview y está colapsado, mostrarlo a la derecha
                          if (preview != null && !isExpanded) ...[
                            const SizedBox(width: 8),
                            const Text('·'),
                            const SizedBox(width: 8),
                            Expanded(child: preview),
                          ],
                        ],
                      ),
                    ),
                    // Solo mostrar chevron en móvil (cuando es interactivo)
                    if (isInteractive)
                      AnimatedRotation(
                        turns: isExpanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 22,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          // Contenido expandible con animación
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Column(
              children: [
                Divider(
                  height: 1,
                  thickness: 1,
                  color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: child,
                ),
              ],
            ),
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
            sizeCurve: Curves.easeInOut,
          ),
        ],
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
            isHighlight: items[index]['isHighlight'] as bool? ?? false,
          ),
          if (index != items.length - 1)
            const Divider(height: 20, thickness: 0.3),
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
    bool isHighlight = false, // Parámetro de destacado
  }) {
    final theme = Theme.of(context);
    final displayValue = value.isNotEmpty ? value : 'No especificado';
    
    // Estilo para valores normales vs destacados
    final textStyle = isHighlight 
        ? theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: valueColor ?? theme.colorScheme.primary,
            letterSpacing: -0.5,
          )
        : theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            height: 1.2,
            color: valueColor,
          );

    return Row(
      crossAxisAlignment: isHighlight ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        if (icon != null) ...[
          Container(
            padding: isHighlight ? const EdgeInsets.all(8) : EdgeInsets.zero,
            decoration: isHighlight 
                ? BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ) 
                : null,
            child: Icon(
              icon, 
              size: isHighlight ? 24 : 20, 
              color: theme.colorScheme.primary.withValues(alpha: isHighlight ? 1 : 0.85)
            ),
          ),
          SizedBox(width: isHighlight ? 16 : 10),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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

  // ═══════════════════════════════════════════════════════════════
  // RELATED PRODUCTS SECTIONS
  // ═══════════════════════════════════════════════════════════════

  Widget _buildRelatedSections(BuildContext context) {
    final allProducts = widget.catalogueProvider.products;
    final currentId = _currentProduct.id;
    final currentCode = _currentProduct.code;

    // Filter lists
    final categoryProducts = allProducts
        .where((p) =>
            p.category == _currentProduct.category &&
            p.id != currentId &&
            p.code != currentCode)
        .toList();

    final providerProducts = allProducts
        .where((p) =>
            p.provider == _currentProduct.provider &&
            p.id != currentId &&
            p.code != currentCode)
        .toList();

    final favoriteProducts = allProducts
        .where((p) => p.favorite && p.id != currentId && p.code != currentCode)
        .toList();

    if (categoryProducts.isEmpty &&
        providerProducts.isEmpty &&
        favoriteProducts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (categoryProducts.isNotEmpty)
          _buildRelatedList(
            context,
            'Más de ${_currentProduct.nameCategory}',
            categoryProducts,
          ),
        if (providerProducts.isNotEmpty)
          _buildRelatedList(
            context,
            'Del mismo proveedor',
            providerProducts,
          ),
        if (favoriteProducts.isNotEmpty)
          _buildRelatedList(
            context,
            'Favoritos destacados',
            favoriteProducts,
          ),
      ],
    );
  }

  Widget _buildRelatedList(
      BuildContext context, String title, List<ProductCatalogue> products) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  products.length.toString(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 280, // Altura reducida al quitar el botón
          child: ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(
              dragDevices: {
                PointerDeviceKind.touch,
                PointerDeviceKind.mouse,
              },
            ),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: products.length,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                return _buildRelatedProductCard(context, products[index]);
              },
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildRelatedProductCard(
      BuildContext context, ProductCatalogue product) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // Ancho responsivo básico
    // ignore: unused_local_variable
    final screenWidth = MediaQuery.of(context).size.width;
    // Usamos un ancho fijo más pequeño para que entren más items en mobile
    const double cardWidth = 180;

    return Container(
      width: cardWidth,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => ProductCatalogueView(
                  product: product,
                  catalogueProvider: widget.catalogueProvider,
                  accountId: widget.accountId,
                ),
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Imagen del producto
              AspectRatio(
                aspectRatio: 1,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      color: Colors.white,
                      child: ProductImage(
                        imageUrl: product.image,
                        productDescription: product.description,
                        fit: BoxFit.cover,
                      ),
                    ),
                    if (product.favorite)
                      const Positioned(
                        top: 8,
                        right: 8,
                        child: Icon(
                          Icons.star_rounded,
                          size: 20,
                          color: Colors.amber,
                        ),
                      ),
                  ],
                ),
              ),
              // Información
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (product.nameMark.isNotEmpty) ...[
                        Text(
                          product.nameMark.toUpperCase(),
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurfaceVariant,
                            letterSpacing: 0.5,
                            fontSize: 10,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                      ],
                      Text(
                        product.description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      Text(
                        CurrencyFormatter.formatPrice(value: product.salePrice),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
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
