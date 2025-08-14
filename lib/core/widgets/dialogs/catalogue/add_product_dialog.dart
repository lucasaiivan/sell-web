import 'package:flutter/material.dart';
import 'package:sellweb/core/utils/fuctions.dart';
import 'package:sellweb/core/widgets/dialogs/base/base_dialog.dart';
import 'package:sellweb/core/widgets/dialogs/base/standard_dialogs.dart';
import 'package:sellweb/core/widgets/dialogs/components/dialog_components.dart';
import 'package:sellweb/core/widgets/component/image.dart';
import 'package:sellweb/domain/entities/catalogue.dart';
import 'package:sellweb/presentation/providers/sell_provider.dart';
import 'package:sellweb/presentation/providers/catalogue_provider.dart';
import 'package:sellweb/presentation/providers/auth_provider.dart';
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
  final SellProvider sellProvider;
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
  late final TextEditingController _descriptionController;
  bool _checkAddCatalogue = true;
  bool _isLoading = false;
  bool _isEditingDescription = false; 

  @override
  void initState() {
    super.initState();
    _priceController = AppMoneyTextEditingController();
    _descriptionController = TextEditingController(text: widget.product.description);
    
    // Si es un producto existente y tiene precio, establecerlo en el controlador
    if (!widget.isNew && widget.product.salePrice > 0) {
      _priceController.updateValue(widget.product.salePrice);
    }
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
      icon: widget.isNew ? Icons.public_rounded : Icons.inventory_2_rounded,
      width: 500,
      headerColor: widget.isNew ? theme.colorScheme.primaryContainer : null,
      content: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
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
                  title: 'Código del Producto', 
                  backgroundColor: theme.colorScheme.surfaceContainer,
                  content: Row(
                  children: [
                    Icon(
                    Icons.qr_code_rounded,
                    color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Text(
                    widget.product.code.isNotEmpty
                      ? widget.product.code
                      : 'Sin código asignado',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    ),
                  ],
                  ),
                ),
                ],
          
              // Campo de descripción para productos nuevos
              if (widget.isNew) ...[ 
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
              DialogComponents.itemSpacing,
              DialogComponents.itemSpacing,
              // DialogComponents.moneyField : entrada de monto de precio de venta
              DialogComponents.moneyField(
                context: context,
                controller: _priceController,
                label: 'Precio',
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
          
              DialogComponents.sectionSpacing,
          
              // Checkbox para agregar al catálogo
              _buildCatalogueOption(),
            
            ],
          ),
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
          text: widget.isNew ? 'Crear' : 'Agregar',
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
                  Text(
                    widget.product.description,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                // Código de barras del producto
                if (widget.product.code.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      DialogComponents.infoBadge(
                        context: context,
                        text: widget.product.code,
                        icon: Icons.qr_code_rounded,
                      ),
                    ],
                  ),
                ],
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
      
      if (price <= 0) {
        throw Exception('El precio debe ser un número válido mayor a cero');
      }

      print('🔄 Procesando producto: ${widget.isNew ? "nuevo" : "existente"}');
      print('💰 Texto del controlador: "${_priceController.text}"');
      print('💰 Precio parseado: \$${price.toStringAsFixed(2)}');

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
      );

      print('📦 Producto actualizado: ${updatedProduct.description} - \$${updatedProduct.salePrice}');

      // Agregar al ticket
      sellProvider.addProductsticket(updatedProduct);
      print('✅ Producto agregado al ticket');

      // Si el producto no está verificado y la descripción cambió, actualizar la base de datos pública
      if (!widget.product.verified && !widget.isNew && 
          _descriptionController.text.trim() != widget.product.description) {
        print('🔄 Actualizando descripción en producto público...');
        await _updatePublicProductDescription(updatedProduct);
      }

      // Procesar según el tipo
      if (widget.isNew) {
        print('🆕 Creando nuevo producto...');
        await _createNewProduct(updatedProduct, catalogueProvider, authProvider, sellProvider);
      } else if (_checkAddCatalogue && updatedProduct.id.isNotEmpty) {
        print('📁 Agregando producto existente al catálogo...');
        await _addExistingProduct(updatedProduct, catalogueProvider, sellProvider, authProvider);
      }

      // Cerrar diálogo si todo fue exitoso
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        Navigator.of(context).pop();
        print('✅ Proceso completado exitosamente');
      }

    } catch (e) {
      print('❌ Error en _processAddProduct: $e');
      
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

  Future<void> _updatePublicProductDescription(ProductCatalogue updatedProduct) async {
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
        upgrade: Utils().getTimestampNow(),
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
      print('❌ Error al actualizar descripción del producto público: $e');
      // No lanzamos el error para no interrumpir el flujo principal
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
      print('❌ Error al crear producto: $e');
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
    SellProvider sellProvider,
    AuthProvider authProvider,
  ) async {
    try {
      
      // Obtener perfil de la cuenta para registrar precio
      final accountProfile = authProvider.getProfileAccountById(sellProvider.profileAccountSelected.id);
      
      await catalogueProvider.addAndUpdateProductToCatalogue(
        updatedProduct, 
        sellProvider.profileAccountSelected.id,
        accountProfile: accountProfile,
      );
    } catch (e) {
      print('❌ Error al agregar producto existente: $e');
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
    final sellProvider = provider_package.Provider.of<SellProvider>(context, listen: false);
    final catalogueProvider = provider_package.Provider.of<CatalogueProvider>(context, listen: false);
    final authProvider = provider_package.Provider.of<AuthProvider>(context, listen: false);

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
    print('❌ Error al mostrar AddProductDialog: $e');
    
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
