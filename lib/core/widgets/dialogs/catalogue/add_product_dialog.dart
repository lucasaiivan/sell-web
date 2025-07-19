import 'package:flutter/material.dart';
import 'package:sellweb/core/utils/fuctions.dart';
import 'package:sellweb/core/widgets/dialogs/base/base_dialog.dart';
import 'package:sellweb/core/widgets/dialogs/base/standard_dialogs.dart';
import 'package:sellweb/core/widgets/dialogs/components/dialog_components.dart';
import 'package:sellweb/core/widgets/component/image_widget.dart';
import 'package:sellweb/domain/entities/catalogue.dart';
import 'package:sellweb/presentation/providers/sell_provider.dart';
import 'package:sellweb/presentation/providers/catalogue_provider.dart';
import 'package:sellweb/presentation/providers/auth_provider.dart';
import 'package:provider/provider.dart' as provider_package;

/// Diálogo para agregar un producto  
class AddProductDialog extends StatefulWidget {
  const AddProductDialog({
    super.key,
    required this.product,
    this.errorMessage,
    this.isNew = false,
  });

  final ProductCatalogue product;
  final String? errorMessage;
  final bool isNew;

  @override
  State<AddProductDialog> createState() => _AddProductDialogState();
}

class _AddProductDialogState extends State<AddProductDialog> {
  final _formKey = GlobalKey<FormState>();
  late final AppMoneyTextEditingController _priceController;
  late final TextEditingController _descriptionController;
  bool _checkAddCatalogue = true;
  bool _isLoading = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _priceController = AppMoneyTextEditingController();
    _descriptionController =
        TextEditingController(text: widget.product.description);
    _errorText = widget.errorMessage;
  }

  @override
  void dispose() {
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BaseDialog(
      title: widget.isNew ? 'Crear Producto' : 'Nuevo Producto',
      icon: widget.isNew ? Icons.add_box_rounded : Icons.inventory_2_rounded,
      width: 500,
      headerColor: widget.isNew ? theme.colorScheme.tertiaryContainer : null,
      content: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Información del código del producto
            DialogComponents.infoSection(
              context: context,
              title: 'Código del Producto',
              icon: Icons.qr_code_rounded,
              content: Text(
                widget.product.code.isNotEmpty
                    ? widget.product.code
                    : 'Sin código asignado',
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            // Información del producto existente
            if (!widget.isNew) ...[
              DialogComponents.sectionSpacing,
              _buildExistingProductInfo(),
            ],

            // Campo de descripción para productos nuevos
            if (widget.isNew) ...[
              DialogComponents.sectionSpacing,
              Text(
                'Información del Producto',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              DialogComponents.itemSpacing,
              DialogComponents.textField(
                context: context,
                controller: _descriptionController,
                label: 'Descripción del Producto',
                hint: 'Ingrese una descripción descriptiva',
                prefixIcon: Icons.label_rounded,
                validator: (value) {
                  if (value?.trim().isEmpty == true) {
                    return 'La descripción es requerida';
                  }
                  return null;
                },
              ),
            ],

            DialogComponents.sectionSpacing,

            // Campo de precio
            Text(
              'Precio de Venta',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            DialogComponents.itemSpacing,

            DialogComponents.textField(
              context: context,
              controller: _priceController,
              label: 'Precio',
              hint: '\$0.00',
              prefixIcon: Icons.monetization_on_rounded,
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value?.trim().isEmpty == true) {
                  return 'El precio es requerido';
                }
                final price = double.tryParse(value!);
                if (price == null || price <= 0) {
                  return 'Ingrese un precio válido';
                }
                return null;
              },
            ),

            DialogComponents.sectionSpacing,

            // Checkbox para agregar al catálogo
            _buildCatalogueOption(),

            // Mostrar error si existe
            if (_errorText != null) ...[
              DialogComponents.itemSpacing,
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      color: theme.colorScheme.onErrorContainer,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorText!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
          text: widget.isNew ? 'Crear Producto' : 'Agregar al Ticket',
          icon: widget.isNew ? Icons.add_rounded : Icons.shopping_cart_rounded,
          onPressed: _processAddProduct,
          isLoading: _isLoading,
        ),
      ],
    );
  }

  Widget _buildExistingProductInfo() {
    return DialogComponents.infoSection(
      context: context,
      title: 'Información del Producto',
      icon: Icons.info_outline_rounded,
      content: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Imagen del producto
          ProductImage(
            imageUrl: widget.product.image,
            size: 60,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.product.description.isNotEmpty)
                  Text(
                    widget.product.description,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (widget.product.nameMark.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      DialogComponents.infoBadge(
                        context: context,
                        text: widget.product.nameMark,
                        icon: Icons.business_rounded,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
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
      _errorText = null;
    });

    try {
      final price = double.parse(_priceController.text);

      // Obtener providers
      final sellProvider =
          provider_package.Provider.of<SellProvider>(context, listen: false);
      final catalogueProvider = provider_package.Provider.of<CatalogueProvider>(
          context,
          listen: false);
      final authProvider =
          provider_package.Provider.of<AuthProvider>(context, listen: false);

      // Crear producto actualizado
      final updatedProduct = widget.product.copyWith(
        description: widget.isNew
            ? _descriptionController.text.trim()
            : widget.product.description,
        code: widget.product.code,
        salePrice: price,
      );

      // Agregar al ticket
      sellProvider.addProductsticket(updatedProduct);

      if (mounted) {
        Navigator.of(context).pop();

        // Mostrar confirmación
        showInfoDialog(
          context: context,
          title: 'Producto Agregado',
          message: 'El producto se ha agregado al ticket de venta.',
          icon: Icons.check_circle_outline_rounded,
        );
      }

      // Procesar en segundo plano
      if (widget.isNew) {
        await _createNewProduct(
            updatedProduct, catalogueProvider, authProvider, sellProvider);
      } else if (_checkAddCatalogue && updatedProduct.id.isNotEmpty) {
        await _addExistingProduct(
            updatedProduct, catalogueProvider, sellProvider);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorText = 'Error inesperado: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _createNewProduct(
    ProductCatalogue updatedProduct,
    CatalogueProvider catalogueProvider,
    AuthProvider authProvider,
    SellProvider sellProvider,
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
        creation: Utils().getTimestampNow(),
        upgrade: Utils().getTimestampNow(),
        idUserCreation: authProvider.user?.email ?? '',
        idUserUpgrade: authProvider.user?.email ?? '',
        verified: false,
        reviewed: false,
        favorite: false,
        followers: 0,
      );

      await catalogueProvider.createPublicProduct(publicProduct);

      if (_checkAddCatalogue) {
        final finalProduct = updatedProduct.copyWith(id: publicProduct.id);
        await catalogueProvider.addProductToCatalogue(
            finalProduct, sellProvider.profileAccountSelected.id);
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
    }
  }

  Future<void> _addExistingProduct(
    ProductCatalogue updatedProduct,
    CatalogueProvider catalogueProvider,
    SellProvider sellProvider,
  ) async {
    try {
      await catalogueProvider.addProductToCatalogue(
          updatedProduct, sellProvider.profileAccountSelected.id);
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
  return showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) => AddProductDialog(
      product: product,
      errorMessage: errorMessage,
      isNew: isNew,
    ),
  );
}
