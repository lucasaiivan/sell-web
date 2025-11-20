import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/core.dart';
import 'package:sellweb/core/services/search_catalogue_service.dart';
import '../../data/catalogue_repository_impl.dart';
import '../../domain/entities/catalogue.dart';
import '../../domain/entities/user.dart';
import '../../domain/usecases/catalogue_usecases.dart';
import '../../domain/usecases/account_usecase.dart';

/// Tipos de filtro disponibles para el catálogo
enum CatalogueFilter { none, favorites, lowStock, outOfStock }

/// Estado inmutable del provider de catálogo
///
/// Encapsula todo el estado relacionado con productos y búsqueda
/// para optimizar notificaciones y mantener coherencia
class _CatalogueState {
  final List<ProductCatalogue> products;
  final ProductCatalogue? lastScannedProduct;
  final String? lastScannedCode;
  final bool showSplash;
  final String? scanError;
  final bool isLoading;
  final List<ProductCatalogue> filteredProducts;
  final String currentSearchQuery;
  final CatalogueFilter activeFilter;

  const _CatalogueState({
    required this.products,
    this.lastScannedProduct,
    this.lastScannedCode,
    this.showSplash = false,
    this.scanError,
    this.isLoading = true,
    this.filteredProducts = const <ProductCatalogue>[],
    this.currentSearchQuery = '',
    this.activeFilter = CatalogueFilter.none,
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
    CatalogueFilter? activeFilter,
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
      activeFilter: activeFilter ?? this.activeFilter,
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
          isLoading == other.isLoading &&
          listEquals(filteredProducts, other.filteredProducts) &&
          currentSearchQuery == other.currentSearchQuery &&
          activeFilter == other.activeFilter;

  @override
  int get hashCode =>
      products.hashCode ^
      lastScannedProduct.hashCode ^
      lastScannedCode.hashCode ^
      showSplash.hashCode ^
      scanError.hashCode ^
      isLoading.hashCode ^
      filteredProducts.hashCode ^
      currentSearchQuery.hashCode ^
      activeFilter.hashCode;
}

/// Provider para gestionar el estado del catálogo de productos
///
/// **Responsabilidad:** Coordinar UI y casos de uso de catálogo
/// - Gestiona estado de productos y búsquedas
/// - Delega operaciones CRUD a CatalogueUseCases (crear, actualizar, buscar)
/// - Delega búsqueda y filtrado a SearchCatalogueService
/// - Maneja streams de Firebase para sincronización en tiempo real
/// - Proporciona búsqueda con debouncing para mejor rendimiento
/// - No contiene lógica de negocio, solo coordinación
///
/// **Arquitectura:**
/// - Estado inmutable con _CatalogueState para optimizar notificaciones
/// - Streams de Firebase para actualizaciones automáticas de productos
/// - Debouncing en búsquedas para reducir operaciones
///
/// **Uso:**
/// ```dart
/// final catalogueProvider = Provider.of<CatalogueProvider>(context);
/// catalogueProvider.initCatalogue(accountId); // Inicializar catálogo
/// catalogueProvider.searchProducts(query: 'producto'); // Buscar productos
/// await catalogueProvider.saveProductToCatalogue(...); // Guardar producto
/// ```
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

  // Dependencies - Únicamente CatalogueUseCases
  CatalogueUseCases _catalogueUseCases;
  final AccountsUseCase getUserAccountsUseCase;

  // Stream subscription y timer para debouncing
  StreamSubscription<QuerySnapshot>? _catalogueSubscription;
  Timer? _searchDebounceTimer;

  // Immutable state
  _CatalogueState _state = _CatalogueState(products: []);

  // Public getters
  List<ProductCatalogue> get products => _state.products;
  List<ProductCatalogue> get filteredProducts => _state.filteredProducts;
  List<ProductCatalogue> get visibleProducts =>
      (currentSearchQuery.isNotEmpty || hasActiveFilter)
          ? _state.filteredProducts
          : _state.products;
  String get currentSearchQuery => _state.currentSearchQuery;
  ProductCatalogue? get lastScannedProduct => _state.lastScannedProduct;
  String? get lastScannedCode => _state.lastScannedCode;
  bool get showSplash => _state.showSplash;
  String? get scanError => _state.scanError;
  bool get isLoading => _state.isLoading;
  CatalogueFilter get activeFilter => _state.activeFilter;
  bool get hasActiveFilter => activeFilter != CatalogueFilter.none;
  bool get isFiltering =>
      currentSearchQuery.isNotEmpty || activeFilter != CatalogueFilter.none;

  /// Obtiene los productos más vendidos ordenados por cantidad de ventas
  /// [limit] Número máximo de productos a retornar (por defecto 8)
  /// [minimumSales] Número mínimo de ventas para incluir el producto (por defecto 1)
  List<ProductCatalogue> getTopFilterProducts(
      {int limit = 50, int minimumSales = 1}) {
    return SearchCatalogueService.getTopSellingProducts(
      products: _state.products,
      limit: limit,
      minimumSales: minimumSales,
    );
  }

  CatalogueProvider({
    required CatalogueUseCases catalogueUseCases,
    required this.getUserAccountsUseCase,
  }) : _catalogueUseCases = catalogueUseCases;

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
    _catalogueUseCases = CatalogueUseCases(newCatalogueRepository);

    // Inicializar el stream de productos para la nueva cuenta
    _catalogueSubscription = _catalogueUseCases.getCatalogueStream().listen(
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
          _refreshFilteredView();
        }

        // Marcar como cargado si aún está en estado loading
        if (_state.isLoading) {
          _updateState(_state.copyWith(isLoading: false));
        }
      },
      onError: (error) {
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
    try {
      return _state.products.firstWhere(
        (product) => product.code.trim().toUpperCase() == normalizedCode,
      );
    } catch (e) {
      return null;
    }
  }

