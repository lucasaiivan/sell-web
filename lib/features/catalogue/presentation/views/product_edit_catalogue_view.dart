import 'package:flutter/material.dart'; 
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sellweb/core/core.dart';
import 'package:sellweb/core/services/storage/i_storage_datasource.dart';
import 'package:sellweb/core/services/storage/storage_paths.dart';
import 'package:sellweb/core/di/injection_container.dart';
import 'package:sellweb/features/catalogue/domain/entities/product_catalogue.dart';
import 'package:sellweb/features/catalogue/domain/entities/category.dart';
import 'package:sellweb/features/catalogue/domain/entities/provider.dart' as catalog_provider;
import 'package:sellweb/features/catalogue/domain/entities/mark.dart';
import '../providers/catalogue_provider.dart';
import '../widgets/brand_search_dialog.dart';
import '../widgets/margin_calculator_card.dart';
import 'package:sellweb/core/presentation/widgets/quantity_selector.dart';
import 'package:sellweb/features/catalogue/presentation/views/dialogs/category_dialog.dart';
import 'package:sellweb/features/catalogue/presentation/views/dialogs/provider_dialog.dart';
import 'package:sellweb/features/catalogue/domain/entities/combo_item.dart'; 
import 'package:sellweb/core/presentation/widgets/success/process_success_view.dart'; 

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
  final bool isCombo;

  const ProductEditCatalogueView({
    super.key,
    required this.product,
    required this.catalogueProvider,
    required this.accountId,
    this.isCreatingMode = false,
    this.isCombo = false,
  });

  @override
  State<ProductEditCatalogueView> createState() =>
      _ProductEditCatalogueViewState();
}

class _ProductEditCatalogueViewState extends State<ProductEditCatalogueView> {
  static const double _iconOpacity = 0.8;

  // Unidades de venta disponibles
  // Unidades de venta disponibles
  static List<String> get _commonUnits => UnitConstants.validUnits;

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
  late final AppMoneyTextEditingController _salePriceController; // precio de venta
  late final AppMoneyTextEditingController _purchasePriceController;

  double _quantityStock = 0;
  double _alertStock = 0;
  late final TextEditingController _categoryController;
  late final TextEditingController _providerController;
  late final TextEditingController _markController;
  late final TextEditingController _unitController;

  // IVA state
  int _selectedIva = 0;
  int _revenuePercentage = 0;
  // Selected IDs
  String? _selectedCategoryId;
  String? _selectedProviderId;
  String? _selectedBrandId;
  String? _selectedBrandImage;

  // Variants
  Map<String, dynamic> _variants = {};
  
  // Calculator reset key (incrementa cuando el usuario edita el precio final manualmente)
  int _calculatorResetKey = 0;

