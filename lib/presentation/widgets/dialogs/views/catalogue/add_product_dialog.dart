import 'package:sellweb/core/core.dart';
import 'package:flutter/material.dart';
import 'package:sellweb/domain/entities/catalogue.dart';
import 'package:sellweb/features/sales/presentation/providers/sales_provider.dart';
import 'package:sellweb/features/catalogue/presentation/providers/catalogue_provider.dart';
import 'package:sellweb/features/auth/presentation/providers/auth_provider.dart';
import 'package:provider/provider.dart' as provider_package;

/// Diálogo modernizado para agregar productos siguiendo Material Design 3
class AddProductDialog extends StatefulWidget {
  const AddProductDialog({
    super.key,
    required this.product,
    required this.sellProvider,
    required this.catalogueProvider,
    required this.authProvider,
    this.errorMessage,
    this.isNew = false,
  });

  final ProductCatalogue product;
  final SalesProvider sellProvider;
  final CatalogueProvider catalogueProvider;
  final AuthProvider authProvider;
  final String? errorMessage;
  final bool isNew;

  @override
  State<AddProductDialog> createState() => _AddProductDialogState();
}

class _AddProductDialogState extends State<AddProductDialog> {
  final _formKey = GlobalKey<FormState>();
  late final AppMoneyTextEditingController _priceController;
  late final AppMoneyTextEditingController _purchasePriceController;
  late final TextEditingController _descriptionController;
  bool _checkAddCatalogue = true;
  bool _isLoading = false;
  bool _isEditingDescription = false;

  @override
  void initState() {
    super.initState();
    _priceController = AppMoneyTextEditingController();
    _purchasePriceController = AppMoneyTextEditingController();
    _descriptionController =
        TextEditingController(text: widget.product.description);

    // Agregar listeners para actualizar el porcentaje de ganancia en tiempo real
    _priceController.addListener(_updateProfitPercentage);
    _purchasePriceController.addListener(_updateProfitPercentage);

    // Si es un producto existente y tiene precio, establecerlo en el controlador
    if (!widget.isNew && widget.product.salePrice > 0) {
      _priceController.updateValue(widget.product.salePrice);
    }

    // Si es un producto existente y tiene precio de compra, establecerlo en el controlador
    if (!widget.isNew && widget.product.purchasePrice > 0) {
      _purchasePriceController.updateValue(widget.product.purchasePrice);
    }
  }

