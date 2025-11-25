import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sellweb/core/core.dart';
import 'package:sellweb/features/catalogue/domain/entities/product_catalogue.dart';
import 'package:sellweb/features/catalogue/domain/entities/category.dart';
import 'package:sellweb/features/catalogue/domain/entities/provider.dart';
import 'package:sellweb/features/catalogue/domain/entities/mark.dart';

import '../providers/catalogue_provider.dart';
import '../../../../presentation/widgets/modals/selection_modal.dart';

/// Formulario de edición de producto con validación y estado local
///
/// Permite editar todos los campos del producto incluyendo:
/// - Imagen del producto
/// - Descripción y código de barras (solo lectura)
/// - Marca (con opción de crear nueva)
/// - Precios de venta y compra con preview de beneficio
/// - Control de stock y alertas
/// - Categoría y proveedor
/// - Estado de favorito
class ProductEditCatalogueView extends StatefulWidget {
  final ProductCatalogue product;
  final CatalogueProvider catalogueProvider;
  final String accountId;

  const ProductEditCatalogueView({
    super.key,
    required this.product,
    required this.catalogueProvider,
    required this.accountId,
  });

  @override
  State<ProductEditCatalogueView> createState() =>
      _ProductEditCatalogueViewState();
}

class _ProductEditCatalogueViewState extends State<ProductEditCatalogueView> {
  // Form state
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;
  bool _stockEnabled = false;
  bool _favoriteEnabled = false;

  // Image state
  Uint8List? _newImageBytes;
  final ImagePicker _picker = ImagePicker();

  // Controllers
  late final TextEditingController _descriptionController;
  late final TextEditingController _salePriceController;
  late final TextEditingController _purchasePriceController;
  late final TextEditingController _quantityStockController;
  late final TextEditingController _alertStockController;
  late final TextEditingController _categoryController;
  late final TextEditingController _providerController;
  late final TextEditingController _markController;

