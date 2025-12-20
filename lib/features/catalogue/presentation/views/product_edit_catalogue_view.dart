import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sellweb/core/core.dart';
import 'package:sellweb/core/services/storage/i_storage_datasource.dart';
import 'package:sellweb/core/services/storage/storage_paths.dart';
import 'package:sellweb/core/di/injection_container.dart';
import 'package:sellweb/features/catalogue/domain/entities/product_catalogue.dart';
import 'package:sellweb/features/catalogue/domain/entities/category.dart';
import 'package:sellweb/features/catalogue/domain/entities/provider.dart'
    as catalog_provider;
import 'package:sellweb/features/catalogue/domain/entities/mark.dart';
import '../providers/catalogue_provider.dart';
import '../widgets/brand_search_dialog.dart';
import 'package:sellweb/features/catalogue/presentation/views/dialogs/category_dialog.dart';
import 'package:sellweb/features/catalogue/presentation/views/dialogs/provider_dialog.dart';

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
  final bool isCreatingMode;

  const ProductEditCatalogueView({
    super.key,
    required this.product,
    required this.catalogueProvider,
    required this.accountId,
    this.isCreatingMode = false,
  });

  @override
  State<ProductEditCatalogueView> createState() =>
      _ProductEditCatalogueViewState();
}

class _ProductEditCatalogueViewState extends State<ProductEditCatalogueView> {
  static const double _iconOpacity = 0.8;

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
  String? _selectedBrandImage;

  // Attributes
  Map<String, dynamic> _attributes = {};

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
    _selectedBrandImage =
        widget.product.imageMark.isNotEmpty ? widget.product.imageMark : null;
    _attributes = Map.from(widget.product.attributes);

