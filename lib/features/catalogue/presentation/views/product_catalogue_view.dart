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
                    '${CurrencyFormatter.formatPrice(value: product.getBenefitsValue, moneda: product.currencySign)} ganancia',
                'icon': Icons.ssid_chart_outlined,
              },
          ],
        ),
      ),
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
                      'value': product.quantityStock % 1 == 0
                          ? product.quantityStock.toInt().toString()
                          : product.quantityStock.toString(),
                      'icon': Icons.inventory_outlined,
                    },
                    {
                      'label': 'Alerta configurada',
                      'value': product.alertStock % 1 == 0
                          ? product.alertStock.toInt().toString()
                          : product.alertStock.toString(),
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
        title: 'Actividad',
        icon: Icons.timeline_outlined,
        child: _buildInfoList(
          context,
          [
            {
              'label': 'Ventas',
              'value': product.sales.round().toString(),
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


    
    // Add Combo Items Card if applicable
    if (product.isCombo && product.comboItems.isNotEmpty) {
      cards.insert(0, _buildInfoCard( // Insert at the top or appropriate position
        context: context,
        title: 'Contenido del Combo',
        icon: Icons.layers_outlined,
        child: Column(
          children: product.comboItems.map((item) {
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                radius: 16,
                backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Text(
                  item.name.isNotEmpty ? item.name[0].toUpperCase() : '?',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant
                  ),
                ),
              ),
              title: Text(item.name, style: Theme.of(context).textTheme.bodyMedium),
              trailing: Text(
                'x${item.quantity.toInt()}',
                 style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            );
          }).toList(),
        ),
      ));
    }

    return cards;
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
                  Row(
                    children: [
                      // chip : code
                      if (product.code.isNotEmpty)
                        _buildMetaChip(
                          context,
                          icon: Icons.qr_code_2,
                          label: product.code,
                        ),
                      const SizedBox(width: 8),
                      // chip : brand
                      if (product.nameMark.isNotEmpty)
                        _buildMetaChip(
                          context,
                          icon: Icons.verified,
                          label: product.nameMark,
                          accentColor: product.isVerified
                              ? colorScheme.primary
                              : null,
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Título
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
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Estados
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            // chip de favorito
            if (product.favorite)
              _buildStatusChip(
                context,
                icon: Icons.star_rate_rounded,
                label: 'Favorito',
                color: Colors.amber.shade600,
              ),
            // chip de stock
            if (product.stock && product.quantityStock > 0)
              _buildStatusChip(
                context,
                icon: product.quantityStock <= product.alertStock
                        ? Icons.warning_amber_rounded
                        : Icons.inventory_outlined,
                label: product.quantityStock <= product.alertStock
                        ? 'Bajo stock (${UnitHelper.formatQuantityAdaptive(product.quantityStock, product.unit)})'
                        : UnitHelper.formatQuantityAdaptive(product.quantityStock, product.unit),
                color: product.quantityStock <= product.alertStock
                        ? Colors.orange
                        : Colors.green,
                filled: true,
              )
            // chip de sin stock
            else if (product.stock && product.quantityStock <= 0)
              _buildStatusChip(
                context,
                icon: Icons.inventory_2_outlined,
                label: 'Sin stock',
                color: Colors.red,
                filled: true,
              )
            // chip de sin control de stock
            else
              _buildStatusChip(
                context,
                icon: Icons.inventory_outlined,
                label: 'Sin control de stock',
                color: colorScheme.outline,
                filled: false,
              ),
            // chip de categoria
            if (product.nameCategory.isNotEmpty)
              _buildStatusChip(
                context,
                icon: Icons.category_outlined,
                label: product.nameCategory,
                color: colorScheme.primary,
                filled: false,
              ),
            // chip de proveedor
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
        // Header Web - Metadatos
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            // chip : code
            if (product.code.isNotEmpty)
              _buildMetaChip(
                context,
                icon: Icons.qr_code_2,
                label: product.code,
              ),
            // chip : brand
            if (product.nameMark.isNotEmpty)
              _buildMetaChip(
                context,
                icon: Icons.verified,
                label: product.nameMark,
                accentColor: product.isVerified
                    ? colorScheme.primary
                    : null,
              ),
          ],
        ),
        const SizedBox(height: 16),
        // Título
        Text(
          product.description.isNotEmpty
              ? TextFormatter.capitalizeString(product.description)
              : 'Producto sin nombre',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
            color: colorScheme.onSurface,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 24),
        // Estados Web
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            // chip de favorito
            if (product.favorite)
              _buildStatusChip(
                context,
                icon: Icons.star_rate_rounded,
                label: 'Favorito',
                color: Colors.amber.shade600,
              ),
            // chip de stock
            if (product.stock && product.quantityStock > 0)
              _buildStatusChip(
                context,
                icon: product.quantityStock <= product.alertStock
                        ? Icons.warning_amber_rounded
                        : Icons.inventory_outlined,
                label: product.quantityStock <= product.alertStock
                        ? 'Bajo stock (${UnitHelper.formatQuantityAdaptive(product.quantityStock, product.unit)})'
                        : UnitHelper.formatQuantityAdaptive(product.quantityStock, product.unit),
                color: product.quantityStock <= product.alertStock
                        ? Colors.orange
                        : Colors.green,
                filled: true,
              )
            // chip de sin stock
            else if (product.stock && product.quantityStock <= 0)
              _buildStatusChip(
                context,
                icon: Icons.inventory_2_outlined,
                label: 'Sin stock',
                color: Colors.red,
                filled: true,
              )
            // chip de sin control de stock
            else
              _buildStatusChip(
                context,
                icon: Icons.inventory_outlined,
                label: 'Sin control de stock',
                color: colorScheme.outline,
                filled: false,
              ),
            // chip de categoria
            if (product.nameCategory.isNotEmpty)
              _buildStatusChip(
                context,
                icon: Icons.category_outlined,
                label: product.nameCategory,
                color: colorScheme.primary,
                filled: false,
              ),
            // chip de proveedor
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

  /// Construye un card genérico con título e ícono
  Widget _buildInfoCard({
    required BuildContext context,
    required String title,
    required Widget child,
    IconData? icon,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con gradiente
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.primaryContainer.withValues(alpha: 0.4),
                  colorScheme.primaryContainer.withValues(alpha: 0.15),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                if (icon != null) ...[ 
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: colorScheme.primary.withValues(alpha: 0.2),
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      icon,
                      size: 20,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          // Contenido
          Padding(
            padding: const EdgeInsets.all(20),
            child: child,
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
          Icon(icon, size: 20, color: theme.colorScheme.primary.withValues(alpha: 0.85)),
          const SizedBox(width: 10),
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
              const SizedBox(height: 6),
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
    Color? accentColor,
    double? radius,
  }) {
    final theme = Theme.of(context);
    final color = accentColor ?? theme.colorScheme.onSurfaceVariant;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: accentColor?.withValues(alpha: 0.1) ?? theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(radius ?? 999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 7),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: accentColor != null ? FontWeight.bold : null,
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