  // Selected IDs
  String? _selectedCategoryId;
  String? _selectedProviderId;
  String? _selectedBrandId;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _initializeState();
    _setupListeners();
  }

  /// Inicializa los controllers con valores del producto
  void _initializeControllers() {
    final product = widget.product;
    _descriptionController = TextEditingController(text: product.description);
    _salePriceController = TextEditingController(
      text: product.salePrice > 0 ? product.salePrice.toString() : '',
    );
    _purchasePriceController = TextEditingController(
      text: product.purchasePrice > 0 ? product.purchasePrice.toString() : '',
    );
    _quantityStockController = TextEditingController(
      text: product.quantityStock.toString(),
    );
    _alertStockController = TextEditingController(
      text: product.alertStock.toString(),
    );
    _categoryController = TextEditingController(text: product.nameCategory);
    _providerController = TextEditingController(text: product.nameProvider);
    _markController = TextEditingController(text: product.nameMark);
  }

  /// Inicializa el estado del formulario
  void _initializeState() {
    _stockEnabled = widget.product.stock;
    _favoriteEnabled = widget.product.favorite;
    _selectedCategoryId =
        widget.product.category.isNotEmpty ? widget.product.category : null;
    _selectedProviderId =
        widget.product.provider.isNotEmpty ? widget.product.provider : null;
    _selectedBrandId =
        widget.product.idMark.isNotEmpty ? widget.product.idMark : null;
  }

  /// Configura listeners para recalcular beneficios
  void _setupListeners() {
    _salePriceController.addListener(() => setState(() {}));
    _purchasePriceController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _salePriceController.dispose();
    _purchasePriceController.dispose();
    _quantityStockController.dispose();
    _alertStockController.dispose();
    _categoryController.dispose();
    _providerController.dispose();
    _markController.dispose();
    super.dispose();
  }

  /// Selecciona una imagen de la galería
  Future<void> _pickImage() async {
    // Verificar si el producto está verificado
    if (widget.product.verified) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.lock, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                    'No se puede modificar la imagen de un producto verificado'),
              ),
            ],
          ),
          backgroundColor: Colors.orange.shade600,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _newImageBytes = bytes;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al seleccionar imagen: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  /// Valida y guarda los cambios del producto en Firebase
  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      var updatedProduct = _buildUpdatedProduct();

      // Subir imagen si se seleccionó una nueva
      if (_newImageBytes != null) {
        final imageUrl = await DatabaseCloudService.uploadProductImage(
            widget.product.id, _newImageBytes!);
        updatedProduct = updatedProduct.copyWith(image: imageUrl);
      }

      // Detectar si cambiaron los precios para actualizar el timestamp upgrade
      final pricesChanged = _havePricesChanged();
      await widget.catalogueProvider.addAndUpdateProductToCatalogue(
        updatedProduct,
        widget.accountId,
        shouldUpdateUpgrade: pricesChanged || _newImageBytes != null,
      );

      if (mounted) {
        _showSuccessMessage();
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) _showErrorMessage(e.toString());
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  /// Construye el producto actualizado con los valores del formulario
  ProductCatalogue _buildUpdatedProduct() {
    return widget.product.copyWith(
      description: widget.product.verified
          ? widget.product.description
          : _descriptionController.text.trim(),
      salePrice: _parsePriceFromController(_salePriceController),
      purchasePrice: _parsePriceFromController(_purchasePriceController),
      quantityStock: int.tryParse(_quantityStockController.text) ?? 0,
      alertStock: int.tryParse(_alertStockController.text) ?? 5,
      category: _selectedCategoryId ?? '',
      nameCategory: _categoryController.text.trim(),
      provider: _selectedProviderId ?? '',
      nameProvider: _providerController.text.trim(),
      idMark: widget.product.verified
          ? widget.product.idMark
          : (_selectedBrandId ?? ''),
      nameMark: widget.product.verified
          ? widget.product.nameMark
          : _markController.text.trim(),
      stock: _stockEnabled,
      favorite: _favoriteEnabled,
    );
  }

  /// Parsea el precio desde un controller limpiando formato
  double _parsePriceFromController(TextEditingController controller) {
    final cleanValue = controller.text.replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(cleanValue) ?? 0.0;
  }

  /// Verifica si los precios de compra o venta han cambiado
  bool _havePricesChanged() {
    final newSalePrice = _parsePriceFromController(_salePriceController);
    final newPurchasePrice =
        _parsePriceFromController(_purchasePriceController);
    return newSalePrice != widget.product.salePrice ||
        newPurchasePrice != widget.product.purchasePrice;
  }

  /// Muestra mensaje de éxito al guardar
  void _showSuccessMessage() {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('Producto actualizado correctamente'),
            ),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Muestra mensaje de error al guardar
  void _showErrorMessage(String error) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text('Error al guardar: $error'),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  /// Muestra dialog para crear una nueva marca
  Future<Mark?> _showCreateBrandDialog() async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    Uint8List? brandImageBytes;
    final picker = ImagePicker();

    return showDialog<Mark>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Crear Nueva Marca'),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Image picker
                    GestureDetector(
                      onTap: () async {
                        try {
                          final XFile? image = await picker.pickImage(
                            source: ImageSource.gallery,
                            maxWidth: 512,
                            maxHeight: 512,
                            imageQuality: 85,
                          );
                          if (image != null) {
                            final bytes = await image.readAsBytes();
                            setState(() {
                              brandImageBytes = bytes;
                            });
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content:
                                    Text('Error al seleccionar imagen: $e')),
                          );
                        }
                      },
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade400),
                        ),
                        child: brandImageBytes != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.memory(
                                  brandImageBytes!,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_photo_alternate,
                                      size: 40, color: Colors.grey.shade600),
                                  const SizedBox(height: 8),
                                  Text('Agregar imagen',
                                      style: TextStyle(
                                          color: Colors.grey.shade600)),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Name field
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre de la marca *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'El nombre es requerido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // Description field
                    TextFormField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Descripción',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;

                  try {
                    // Generate ID for the brand
                    final brandId =
                        DateTime.now().millisecondsSinceEpoch.toString();

                    // Upload image if provided
                    String imageUrl = '';
                    if (brandImageBytes != null) {
                      imageUrl = await DatabaseCloudService.uploadBrandImage(
                        brandId,
                        brandImageBytes!,
                      );
                    }

                    // Create brand object
                    final newBrand = Mark(
                      id: brandId,
                      name: nameController.text.trim(),
                      country: 'ARG',
                      description: descriptionController.text.trim(),
                      image: imageUrl,
                      verified: false,
                      creation: DateTime.now(),
                      upgrade: DateTime.now(),
                    );

                    // Save to database
                    await widget.catalogueProvider.createBrand(newBrand);

                    if (context.mounted) {
                      Navigator.of(context).pop(newBrand);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Marca creada exitosamente'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error al crear marca: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                child: const Text('Crear'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildForm(),
      floatingActionButton: _buildFab(),
    );
  }

  /// Construye el AppBar con indicador de carga
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Editar producto'),
      centerTitle: false,
      actions: [
        if (_isSaving)
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
      ],
    );
  }

  /// Construye el formulario completo con todas las secciones
  Widget _buildForm() {
    final colorScheme = Theme.of(context).colorScheme;
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildImageSection(),
                const SizedBox(height: 24),
                _buildBasicInfoSection(colorScheme),
                const SizedBox(height: 24),
                _buildPricingSection(),
                const SizedBox(height: 24),
                _buildInventorySection(colorScheme),
                const SizedBox(height: 24),
                _buildPreferencesSection(colorScheme),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Construye sección de imagen del producto
  Widget _buildImageSection() {
    final isVerified = widget.product.verified;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionHeader(
          context: context,
          title: 'Imagen del producto',
          icon: Icons.image_outlined,
        ),
        const SizedBox(height: 12),
        _buildCard(
          context: context,
          child: Center(
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                GestureDetector(
                  onTap: isVerified ? null : _pickImage,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: _newImageBytes != null
                        ? Image.memory(
                            _newImageBytes!,
                            width: 200,
                            height: 200,
                            fit: BoxFit.cover,
                          )
                        : SizedBox(
                            width: 200,
                            height: 200,
                            child: ProductImage(
                              imageUrl: widget.product.image,
                              fit: BoxFit.cover,
                            ),
                          ),
                  ),
                ),
                if (!isVerified)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextButton.icon(
                      onPressed: _pickImage,
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.black.withValues(alpha: 0.6),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('Actualizar'),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Construye sección de información básica (descripción y código)
  Widget _buildBasicInfoSection(ColorScheme colorScheme) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionHeader(
          context: context,
          title: 'Información básica',
          icon: Icons.info_outline,
        ),
        const SizedBox(height: 12),
        Column(
          children: [
            // Campo de código de barras (solo lectura)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.qr_code_2,
                    color: colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Código de barras',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.product.code.isNotEmpty
                              ? widget.product.code
                              : 'Sin código',
                          style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              fontFamily: 'monospace',
                              fontSize: 18),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            if (widget.product.verified) ...[
              // Campo de descripción (solo lectura)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: colorScheme.outline.withValues(alpha: 0.2))),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Descripción',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.product.description.isNotEmpty
                          ? widget.product.description
                          : 'Producto sin nombre',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Campo de descripción (editable)
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Descripción del producto *',
                  hintText: 'Ej: Coca Cola 2L',
                  prefixIcon: const Icon(Icons.description_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                maxLength: 100,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'La descripción es requerida';
                  }
                  return null;
                },
              ),
            ],
            const SizedBox(height: 12),
            // view : marca del prodicto segun si esta verificado o no
            if (widget.product.verified) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: colorScheme.outline.withValues(alpha: 0.2))),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Marca del producto',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: Colors.blue,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          widget.product.nameMark.isNotEmpty
                              ? widget.product.nameMark
                              : 'Marca no especificada',
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 18,
                                    color: Colors.blue,
                                  ),
                        ),
                      ],
                    ),
                  ],
                ),
              )
            ] else ...[
              _buildMarkField(),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ],
    );
  }

  /// Construye sección de precios con preview de beneficio
  Widget _buildPricingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionHeader(
          context: context,
          title: 'Precios y márgenes',
          icon: Icons.attach_money,
        ),
        const SizedBox(height: 12),
        _buildSalePriceField(),
        const SizedBox(height: 16),
        _buildPurchasePriceField(),
        if (_salePriceController.text.isNotEmpty &&
            _purchasePriceController.text.isNotEmpty)
          _buildProfitPreview(),
      ],
    );
  }

  /// Campo de precio de venta con validación
  Widget _buildSalePriceField() {
    return TextFormField(
      controller: _salePriceController,
      decoration: InputDecoration(
        labelText: 'Precio de venta *',
        hintText: '0.00',
        prefixIcon: const Icon(Icons.trending_up),
        prefixText: '\$ ',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [AppMoneyInputFormatter(symbol: '')],
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'El precio de venta es requerido';
        }
        final price = _parsePriceFromController(_salePriceController);
        if (price <= 0) return 'Ingrese un precio válido mayor a 0';
        return null;
      },
    );
  }

  /// Campo de precio de compra
  Widget _buildPurchasePriceField() {
    return TextFormField(
      controller: _purchasePriceController,
      decoration: InputDecoration(
        labelText: 'Precio de compra',
        hintText: '0.00',
        prefixIcon: const Icon(Icons.shopping_basket_outlined),
        prefixText: '\$ ',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [AppMoneyInputFormatter(symbol: '')],
    );
  }

  /// Construye sección de inventario y control de stock
  Widget _buildInventorySection(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionHeader(
          context: context,
          title: 'Inventario y stock',
          icon: Icons.inventory_2_outlined,
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.3),
            ),
          ),
          child: SwitchListTile(
            value: _stockEnabled,
            onChanged: (value) => setState(() => _stockEnabled = value),
            title: const Text('Control de stock'),
            subtitle: const Text('Activa para rastrear cantidad disponible'),
            secondary: Icon(
              _stockEnabled ? Icons.inventory : Icons.inventory_outlined,
              color: _stockEnabled ? colorScheme.primary : null,
            ),
          ),
        ),
        if (_stockEnabled) ...[
          const SizedBox(height: 16),
          _buildQuantityField(),
          const SizedBox(height: 16),
          _buildAlertStockField(),
        ],
      ],
    );
  }

  /// Campo de cantidad en stock con validación
  Widget _buildQuantityField() {
    return TextFormField(
      controller: _quantityStockController,
      decoration: InputDecoration(
        labelText: 'Cantidad disponible',
        hintText: '0',
        prefixIcon: const Icon(Icons.numbers),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      keyboardType: TextInputType.number,
      validator: _stockEnabled
          ? (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Ingrese la cantidad';
              }
              final qty = int.tryParse(value);
              if (qty == null || qty < 0) return 'Ingrese una cantidad válida';
              return null;
            }
          : null,
    );
  }

  /// Campo de alerta de stock bajo
  Widget _buildAlertStockField() {
    return TextFormField(
      controller: _alertStockController,
      decoration: InputDecoration(
        labelText: 'Alerta de stock bajo',
        hintText: '5',
        prefixIcon: const Icon(Icons.notification_important_outlined),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        helperText: 'Se mostrará una alerta cuando el stock esté en este nivel',
      ),
      keyboardType: TextInputType.number,
    );
  }

  /// Construye sección de preferencias (categoría, proveedor, marca, favorito)
  Widget _buildPreferencesSection(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionHeader(
          context: context,
          title: 'Preferencias',
          icon: Icons.tune,
        ),
        const SizedBox(height: 20),
        _buildCategoryField(),
        const SizedBox(height: 16),
        _buildProviderField(),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.3),
            ),
          ),
          child: SwitchListTile(
            value: _favoriteEnabled,
            onChanged: (value) => setState(() => _favoriteEnabled = value),
            title: const Text('Producto favorito'),
            subtitle: const Text('Marca como favorito para acceso rápido'),
            secondary: Icon(
              _favoriteEnabled ? Icons.star : Icons.star_border,
              color: _favoriteEnabled ? Colors.amber.shade600 : null,
            ),
          ),
        ),
      ],
    );
  }

  /// Campo de categoría
  Widget _buildCategoryField() {
    return StreamBuilder<List<Category>>(
      stream: widget.catalogueProvider.getCategoriesStream(widget.accountId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }

        final categories = snapshot.data ?? [];

        return InkWell(
          onTap: () async {
            final selected = await showModalBottomSheet<Category>(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => SelectionModal<Category>(
                title: 'Seleccionar Categoría',
                items: categories,
                labelBuilder: (item) => item.name,
                idBuilder: (item) => item.id,
                selectedItem: _selectedCategoryId != null
                    ? categories.firstWhere((c) => c.id == _selectedCategoryId,
                        orElse: () => Category())
                    : null,
                searchHint: 'Buscar categoría...',
              ),
            );

            if (selected != null) {
              setState(() {
                _selectedCategoryId = selected.id;
                _categoryController.text = selected.name;
              });
            }
          },
          child: IgnorePointer(
            child: TextFormField(
              controller: _categoryController,
              decoration: InputDecoration(
                labelText: 'Categoría',
                hintText: 'Seleccionar categoría',
                prefixIcon: const Icon(Icons.category_outlined),
                suffixIcon: const Icon(Icons.arrow_drop_down),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Campo de proveedor
  Widget _buildProviderField() {
    return StreamBuilder<List<Provider>>(
      stream: widget.catalogueProvider.getProvidersStream(widget.accountId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }

        final providers = snapshot.data ?? [];

        return InkWell(
          onTap: () async {
            final selected = await showModalBottomSheet<Provider>(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => SelectionModal<Provider>(
                title: 'Seleccionar Proveedor',
                items: providers,
                labelBuilder: (item) => item.name,
                idBuilder: (item) => item.id,
                selectedItem: _selectedProviderId != null
                    ? providers.firstWhere((p) => p.id == _selectedProviderId,
                        orElse: () => Provider(id: '', name: ''))
                    : null,
                searchHint: 'Buscar proveedor...',
              ),
            );

            if (selected != null) {
              setState(() {
                _selectedProviderId = selected.id;
                _providerController.text = selected.name;
              });
            }
          },
          child: IgnorePointer(
            child: TextFormField(
              controller: _providerController,
              decoration: InputDecoration(
                labelText: 'Proveedor',
                hintText: 'Seleccionar proveedor',
                prefixIcon: const Icon(Icons.local_shipping_outlined),
                suffixIcon: const Icon(Icons.arrow_drop_down),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Campo de marca
  Widget _buildMarkField() {
    final isVerified = widget.product.verified;
    return StreamBuilder<List<Mark>>(
      stream: widget.catalogueProvider.getBrandsStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }

        final brands = snapshot.data ?? [];

        return InkWell(
          onTap: isVerified
              ? () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Row(
                        children: [
                          Icon(Icons.lock, color: Colors.white),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                                'No se puede modificar la marca de un producto verificado'),
                          ),
                        ],
                      ),
                      backgroundColor: Colors.orange.shade600,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              : () async {
                  final selected = await _showBrandSelectionModal(brands);

                  if (selected != null) {
                    setState(() {
                      _selectedBrandId = selected.id;
                      _markController.text = selected.name;
                    });
                  }
                },
          child: IgnorePointer(
            child: TextFormField(
              controller: _markController,
              decoration: InputDecoration(
                labelText: 'Marca',
                hintText: 'Seleccionar marca',
                prefixIcon: Icon(
                  isVerified
                      ? Icons.verified
                      : Icons.branding_watermark_outlined,
                  color: isVerified ? Colors.blue : null,
                ),
                suffixIcon: Icon(
                  isVerified ? Icons.lock : Icons.arrow_drop_down,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: isVerified
                    ? OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.blue.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                      )
                    : null,
              ),
            ),
          ),
        );
      },
    );
  }

  /// Muestra modal personalizado de selección de marca con botón para crear nueva
  Future<Mark?> _showBrandSelectionModal(
      List<Mark> brands) async {
    return showModalBottomSheet<Mark>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        final searchController = TextEditingController();

        return StatefulBuilder(
          builder: (context, setState) {
            // Filter brands based on search
            final query = searchController.text.toLowerCase().trim();
            final filteredBrands = query.isEmpty
                ? brands
                : brands.where((brand) {
                    return brand.name.toLowerCase().contains(query) ||
                        brand.description.toLowerCase().contains(query);
                  }).toList();

            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 8),
                      width: 32,
                      height: 4,
                      decoration: BoxDecoration(
                        color:
                            colorScheme.outlineVariant.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Seleccionar Marca',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close),
                          style: IconButton.styleFrom(
                            backgroundColor:
                                colorScheme.surfaceContainerHighest,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Search bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: TextField(
                      controller: searchController,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Buscar marca...',
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // List
                  Expanded(
                    child: filteredBrands.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.search_off_rounded,
                                  size: 64,
                                  color: colorScheme.outline
                                      .withValues(alpha: 0.5),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No se encontraron resultados',
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                // Botón para crear marca - solo si hay búsqueda
                                if (query.isNotEmpty) ...[
                                  const SizedBox(height: 24),
                                  TextButton.icon(
                                    onPressed: () async {
                                      final newBrand =
                                          await _showCreateBrandDialog();
                                      if (newBrand != null && context.mounted) {
                                        Navigator.of(context).pop(newBrand);
                                      }
                                    },
                                    icon: Icon(Icons.add_circle_outline,
                                        size: 20),
                                    label: Text('Crear "$query"'),
                                    style: TextButton.styleFrom(
                                      foregroundColor: colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: filteredBrands.length,
                            itemBuilder: (context, index) {
                              final brand = filteredBrands[index];
                              final isSelected = _selectedBrandId != null &&
                                  brand.id == _selectedBrandId;

                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 4),
                                leading: brand.image.isNotEmpty
                                    ? CircleAvatar(
                                        backgroundImage:
                                            NetworkImage(brand.image),
                                        backgroundColor:
                                            colorScheme.surfaceContainerHighest,
                                      )
                                    : CircleAvatar(
                                        backgroundColor:
                                            colorScheme.surfaceContainerHighest,
                                        child: Icon(Icons.branding_watermark,
                                            color:
                                                colorScheme.onSurfaceVariant),
                                      ),
                                title: Text(
                                  brand.name,
                                  style: TextStyle(
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color:
                                        isSelected ? colorScheme.primary : null,
                                  ),
                                ),
                                subtitle: brand.description.isNotEmpty
                                    ? Text(brand.description)
                                    : null,
                                trailing: isSelected
                                    ? Icon(Icons.check_circle,
                                        color: colorScheme.primary)
                                    : null,
                                onTap: () => Navigator.of(context).pop(brand),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Botón flotante de guardar
  Widget? _buildFab() {
    if (_isSaving) return null;
    return FloatingActionButton.extended(
      onPressed: _saveProduct,
      label: const Text('Guardar'),
    );
  }

  /// Encabezado de sección con ícono y título
  Widget _buildSectionHeader({
    required BuildContext context,
    required String title,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }

  /// Tarjeta contenedora con bordes redondeados
  Widget _buildCard({
    required BuildContext context,
    required Widget child,
  }) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context)
              .colorScheme
              .outlineVariant
              .withValues(alpha: 0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: child,
      ),
    );
  }

  /// Calcula el beneficio y porcentaje de ganancia
  ({double profit, double percentage, bool isProfitable})? _calculateProfit() {
    final salePrice = _parsePriceFromController(_salePriceController);
    final purchasePrice = _parsePriceFromController(_purchasePriceController);

    if (salePrice <= 0 || purchasePrice <= 0) return null;

    final profit = salePrice - purchasePrice;
    final percentage = (profit / purchasePrice) * 100;

    return (
      profit: profit,
      percentage: percentage,
      isProfitable: profit > 0,
    );
  }

  /// Preview del beneficio calculado con indicadores visuales
  Widget _buildProfitPreview() {
    final calculation = _calculateProfit();
    if (calculation == null) return const SizedBox.shrink();

    final profit = calculation.profit;
    final percentage = calculation.percentage;
    final isProfitable = calculation.isProfitable;

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isProfitable
            ? Colors.green.withValues(alpha: 0.08)
            : Colors.red.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isProfitable
              ? Colors.green.withValues(alpha: 0.3)
              : Colors.red.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isProfitable ? Icons.trending_up : Icons.trending_down,
            color: isProfitable ? Colors.green.shade700 : Colors.red.shade700,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isProfitable ? 'Beneficio estimado' : 'Pérdida estimada',
                  style: TextStyle(
                    fontSize: 12,
                    color: isProfitable
                        ? Colors.green.shade700
                        : Colors.red.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  CurrencyFormatter.formatPrice(value: profit.abs()),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isProfitable
                        ? Colors.green.shade700
                        : Colors.red.shade700,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isProfitable ? Colors.green : Colors.red,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${isProfitable ? '+' : ''}${percentage.toStringAsFixed(1)}%',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