  // Combo state
  bool _isCombo = false;
  List<ComboItem> _comboItems = [];
  DateTime? _comboExpiration;
  final TextEditingController _expirationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    
    // Inicializar isCombo desde el parámetro del widget
    _isCombo = widget.isCombo || widget.product.isCombo;
    _initializeControllers();
    _initializeState();
    _setupListeners();
  }

  /// Inicializa los controllers con valores del producto
  void _initializeControllers() {
    final product = widget.product;
    _descriptionController = TextEditingController(text: product.description);
    _salePriceController = AppMoneyTextEditingController(
      value: product.salePrice > 0
          ? CurrencyFormatter.formatPrice(value: product.salePrice, moneda: '')
          : '',
    );
    _purchasePriceController = AppMoneyTextEditingController(
      value: product.purchasePrice > 0
          ? CurrencyFormatter.formatPrice(
              value: product.purchasePrice, moneda: '')
          : '',
    );
    _quantityStock = product.quantityStock;
    _alertStock = product.alertStock;
    _categoryController = TextEditingController(text: product.nameCategory);
    _providerController = TextEditingController(text: product.nameProvider);
    _markController = TextEditingController(text: product.nameMark);
    _unitController = TextEditingController(text: product.unit);
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
    _variants = Map.from(widget.product.variants);

    debugPrint(
        '🔍 ProductEdit: Inicializando con ${_variants.length} variantes: $_variants');
        
    // Inicializar estado de combo
    _isCombo = widget.isCombo || widget.product.isCombo;
    _comboItems = List.from(widget.product.comboItems);
    _comboExpiration = widget.product.comboExpiration;
    if (_comboExpiration != null) {
      _expirationController.text = '${_comboExpiration!.day}/${_comboExpiration!.month}/${_comboExpiration!.year}'; 
    }
    
    // Inicializar IVA y Margen
    _selectedIva = widget.product.iva;
    _revenuePercentage = widget.product.revenuePercentage;
  }

  /// Configura listeners para recalcular beneficios y actualizar preview
  /// 
  /// Verifica [mounted] antes de llamar a [setState] para evitar errores
  /// cuando el widget ya ha sido eliminado del árbol de widgets.
  void _setupListeners() {
    _salePriceController.addListener(() {
      if (mounted) {
        setState(() {
          // Incrementar el contador para resetear la calculadora
          // cada vez que el usuario edita el precio final principal
          _calculatorResetKey++;
        });
      }
    });
    _purchasePriceController.addListener(() {
      if (mounted) setState(() {});
    });
    _descriptionController.addListener(() {
      if (mounted) setState(() {});
    });
    _markController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _salePriceController.dispose();
    _purchasePriceController.dispose();
    _categoryController.dispose();
    _providerController.dispose();
    _markController.dispose();
    _unitController.dispose();
    _expirationController.dispose();
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
  ///
  /// Usa [ProcessSuccessView] para proporcionar feedback visual consistente
  /// tanto para creación como para actualización.
  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    // Usar ProcessSuccessView para ambos casos: creación y actualización
    _saveProductWithSuccessView();
  }

  /// Guarda el producto usando la vista de éxito
  ///
  /// Utilizado tanto para creación como para actualización.
  /// Proporciona feedback visual inmersivo con [ProcessSuccessView].
  void _saveProductWithSuccessView() {
    // Determinar textos según modo de edición
    final bool isCreating = widget.isCreatingMode;
    final String loadingText = isCreating
        ? (_isCombo ? 'Creando combo...' : 'Creando producto...')
        : (_isCombo ? 'Actualizando combo...' : 'Actualizando producto...');
    final String successTitle = isCreating
        ? (_isCombo ? '¡Combo Creado!' : '¡Producto Creado!')
        : (_isCombo ? '¡Combo Actualizado!' : '¡Producto Actualizado!');

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ProcessSuccessView(
          loadingText: loadingText,
          successTitle: successTitle,
          successSubtitle: _descriptionController.text.trim(),
          finalText: null, // No mostrar "Redirigiendo..." para guardar
          // popCount: 2 = cerrar ProcessSuccessView + cerrar ProductEditView
          // El resultado del action se usará automáticamente para el último pop
          popCount: 2,
          action: () async {
            final updatedProduct = _buildUpdatedProduct();

            // Detectar si cambiaron los precios para actualizar el timestamp upgrade
            final pricesChanged = isCreating ? true : _havePricesChanged();
            final shouldUpdateUpgrade = pricesChanged || _newImageBytes != null;

            // Ejecutar guardado
            final result = await widget.catalogueProvider.saveProduct(
              product: updatedProduct,
              accountId: widget.accountId,
              isCreatingMode: isCreating,
              shouldUpdateUpgrade: shouldUpdateUpgrade,
              newImageBytes: _newImageBytes,
            );

            // Pequeña espera para asegurar propagación de Firestore
            await Future.delayed(const Duration(milliseconds: 300));

            // Retornar el producto guardado como resultado para el pop
            return result.updatedProduct;
          },
          onError: (error) {
            Navigator.of(context).pop(); // Cerrar ProcessSuccessView
            _showErrorMessage(error.toString());
          },
        ),
      ),
    );
  }

  /// Construye el producto actualizado con los valores del formulario
  ProductCatalogue _buildUpdatedProduct() {
    // Parsear cantidad de stock (soporta decimales para unidades fraccionarias)
    final stockValue = _quantityStock;

    final updated = widget.product.copyWith(
      description: widget.product.isVerified
          ? widget.product.description
          : _descriptionController.text.trim(),
      salePrice: _salePriceController.doubleValue,
      purchasePrice: _purchasePriceController.doubleValue,
      quantityStock: stockValue,
      alertStock: _alertStock,
      category: _selectedCategoryId ?? '',
      nameCategory: _categoryController.text.trim(),
      provider: _selectedProviderId ?? '',
      nameProvider: _providerController.text.trim(),
      unit: widget.product.isVerified
          ? widget.product.unit
          : _unitController.text.trim(),
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
      variants: _variants,
      iva: _selectedIva,
      revenuePercentage: _revenuePercentage,
      comboItems: _isCombo ? _comboItems : [],
      comboExpiration: _isCombo ? _comboExpiration : null,
      status: widget.product.status, // Mantener status original
    );
    return updated;
  }



  bool _havePricesChanged() {
    final newSalePrice = _salePriceController.doubleValue;
    final newPurchasePrice = _purchasePriceController.doubleValue;
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
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.blue.withOpacity(0.3),
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

  /// Elimina el producto del catálogo usando ProcessSuccessView
  ///
  /// Proporciona feedback visual inmersivo durante el proceso de eliminación.
  /// Maneja errores de manera consistente con el resto de operaciones CRUD.
  Future<void> _deleteProduct() async {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ProcessSuccessView(
          loadingText: _isCombo ? 'Eliminando combo...' : 'Eliminando producto...',
          successTitle: _isCombo ? '¡Combo Eliminado!' : '¡Producto Eliminado!',
          successSubtitle: widget.product.description,
          finalText: null, // No mostrar "Redirigiendo..." para eliminar
          playSound: false, // No reproducir sonido de éxito para eliminación
          // popCount: 2 = cerrar ProcessSuccessView + cerrar ProductEditView
          // popResult: null indica que el producto fue eliminado
          popCount: 2,
          popResult: null,
          action: () async {
            // Ejecutar eliminación
            await widget.catalogueProvider.deleteProduct(
              product: widget.product,
              accountId: widget.accountId,
            );

            // Pequeña espera para asegurar propagación de Firestore
            await Future.delayed(const Duration(milliseconds: 300));
          },
          onError: (error) {
            Navigator.of(context).pop(); // Cerrar ProcessSuccessView
            _showErrorMessage(error.toString());
          },
        ),
      ),
    );
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
                                    colorScheme.outline.withOpacity(0.2),
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
                              colorScheme.surface.withOpacity(0.0),
                              colorScheme.surface.withOpacity(0.8),
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
                                .withOpacity(0.3),
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
      color: colorScheme.primary.withOpacity(0.7),
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
      title = _isCombo ? 'Nuevo combo' : 'Nuevo producto';
    } else {
      // Producto que ya existe en el catálogo
      title = _isCombo ? 'Editar combo' : 'Editar producto';
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
                // Preview Card
                _buildPreviewProductCard(),
                const SizedBox(height: 24),
                
                // Información Básica (siempre visible)
                _buildBasicInfoSection(colorScheme),
                const SizedBox(height: 24),
                
                // Variantes (solo en modo producto no verificado)
                if (!_isCombo && (!widget.product.isVerified || _variants.isNotEmpty)) ...[
                  _buildVariantsSection(colorScheme),
                  const SizedBox(height: 24),
                ],
                
                // Precios y costos (siempre visible)
                _buildPricingSection(),
                const SizedBox(height: 24),
                
                // Contenido del Combo (solo en modo combo)
                if (_isCombo) ...[
                  _buildComboSection(colorScheme),
                  const SizedBox(height: 24),
                ],
                
                // Inventario y control de stock (siempre visible)
                _buildInventorySection(colorScheme),
                const SizedBox(height: 24),
                
                // Categoría y Proveedor (siempre visible)
                _buildPreferencesSection(colorScheme),
                
                // Espaciado final para el FAB
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Construye sección de variantes dinámicas
  Widget _buildVariantsSection(ColorScheme colorScheme) {
    final isVerified = widget.product.isVerified;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionHeader(
          context: context,
          title: 'Variantes',
          icon: Icons.label_outline,
        ),
        if (_variants.isEmpty) ...[
          const SizedBox(height: 16),
          if (!isVerified)
          // Botón para agregar variantes si el producto no está verificado
            AppButton.outlined(
              text: 'Agregar variante',
              onPressed: _showAddVariantDialog,
              icon: const Icon(Icons.add),
              borderRadius: UIConstants.defaultRadius,  
            )
          else
          // Mensaje cuando no hay variantes y el producto no está verificado
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: colorScheme.outline.withOpacity(0.3),
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
                    'sin variantes',
                    style: TextStyle(
                      fontSize: 11,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
        ] else ...[
          // mostrar si el producto está verificado y tiene variantes
          const SizedBox(height: 12),
          
          // Lista de variantes con layout responsivo
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ..._variants.entries.map((entry) {
                final value = entry.value;
                final String displayValue =
                    value is List ? value.join(', ') : value?.toString() ?? '';

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: !isVerified
                          ? () => _showAddVariantDialog(
                                editKey: entry.key,
                                editValue: entry.value,
                              )
                          : null,
                      borderRadius: BorderRadius.circular(UIConstants.defaultRadius),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(UIConstants.defaultRadius),
                          border: Border.all(
                            color: colorScheme.outline.withValues(alpha: 0.3),
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
                        child: Row(
                          children: [
                            // Nombre de la variante (Sin ícono previo)
                            Text(
                              entry.key,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                                fontSize: 14,
                              ),
                            ),
                            
                            // Mostrar opciones solo si hay datos
                            if (displayValue.isNotEmpty) ...[
                              const SizedBox(width: 12),
                              // Separador
                              Text(
                                '-',
                                style: TextStyle(
                                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(width: 12),
                              
                              // Opciones de la variante
                              Expanded(
                                child: Text(
                                  displayValue,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ] else 
                              const Spacer(),
                            
                            // Icono de edición (solo si no está verificado)
                            if (!isVerified) ...[
                              const SizedBox(width: 8),
                              Icon(
                                Icons.edit_outlined,
                                size: 18,
                                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
              
              // Botón para agregar nueva variante (Estilo simplificado)
              if (!isVerified)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: InkWell(
                    onTap: _showAddVariantDialog,
                    borderRadius: BorderRadius.circular(UIConstants.defaultRadius),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(UIConstants.defaultRadius),
                        border: Border.all(
                          color: colorScheme.outline.withValues(alpha: 0.5),
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add, 
                            size: 18, 
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Agregar variante',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }

  void _showDeleteVariantDialog(String variantKey) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar variante?'),
        content: Text(
          'Estás a punto de eliminar la variante "$variantKey". Esta acción no se puede deshacer.',
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
                _variants.remove(variantKey);
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

  void _showAddVariantDialog({String? editKey, dynamic editValue}) {
    final keyController = TextEditingController(text: editKey);
    final formKey = GlobalKey<FormState>();

    // Lista de variantes con controladores editables y FocusNodes
    final List<TextEditingController> variantControllers = [];
    final List<FocusNode> variantFocusNodes = [];

    // Inicializar controladores con valores existentes
    if (editValue is List) {
      for (var variant in editValue) {
        if (variant.toString().isNotEmpty) {
          variantControllers
              .add(TextEditingController(text: variant.toString()));
          variantFocusNodes.add(FocusNode());
        }
      }
    } else if (editValue != null && editValue.toString().isNotEmpty) {
      variantControllers.add(TextEditingController(text: editValue.toString()));
      variantFocusNodes.add(FocusNode());
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
                          colorScheme.primaryContainer.withOpacity(0.5),
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
                        Text(isEditing ? 'Editar' : 'Nueva variante'),
                  ),
                  if (isEditing)
                    IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _showDeleteVariantDialog(editKey);
                      },
                      icon: Icon(
                        Icons.delete_outline,
                        color: colorScheme.error,
                      ),
                      tooltip: 'Eliminar variante',
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
                      InputTextField(
                        controller: keyController,
                        enabled: true,
                        autofocus: !isEditing, 
                        hintText: 'ej. Color, Talle, Rojo, ..',
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'El nombre es obligatorio';
                          }
                          final newKey = value.trim();
                          // Validar si la variante ya existe (excluyendo la actual si estamos editando)
                          if (_variants.containsKey(newKey)) {
                            if (!isEditing || (isEditing && newKey != editKey)) {
                              return 'Esta variante ya existe';
                            }
                          }
                          return null;
                        },
                      ),                      const SizedBox(height: 16),   
                      // Botón estilo Input para "Agregar opción"
                      InkWell(
                        onTap: () {
                          setDialogState(() {
                            // Insertar al principio de la lista (índice 0)
                            variantControllers.insert(0, TextEditingController());
                            final newFocusNode = FocusNode();
                            variantFocusNodes.insert(0, newFocusNode);
                            
                            // Dar foco al nuevo campo después de que se construya
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (newFocusNode.canRequestFocus) {
                                newFocusNode.requestFocus();
                              }
                            });
                          });
                        },
                        borderRadius: BorderRadius.circular(UIConstants.defaultRadius),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 14, // Altura estándar de inputs
                          ),
                          decoration: BoxDecoration(
                            // Fondo con opacidad para destacar la acción
                            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(UIConstants.defaultRadius),
                            border: Border.all(
                              color: colorScheme.outline.withValues(alpha: 0.3),
                              width: 1.0,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.add,
                                size: 20,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Agregar opción',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: colorScheme.onSurfaceVariant, // Estilo hintText
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 12),

                      // Items de variantes en lista (AHORA DEBAJO DEL BOTÓN)
                      if (variantControllers.isNotEmpty)
                        Container(
                          constraints: const BoxConstraints(maxHeight: 250),
                          child: SingleChildScrollView(
                            child: Column(
                              children: [
                                // 🔥 Mostrar variantes en el orden actual (nuevas arriba)
                                ...List.generate(variantControllers.length,
                                    (index) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        // Fondo transparente para los items
                                        color: Colors.transparent,
                                        border: Border.all(
                                          color: colorScheme.outline
                                              .withOpacity(0.3),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          // Número indicador
                                          Container(
                                            margin: const EdgeInsets.only(left: 12),
                                            child: Text(
                                              '${index + 1}.',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: colorScheme.primary
                                                    .withOpacity(0.6),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: TextField(
                                              controller:
                                                  variantControllers[index],
                                              focusNode: variantFocusNodes[index],
                                              textCapitalization:
                                                  TextCapitalization.sentences,
                                              decoration: InputDecoration(
                                                hintText: 'Escribe la opción',
                                                hintStyle: TextStyle(
                                                  color: colorScheme.onSurfaceVariant
                                                      .withValues(alpha: 0.6),
                                                ) ,
                                                border: InputBorder.none,
                                                contentPadding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 12,
                                                ),
                                              ),
                                            ),
                                          ),
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
                                                variantFocusNodes[index]
                                                    .dispose();
                                                variantControllers
                                                    .removeAt(index);
                                                variantFocusNodes
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
                        )
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
                    for (var focusNode in variantFocusNodes) {
                      focusNode.dispose();
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
        _variants.remove(oldKey);
      }

      // Guardar: si hay variantes, guardar como string (1) o lista (2+), sino guardar como lista vacía
      if (variants.isEmpty) {
        _variants[key] = [];
      } else if (variants.length == 1) {
        _variants[key] = variants.first;
      } else {
        _variants[key] = variants.toList();
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
                      ? Colors.amber.withOpacity(0.15)
                      : colorScheme.surfaceContainerHighest
                          .withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                  border: _favoriteEnabled
                      ? Border.all(
                          color: Colors.amber.withOpacity(0.3),
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
                              color: colorScheme.outline.withOpacity(0.1),
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
                        .withOpacity(0.5),
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isValidCode
                    ? Colors.green.withOpacity(0.05)
                    : Colors.orange.withOpacity(0.05),
                borderRadius: BorderRadius.circular(UIConstants.defaultRadius),
                border: Border.all(
                  color: colorScheme.outline.withValues(alpha: 0.1),
                  width: 1.0,
                ),
              ),
              child: Row(
                children: [
                   Icon(
                    isValidCode ? Icons.public : Icons.qr_code_rounded,
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
                margin: const EdgeInsets.only(left: 4),
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: isValidCode
                      ? Colors.green.withOpacity(0.15)
                      : Colors.orange.withOpacity(0.15),
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
                          code,
                           style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                           ),
                           
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
                    color: colorScheme.outline.withOpacity(0.2),
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
              // Campo de descripción
            FormInputTextField(
              controller: _descriptionController,
              labelText: 'Nombre',
              hintText: 'Ej: Coca Cola 1.5L, Pack Oferta',
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'El nombre es requerido';
                }
                return null;
              },
              maxLength: 60,
              borderRadius: UIConstants.defaultRadius,
              prefixIcon: const Opacity(
                opacity: _iconOpacity,
                child: Icon(Icons.edit_outlined),
              ),
            ),
            ],
            if (widget.product.isVerified || !_isCombo)
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
                    color: colorScheme.outline.withOpacity(0.2),
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
                                    ),
                        ),
                      ],
                    ),
                  ],
                ),
              )
            ] else if (!_isCombo) ...[
              _buildMarkField(),
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
          title: 'Precios y Costos',
          icon: Icons.attach_money,
        ),
        const SizedBox(height: 12), 
        // El campo de IVA se movió dentro de MarginCalculatorCard
        if (!_isCombo) ...[
          const SizedBox(height: 16),
          _buildPurchasePriceField(), // precio de costo
          const SizedBox(height: 16),
          _buildSalePriceField(), // precio de venta
          
          // Profit Indicator (se muestra si hay precio de venta y costo válidos)
          if (_purchasePriceController.doubleValue > 0 && _salePriceController.doubleValue > 0)
            _buildProfitIndicator(),
 
          // Margin Calculator (se muestra solo si hay un costo válido)
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child:Column(
                    children: [
                      const SizedBox(height: 16),
                      MarginCalculatorCard(
                        key: ValueKey('calculator_$_calculatorResetKey'),
                        costPrice: _purchasePriceController.doubleValue,
                        salePrice: _salePriceController.doubleValue,
                        initialIva: _selectedIva,
                        initialRevenuePercentage: _revenuePercentage,
                        onApplyValues: (newPrice, newRevenuePercentage, newIva) {
                          setState(() {
                            _salePriceController.updateValue(newPrice);
                            _revenuePercentage = newRevenuePercentage;
                            _selectedIva = newIva;
                          });
                        },
                      ),
                    ],
                  ) ,
          ),
        ],
      ],
    );
  }

  /// Campo de precio de venta con validación
  Widget _buildSalePriceField() {
    // Texto condicional según si hay IVA aplicado
    final helperText = _selectedIva > 0
        ? 'Este es el precio que cobrarás ( IVA incluido )'
        : 'Este es el precio que cobrarás';
    
    return MoneyInputTextField(
      controller: _salePriceController,
      labelText: 'Precio Final',
      hintText: '0.00',
      helperText: helperText,
      validator: (value) {
        // En algunos flujos el precio puede ser 0 (ej. productos promocionales o por definir)
        // Solo validamos que sea numérico si se ingresó algo.
        if (value == null || value.trim().isEmpty) {
          // Si es obligatorio requerir precio > 0, mantener validación.
          // Pero si el usuario dice que "siempre da error", es probable que el controller
          // no esté actualizando el valor a tiempo o se desee permitir 0.
          // Validaremos solo formato por ahora.
          return 'El precio de venta es requerido';
        }
        return null;
      },
      borderRadius: UIConstants.defaultRadius,
    );
  }

  /// Campo de precio de coste
  Widget _buildPurchasePriceField() {
    return MoneyInputTextField(
      controller: _purchasePriceController,
      labelText: 'Costo',
      hintText: '0.00',
      borderRadius: UIConstants.defaultRadius,
    );
  }

  /// Indicador de beneficio/pérdida estimado
  Widget _buildProfitIndicator() {
    final theme = Theme.of(context);
    
    final costPrice = _purchasePriceController.doubleValue;
    final salePrice = _salePriceController.doubleValue;
    
    if (costPrice <= 0 || salePrice <= 0) {
      return const SizedBox.shrink();
    }
    
    final profit = salePrice - costPrice;
    final percentage = (profit / costPrice) * 100;
    final isProfitable = profit > 0;

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isProfitable
              ? [Colors.green.withValues(alpha: 0.12), Colors.green.withValues(alpha: 0.05)]
              : [Colors.red.withValues(alpha: 0.12), Colors.red.withValues(alpha: 0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(UIConstants.defaultRadius),
        border: Border.all(
          color: isProfitable
              ? Colors.green.withValues(alpha: 0.4)
              : Colors.red.withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isProfitable
                  ? Colors.green.withValues(alpha: 0.15)
                  : Colors.red.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isProfitable ? Icons.trending_up_rounded : Icons.trending_down_rounded,
              color: isProfitable ? Colors.green.shade700 : Colors.red.shade700,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isProfitable ? 'Beneficio estimado' : 'Pérdida estimada',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: isProfitable
                        ? Colors.green.shade700
                        : Colors.red.shade700,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${percentage.abs().round()}% de ${isProfitable ? 'ganancia' : 'pérdida'}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: (isProfitable ? Colors.green : Colors.red).shade600,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                CurrencyFormatter.formatPrice(value: profit.abs()),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isProfitable
                      ? Colors.green.shade700
                      : Colors.red.shade700,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }



  /// Campo de unidad de venta con estilo similar al campo de marca
  Widget _buildUnitFieldAsLabel() {
    final isVerified = widget.product.isVerified;
    final colorScheme = Theme.of(context).colorScheme;
  

    if (isVerified) {
      return InputTextField(
        controller: TextEditingController(
          text: _getUnitDisplayName(_unitController.text),
        ),
        readOnly: true,
        labelText: 'Vender por',
        helperText: 'Unidad verificada por el sistema',
        fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: UIConstants.defaultRadius,
      );
    }

    return InkWell(
      onTap: () => _showUnitSelectionDialog(),
      child: IgnorePointer(
        child: InputTextField(
          controller: TextEditingController(
            text: _getUnitDisplayName(_unitController.text),
          ),
          labelText: 'Vender por',
          suffixIcon: const Icon(Icons.arrow_drop_down),
          borderRadius: UIConstants.defaultRadius,
        ),
      ),
    );
  }

  /// Obtiene el nombre de visualización de la unidad con conversiones
  /// Obtiene el nombre de visualización de la unidad con conversiones
  String _getUnitDisplayName(String unit) {
    return UnitConstants.getDisplayName(unit);
  }

  /// Muestra diálogo de selección de unidad
  void _showUnitSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Seleccionar unidad de venta'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ..._commonUnits.map((unit) {
                final displayName = _getUnitDisplayName(unit);
                final conversionInfo = _getUnitConversionInfo(unit);

                return RadioListTile<String>(
                  title: Text(displayName),
                  subtitle: conversionInfo.isNotEmpty
                      ? Text(
                          conversionInfo,
                          style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant
                                .withOpacity(0.7),
                          ),
                        )
                      : null,
                  value: unit,
                  groupValue: _unitController.text,
                  onChanged: (value) {
                    setState(() {
                      final newUnit = value ?? UnitConstants.unit;
                      _unitController.text = newUnit;
                    });

                      Navigator.pop(context);
                  },
                );
              }),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  /// Obtiene información de conversión para mostrar en el diálogo
  /// Obtiene información de conversión para mostrar en el diálogo
  String _getUnitConversionInfo(String unit) {
    switch (unit.toLowerCase()) {
      case UnitConstants.kilogram:
        return '1 kg = 1000 g';
      case UnitConstants.liter:
        return '1 L = 1000 ml';
      case UnitConstants.meter:
        return '1 m = 100 cm = 1000 mm';
      case UnitConstants.box:
        return 'Unidad de empaque';
      default:
        return '';
    }
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
        if (!_isCombo) ...[
          _buildUnitFieldAsLabel(), // unidad de venta
          const SizedBox(height: 16),
        ], 
        // view : control de stock
        Container(
          decoration: BoxDecoration(
             borderRadius: BorderRadius.circular(UIConstants.defaultRadius),
            border: Border.all(
              color: colorScheme.primary.withValues (alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              SwitchListTile(
                value: _stockEnabled,
                onChanged: (value) => setState(() => _stockEnabled = value),
                title: Text(_isCombo ? 'Límite de ventas' : 'Stock'),
                subtitle: Text(_isCombo
                    ? 'Define cuántas veces se puede vender este combo'
                    : 'Controla la cantidad disponible del producto'),
                secondary: Opacity(
                  opacity: _iconOpacity,
                  child: Icon(
                    _isCombo ? Icons.production_quantity_limits : Icons.inventory_outlined,
                    color: _stockEnabled ? colorScheme.primary : null,
                  ),
                ),
              ),
              // view : control de stock
              if (_stockEnabled) ...[
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildQuantityField(),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildAlertStockField(),
                ),
                const SizedBox(height: 16),
              ],
            ],
          ),
        ),
        
      ],
    );
  }



  /// Campo de cantidad en stock con validación
  /// Soporta decimales para unidades fraccionarias (kg, L, m)
  Widget _buildQuantityField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.max,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'Cantidad disponible',
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        QuantitySelector(
          initialQuantity: _quantityStock,
          unit: _unitController.text,
          onQuantityChanged: (value) {
            setState(() {
              _quantityStock = value;
            });
          },
          showInput: true,
          showUnit: true,
          buttonSize: 48,
        ),
      ],
    );
  }

  /// Campo de alerta de stock bajo
  Widget _buildAlertStockField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'Cantidad mínima',
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        QuantitySelector(
          initialQuantity: _alertStock,
          unit: _unitController.text,
          onQuantityChanged: (value) {
            setState(() {
              _alertStock = value;
            });
          },
          showInput: true,
          showUnit: true,
           buttonSize: 48,
        ),
        const SizedBox(height: 8),
        Text(
          'Se mostrará una alerta cuando el stock esté en este nivel',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
          ),
        ),
      ],
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
                onAdd: () async {
                  // Mostrar diálogo de creación y esperar resultado
                  final newCategory = await showCategoryDialog(
                    context,
                    catalogueProvider: widget.catalogueProvider,
                    accountId: widget.accountId,
                  );
                  // Si se creó una categoría, retornarla para seleccionarla
                  return newCategory;
                },
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
            child: InputTextField(
              controller: _categoryController,
              labelText: 'Categoría',
            hintText: 'Seleccionar categoría',
            borderRadius: UIConstants.defaultRadius,
            prefixIcon: const Opacity(
                opacity: _iconOpacity,
                child: Icon(Icons.category_outlined),
              ),
              suffixIcon: const Icon(Icons.arrow_drop_down),
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
                onAdd: () async {
                  // Mostrar diálogo de creación y esperar resultado
                  final newProvider = await showProviderDialog(
                    context,
                    catalogueProvider: widget.catalogueProvider,
                    accountId: widget.accountId,
                  );
                  // Si se creó un proveedor, retornarlo para seleccionarlo
                  return newProvider;
                },
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
            child: InputTextField(
              controller: _providerController,
              labelText: 'Proveedor',
            hintText: 'Seleccionar proveedor',
            borderRadius: UIConstants.defaultRadius,
            prefixIcon: const Opacity(
                opacity: _iconOpacity,
                child: Icon(Icons.local_shipping_outlined),
              ),
              suffixIcon: const Icon(Icons.arrow_drop_down),
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
        child: InputTextField(
          controller: _markController,
          labelText: 'Buscar marca',
          borderRadius: UIConstants.defaultRadius,
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
          enabled: !isVerified, // InputTextField handles enabled/disabled style
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

  // ═══════════════════════════════════════════════════════════════════════════
  // LÓGICA DE COMBOS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Construye la sección de configuración de combos
  Widget _buildComboSection(ColorScheme colorScheme) {
    if (!_isCombo) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionHeader(
          context: context,
          title: 'Productos incluidos',
          icon: Icons.layers_outlined,
        ),
        const SizedBox(height: 12),

          if (_comboItems.isEmpty)
            // Estado vacío - sin cambios
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.outline.withValues(alpha: 0.2),
                  width: 1,
                  style: BorderStyle.solid, 
                ),
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.add_to_photos_rounded,
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                      size: 32,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sin productos',
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            // Vista previa compacta con resumen
            InkWell(
              onTap: _showComboItemsModal,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colorScheme.outline.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header: Cantidad de productos + botón editar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.shopping_basket_outlined,
                              size: 20,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${_comboItems.length} ${_comboItems.length == 1 ? 'producto' : 'productos'}',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                        TextButton.icon(
                          onPressed: _showComboItemsModal,
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          label: const Text('Editar'),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                    
                    // Vista previa de productos (primeros 3)
                    ...List.generate(
                      _comboItems.length > 3 ? 3 : _comboItems.length,
                      (index) {
                        final item = _comboItems[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: colorScheme.primaryContainer.withValues(alpha: 0.5),
                                child: Text(
                                  item.name.isNotEmpty ? item.name[0].toUpperCase() : '?',
                                  style: TextStyle(
                                    color: colorScheme.onPrimaryContainer,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  item.name,
                                  style: const TextStyle(fontSize: 13),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'x${item.quantity.toStringAsFixed(item.quantity % 1 == 0 ? 0 : 1)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    
                    // Indicador de más productos
                    if (_comboItems.length > 3)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '+ ${_comboItems.length - 3} más',
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                    
                    // Resumen financiero
                    Column(
                      children: [
                        _buildSummaryRow(
                          label: 'Valor real:',
                          value: CurrencyFormatter.formatPrice(
                            value: _calculateComboRealValue(),
                            moneda: '\$',
                          ),
                          textStyle: TextStyle(
                            decoration: TextDecoration.lineThrough,
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 13,
                          ),
                          valueStyle: TextStyle(
                            decoration: TextDecoration.lineThrough,
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 6),
                        _buildSummaryRow(
                          label: 'Costo total:',
                          value: CurrencyFormatter.formatPrice(
                            value: _calculateComboCost(),
                            moneda: '\$',
                          ),
                          textStyle: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 13,
                          ),
                          valueStyle: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 6),
                        _buildSummaryRow(
                          label: 'Precio final:',
                          value: _salePriceController.text.isEmpty
                              ? '\$0.00'
                              : '\$${_salePriceController.text}',
                          textStyle: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                            fontSize: 14,
                          ),
                          valueStyle: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 16),
          AppButton.filled(text: 'Agregar producto', onPressed: _showComboItemsModal),
          
          const SizedBox(height: 24),
          // Fecha de expiración (opcional)
          InputTextField(
            controller: _expirationController,
            hintText: 'Seleccionar fecha de expiración',
            labelText: 'Válido hasta (Opcional)',
            readOnly: true,
            prefixIcon: const Icon(Icons.calendar_today_outlined),
            suffixIcon: _comboExpiration != null
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      setState(() {
                        _comboExpiration = null;
                        _expirationController.clear();
                      });
                    },
                  )
                : null,
            onTap: () async {
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: _comboExpiration ?? DateTime.now().add(const Duration(days: 7)),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
              );
              if (picked != null) {
                setState(() {
                  _comboExpiration = picked;
                  // Formato de fecha local
                  _expirationController.text =
                      '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
                });
              }
            },
            
          ),
        ],

    );
  }
  
  /// Widget helper para crear filas de resumen
  Widget _buildSummaryRow({
    required String label,
    required String value,
    required TextStyle textStyle,
    required TextStyle valueStyle,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: textStyle),
        Text(value, style: valueStyle),
      ],
    );
  }

  /// Calcula el valor real sumando los precios de los items
  double _calculateComboRealValue() {
    double total = 0.0;
    for (var item in _comboItems) {
      total += item.originalSalePrice * item.quantity;
    }
    return total;
  }

  /// Calcula el costo del combo sumando purchasePrice * quantity 
  double _calculateComboCost() {
    double total = 0.0;
    for (var item in _comboItems) {
      total += item.purchasePrice * item.quantity;
    }
    return total;
  }



  /// Muestra modal unificado para gestionar los productos del combo
  void _showComboItemsModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ComboManagementSheet(
        comboItems: _comboItems,
        catalogueProvider: widget.catalogueProvider,
        onItemsChanged: (updatedItems) {
          setState(() {
            _comboItems = updatedItems;
          });
        },
      ),
    );
  }
}