  @override
  void dispose() {
    _priceController.dispose();
    _purchasePriceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  /// Actualiza la UI cuando cambian los precios para mostrar el porcentaje de ganancia en tiempo real
  void _updateProfitPercentage() {
    setState(() {
      // Solo trigger del rebuild para actualizar el porcentaje de ganancia
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BaseDialog(
      title: widget.isNew ? 'Crear nuevo producto' : 'Nuevo producto',
      icon: widget.isNew ? Icons.public_rounded : Icons.inventory_2_rounded,
      width: 500,
      headerColor: widget.isNew ? theme.colorScheme.primaryContainer : null,
      content: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Información del producto (código y detalles)
            if (!widget.isNew) ...[
              _buildExistingProductInfoSection(),
            ] else ...[
              // Solo mostrar código para productos nuevos
              DialogComponents.infoSection(
                context: context,
                title: 'Código',
                content: widget.product.code.isEmpty
                    ? Text(
                        'Sin código asignado',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w400,
                        ),
                      )
                    : Text(widget.product.code,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 30,
                        )),
              ),
            ],

            // Campo de descripción para productos nuevos
            if (widget.isNew) ...[
              DialogComponents.itemSpacing,
              DialogComponents.textField(
                context: context,
                controller: _descriptionController,
                label: 'Descripción',
                hint: 'Ingrese una descripción descriptiva',
                validator: (value) {
                  if (value?.trim().isEmpty == true) {
                    return 'La descripción es requerida';
                  }
                  return null;
                },
              ),
            ],
            DialogComponents.itemSpacing,
            // Campo de precio de compra (opcional)
            DialogComponents.moneyField(
              context: context,
              controller: _purchasePriceController,
              label: 'Precio de compra (Opcional)',
              hint: '\$0.00',
              validator: (value) {
                // El precio de compra es opcional, pero si se ingresa debe ser válido
                if (value != null && value.trim().isNotEmpty) {
                  final purchasePrice = _purchasePriceController.doubleValue;
                  final salePrice = _priceController.doubleValue;

                  if (purchasePrice < 0) {
                    return 'El precio no puede ser negativo';
                  }

                  // Validar que el precio de compra no sea mayor al de venta si ambos están definidos
                  if (purchasePrice > 0 &&
                      salePrice > 0 &&
                      purchasePrice > salePrice) {
                    return 'El precio de compra no puede ser mayor al de venta';
                  }
                }
                return null;
              },
            ),

            // text :  Mostrar porcentaje de ganancia si ambos precios están definidos
            if (_priceController.doubleValue > 0 &&
                _purchasePriceController.doubleValue > 0) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.trending_up_rounded,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Ganancia: ',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '${((_priceController.doubleValue - _purchasePriceController.doubleValue) / _purchasePriceController.doubleValue * 100).round()}%',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
            DialogComponents.itemSpacing,
            // DialogComponents.moneyField : entrada de monto de precio de venta
            DialogComponents.moneyField(
              context: context,
              controller: _priceController,
              label: 'Precio de venta al público',
              hint: '\$0.00',
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'El precio es requerido';
                }

                // Usar el método doubleValue del controlador para validación consistente
                final price = _priceController.doubleValue;

                if (price <= 0) {
                  return 'El precio debe ser mayor a cero';
                }

                return null;
              },
            ),
            DialogComponents.itemSpacing,
            DialogComponents.itemSpacing,
            // Checkbox para agregar al catálogo
            _buildCatalogueOption(),
          ],
        ),
      ),
      actions: [
        DialogComponents.secondaryActionButton(
          context: context,
          text: 'Cancelar',
          onPressed: () => Navigator.of(context).pop(),
        ),
        DialogComponents.primaryActionButton(
          context: context,
          text: widget.isNew ? 'Confirmar' : 'Agregar',
          onPressed: _processAddProduct,
          isLoading: _isLoading,
        ),
      ],
    );
  }

  Widget _buildExistingProductInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildExistingProductInfo(),
        // Botón de editar solo visible si el producto no está verificado
        if (!widget.product.verified) ...[
          const SizedBox(height: 8),
          _buildEditButton(),
        ],
      ],
    );
  }

  Widget _buildExistingProductInfo() {
    final theme = Theme.of(context);

    return DialogComponents.infoSection(
      context: context,
      backgroundColor: widget.product.verified
          ? theme.colorScheme.primaryContainer.withValues(alpha: 0.1)
          : theme.colorScheme.tertiaryContainer.withValues(alpha: 0.1),
      title: widget.product.code,
      icon:
          widget.product.verified ? Icons.verified : Icons.info_outline_rounded,
      accentColor:
          widget.product.verified ? Colors.blue : theme.colorScheme.tertiary,
      content: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Imagen del producto
          ProductImage(
            borderRadius: 8,
            imageUrl: widget.product.image,
            size: 60,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Descripción - mostrar campo editable si está en modo edición
                if (_isEditingDescription) ...[
                  DialogComponents.textField(
                    context: context,
                    controller: _descriptionController,
                    label: 'Descripción del Producto',
                    hint: 'Ingrese una descripción descriptiva',
                    validator: (value) {
                      if (value?.trim().isEmpty == true) {
                        return 'La descripción es requerida';
                      }
                      return null;
                    },
                  ),
                ] else if (widget.product.description.isNotEmpty) ...[
                  // text : descripción
                  Text(
                    widget.product.description,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                const SizedBox(height: 8),

                // Badges de información
                if (widget.product.nameMark.isNotEmpty) ...[
                  DialogComponents.infoBadge(
                    context: context,
                    text: widget.product.nameMark,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditButton() {
    final theme = Theme.of(context);

    if (_isEditingDescription) {
      // Mostrar botón de cancelar cuando está editando
      return Align(
        alignment: Alignment.centerRight,
        child: TextButton.icon(
          onPressed: () {
            setState(() {
              _isEditingDescription = false;
              _descriptionController.text = widget.product.description;
            });
          },
          icon: const Icon(Icons.close_rounded),
          label: const Text('Cancelar'),
          style: TextButton.styleFrom(
            foregroundColor: theme.colorScheme.error,
          ),
        ),
      );
    }

    // Botón de editar normal
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton.icon(
        onPressed: () {
          setState(() {
            _isEditingDescription = true;
          });
        },
        icon: const Icon(Icons.edit_rounded),
        label: const Text('Editar'),
        style: TextButton.styleFrom(
          foregroundColor: theme.colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildCatalogueOption() {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: _checkAddCatalogue
              ? theme.colorScheme.primary
              : theme.colorScheme.outline.withValues(alpha: 0.5),
        ),
        color: _checkAddCatalogue
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
            : null,
        borderRadius: BorderRadius.circular(12),
      ),
      child: CheckboxListTile(
        title: Text(
          'Agregar al catálogo',
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          'Guardar este producto para uso futuro',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        value: _checkAddCatalogue,
        onChanged: (value) {
          setState(() {
            _checkAddCatalogue = value ?? false;
          });
        },
        controlAffinity: ListTileControlAffinity.leading,
        activeColor: theme.colorScheme.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Future<void> _processAddProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Validar que el precio sea válido
      if (_priceController.text.trim().isEmpty) {
        throw Exception('El precio es requerido');
      }

      // Usar el método doubleValue del AppMoneyTextEditingController que maneja correctamente el formateo
      final price = _priceController.doubleValue;
      final purchasePrice = _purchasePriceController.doubleValue;

      if (price <= 0) {
        throw Exception('El precio debe ser un número válido mayor a cero');
      }

      // Usar los providers pasados como parámetros
      final sellProvider = widget.sellProvider;
      final catalogueProvider = widget.catalogueProvider;
      final authProvider = widget.authProvider;

      // Validar que los providers estén disponibles
      if (sellProvider.profileAccountSelected.id.isEmpty) {
        throw Exception('No hay cuenta seleccionada');
      }

      // Crear producto actualizado
      final updatedProduct = widget.product.copyWith(
        description: _descriptionController.text.trim(),
        code: widget.product.code,
        salePrice: price,
        purchasePrice: purchasePrice,
      );

      // Agregar al ticket
      sellProvider.addProductsticket(updatedProduct);

      // Si el producto no está verificado y la descripción cambió, actualizar la base de datos pública
      if (!widget.product.verified &&
          !widget.isNew &&
          _descriptionController.text.trim() != widget.product.description) {
        await _updatePublicProductDescription(updatedProduct);
      }

      // Procesar según el tipo
      if (widget.isNew) {
        await _createNewProduct(
            updatedProduct, catalogueProvider, authProvider, sellProvider);
      } else if (_checkAddCatalogue && updatedProduct.id.isNotEmpty) {
        await _addExistingProduct(
            updatedProduct, catalogueProvider, sellProvider, authProvider);
      }

      // Cerrar diálogo si todo fue exitoso
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // Mostrar error al usuario
        showErrorDialog(
          context: context,
          title: 'Error al Procesar Producto',
          message: 'No se pudo procesar el producto.',
          details: e.toString(),
        );
      }
    }
  }

  Future<void> _updatePublicProductDescription(
      ProductCatalogue updatedProduct) async {
    try {
      // Crear producto actualizado para la base de datos pública
      final updatedPublicProduct = Product(
        id: updatedProduct.id,
        code: updatedProduct.code,
        description: updatedProduct.description,
        image: updatedProduct.image,
        idMark: updatedProduct.idMark,
        nameMark: updatedProduct.nameMark,
        imageMark: updatedProduct.imageMark,
        creation: updatedProduct.documentCreation,
        upgrade: DateFormatter.getCurrentTimestamp(),
        idUserCreation: updatedProduct.documentIdCreation,
        idUserUpgrade: widget.authProvider.user?.email ?? '',
        verified: updatedProduct.verified,
        reviewed: updatedProduct.reviewed,
        favorite: updatedProduct.outstanding,
        followers: updatedProduct.followers,
      );

      // Actualizar el producto público
      await widget.catalogueProvider.createPublicProduct(updatedPublicProduct);
    } catch (e) {
      // No lanzamos el error para no interrumpir el flujo principal
    }
  }

  Future<void> _createNewProduct(
    ProductCatalogue updatedProduct,
    CatalogueProvider catalogueProvider,
    AuthProvider authProvider,
    SalesProvider sellProvider,
  ) async {
    try {
      final publicProduct = Product(
        id: updatedProduct.id.isEmpty
            ? 'prod_${DateTime.now().millisecondsSinceEpoch}'
            : updatedProduct.id,
        code: updatedProduct.code,
        description: updatedProduct.description,
        image: updatedProduct.image,
        idMark: updatedProduct.idMark,
        nameMark: updatedProduct.nameMark,
        imageMark: updatedProduct.imageMark,
        creation: DateFormatter.getCurrentTimestamp(),
        upgrade: DateFormatter.getCurrentTimestamp(),
        idUserCreation: authProvider.user?.email ?? '',
        idUserUpgrade: authProvider.user?.email ?? '',
        verified: false,
        reviewed: false,
        favorite: false,
        followers: 0,
      );

      // Crear producto público
      await catalogueProvider.createPublicProduct(publicProduct);

      if (_checkAddCatalogue) {
        // Obtener perfil de la cuenta para registrar precio
        final accountProfile = authProvider.getProfileAccountById(sellProvider.profileAccountSelected.id);

        final finalProduct = updatedProduct.copyWith(id: publicProduct.id);
        await catalogueProvider.addAndUpdateProductToCatalogue(
          finalProduct,
          sellProvider.profileAccountSelected.id,
          accountProfile: accountProfile,
        );
      }
    } catch (e) {
      // Mostrar error si falla la creación
      if (mounted) {
        showErrorDialog(
          context: context,
          title: 'Error al Crear Producto',
          message: 'No se pudo crear el producto público.',
          details: e.toString(),
        );
      }
      rethrow; // Re-lanzar para que se maneje en _processAddProduct
    }
  }

  Future<void> _addExistingProduct(
    ProductCatalogue updatedProduct,
    CatalogueProvider catalogueProvider,
    SalesProvider sellProvider,
    AuthProvider authProvider,
  ) async {
    try {
      // Obtener perfil de la cuenta para registrar precio
      final accountProfile = authProvider
          .getProfileAccountById(sellProvider.profileAccountSelected.id);

      await catalogueProvider.addAndUpdateProductToCatalogue(
        updatedProduct,
        sellProvider.profileAccountSelected.id,
        accountProfile: accountProfile,
      );
    } catch (e) {
      // Mostrar error si falla
      if (mounted) {
        showErrorDialog(
          context: context,
          title: 'Error al Guardar',
          message: 'No se pudo guardar el producto en el catálogo.',
          details: e.toString(),
        );
      }
      rethrow; // Re-lanzar para que se maneje en _processAddProduct
    }
  }
}

/// Helper function para mostrar el diálogo de agregar producto
Future<void> showAddProductDialog(
  BuildContext context, {
  required ProductCatalogue product,
  String? errorMessage,
  bool isNew = false,
}) {
  try {
    // Obtener los providers del contexto antes de mostrar el diálogo
    final sellProvider =
        provider_package.Provider.of<SalesProvider>(context, listen: false);
    final catalogueProvider =
        provider_package.Provider.of<CatalogueProvider>(context, listen: false);
    final authProvider =
        provider_package.Provider.of<AuthProvider>(context, listen: false);

    // Validar que los providers estén disponibles
    if (sellProvider.profileAccountSelected.id.isEmpty) {
      throw Exception('No hay cuenta seleccionada para agregar productos');
    }

    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AddProductDialog(
        product: product,
        sellProvider: sellProvider,
        catalogueProvider: catalogueProvider,
        authProvider: authProvider,
        errorMessage: errorMessage,
        isNew: isNew,
      ),
    );
  } catch (e) {
    // Mostrar error al usuario si falla la obtención de providers
    showErrorDialog(
      context: context,
      title: 'Error de Configuración',
      message: 'No se pudo abrir el diálogo de productos.',
      details: e.toString(),
    );

    return Future.value(); // Retornar un Future completado
  }
}