  /// Busca un producto público por código de barra en la base pública.
  Future<Product?> getPublicProductByCode(String code) async {
    return await _catalogueUseCases.getPublicProductByCode(code);
  }

  /// Busca productos usando el algoritmo avanzado de búsqueda
  /// Permite buscar sin importar el orden de las palabras
  List<ProductCatalogue> searchProducts({
    required String query,
    int? maxResults,
  }) {
    final results = SearchCatalogueService.searchProducts(
      products: _state.products,
      query: query,
      maxResults: maxResults,
    );

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
      _recomputeFilteredProducts(
        query: query,
        searchResults: results,
      );
    });
  }

  /// Limpia los resultados de búsqueda
  void clearSearchResults() {
    _searchDebounceTimer?.cancel();
    _recomputeFilteredProducts(query: '');
  }

  /// Aplica un filtro predefinido a la lista de productos
  void applyFilter(CatalogueFilter filter) {
    if (filter == _state.activeFilter) {
      return;
    }
    _recomputeFilteredProducts(filter: filter);
  }

  /// Limpia cualquier filtro aplicado
  void clearFilter() {
    if (!hasActiveFilter) {
      return;
    }
    _recomputeFilteredProducts(filter: CatalogueFilter.none);
  }

  /// Busca productos por código exacto
  List<ProductCatalogue> searchByExactCode(String code) {
    return SearchCatalogueService.searchByExactCode(
      products: _state.products,
      code: code,
    );
  }

  /// Busca productos por categoría
  List<ProductCatalogue> searchByCategory(String category) {
    return SearchCatalogueService.searchByCategory(
      products: _state.products,
      category: category,
    );
  }

  /// Fuerza la actualización del catálogo desde Firebase
  /// Útil cuando se necesita asegurar que los datos estén sincronizados
  Future<void> forceRefreshCatalogue() async {
    if (_catalogueSubscription == null) {
      return;
    }

    try {
      _updateState(_state.copyWith(isLoading: true));

      // La actualización se hará automáticamente por el listener del stream
      // Solo necesitamos marcar que estamos refrescando
    } catch (e) {
      _updateState(_state.copyWith(
        isLoading: false,
        scanError: 'Error al actualizar catálogo: $e',
      ));
    }
  }

  /// Busca productos por marca
  List<ProductCatalogue> searchByBrand(String brand) {
    return SearchCatalogueService.searchByBrand(
      products: _state.products,
      brand: brand,
    );
  }

  /// Obtiene sugerencias de búsqueda
  List<String> getSearchSuggestions({
    required String query,
    int maxSuggestions = 5,
  }) {
    final suggestions = SearchCatalogueService.getSearchSuggestions(
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
      await _catalogueUseCases.addProductToCatalogue(productToSave, accountId);
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
        creation: DateFormatter.getCurrentTimestamp(),
        upgrade: DateFormatter.getCurrentTimestamp(),
        idUserCreation: product.idUserCreation,
        idUserUpgrade: product.idUserUpgrade,
      );

      await _catalogueUseCases.createPublicProduct(productToSave);
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
    _recomputeFilteredProducts(shouldNotify: false);
    _shouldNotifyListeners = true;
    notifyListeners();
  }

  /// Agrega un nuevo producto al catálogo o actualiza uno existente.
  ///
  /// [product] El producto a agregar o actualizar en el catálogo
  /// [accountId] El ID de la cuenta donde se agregará el producto
  /// [accountProfile] El perfil de la cuenta para registrar el precio (opcional)
  /// Retorna un [Future<void>] que se completa cuando la operación termina
  Future<void> addAndUpdateProductToCatalogue(
      ProductCatalogue product, String accountId,
      {AccountProfile? accountProfile}) async {
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
          upgrade: DateFormatter.getCurrentTimestamp(),
          documentIdUpgrade: accountId,
        );
        await _catalogueUseCases.addProductToCatalogue(
            updatedProduct, accountId);
      } else {
        // Agregar nuevo producto
        final newProduct = product.copyWith(
          creation: DateFormatter.getCurrentTimestamp(),
          upgrade: DateFormatter.getCurrentTimestamp(),
          documentIdCreation: accountId,
          documentIdUpgrade: accountId,
        );
        await _catalogueUseCases.addProductToCatalogue(newProduct, accountId);
      }

      // Registrar precio del producto en la base de datos pública si se proporciona accountProfile
      if (accountProfile != null && product.salePrice > 0) {
        try {
          final productPrice = ProductPrice(
            id: accountId,
            idAccount: accountId,
            imageAccount: accountProfile.image,
            nameAccount: accountProfile.name,
            price: product.salePrice,
            time: DateFormatter.getCurrentTimestamp(),
            currencySign: accountProfile.currencySign,
            province: accountProfile.province,
            town: accountProfile.town,
          );

          await _catalogueUseCases.registerProductPrice(
              productPrice, product.code);
        } catch (e) {
          // No lanzamos error aquí para no interrumpir el flujo principal
        }
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
      // Ejecutar el incremento de ventas usando CatalogueUseCases
      await _catalogueUseCases.incrementProductSales(accountId, productId,
          quantity: quantity);

      // El stream de Firebase se encargará automáticamente de la actualización
      // gracias a que estamos usando FieldValue.increment() y actualizamos el timestamp
    } catch (e) {
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
      // Ejecutar la reducción de stock usando CatalogueUseCases
      await _catalogueUseCases.decrementProductStock(
          accountId, productId, quantity);

      // El stream de Firebase se encargará automáticamente de la actualización
      // gracias a que estamos usando FieldValue.increment() y actualizamos el timestamp
    } catch (e) {
      throw Exception('Error al decrementar stock del producto: $e');
    }
  }

  /// Actualiza el estado de favorito de un producto en el catálogo
  ///
  /// Este método se llama cuando el usuario marca/desmarca un producto como favorito
  /// para sincronizar el estado con Firebase.
  ///
  /// [accountId] - ID de la cuenta del negocio
  /// [productId] - ID del producto
  /// [isFavorite] - Nuevo estado de favorito
  Future<void> updateProductFavorite(
      String accountId, String productId, bool isFavorite) async {
    // Validar parámetros
    if (accountId.isEmpty || productId.isEmpty) {
      throw Exception('El accountId y productId son requeridos');
    }

    try {
      // Ejecutar la actualización de favorito usando CatalogueUseCases
      await _catalogueUseCases.updateProductFavorite(
          accountId, productId, isFavorite);

      // El stream de Firebase se encargará automáticamente de la actualización
      // gracias a que actualizamos el timestamp de modificación
    } catch (e) {
      throw Exception('Error al actualizar favorito del producto: $e');
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

  /// Recalcula la lista filtrada en base al query y filtro activo
  void _recomputeFilteredProducts({
    String? query,
    List<ProductCatalogue>? searchResults,
    CatalogueFilter? filter,
    bool shouldNotify = true,
  }) {
    final normalizedQuery = (query ?? _state.currentSearchQuery).trim();
    final effectiveFilter = filter ?? _state.activeFilter;

    final bool hasQuery = normalizedQuery.isNotEmpty;
    final bool hasFilter = effectiveFilter != CatalogueFilter.none;

    List<ProductCatalogue> workingList = _state.products;

    if (hasQuery) {
      workingList = searchResults ?? searchProducts(query: normalizedQuery);
    }

    if (hasFilter) {
      workingList = _filterProductsByOption(workingList, effectiveFilter);
    }

    final bool shouldUseFilteredList = hasQuery || hasFilter;

    _state = _state.copyWith(
      filteredProducts: shouldUseFilteredList
          ? List<ProductCatalogue>.from(workingList)
          : const <ProductCatalogue>[],
      currentSearchQuery: normalizedQuery,
      activeFilter: effectiveFilter,
    );

    if (shouldNotify) {
      notifyListeners();
    }
  }

  /// Aplica la regla del filtro correspondiente
  List<ProductCatalogue> _filterProductsByOption(
      List<ProductCatalogue> source, CatalogueFilter filter) {
    switch (filter) {
      case CatalogueFilter.favorites:
        return source.where((product) => product.favorite).toList();
      case CatalogueFilter.lowStock:
        return source.where(_isLowStock).toList();
      case CatalogueFilter.outOfStock:
        return source.where(_isOutOfStock).toList();
      case CatalogueFilter.none:
        return source;
    }
  }

  bool _isLowStock(ProductCatalogue product) {
    if (!product.stock) return false;
    return product.quantityStock > 0 &&
        product.quantityStock <= product.alertStock;
  }

  bool _isOutOfStock(ProductCatalogue product) {
    if (!product.stock) return false;
    return product.quantityStock <= 0;
  }

  void _refreshFilteredView() {
    if (!isFiltering) {
      return;
    }
    _recomputeFilteredProducts(shouldNotify: false);
    _notifyProductChanges();
  }
}