/// Widget unificado para gestionar productos del combo
/// Integra búsqueda y edición en una sola interfaz
class _ComboManagementSheet extends StatefulWidget {
  final List<ComboItem> comboItems;
  final CatalogueProvider catalogueProvider;
  final Function(List<ComboItem>) onItemsChanged;

  const _ComboManagementSheet({
    required this.comboItems,
    required this.catalogueProvider,
    required this.onItemsChanged,
  });

  @override
  State<_ComboManagementSheet> createState() => _ComboManagementSheetState();
}

class _ComboManagementSheetState extends State<_ComboManagementSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<ComboItem> _items = [];
  List<ProductCatalogue> _allProducts = [];
  List<ProductCatalogue> _searchResults = [];
  
  // Usamos el estado del query para determinar si estamos buscando
  bool get _isSearching => _searchController.text.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.comboItems);
    _allProducts = widget.catalogueProvider.products;
    // El listener solo es para actualizar la UI si usamos el getter _isSearching
    _searchController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    final lowerQuery = query.toLowerCase().trim();
    setState(() {
      _searchResults = _allProducts.where((product) {
        // No permitir combos dentro de combos
        if (product.isCombo) return false;
        return product.description.toLowerCase().contains(lowerQuery) ||
               product.code.toLowerCase().contains(lowerQuery) ||
               product.nameMark.toLowerCase().contains(lowerQuery);
      }).toList();
    });
  }

  void _addOrUpdateProduct(ProductCatalogue product) {
    setState(() {
      final existingIndex = _items.indexWhere((item) => item.productId == product.id);
      
      if (existingIndex >= 0) {
        // Si ya existe, incrementar cantidad
        _items[existingIndex] = ComboItem(
          productId: _items[existingIndex].productId,
          name: _items[existingIndex].name,
          quantity: _items[existingIndex].quantity + 1.0,
          originalSalePrice: _items[existingIndex].originalSalePrice,
          purchasePrice: _items[existingIndex].purchasePrice,
        );
      } else {
        // Si no existe, agregar nuevo
        _items.add(ComboItem(
          productId: product.id,
          name: product.description,
          quantity: 1.0,
          originalSalePrice: product.salePrice,
          purchasePrice: product.purchasePrice,
        ));
      }
      
      // Limpiar búsqueda
      _searchController.clear();
      _searchResults = [];
      
      // Notificar cambios
      widget.onItemsChanged(_items);
    });
  }

  void _updateQuantity(int index, double change) {
    setState(() {
      final newQuantity = _items[index].quantity + change;
      if (newQuantity > 0) {
        _items[index] = ComboItem(
          productId: _items[index].productId,
          name: _items[index].name,
          quantity: newQuantity,
          originalSalePrice: _items[index].originalSalePrice,
          purchasePrice: _items[index].purchasePrice,
        );
        widget.onItemsChanged(_items);
      }
    });
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
      widget.onItemsChanged(_items);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return BaseBottomSheet(
      title: 'Gestionar Combo',
      subtitle: _isSearching 
          ? 'Buscando productos...' 
          : '${_items.length} ${_items.length == 1 ? 'producto' : 'productos'}',
      icon: Icons.layers_outlined,
      onSearch: _onSearch,
      searchController: _searchController,
      searchHint: 'Buscar producto',
      body: Column(
        children: [
            // El buscador ahora es parte del header en BaseBottomSheet
            
            // Contenido principal: resultados de búsqueda o lista de items
            Expanded(
            child: _isSearching
                ? _buildSearchResults(colorScheme, theme)
                : _buildComboItemsList(colorScheme, theme),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(ColorScheme colorScheme, ThemeData theme) {
    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 64,
              color: colorScheme.outline.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No se encontraron productos',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final product = _searchResults[index];
        final isAlreadyAdded = _items.any((item) => item.productId == product.id);

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            leading: product.image.isNotEmpty
                ? CircleAvatar(
                    backgroundImage: NetworkImage(product.image),
                    backgroundColor: colorScheme.surfaceContainerHighest,
                  )
                : CircleAvatar(
                    backgroundColor: colorScheme.primaryContainer,
                    child: Text(
                      product.description.isNotEmpty
                          ? product.description[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
            title: Text(
              product.description,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              '${CurrencyFormatter.formatPrice(value: product.salePrice, moneda: '\$')} • Stock: ${product.quantityStock}',
              style: theme.textTheme.bodySmall,
            ),
            trailing: isAlreadyAdded
                ? Chip(
                    label: const Text('Agregado'),
                    backgroundColor: colorScheme.primaryContainer,
                    labelStyle: TextStyle(
                      color: colorScheme.onPrimaryContainer,
                      fontSize: 11,
                    ),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  )
                : Icon(Icons.add_circle_outline, color: colorScheme.primary),
            onTap: () => _addOrUpdateProduct(product),
          ),
        );
      },
    );
  }

  Widget _buildComboItemsList(ColorScheme colorScheme, ThemeData theme) {
    if (_items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_basket_outlined,
              size: 64,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No hay productos en el combo',
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Usa el buscador para agregar productos',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      itemCount: _items.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = _items[index];
        
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 20,
                backgroundColor: colorScheme.primaryContainer,
                child: Text(
                  item.name.isNotEmpty ? item.name[0].toUpperCase() : '?',
                  style: TextStyle(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Información del producto
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      CurrencyFormatter.formatPrice(
                        value: item.originalSalePrice,
                        moneda: '\$',
                      ),
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              // Controles de cantidad
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, size: 20),
                      onPressed: () => _updateQuantity(index, -1),
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                      visualDensity: VisualDensity.compact,
                    ),
                    Container(
                      constraints: const BoxConstraints(minWidth: 36),
                      alignment: Alignment.center,
                      child: Text(
                        item.quantity.toStringAsFixed(item.quantity % 1 == 0 ? 0 : 2),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline, size: 20),
                      onPressed: () => _updateQuantity(index, 1),
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ),

              // Botón eliminar
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(Icons.delete_outline, color: colorScheme.error, size: 20),
                onPressed: () => _removeItem(index),
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        );
      },
    );
  }
}
