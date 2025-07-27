import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sellweb/core/utils/fuctions.dart';
import 'package:sellweb/core/utils/product_search_algorithm.dart';
import 'package:sellweb/core/utils/catalogue_filter.dart';
import '../../data/catalogue_repository_impl.dart';
import '../../domain/entities/catalogue.dart';
import '../../domain/usecases/catalogue_usecases.dart';
import '../../domain/usecases/account_usecase.dart';

class _CatalogueState {
  final List<ProductCatalogue> products;
  final ProductCatalogue? lastScannedProduct;
  final String? lastScannedCode;
  final bool showSplash;
  final String? scanError;
  final bool isLoading;
  final List<ProductCatalogue> filteredProducts;
  final String currentSearchQuery;

  const _CatalogueState({
    required this.products,
    this.lastScannedProduct,
    this.lastScannedCode,
    this.showSplash = false,
    this.scanError,
    this.isLoading = true,
    this.filteredProducts = const [],
    this.currentSearchQuery = '',
  });

  _CatalogueState copyWith({
    List<ProductCatalogue>? products,
    Object? lastScannedProduct = const Object(),
    Object? lastScannedCode = const Object(),
    bool? showSplash,
    Object? scanError = const Object(),
    bool? isLoading,
    List<ProductCatalogue>? filteredProducts,
    String? currentSearchQuery,
  }) {
    return _CatalogueState(
      products: products ?? this.products,
      lastScannedProduct: lastScannedProduct == const Object()
          ? this.lastScannedProduct
          : lastScannedProduct as ProductCatalogue?,
      lastScannedCode: lastScannedCode == const Object()
          ? this.lastScannedCode
          : lastScannedCode as String?,
      showSplash: showSplash ?? this.showSplash,
      scanError:
          scanError == const Object() ? this.scanError : scanError as String?,
      isLoading: isLoading ?? this.isLoading,
      filteredProducts: filteredProducts ?? this.filteredProducts,
      currentSearchQuery: currentSearchQuery ?? this.currentSearchQuery,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _CatalogueState &&
          runtimeType == other.runtimeType &&
          listEquals(products, other.products) &&
          lastScannedProduct == other.lastScannedProduct &&
          lastScannedCode == other.lastScannedCode &&
          showSplash == other.showSplash &&
          scanError == other.scanError &&
          isLoading == other.isLoading;

  @override
  int get hashCode =>
      products.hashCode ^
      lastScannedProduct.hashCode ^
      lastScannedCode.hashCode ^
      showSplash.hashCode ^
      scanError.hashCode ^
      isLoading.hashCode;
}

class CatalogueProvider extends ChangeNotifier {
  bool _shouldNotifyListeners = true;

  /// Flag para controlar si se deben notificar los cambios
  set shouldNotifyListeners(bool value) {
    _shouldNotifyListeners = value;
  }

  @override
  void notifyListeners() {
    if (_shouldNotifyListeners) {
      super.notifyListeners();
    }
  }

  // Dependencies
  GetCatalogueStreamUseCase getProductsStreamUseCase;
  final GetProductByCodeUseCase getProductByCodeUseCase;
  final IsProductScannedUseCase isProductScannedUseCase;
  final GetPublicProductByCodeUseCase getPublicProductByCodeUseCase;
  AddProductToCatalogueUseCase addProductToCatalogueUseCase;
  CreatePublicProductUseCase createPublicProductUseCase;
  final GetUserAccountsUseCase getUserAccountsUseCase;

  // Stream subscription y timer para debouncing
  StreamSubscription<QuerySnapshot>? _catalogueSubscription;
  Timer? _searchDebounceTimer;

  // Immutable state
  _CatalogueState _state = _CatalogueState(products: []);

  // Public getters
  List<ProductCatalogue> get products => _state.products;
  List<ProductCatalogue> get filteredProducts => _state.filteredProducts;
  String get currentSearchQuery => _state.currentSearchQuery;
  ProductCatalogue? get lastScannedProduct => _state.lastScannedProduct;
  String? get lastScannedCode => _state.lastScannedCode;
  bool get showSplash => _state.showSplash;
  String? get scanError => _state.scanError;
  bool get isLoading => _state.isLoading;

  /// Obtiene los productos más vendidos ordenados por cantidad de ventas
  /// [limit] Número máximo de productos a retornar (por defecto 8)
  /// [minimumSales] Número mínimo de ventas para incluir el producto (por defecto 1)
  List<ProductCatalogue> getTopFilterProducts(
      {int limit = 50, int minimumSales = 1}) {
    return CatalogueProductFilterAlgorithm.getTopSellingProducts(
      products: _state.products,
      limit: limit,
      minimumSales: minimumSales,
    );
  }

  CatalogueProvider({
    required this.getProductsStreamUseCase,
    required this.getProductByCodeUseCase,
    required this.isProductScannedUseCase,
    required this.getPublicProductByCodeUseCase,
    required this.addProductToCatalogueUseCase,
    required this.createPublicProductUseCase,
    required this.getUserAccountsUseCase,
  }); // Removido _initProducts() del constructor

  /// Inicializa el catálogo para una cuenta específica
  void initCatalogue(String id) {
    // Validar que el ID no esté vacío
    if (id.isEmpty) {
      throw Exception('El ID de la cuenta no puede estar vacío.');
    }

    // Cancelar la suscripción anterior si existe
    _catalogueSubscription?.cancel();

    // Reinicializar el estado del catálogo
    _updateState(_CatalogueState(
      products: [],
      isLoading: true,
    ));

    // Crear nuevos casos de uso con el nuevo ID de cuenta
    final newCatalogueRepository = CatalogueRepositoryImpl(id: id);
    getProductsStreamUseCase =
        GetCatalogueStreamUseCase(newCatalogueRepository);
    addProductToCatalogueUseCase =
        AddProductToCatalogueUseCase(newCatalogueRepository);
    createPublicProductUseCase =
        CreatePublicProductUseCase(newCatalogueRepository);

    // Inicializar el stream de productos para la nueva cuenta
    _catalogueSubscription = getProductsStreamUseCase().listen(
      (snapshot) {
        // Convertir los documentos del snapshot en objetos ProductCatalogue
        final products = snapshot.docs
            .map((doc) =>
                ProductCatalogue.fromMap(doc.data() as Map<String, dynamic>))
            .toList();

        // Ordenar productos por fecha de actualización (más recientes primero)
        products.sort((a, b) => b.upgrade.compareTo(a.upgrade));

        // Siempre actualizar si hay cambios detectados
        if (!_areProductListsEqual(_state.products, products)) {
          _updateState(_state.copyWith(products: products));
          print(
              '📦 Lista de catálogo actualizada: ${products.length} productos');
        }

        // Marcar como cargado si aún está en estado loading
        if (_state.isLoading) {
          _updateState(_state.copyWith(isLoading: false));
          print('✅ Catálogo inicializado correctamente');
        }
      },
      onError: (error) {
        print('Error al cargar productos: $error');
        _updateState(_state.copyWith(
          isLoading: false,
          scanError: error.toString(),
        ));
      },
    );
  }

  /// Busca un producto por código de barras en el catálogo local.
  ProductCatalogue? getProductByCode(String code) {
    final normalizedCode = code.trim().toUpperCase();
    return _state.products.firstWhere(
      (product) => product.code.trim().toUpperCase() == normalizedCode,
      orElse: () => ProductCatalogue(),
    );
  }

  /// Busca un producto público por código de barra en la base pública.
  Future<Product?> getPublicProductByCode(String code) async {
    return await getPublicProductByCodeUseCase(code);
  }

  /// Busca productos usando el algoritmo avanzado de búsqueda
  /// Permite buscar sin importar el orden de las palabras
  List<ProductCatalogue> searchProducts({
    required String query,
    int? maxResults,
  }) {
    print('🔍 CatalogueProvider - searchProducts llamado con: "$query"');
    print('📦 Productos disponibles en state: ${_state.products.length}');

    final results = ProductSearchAlgorithm.searchProducts(
      products: _state.products,
      query: query,
      maxResults: maxResults,
    );

    print('✅ Resultados de búsqueda: ${results.length}');
    return results;
  }

  /// Busca productos con debouncing para mejorar el rendimiento
  void searchProductsWithDebounce({
    required String query,
    int? maxResults,
    Duration delay = const Duration(milliseconds: 300),
  }) {
    // Cancelar timer anterior si existe
    _searchDebounceTimer?.cancel();

    // Crear nuevo timer
    _searchDebounceTimer = Timer(delay, () {
      final results = searchProducts(query: query, maxResults: maxResults);
      _state = _state.copyWith(
        filteredProducts: results,
        currentSearchQuery: query,
      );
      notifyListeners();
    });
  }

  /// Limpia los resultados de búsqueda
  void clearSearchResults() {
    _searchDebounceTimer?.cancel();
    _state = _state.copyWith(
      filteredProducts: [],
      currentSearchQuery: '',
    );
    notifyListeners();
  }

  /// Busca productos por código exacto
  List<ProductCatalogue> searchByExactCode(String code) {
    return ProductSearchAlgorithm.searchByExactCode(
      products: _state.products,
      code: code,
    );
  }

  /// Busca productos por categoría
  List<ProductCatalogue> searchByCategory(String category) {
    return ProductSearchAlgorithm.searchByCategory(
      products: _state.products,
      category: category,
    );
  }

  /// Fuerza la actualización del catálogo desde Firebase
  /// Útil cuando se necesita asegurar que los datos estén sincronizados
  Future<void> forceRefreshCatalogue() async {
    if (_catalogueSubscription == null) {
      print('⚠️ No hay suscripción activa al catálogo');
      return;
    }

    try {
      print('🔄 Forzando actualización del catálogo...');
      _updateState(_state.copyWith(isLoading: true));

      // La actualización se hará automáticamente por el listener del stream
      // Solo necesitamos marcar que estamos refrescando
      print('✅ Solicitud de actualización enviada');
    } catch (e) {
      print('❌ Error al forzar actualización del catálogo: $e');
      _updateState(_state.copyWith(
        isLoading: false,
        scanError: 'Error al actualizar catálogo: $e',
      ));
    }
  }

  /// Busca productos por marca
  List<ProductCatalogue> searchByBrand(String brand) {
    return ProductSearchAlgorithm.searchByBrand(
      products: _state.products,
      brand: brand,
    );
  }

  /// Obtiene sugerencias de búsqueda
  List<String> getSearchSuggestions({
    required String query,
    int maxSuggestions = 5,
  }) {
    final suggestions = ProductSearchAlgorithm.getSearchSuggestions(
      products: _state.products,
      query: query,
      maxSuggestions: maxSuggestions,
    );

    return suggestions;
  }

  /// Intenta escanear un producto: si no está en el catálogo, busca en la base pública.
  Future<void> scanProduct(String code,
      {required Function(Product) onFoundInPublic}) async {
    final localProduct = getProductByCode(code);
    if (localProduct != null && localProduct.id.isNotEmpty) {
      _state = _state.copyWith(
        lastScannedProduct: localProduct,
        lastScannedCode: code,
      );
      notifyListeners();
      return;
    }

    // Buscar en la base pública
    final publicProduct = await getPublicProductByCode(code);
    if (publicProduct != null) {
      onFoundInPublic(publicProduct);
    } else {
      _state = _state.copyWith(scanError: 'Producto no encontrado');
      notifyListeners();
    }
  }

  /// Guarda un producto en el catálogo de la cuenta actual.
  Future<void> saveProductToCatalogue(
      ProductCatalogue productToSave, String accountId) async {
    if (accountId.isEmpty) {
      throw Exception('El ID de la cuenta no está definido o es nulo.');
    }
    try {
      _shouldNotifyListeners = false;
      await addProductToCatalogueUseCase(productToSave, accountId);
      _shouldNotifyListeners = true;
      notifyListeners();
    } catch (e) {
      _shouldNotifyListeners = true;
      throw Exception('Error al guardar producto en catálogo: $e');
    }
  }

  /// Crea un nuevo producto en la base de datos pública.
  Future<void> createPublicProduct(Product product) async {
    try {
      final productToSave = Product(
        id: product.id,
        idMark: product.idMark,
        nameMark: product.nameMark,
        imageMark: product.imageMark,
        description: product.description,
        image: product.image,
        code: product.code,
        followers: product.followers,
        favorite: product.favorite,
        verified: product.verified,
        reviewed: product.reviewed,
        creation: Utils().getTimestampNow(),
        upgrade: Utils().getTimestampNow(),
        idUserCreation: product.idUserCreation,
        idUserUpgrade: product.idUserUpgrade,
      );

      await createPublicProductUseCase(productToSave);
    } catch (e) {
      throw Exception('Error al crear producto público: $e');
    }
  }

  /// Carga productos de demostración (solo para modo demo).
  void loadDemoProducts(List<ProductCatalogue> demoProducts) {
    _shouldNotifyListeners = false;
    _state = _state.copyWith(
      products: demoProducts,
      isLoading: false,
    );
    _shouldNotifyListeners = true;
    notifyListeners();
  }

  /// Agrega un nuevo producto al catálogo o actualiza uno existente.
  ///
  /// [product] El producto a agregar o actualizar en el catálogo
  /// [accountId] El ID de la cuenta donde se agregará el producto
  /// Retorna un [Future<void>] que se completa cuando la operación termina
  Future<void> addProductToCatalogue(
      ProductCatalogue product, String accountId) async {
    // Validar parámetros requeridos
    if (accountId.isEmpty) {
      throw Exception(
          'El ID de la cuenta es requerido para agregar productos al catálogo');
    }
    if (product.code.isEmpty) {
      throw Exception('El código del producto es requerido');
    }

    try {
      _state = _state.copyWith(isLoading: true);
      notifyListeners();

      // Verificar si el producto ya existe
      final existingProduct = getProductByCode(product.code);

      if (existingProduct != null && existingProduct.id.isNotEmpty) {
        // Actualizar producto existente
        final updatedProduct = product.copyWith(
          upgrade: Utils().getTimestampNow(),
          documentIdUpgrade: accountId,
        );
        await addProductToCatalogueUseCase(updatedProduct, accountId);
      } else {
        // Agregar nuevo producto
        final newProduct = product.copyWith(
          creation: Utils().getTimestampNow(),
          upgrade: Utils().getTimestampNow(),
          documentIdCreation: accountId,
          documentIdUpgrade: accountId,
        );
        await addProductToCatalogueUseCase(newProduct, accountId);
      }

      _state = _state.copyWith(
        isLoading: false,
        lastScannedProduct: product,
        lastScannedCode: product.code,
        scanError: null,
      );
      notifyListeners();
    } catch (e) {
      _state = _state.copyWith(
        isLoading: false,
        scanError: 'Error al agregar producto al catálogo: ${e.toString()}',
      );
      notifyListeners();
      throw Exception('Error al agregar producto al catálogo: $e');
    }
  }

  /// Incrementa el contador de ventas de un producto en el catálogo
  ///
  /// Este método se llama cuando se confirma una venta para actualizar
  /// las estadísticas de ventas del producto en Firebase.
  ///
  /// [accountId] - ID de la cuenta del negocio
  /// [productId] - ID del producto
  /// [quantity] - Cantidad vendida (por defecto 1)
  Future<void> incrementProductSales(String accountId, String productId,
      {int quantity = 1}) async {
    // Validar parámetros
    if (accountId.isEmpty || productId.isEmpty) {
      throw Exception('El accountId y productId son requeridos');
    }

    if (quantity <= 0) {
      throw Exception('La cantidad debe ser mayor a 0');
    }

    try {
      // Crear nuevos casos de uso con el ID de cuenta actual
      final catalogueRepository = CatalogueRepositoryImpl(id: accountId);
      final incrementSalesUseCase =
          IncrementProductSalesUseCase(catalogueRepository);

      // Ejecutar el incremento de ventas
      await incrementSalesUseCase(accountId, productId, quantity: quantity);

      print('✅ Ventas incrementadas: Producto $productId, Cantidad: $quantity');

      // El stream de Firebase se encargará automáticamente de la actualización
      // gracias a que estamos usando FieldValue.increment() y actualizamos el timestamp
    } catch (e) {
      print('❌ Error al incrementar ventas del producto $productId: $e');
      throw Exception('Error al incrementar ventas del producto: $e');
    }
  }

  /// Decrementa el stock de un producto en el catálogo
  ///
  /// Este método se llama cuando se confirma una venta para actualizar
  /// el inventario del producto en Firebase.
  ///
  /// [accountId] - ID de la cuenta del negocio
  /// [productId] - ID del producto
  /// [quantity] - Cantidad a decrementar del stock
  Future<void> decrementProductStock(
      String accountId, String productId, int quantity) async {
    // Validar parámetros
    if (accountId.isEmpty || productId.isEmpty) {
      throw Exception('El accountId y productId son requeridos');
    }

    if (quantity <= 0) {
      throw Exception('La cantidad debe ser mayor a 0');
    }

    try {
      // Crear nuevos casos de uso con el ID de cuenta actual
      final catalogueRepository = CatalogueRepositoryImpl(id: accountId);
      final decrementStockUseCase =
          DecrementProductStockUseCase(catalogueRepository);

      // Ejecutar la reducción de stock
      await decrementStockUseCase(accountId, productId, quantity);

      print('✅ Stock decrementado: Producto $productId, Cantidad: $quantity');

      // El stream de Firebase se encargará automáticamente de la actualización
      // gracias a que estamos usando FieldValue.increment() y actualizamos el timestamp
    } catch (e) {
      print('❌ Error al decrementar stock del producto $productId: $e');
      throw Exception('Error al decrementar stock del producto: $e');
    }
  }

  /// Determina si dos listas de productos son iguales comparando todos los campos relevantes
  /// incluidos sales, quantityStock y upgrade para detectar cambios de actualización
  bool _areProductListsEqual(
      List<ProductCatalogue> list1, List<ProductCatalogue> list2) {
    if (list1.length != list2.length) return false;

    for (var i = 0; i < list1.length; i++) {
      if (list1[i].id != list2[i].id ||
          list1[i].code != list2[i].code ||
          list1[i].salePrice != list2[i].salePrice ||
          list1[i].description != list2[i].description ||
          list1[i].sales != list2[i].sales ||
          list1[i].quantityStock != list2[i].quantityStock ||
          list1[i].upgrade != list2[i].upgrade) {
        return false;
      }
    }
    return true;
  }

  @override
  void dispose() {
    _catalogueSubscription?.cancel();
    _searchDebounceTimer?.cancel();
    super.dispose();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CatalogueProvider &&
          runtimeType == other.runtimeType &&
          _state == other._state;

  @override
  int get hashCode => _state.hashCode;

  /// Notifica solo cuando cambian productos específicos
  void _notifyProductChanges() {
    // Evitar notificaciones si no hay cambios reales
    if (!hasListeners) return;
    notifyListeners();
  }

  /// Actualiza el estado de forma selectiva
  void _updateState(_CatalogueState newState) {
    final oldState = _state;
    _state = newState;

    // Notificar solo si hay cambios relevantes
    if (oldState != _state) {
      _notifyProductChanges();
    }
  }
}
