import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sellweb/features/catalogue/domain/entities/product_catalogue.dart';
import 'package:sellweb/features/catalogue/domain/entities/product.dart';
import 'package:sellweb/features/catalogue/presentation/providers/catalogue_provider.dart';
import 'package:sellweb/features/catalogue/presentation/widgets/product_edit_catalogue_view.dart';
import 'package:sellweb/features/sales/presentation/providers/sales_provider.dart';
import 'package:sellweb/core/utils/helpers/barcode_validator.dart';

/// Vista de pantalla completa para buscar y agregar productos al catálogo
///
/// Permite:
/// - Ingresar código de barras manualmente
/// - Buscar producto en el catálogo local del comercio
/// - Buscar producto en la base de datos global
/// - Crear nuevo producto si no existe
/// - Editar producto existente
class ProductSearchFullScreenView extends StatefulWidget {
  final CatalogueProvider catalogueProvider;
  final SalesProvider salesProvider;

  const ProductSearchFullScreenView({
    super.key,
    required this.catalogueProvider,
    required this.salesProvider,
  });

  @override
  State<ProductSearchFullScreenView> createState() =>
      _ProductSearchFullScreenViewState();
}

class _ProductSearchFullScreenViewState
    extends State<ProductSearchFullScreenView> {
  final TextEditingController _codeController = TextEditingController();
  final FocusNode _codeFocusNode = FocusNode();
  bool _isSearching = false;
  String? _errorMessage;
  bool _hasText = false;
  bool _isValidBarcode = false;

  // Control del listener del escáner
  bool _isListenerActive = false;
  late final _ScannerInputController _scannerInputController;

  // Flag para prevenir búsquedas duplicadas desde el escáner
  bool _isProcessingScannerInput = false;

  // Flag para prevenir múltiples navegaciones simultáneas
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();

    // Inicializar el controlador del escáner
    _scannerInputController = _ScannerInputController(
      onCodeDetected: (code) {
        // Prevenir búsquedas duplicadas o navegaciones simultáneas
        if (_isProcessingScannerInput || _isSearching || _isNavigating) {
          print('⚠️ Ignorando escaneo: busy');
          return;
        }

        print('📱 Código escaneado detectado: $code');
        _isProcessingScannerInput = true;

        // Actualizar el campo de texto con el código escaneado
        _codeController.text = code;

        // Buscar automáticamente después de un pequeño delay
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted && !_isNavigating) {
            _searchProduct();
          }
          _isProcessingScannerInput = false;
        });
      },
    );

    // Enfocar automáticamente al cargar la vista
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _codeFocusNode.requestFocus();
      _activateListener(); // Activar listener del escáner
    });

    // Escuchar cambios en el texto para mostrar/ocultar el FAB de búsqueda
    _codeController.addListener(() {
      // Ignorar cambios si están siendo procesados por el escáner
      if (_isProcessingScannerInput) return;

      final hasText = _codeController.text.trim().isNotEmpty;
      final isValid = BarcodeValidator.isValid(_codeController.text.trim());

      if (_hasText != hasText || _isValidBarcode != isValid) {
        setState(() {
          _hasText = hasText;
          _isValidBarcode = isValid;
        });
      }
    });
  }

  @override
  void dispose() {
    _deactivateListener(); // Desactivar listener del escáner
    _codeController.dispose();
    _codeFocusNode.dispose();
    _scannerInputController.dispose();
    super.dispose();
  }

  /// Activa el listener del teclado/escáner
  void _activateListener() {
    if (!_isListenerActive) {
      RawKeyboard.instance.addListener(_handleRawKeyEvent);
      _isListenerActive = true;
      _codeFocusNode.requestFocus(); // Enfocar para recibir eventos
    }
  }

  /// Desactiva el listener del teclado/escáner
  void _deactivateListener() {
    if (_isListenerActive) {
      RawKeyboard.instance.removeListener(_handleRawKeyEvent);
      _isListenerActive = false;
      _scannerInputController.reset(); // Limpiar buffer al desactivar
    }
  }

  /// Maneja los eventos de teclado crudos para detectar entradas del escáner
  void _handleRawKeyEvent(RawKeyEvent event) {
    if (event is! RawKeyDownEvent) return;

    _scannerInputController.handleKeyInput(
      logicalKey: event.logicalKey,
      character: event.character,
    );
  }

  /// Busca el producto por código en el catálogo local y global
  Future<void> _searchProduct() async {
    if (_codeController.text.trim().isEmpty) return;

    setState(() {
      _isSearching = true;
      _errorMessage = null;
    });

    final code = _codeController.text.trim();
    final accountId = widget.salesProvider.profileAccountSelected.id;

    try {
      // 0. Validación Matemática (Local)
      final isValidChecksum = BarcodeValidator.isValid(code);

      // Si el checksum es inválido, forzamos creación local directa
      // (Saltamos búsqueda global para ahorrar lecturas)
      if (!isValidChecksum) {
        // Pero primero verificamos si ya lo tenemos localmente (por si acaso)
        final localProducts = widget.catalogueProvider.searchByExactCode(code);
        if (localProducts.isNotEmpty) {
          if (mounted) _openEditView(localProducts.first, accountId);
          return;
        }

        // Si no existe local y es inválido -> Crear Local Only
        if (mounted) {
          _openCreateViewNew(code, accountId, forceLocal: true);
        }
        return;
      }

      // 1. Buscar en el catálogo local del comercio
      final localProducts = widget.catalogueProvider.searchByExactCode(code);

      if (localProducts.isNotEmpty) {
        // Producto existe en el catálogo local - abrir edición
        final product = localProducts.first;
        if (mounted) {
          _openEditView(product, accountId);
        }
        return;
      }

      // 2. Buscar en la base de datos global de productos
      final globalProduct =
          await widget.catalogueProvider.getPublicProductByCode(code);

      if (globalProduct != null) {
        // Producto existe en BD global pero no en catálogo local
        // Crear referencia en el catálogo con el producto global
        if (mounted) {
          _openCreateViewFromGlobal(globalProduct, accountId);
        }
        return;
      }

      // 3. Producto no existe en ninguna parte - crear nuevo
      if (mounted) {
        _openCreateViewNew(code, accountId);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al buscar producto: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  /// Abre la vista de edición para un producto existente en el catálogo
  void _openEditView(ProductCatalogue product, String accountId) {
    // Prevenir navegaciones múltiples
    if (_isNavigating) return;

    _isNavigating = true;
    // Desactivar listener del escáner antes de navegar
    _deactivateListener();

    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (context) => ProductEditCatalogueView(
          product: product,
          catalogueProvider: widget.catalogueProvider,
          accountId: accountId,
        ),
      ),
    )
        .then((_) {
      // Limpiar y volver al campo de búsqueda
      _codeController.clear();
      _isNavigating = false;
      _codeFocusNode.requestFocus();
      // Reactivar listener del escáner al volver
      _activateListener();
    });
  }

  /// Abre la vista de creación desde un producto global existente
  void _openCreateViewFromGlobal(Product globalProduct, String accountId) {
    // Prevenir navegaciones múltiples
    if (_isNavigating) return;

    _isNavigating = true;
    // Desactivar listener del escáner antes de navegar
    _deactivateListener();

    // Convertir Product a ProductCatalogue para el formulario
    final newProduct = ProductCatalogue(
      id: globalProduct.id,
      code: globalProduct.code,
      description: globalProduct.description,
      image: globalProduct.image,
      reviewed: globalProduct.reviewed,
      idMark: globalProduct.idMark,
      nameMark: globalProduct.nameMark,
      imageMark: globalProduct.imageMark,
      followers: globalProduct.followers,
      creation: DateTime.now(),
      upgrade: DateTime.now(),
      documentCreation: globalProduct.creation,
      documentUpgrade: globalProduct.upgrade,
      documentIdCreation: globalProduct.idUserCreation,
      documentIdUpgrade: globalProduct.idUserUpgrade,
      local: false, // Producto de la BD global
    );

    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (context) => ProductEditCatalogueView(
          product: newProduct,
          catalogueProvider: widget.catalogueProvider,
          accountId: accountId,
          isCreatingMode: true,
        ),
      ),
    )
        .then((_) {
      _codeController.clear();
      _isNavigating = false;
      _codeFocusNode.requestFocus();
      // Reactivar listener del escáner al volver
      _activateListener();
    });
  }

  /// Abre la vista de creación para un producto completamente nuevo
  ///
  /// ## Flujo de decisión:
  /// - **forceLocal = true** (SKU generado): status = 'sku', local = true
  /// - **Código inválido**: status = 'sku', local = true (solo catálogo privado)
  /// - **Código válido**: status = 'pending', local = false (BD global + catálogo)
  void _openCreateViewNew(String code, String accountId,
      {bool forceLocal = false}) {
    // Prevenir navegaciones múltiples
    if (_isNavigating) return;

    _isNavigating = true;
    // Desactivar listener del escáner antes de navegar
    _deactivateListener();

    // Determinar si es un producto válido para BD global
    final isValidCode = BarcodeValidator.isValid(code);
    final isSku = forceLocal || code.startsWith('SKU-');
    final isLocal = isSku || !isValidCode;

    // Determinar el status según el tipo de código
    // - 'sku': Producto interno del comercio (SKU generado o código no estándar)
    // - '': Producto nuevo con código válido (el UseCase asignará 'pending' al crearlo en BD)
    final status = isLocal ? 'sku' : '';

    // Debug: Verificar valores
    print('🔍 Creando producto nuevo:');
    print('   Código: $code');
    print('   Es válido: $isValidCode');
    print('   Es SKU: $isSku');
    print('   Es local: $isLocal');
    print('   Status: $status');

    final newProduct = ProductCatalogue(
      id: '', // Se generará al guardar
      code: code,
      description: '',
      image: '',
      creation: DateTime.now(),
      upgrade: DateTime.now(),
      documentCreation: DateTime.now(),
      documentUpgrade: DateTime.now(),
      local: isLocal,
      status: status,
    );

    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (context) => ProductEditCatalogueView(
          product: newProduct,
          catalogueProvider: widget.catalogueProvider,
          accountId: accountId,
          isCreatingMode: true,
        ),
      ),
    )
        .then((_) {
      _codeController.clear();
      _isNavigating = false;
      _codeFocusNode.requestFocus();
      // Reactivar listener del escáner al volver
      _activateListener();
    });
  }

  /// Genera un SKU híbrido y abre la vista de creación
  void _generateSkuAndCreate() {
    final accountId = widget.salesProvider.profileAccountSelected.id;
    final sku = widget.catalogueProvider.generateHybridSku(accountId);

    // Abrir vista de creación con el SKU generado
    // Forzamos local porque es un producto sin código estándar
    _openCreateViewNew(sku, accountId, forceLocal: true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Volver al catálogo'),
        centerTitle: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Ícono ilustrativo con animación sutil
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOut,
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: 0.8 + (value * 0.2),
                      child: Opacity(
                        opacity: value,
                        child: child,
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color:
                          colorScheme.primaryContainer.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.qr_code_scanner_rounded,
                      size: 80,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Título
                Text(
                  'Escanee o ingrese el código',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                // Campo de entrada del código
                _buildCodeTextField(theme, colorScheme),

                const SizedBox(height: 16),

                // Botón "No tengo código"
                TextButton.icon(
                  onPressed: _generateSkuAndCreate,
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('No tengo código (Generar SKU)'),
                  style: TextButton.styleFrom(
                    foregroundColor: colorScheme.secondary,
                  ),
                ),
                const SizedBox(height: 12),

                // Indicador de carga
                if (_isSearching)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20.0),
                    child: CircularProgressIndicator(),
                  ),
              ],
            ),
          ),
        ),
      ),

      // Botones flotantes
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Botón para enfocar el teclado
          FloatingActionButton(
            heroTag: 'focus_keyboard_fab',
            onPressed: () {
              _codeFocusNode.requestFocus();
            },
            tooltip: 'Abrir teclado',
            child: const Icon(Icons.keyboard),
          ),
          const SizedBox(height: 16),

          // Botón para buscar (solo visible si hay contenido)
          AnimatedScale(
            scale: _hasText ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: _hasText
                ? FloatingActionButton.extended(
                    heroTag: 'search_product_fab',
                    onPressed: _isSearching ? null : _searchProduct,
                    icon: _isSearching
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.search),
                    label: Text(_isSearching ? 'Buscando...' : 'Buscar'),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  /// Construye el campo de texto del código con validación visual
  ///
  /// Muestra:
  /// - Formato del código (EAN-13, UPC-A, etc.)
  /// - Bandera del país de origen si se puede identificar
  /// - Indicador visual de validación (verde=válido, naranja=no estándar)
  Widget _buildCodeTextField(ThemeData theme, ColorScheme colorScheme) {
    final code = _codeController.text.trim();
    final codeLength = code.length;

    // Usar el nuevo validador con soporte de formato y país
    final countryInfo = BarcodeValidator.getCountryInfo(code);
    final formattedDescription = BarcodeValidator.getFormattedDescription(code);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _codeController,
          focusNode: _codeFocusNode,
          decoration: InputDecoration(
            labelText: 'Código de barras',
            hintText: 'Ej: 7790310081556',
            prefixIcon: _hasText
                ? Icon(
                    _isValidBarcode ? Icons.check_circle : Icons.info,
                    color:
                        _isValidBarcode ? Colors.green : Colors.orange.shade700,
                  )
                : null,
            suffixIcon: _hasText
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      setState(() {
                        _codeController.clear();
                        _errorMessage = null;
                      });
                      _codeFocusNode.requestFocus();
                    },
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: _hasText
                    ? (_isValidBarcode
                        ? Colors.green.withValues(alpha: 0.5)
                        : Colors.orange.withValues(alpha: 0.5))
                    : Colors.grey.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: _hasText
                    ? (_isValidBarcode ? Colors.green : Colors.orange)
                    : colorScheme.primary,
                width: 2,
              ),
            ),
            filled: true,
            fillColor: Colors.transparent,
            errorText: _errorMessage,
            counterText: '',
          ),
          maxLength: 20,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
          ],
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            color: _hasText
                ? (_isValidBarcode
                    ? Colors.green.shade700
                    : Colors.orange.shade700)
                : null,
          ),
          onSubmitted: (_) => _searchProduct(),
          onChanged: (_) {
            if (_errorMessage != null) {
              setState(() => _errorMessage = null);
            }
          },
        ),
        if (_hasText) ...[
          const SizedBox(height: 8),
          // Feedback de validación con tipo de código y país
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Información del formato y país
              Expanded(
                child: Row(
                  children: [
                    // Texto del formato
                    Text(
                      _isValidBarcode
                          ? (formattedDescription ?? 'Código válido')
                          : 'Código no estándar',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: _isValidBarcode
                            ? Colors.green.shade700
                            : Colors.orange.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    // Información adicional del país
                    if (_isValidBarcode && countryInfo != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        countryInfo.country,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Contador de caracteres
              Text(
                '$codeLength/20',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Controlador para detectar entrada de escáner de código de barras
///
/// Diferencia entre:
/// - Entrada rápida del escáner (< 50ms entre caracteres)
/// - Entrada manual del usuario
class _ScannerInputController {
  _ScannerInputController({
    required this.onCodeDetected,
  });

  // Parámetros optimizados para mejor detección
  static const Duration _scannerKeyInterval =
      Duration(milliseconds: 60); // Margen para variaciones del escáner
  static const Duration _scannerProcessDelay =
      Duration(milliseconds: 250); // Esperar más antes de procesar
  static const Duration _scannerSequenceMaxDuration =
      Duration(milliseconds: 1200); // Ventana más amplia para secuencias
  static const int _scannerMinLength =
      4; // Mínimo 4 dígitos para considerar código válido
  static final RegExp _numericRegExp = RegExp(r'^[0-9]$');

  final void Function(String code) onCodeDetected;

  DateTime? _lastKey;
  final StringBuffer _scannerBuffer = StringBuffer();
  Timer? _scannerProcessingTimer;
  bool _scannerCandidateActive = false;
  DateTime? _scannerSequenceStart;

  void handleKeyInput({
    required LogicalKeyboardKey logicalKey,
    String? character,
  }) {
    // Manejar Enter - finalizar secuencia
    if (logicalKey == LogicalKeyboardKey.enter) {
      if (_scannerCandidateActive && _scannerBuffer.isNotEmpty) {
        // Forzar procesamiento inmediato al detectar Enter
        _finalizeScannerCandidate(forceScanner: true);
      }
      return;
    }

    // Solo procesar caracteres numéricos
    final char = character;
    if (char == null || !_numericRegExp.hasMatch(char)) {
      return;
    }

    final previousTimestamp = _lastKey;
    final now = DateTime.now();
    final diff =
        previousTimestamp == null ? null : now.difference(previousTimestamp);
    _lastKey = now;

    final bool isRapidInput = diff != null && diff <= _scannerKeyInterval;
    final bool isFirstChar = previousTimestamp == null;

    // Siempre iniciar secuencia con el primer carácter numérico
    // o continuar si la entrada es rápida
    if (isFirstChar || isRapidInput) {
      _appendScannerCharacter(char, now, previousTimestamp);
    } else if (_scannerCandidateActive) {
      // Si ya hay una secuencia activa pero la entrada se ralentizó,
      // aún agregamos el carácter (puede ser variación del escáner)
      // pero solo si no ha pasado demasiado tiempo
      final elapsed = _scannerSequenceStart != null
          ? now.difference(_scannerSequenceStart!)
          : null;

      if (elapsed != null && elapsed <= _scannerSequenceMaxDuration) {
        print(
            '⚠️ Entrada lenta pero dentro de ventana: ${diff?.inMilliseconds}ms');
        _appendScannerCharacter(char, now, previousTimestamp);
      } else {
        // Secuencia demasiado larga - cancelar y reiniciar
        print(
            '❌ Secuencia excedió duración máxima: ${elapsed?.inMilliseconds}ms');
        _cancelScannerCandidate();
      }
    } else {
      // No hay secuencia activa y entrada es lenta - ignorar
      print('⏸️ Entrada lenta sin secuencia activa: ${diff?.inMilliseconds}ms');
    }
  }

  void dispose() {
    _scannerProcessingTimer?.cancel();
  }

  void reset() {
    _cancelScannerCandidate();
    _lastKey = null;
  }

  void _appendScannerCharacter(
    String char,
    DateTime timestamp,
    DateTime? previousTimestamp,
  ) {
    if (!_scannerCandidateActive) {
      _scannerCandidateActive = true;
      _scannerSequenceStart = previousTimestamp ?? timestamp;
      _scannerBuffer.clear();
      print('🟢 Iniciando secuencia de escáner');
    }
    _scannerBuffer.write(char);
    print(
        '📝 Buffer actual: ${_scannerBuffer.toString()} (${_scannerBuffer.length} chars)');
    _scheduleScannerProcessing();
  }

  void _scheduleScannerProcessing() {
    _scannerProcessingTimer?.cancel();
    _scannerProcessingTimer = Timer(
      _scannerProcessDelay,
      _finalizeScannerCandidate,
    );
  }

  void _finalizeScannerCandidate({bool forceScanner = false}) {
    if (!_scannerCandidateActive || _scannerBuffer.isEmpty) {
      _cancelScannerCandidate();
      return;
    }

    final code = _scannerBuffer.toString();
    final elapsed = _scannerSequenceStart == null
        ? null
        : DateTime.now().difference(_scannerSequenceStart!);

    // Criterios más flexibles para detectar escáner
    final qualifiesAsScanner = forceScanner ||
        (code.length >= _scannerMinLength &&
            elapsed != null &&
            elapsed <= _scannerSequenceMaxDuration);

    print('🔍 Evaluando código candidato:');
    print('   Código: $code (${code.length} dígitos)');
    print('   Tiempo transcurrido: ${elapsed?.inMilliseconds}ms');
    print('   ¿Califica como escáner?: $qualifiesAsScanner');

    _cancelScannerCandidate();

    if (qualifiesAsScanner) {
      _handleScannerDetection(code);
    } else {
      print('⚠️ Código descartado (no cumple criterios de escáner)');
    }
  }

  void _cancelScannerCandidate({bool clearBuffer = true}) {
    if (_scannerCandidateActive && _scannerBuffer.isNotEmpty) {
      print('🔴 Cancelando candidato: ${_scannerBuffer.toString()}');
    }
    _scannerCandidateActive = false;
    _scannerSequenceStart = null;
    _scannerProcessingTimer?.cancel();
    if (clearBuffer) {
      _scannerBuffer.clear();
    }
  }

  void _handleScannerDetection(String code) {
    if (code.isEmpty) return;
    onCodeDetected(code);
  }
}