    debugPrint(
        '🔍 ProductEdit: Inicializando con ${_attributes.length} atributos: $_attributes');
  }

  /// Configura listeners para recalcular beneficios y actualizar preview
  void _setupListeners() {
    _salePriceController.addListener(() => setState(() {}));
    _purchasePriceController.addListener(() => setState(() {}));
    _descriptionController.addListener(() => setState(() {}));
    _markController.addListener(() => setState(() {}));
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
    if (widget.product.isVerified) {
      final uniqueKey = UniqueKey();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          key: uniqueKey,
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
          margin: const EdgeInsets.only(
            bottom: 16,
            left: 16,
            right: 16,
          ),
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
        final uniqueKey = UniqueKey();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            key: uniqueKey,
            content: Text('Error al seleccionar imagen: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  /// Valida y guarda los cambios del producto
  ///
  /// Delega toda la lógica de negocio al [SaveProductUseCase]
  /// que determina el tipo de producto y aplica las reglas correspondientes.
  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final updatedProduct = _buildUpdatedProduct();

      // Detectar si cambiaron los precios para actualizar el timestamp upgrade
      final pricesChanged = widget.isCreatingMode ? true : _havePricesChanged();
      final shouldUpdateUpgrade = pricesChanged || _newImageBytes != null;

      // Delegar toda la lógica de negocio al Provider
      final result = await widget.catalogueProvider.saveProduct(
        product: updatedProduct,
        accountId: widget.accountId,
        isCreatingMode: widget.isCreatingMode,
        shouldUpdateUpgrade: shouldUpdateUpgrade,
        newImageBytes: _newImageBytes,
      );

      if (mounted) {
        setState(() => _isSaving = false);
        _showSuccessMessage(result.message);

        // Esperar un frame antes de hacer pop para evitar errores de renderizado
        await Future.delayed(const Duration(milliseconds: 100));
        if (mounted) {
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        _showErrorMessage(e.toString());
      }
    }
  }

  /// Construye el producto actualizado con los valores del formulario
  ProductCatalogue _buildUpdatedProduct() {
    final updated = widget.product.copyWith(
      description: widget.product.isVerified
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
      idMark: widget.product.isVerified
          ? widget.product.idMark
          : (_selectedBrandId ?? ''),
      nameMark: widget.product.isVerified
          ? widget.product.nameMark
          : _markController.text.trim(),
      imageMark: widget.product.isVerified
          ? widget.product.imageMark
          : (_selectedBrandImage ?? ''),
      stock: _stockEnabled,
      favorite: _favoriteEnabled,
      attributes: _attributes,
    );

    debugPrint(
        '🔍 ProductEdit: Guardando producto con ${_attributes.length} atributos: $_attributes');
    return updated;
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
  void _showSuccessMessage([String? customMessage]) {
    ScaffoldMessenger.of(context).clearSnackBars();
    final uniqueKey = UniqueKey();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        key: uniqueKey,
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(customMessage ??
                  (widget.isCreatingMode
                      ? 'Producto agregado correctamente'
                      : 'Producto actualizado correctamente')),
            ),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(
          bottom: 16,
          left: 16,
          right: 16,
        ),
      ),
    );
  }

  /// Muestra mensaje de error al guardar
  void _showErrorMessage(String error) {
    ScaffoldMessenger.of(context).clearSnackBars();
    final uniqueKey = UniqueKey();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        key: uniqueKey,
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
        margin: const EdgeInsets.only(
          bottom: 16,
          left: 16,
          right: 16,
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  /// Muestra diálogo de confirmación para eliminar producto
  Future<void> _showDeleteConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar producto?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Esta acción eliminará "${widget.product.description}" de tu catálogo.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            if (widget.product.isVerified || widget.product.isPending)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.blue.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: Colors.blue,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'El producto permanecerá en la base de datos global para otros comercios.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteProduct();
    }
  }

  /// Elimina el producto del catálogo
  Future<void> _deleteProduct() async {
    setState(() => _isSaving = true);

    try {
      await widget.catalogueProvider.deleteProduct(
        product: widget.product,
        accountId: widget.accountId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        final uniqueKey = UniqueKey();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            key: uniqueKey,
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                      'Producto "${widget.product.description}" eliminado'),
                ),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.only(
              bottom: 16,
              left: 16,
              right: 16,
            ),
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        final uniqueKey = UniqueKey();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            key: uniqueKey,
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Error al eliminar: $e'),
                ),
              ],
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.only(
              bottom: 16,
              left: 16,
              right: 16,
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  /// Muestra modal para crear o editar una marca
  Future<Mark?> _showBrandDialog({Mark? brand}) async {
    final isEditing = brand != null;
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: brand?.name);
    final descriptionController =
        TextEditingController(text: brand?.description);
    Uint8List? brandImageBytes;
    final picker = ImagePicker();
    bool isLoading = false;
    bool isVerified = brand?.verified ?? false;
    String currentImageUrl = brand?.image ?? '';

    return showModalBottomSheet<Mark>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final theme = Theme.of(context);
          final colorScheme = theme.colorScheme;

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
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                  child: Row(
                    children: [
                      Icon(
                        isEditing
                            ? Icons.edit
                            : Icons.branding_watermark_outlined,
                        color: colorScheme.primary,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          isEditing ? 'Editar Marca' : 'Crear Nueva Marca',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // Content
                Expanded(
                  child: Form(
                    key: formKey,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(
                          left: 24, right: 24, top: 24, bottom: 180),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Image picker
                          Center(
                            child: GestureDetector(
                              onTap: isLoading
                                  ? null
                                  : () async {
                                      try {
                                        final XFile? image =
                                            await picker.pickImage(
                                          source: ImageSource.gallery,
                                          maxWidth: 512,
                                          maxHeight: 512,
                                          imageQuality: 85,
                                        );
                                        if (image != null) {
                                          final bytes =
                                              await image.readAsBytes();
                                          setState(() {
                                            brandImageBytes = bytes;
                                          });
                                        }
                                      } catch (e) {
                                        if (context.mounted) {
                                          final uniqueKey = UniqueKey();
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              key: uniqueKey,
                                              content: Text(
                                                  'Error al seleccionar imagen: $e'),
                                              backgroundColor:
                                                  colorScheme.error,
                                            ),
                                          );
                                        }
                                      }
                                    },
                              child: Container(
                                width: 140,
                                height: 140,
                                decoration: BoxDecoration(
                                  color: (brandImageBytes != null ||
                                          currentImageUrl.isNotEmpty)
                                      ? Colors.transparent
                                      : colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: brandImageBytes != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(14),
                                        child: Image.memory(
                                          brandImageBytes!,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : currentImageUrl.isNotEmpty
                                        ? ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(14),
                                            child: Image.network(
                                              currentImageUrl,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                return _buildImagePlaceholder(
                                                    colorScheme,
                                                    theme,
                                                    isEditing);
                                              },
                                            ),
                                          )
                                        : _buildImagePlaceholder(
                                            colorScheme, theme, isEditing),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Name field
                          TextFormField(
                            controller: nameController,
                            enabled: !isLoading,
                            textCapitalization: TextCapitalization.words,
                            decoration: InputDecoration(
                              labelText: 'Nombre de la marca *',
                              hintText: 'Ej: Coca-Cola',
                              prefixIcon: const Opacity(
                                opacity: _iconOpacity,
                                child: Icon(Icons.label_outlined),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'El nombre es requerido';
                              }
                              if (value.trim().length < 2) {
                                return 'El nombre debe tener al menos 2 caracteres';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          // Description field
                          TextFormField(
                            controller: descriptionController,
                            enabled: !isLoading,
                            keyboardType: TextInputType.multiline,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: InputDecoration(
                              labelText: 'Descripción (opcional)',
                              hintText: 'Información adicional sobre la marca',
                              prefixIcon: const Opacity(
                                opacity: _iconOpacity,
                                child: Icon(Icons.description_outlined),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            minLines: 1,
                            maxLines: null,
                            maxLength: 200,
                          ),
                          const SizedBox(height: 16),
                          // Verification switch
                          SwitchListTile(
                            title: const Text('Marca verificada'),
                            subtitle: const Text(
                                'Indica si la marca es oficial y reconocida'),
                            value: isVerified,
                            onChanged: isLoading
                                ? null
                                : (value) => setState(() => isVerified = value),
                            secondary: Opacity(
                              opacity: _iconOpacity,
                              child: Icon(
                                Icons.verified,
                                color: isVerified
                                    ? Colors.blue
                                    : colorScheme.onSurfaceVariant,
                              ),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color:
                                    colorScheme.outline.withValues(alpha: 0.2),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Actions : Guardar y Cancelar con degradado
                Stack(
                  children: [
                    // Degradado transparente
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        height: 100,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              colorScheme.surface.withValues(alpha: 0.0),
                              colorScheme.surface.withValues(alpha: 0.8),
                              colorScheme.surface,
                            ],
                            stops: const [0.0, 0.5, 1.0],
                          ),
                        ),
                      ),
                    ),
                    // Contenedor de botones
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        border: Border(
                          top: BorderSide(
                            color: colorScheme.outlineVariant
                                .withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: isLoading
                                  ? null
                                  : () => Navigator.of(context).pop(),
                              child: const Text('Cancelar'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: FilledButton(
                              onPressed: isLoading
                                  ? null
                                  : () async {
                                      if (!formKey.currentState!.validate())
                                        return;

                                      setState(() => isLoading = true);

                                      try {
                                        String brandId = brand?.id ??
                                            IdGenerator.generateBrandId();
                                        String imageUrl = currentImageUrl;

                                        if (brandImageBytes != null) {
                                          final storage =
                                              getIt<IStorageDataSource>();
                                          final path =
                                              StoragePaths.publicBrandImage(
                                                  brandId);
                                          imageUrl = await storage.uploadFile(
                                            path,
                                            brandImageBytes!,
                                            metadata: {
                                              'contentType': 'image/jpeg',
                                              'uploaded_by': 'user',
                                            },
                                          );
                                        }

                                        final finalBrand = isEditing
                                            ? brand.copyWith(
                                                name:
                                                    nameController.text.trim(),
                                                description:
                                                    descriptionController.text
                                                        .trim(),
                                                image: imageUrl,
                                                verified: isVerified,
                                                upgrade: DateTime.now(),
                                              )
                                            : Mark(
                                                id: brandId,
                                                name: nameController.text
                                                    .trim()
                                                    .toLowerCase(),
                                                description:
                                                    descriptionController.text
                                                        .trim()
                                                        .toLowerCase(),
                                                image: imageUrl,
                                                verified: isVerified,
                                                creation: DateTime.now(),
                                                upgrade: DateTime.now(),
                                              );

                                        if (isEditing) {
                                          await widget.catalogueProvider
                                              .updateBrand(finalBrand);
                                        } else {
                                          await widget.catalogueProvider
                                              .createBrand(finalBrand);
                                        }

                                        if (context.mounted) {
                                          Navigator.of(context).pop(finalBrand);
                                          _showSuccessMessage(isEditing
                                              ? 'Marca actualizada exitosamente'
                                              : 'Marca creada exitosamente');
                                        }
                                      } catch (e) {
                                        setState(() => isLoading = false);
                                        if (context.mounted) {
                                          _showErrorMessage(e.toString());
                                        }
                                      }
                                    },
                              child: Text(isLoading
                                  ? (isEditing ? 'Guardando...' : 'Creando...')
                                  : (isEditing ? 'Guardar' : 'Crear')),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildImagePlaceholder(
      ColorScheme colorScheme, ThemeData theme, bool isEditing) {
    return Icon(
      Icons.add_photo_alternate,
      size: 48,
      color: colorScheme.primary.withValues(alpha: 0.7),
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
    // Determinar el título según el estado del producto
    String title;
    if (widget.product.id.isEmpty ||
        !widget.product.creation.isAfter(DateTime(2000))) {
      // Producto nuevo que no existe en ningún lado
      title = 'Nuevo producto';
    } else {
      // Producto que ya existe en el catálogo
      title = 'Editar producto';
    }

    return AppBar(
      title: Text(title),
      centerTitle: false,
      actions: [
        // Botón eliminar (solo en modo edición)
        if (!widget.isCreatingMode && !_isSaving)
          IconButton(
            padding: const EdgeInsets.all(16.0),
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Eliminar producto',
            onPressed: _showDeleteConfirmation,
          ),
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
                _buildPreviewProductCard(),
                const SizedBox(height: 24),
                _buildBasicInfoSection(colorScheme),
                const SizedBox(height: 24),
                // Solo mostrar atributos si no está verificado o si tiene atributos
                if (!widget.product.isVerified || _attributes.isNotEmpty) ...[
                  _buildAttributesSection(colorScheme),
                  const SizedBox(height: 24),
                ],
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

  /// Construye sección de atributos dinámicos
  Widget _buildAttributesSection(ColorScheme colorScheme) {
    final isVerified = widget.product.isVerified;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionHeader(
          context: context,
          title: 'Atributos',
          icon: Icons.label_outline,
        ),
        if (_attributes.isEmpty) ...[
          const SizedBox(height: 16),
          if (!isVerified)
            InkWell(
              onTap: _showAddAttributeDialog,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: colorScheme.outline.withValues(alpha: 0.3),
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add,
                      size: 18,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Agregar atributo',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.primary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: colorScheme.outline.withValues(alpha: 0.3),
                ),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Producto verificado',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'sin atributos',
                    style: TextStyle(
                      fontSize: 11,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
        ] else ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ..._attributes.entries.map((entry) {
                final value = entry.value;
                final String displayValue =
                    value is List ? value.join(', ') : value?.toString() ?? '';

                return InkWell(
                  onTap: !isVerified
                      ? () => _showAddAttributeDialog(
                            editKey: entry.key,
                            editValue: entry.value,
                          )
                      : null,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: colorScheme.outline.withValues(alpha: 0.3),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          entry.key,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.primary,
                            fontSize: 12,
                          ),
                        ),
                        if (displayValue.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            displayValue,
                            style: TextStyle(
                              fontSize: 11,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }),
              if (!isVerified)
                InkWell(
                  onTap: _showAddAttributeDialog,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colorScheme.primary.withValues(alpha: 0.25),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.add,
                          size: 16,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Agregar',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: colorScheme.primary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }

  void _showDeleteAttributeDialog(String attributeKey) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar atributo?'),
        content: Text(
          'Estás a punto de eliminar el atributo "$attributeKey". Esta acción no se puede deshacer.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              setState(() {
                _attributes.remove(attributeKey);
              });
              Navigator.pop(context);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _showAddAttributeDialog({String? editKey, dynamic editValue}) {
    final keyController = TextEditingController(text: editKey);
    final formKey = GlobalKey<FormState>();

    // Lista de variantes con controladores editables
    final List<TextEditingController> variantControllers = [];

    // Inicializar controladores con valores existentes
    if (editValue is List) {
      for (var variant in editValue) {
        if (variant.toString().isNotEmpty) {
          variantControllers
              .add(TextEditingController(text: variant.toString()));
        }
      }
    } else if (editValue != null && editValue.toString().isNotEmpty) {
      variantControllers.add(TextEditingController(text: editValue.toString()));
    }

    // Para nuevos atributos, las variantes son opcionales, no agregar campo inicial

    showDialog(
      context: context,
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        final isEditing = editKey != null;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color:
                          colorScheme.primaryContainer.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isEditing ? Icons.edit_outlined : Icons.label_outline,
                      color: colorScheme.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child:
                        Text(isEditing ? 'Editar atributo' : 'Nuevo atributo'),
                  ),
                  if (isEditing)
                    IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _showDeleteAttributeDialog(editKey);
                      },
                      icon: Icon(
                        Icons.delete_outline,
                        color: colorScheme.error,
                      ),
                      tooltip: 'Eliminar atributo',
                    ),
                ],
              ),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Campo: Nombre del atributo
                      TextFormField(
                        controller: keyController,
                        enabled: !isEditing,
                        autofocus: !isEditing,
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(
                          labelText: 'Nombre del atributo',
                          hintText: 'ej. Color, Talle, Peso',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Ingrese el nombre del atributo';
                          }
                          if (!isEditing &&
                              _attributes.containsKey(value.trim())) {
                            return 'Este atributo ya existe';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Lista de variantes editables
                      Row(
                        children: [
                          Text(
                            'Variantes',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '(Opcional)',
                            style: TextStyle(
                              fontSize: 11,
                              color: colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.6),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Items de variantes en lista
                      Container(
                        constraints: const BoxConstraints(maxHeight: 250),
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              ...List.generate(variantControllers.length,
                                  (index) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: colorScheme.outline
                                            .withValues(alpha: 0.3),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: TextField(
                                            controller:
                                                variantControllers[index],
                                            textCapitalization:
                                                TextCapitalization.sentences,
                                            decoration: InputDecoration(
                                              hintText: 'Escribe la variante',
                                              border: InputBorder.none,
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 12,
                                              ),
                                            ),
                                          ),
                                        ),
                                        if (variantControllers.length > 1)
                                          IconButton(
                                            icon: Icon(
                                              Icons.close,
                                              size: 18,
                                              color: colorScheme.error,
                                            ),
                                            onPressed: () {
                                              setDialogState(() {
                                                variantControllers[index]
                                                    .dispose();
                                                variantControllers
                                                    .removeAt(index);
                                              });
                                            },
                                            tooltip: 'Eliminar',
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Botón agregar variante
                      InkWell(
                        onTap: () {
                          setDialogState(() {
                            variantControllers.add(TextEditingController());
                          });
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: colorScheme.primary.withValues(alpha: 0.4),
                              style: BorderStyle.solid,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add,
                                size: 18,
                                color: colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Agregar variante',
                                style: TextStyle(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.w500,
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
              actions: [
                TextButton(
                  onPressed: () {
                    for (var controller in variantControllers) {
                      controller.dispose();
                    }
                    Navigator.pop(context);
                  },
                  child: const Text('Cancelar'),
                ),
                FilledButton.icon(
                  onPressed: () => _submitAttribute(
                    formKey,
                    keyController,
                    variantControllers,
                    isEditing,
                    editKey,
                  ),
                  icon: Icon(isEditing ? Icons.check : Icons.add, size: 20),
                  label: Text(isEditing ? 'Guardar' : 'Agregar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Método auxiliar para enviar el atributo
  void _submitAttribute(
    GlobalKey<FormState> formKey,
    TextEditingController keyController,
    List<TextEditingController> variantControllers,
    bool isEditing,
    String? oldKey,
  ) {
    if (!formKey.currentState!.validate()) return;

    final key = keyController.text.trim();

    // Extraer valores de los controladores y filtrar vacíos
    final variants = variantControllers
        .map((controller) => controller.text.trim())
        .where((text) => text.isNotEmpty)
        .toList();

    setState(() {
      // Si está editando y cambió la key, eliminar la anterior
      if (isEditing && oldKey != null && oldKey != key) {
        _attributes.remove(oldKey);
      }

      // Guardar: si hay variantes, guardar como string (1) o lista (2+), sino guardar como lista vacía
      if (variants.isEmpty) {
        _attributes[key] = [];
      } else if (variants.length == 1) {
        _attributes[key] = variants.first;
      } else {
        _attributes[key] = variants.toList();
      }
    });

    // Limpiar controladores
    for (var controller in variantControllers) {
      controller.dispose();
    }

    Navigator.pop(context);
  }

  /// Construye sección de imagen del producto
  Widget _buildPreviewProductCard() {
    final isVerified = widget.product.isVerified;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionHeader(
          context: context,
          title: 'Vista previa',
          icon: Icons.preview_outlined,
        ),
        const SizedBox(height: 12),
        Center(
          // tarjeta: vista previa del producto con botones
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Botón de favorito (izquierda)
              Container(
                decoration: BoxDecoration(
                  color: _favoriteEnabled
                      ? Colors.amber.withValues(alpha: 0.15)
                      : colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                  border: _favoriteEnabled
                      ? Border.all(
                          color: Colors.amber.withValues(alpha: 0.3),
                          width: 1.5,
                        )
                      : null,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () =>
                        setState(() => _favoriteEnabled = !_favoriteEnabled),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        _favoriteEnabled ? Icons.star : Icons.star_border,
                        color: _favoriteEnabled
                            ? Colors.amber.shade600
                            : colorScheme.onSurfaceVariant,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Tarjeta del producto
              SizedBox(
                width: 200,
                height: 200,
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  color: (_newImageBytes != null ||
                          widget.product.image.isNotEmpty)
                      ? Colors.transparent
                      : colorScheme.surfaceContainerHighest,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  elevation: 0.0,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      //  Contenedor de la imagen del producto o imagen por defecto
                      Expanded(
                        child: SizedBox(
                          width: double.infinity,
                          child: _newImageBytes != null
                              ? Image.memory(
                                  _newImageBytes!,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                )
                              : ProductImage(
                                  imageUrl: widget.product.image,
                                  fit: BoxFit.cover,
                                  productDescription:
                                      _descriptionController.text,
                                ),
                        ),
                      ),

                      // Nombre del producto
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHigh,
                          border: Border(
                            top: BorderSide(
                              color: colorScheme.outline.withValues(alpha: 0.1),
                              width: 1,
                            ),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _descriptionController.text.isNotEmpty
                                  ? _descriptionController.text
                                  : 'Producto sin nombre',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: colorScheme.onSurface,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            // Precio de venta
                            Text(
                              _salePriceController.text.isNotEmpty
                                  ? '\$${_salePriceController.text}'
                                  : '\$0.00',
                              style: TextStyle(
                                color: colorScheme.primary,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Botón de editar imagen (derecha) - solo si no es verificado
              if (!isVerified)
                Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _pickImage,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Icon(
                          Icons.image_outlined,
                          color: colorScheme.primary,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                )
              else
                const SizedBox(
                    width: 44), // Espacio equivalente cuando no hay botón
            ],
          ),
        ),
      ],
    );
  }

  /// Construye sección de información básica (descripción y código)
  Widget _buildBasicInfoSection(ColorScheme colorScheme) {
    final theme = Theme.of(context);
    final code = widget.product.code;
    final isValidCode = BarcodeValidator.isValid(code);
    final formattedDescription = BarcodeValidator.getFormattedDescription(code);
    final displayLabel = formattedDescription ??
        (isValidCode ? 'Código válido' : 'Personalizado');

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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.outline.withValues(alpha: 0.2),
                  width: 1.0,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isValidCode ? Icons.public : Icons.store,
                    color: isValidCode ? Colors.green : Colors.orange.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Código de barras',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: isValidCode
                                    ? Colors.green.withValues(alpha: 0.15)
                                    : Colors.orange.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                displayLabel,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: isValidCode
                                      ? Colors.green.shade700
                                      : Colors.orange.shade700,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
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
            if (widget.product.isVerified) ...[
              // Campo de descripción (solo lectura)
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colorScheme.outline.withValues(alpha: 0.2),
                    width: 1.0,
                  ),
                ),
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
                keyboardType: TextInputType.multiline,
                decoration: InputDecoration(
                  labelText: 'Descripción del producto *',
                  hintText: 'Ej: Coca Cola 2L',
                  prefixIcon: const Opacity(
                    opacity: _iconOpacity,
                    child: Icon(Icons.description_outlined),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                minLines: 1,
                maxLines: null,
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
            if (widget.product.isVerified) ...[
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colorScheme.outline.withValues(alpha: 0.2),
                    width: 1.0,
                  ),
                ),
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
                        if (widget.product.imageMark.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(right: 10.0),
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                image: DecorationImage(
                                  image: NetworkImage(widget.product.imageMark),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          )
                        else
                          const Icon(
                            Icons.check_circle,
                            color: Colors.blue,
                            size: 18,
                          ),
                        const SizedBox(width: 4),
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
        labelText: 'Precio de venta',
        hintText: '0.00',
        prefixIcon: const Opacity(
          opacity: _iconOpacity,
          child: Icon(Icons.public_sharp),
        ),
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
        prefixIcon: const Opacity(
          opacity: _iconOpacity,
          child: Icon(Icons.inventory_2_outlined),
        ),
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
              color: colorScheme.primary.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: SwitchListTile(
            value: _stockEnabled,
            onChanged: (value) => setState(() => _stockEnabled = value),
            title: const Text('Control de stock'),
            subtitle: const Text('Activa para rastrear cantidad disponible'),
            secondary: Opacity(
              opacity: _iconOpacity,
              child: Icon(
                Icons.inventory_outlined,
                color: _stockEnabled ? colorScheme.primary : null,
              ),
            ),
          ),
        ),
        if (_stockEnabled) ...[
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: _buildQuantityField(),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: _buildAlertStockField(),
          ),
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
                searchHint: 'Buscar',
                onAdd: () => showCategoryDialog(
                  context,
                  catalogueProvider: widget.catalogueProvider,
                  accountId: widget.accountId,
                ),
                labelButton: 'Crear categoría',
                onButton: (item) => showCategoryDialog(
                  context,
                  catalogueProvider: widget.catalogueProvider,
                  accountId: widget.accountId,
                  category: item,
                ),
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
                prefixIcon: const Opacity(
                  opacity: _iconOpacity,
                  child: Icon(Icons.category_outlined),
                ),
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
    return StreamBuilder<List<catalog_provider.Provider>>(
      stream: widget.catalogueProvider.getProvidersStream(widget.accountId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }

        final providers = snapshot.data ?? [];

        return InkWell(
          onTap: () async {
            final selected =
                await showModalBottomSheet<catalog_provider.Provider>(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => SelectionModal<catalog_provider.Provider>(
                title: 'Seleccionar Proveedor',
                items: providers,
                labelBuilder: (item) => item.name,
                idBuilder: (item) => item.id,
                selectedItem: _selectedProviderId != null
                    ? providers.firstWhere((p) => p.id == _selectedProviderId,
                        orElse: () =>
                            catalog_provider.Provider(id: '', name: ''))
                    : null,
                searchHint: 'Buscar',
                onAdd: () => showProviderDialog(
                  context,
                  catalogueProvider: widget.catalogueProvider,
                  accountId: widget.accountId,
                ),
                labelButton: 'Crear proveedor',
                onButton: (item) => showProviderDialog(
                  context,
                  catalogueProvider: widget.catalogueProvider,
                  accountId: widget.accountId,
                  provider: item,
                ),
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
                prefixIcon: const Opacity(
                  opacity: _iconOpacity,
                  child: Icon(Icons.local_shipping_outlined),
                ),
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

  /// Campo de marca con búsqueda optimizada
  Widget _buildMarkField() {
    final isVerified = widget.product.isVerified;

    return InkWell(
      onTap: isVerified
          ? () {
              final uniqueKey = UniqueKey();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  key: uniqueKey,
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
                  margin: const EdgeInsets.only(
                    bottom: 16,
                    left: 16,
                    right: 16,
                  ),
                ),
              );
            }
          : () => _showBrandSearchDialog(),
      child: IgnorePointer(
        child: TextFormField(
          controller: _markController,
          decoration: InputDecoration(
            labelText: 'Buscar marca',
            prefixIcon:
                _selectedBrandImage != null && _selectedBrandImage!.isNotEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            image: DecorationImage(
                              image: NetworkImage(_selectedBrandImage!),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      )
                    : Icon(
                        isVerified
                            ? Icons.verified
                            : Icons.branding_watermark_outlined,
                        color: isVerified ? Colors.blue : null,
                      ),
            suffixIcon: Icon(
              isVerified ? Icons.lock : Icons.search,
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
  }

  /// Muestra modal de búsqueda de marca optimizado
  Future<void> _showBrandSearchDialog() async {
    final result = await showModalBottomSheet<Mark>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BrandSearchDialog(
        catalogueProvider: widget.catalogueProvider,
        currentBrandId: _selectedBrandId,
        currentBrandName: _markController.text,
        onCreateNewBrand: () async {
          final newBrand = await _showBrandDialog();
          if (newBrand != null && mounted) {
            setState(() {
              _selectedBrandId = newBrand.id;
              _markController.text = newBrand.name;
              _selectedBrandImage = newBrand.image;
            });
          }
        },
        onEditBrand: (brand) async {
          final updatedBrand = await _showBrandDialog(brand: brand);
          if (updatedBrand != null && mounted) {
            setState(() {
              _selectedBrandId = updatedBrand.id;
              _markController.text = updatedBrand.name;
              _selectedBrandImage = updatedBrand.image;
            });
          }
        },
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _selectedBrandId = result.id;
        _markController.text = result.name;
        _selectedBrandImage = result.image;
      });
    }
  }

  /// Botón flotante de guardar
  Widget? _buildFab() {
    if (_isSaving) return null;

    // Determinar el texto del botón según el estado del producto
    String buttonText;
    if (widget.product.id.isEmpty ||
        !widget.product.creation.isAfter(DateTime(2000))) {
      // Producto nuevo que no existe en ningún lado
      buttonText = 'Crear';
    } else if (widget.isCreatingMode) {
      // Producto que existe en la BD global pero no en el catálogo
      buttonText = 'Agregar';
    } else {
      // Producto que ya existe en el catálogo
      buttonText = 'Actualizar';
    }

    return FloatingActionButton.extended(
      heroTag: 'product_edit_save_fab',
      onPressed: _saveProduct,
      label: Text(buttonText),
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
