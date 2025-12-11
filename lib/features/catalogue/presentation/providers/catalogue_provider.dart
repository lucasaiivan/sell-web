import 'dart:async';
import 'package:flutter/foundation.dart' hide Category;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';
import 'package:sellweb/features/catalogue/data/datasources/local_search_datasource.dart';
import 'package:sellweb/features/catalogue/domain/entities/product_catalogue.dart';
import 'package:sellweb/features/catalogue/domain/entities/product.dart';
import 'package:sellweb/features/catalogue/domain/entities/product_price.dart';
import 'package:sellweb/features/catalogue/domain/entities/category.dart';
import 'package:sellweb/features/catalogue/domain/entities/mark.dart';
import 'package:sellweb/features/catalogue/domain/entities/provider.dart';
import 'package:sellweb/features/catalogue/domain/entities/catalogue_metric.dart';
import 'package:sellweb/features/auth/domain/entities/account_profile.dart';
import 'package:sellweb/core/presentation/providers/initializable_provider.dart';

// UseCases
import '../../domain/usecases/get_catalogue_stream_usecase.dart';
import '../../domain/usecases/get_public_product_by_code_usecase.dart';
import '../../domain/usecases/add_product_to_catalogue_usecase.dart';
import '../../domain/usecases/register_product_price_usecase.dart';
import '../../domain/usecases/increment_product_sales_usecase.dart';
import '../../domain/usecases/decrement_product_stock_usecase.dart';
import '../../domain/usecases/update_product_favorite_usecase.dart';
import '../../domain/usecases/get_categories_stream_usecase.dart';
import '../../domain/usecases/get_providers_stream_usecase.dart';
import '../../domain/usecases/get_brands_stream_usecase.dart';
import '../../domain/usecases/create_brand_usecase.dart';
import '../../domain/usecases/create_pending_product_usecase.dart';

/// Tipos de filtro disponibles para el catálogo
enum CatalogueFilter { none, favorites, lowStock, outOfStock }

/// Estado inmutable del provider de catálogo
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
@injectable
class CatalogueProvider extends ChangeNotifier
    implements InitializableProvider {
  bool _shouldNotifyListeners = true;

  set shouldNotifyListeners(bool value) {
    _shouldNotifyListeners = value;
  }

  @override
  void notifyListeners() {
    if (_shouldNotifyListeners) {
      super.notifyListeners();
    }
  }

  // UseCases
  final GetCatalogueStreamUseCase _getCatalogueStreamUseCase;
  final GetPublicProductByCodeUseCase _getPublicProductByCodeUseCase;
  final AddProductToCatalogueUseCase _addProductToCatalogueUseCase;
  final RegisterProductPriceUseCase _registerProductPriceUseCase;
  final IncrementProductSalesUseCase _incrementProductSalesUseCase;
  final DecrementProductStockUseCase _decrementProductStockUseCase;
  final UpdateProductFavoriteUseCase _updateProductFavoriteUseCase;
  final GetCategoriesStreamUseCase _getCategoriesStreamUseCase;
  final GetProvidersStreamUseCase _getProvidersStreamUseCase;
  final GetBrandsStreamUseCase _getBrandsStreamUseCase;
  final CreateBrandUseCase _createBrandUseCase;
  final CreatePendingProductUseCase _createPendingProductUseCase;

  // Stream subscription y timer para debouncing
  StreamSubscription<QuerySnapshot>? _catalogueSubscription;
  Timer? _searchDebounceTimer;

  // Immutable state
  _CatalogueState _state = const _CatalogueState(products: []);

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

  // ==================== MÉTRICAS DEL CATÁLOGO ====================
  
  /// Calcula las métricas basadas en los productos visibles (filtrados)
  /// Las métricas se ajustan automáticamente según el filtro activo
  CatalogueMetrics get catalogueMetrics {
    final productsList = visibleProducts;
    return CatalogueMetrics.fromProducts(
      products: productsList,
      currencySign: productsList.isNotEmpty 
          ? productsList.first.currencySign 
          : '\$',
    );
  }

  // ===============================================================

  List<ProductCatalogue> getTopFilterProducts(
      {int limit = 50, int minimumSales = 1}) {
    return LocalSearchDataSource.getTopSellingProducts(
      products: _state.products,
      limit: limit,
      minimumSales: minimumSales,
    );
  }

  CatalogueProvider(
    this._getCatalogueStreamUseCase,
    this._getPublicProductByCodeUseCase,
    this._addProductToCatalogueUseCase,
    this._registerProductPriceUseCase,
    this._incrementProductSalesUseCase,
    this._decrementProductStockUseCase,
    this._updateProductFavoriteUseCase,
    this._getCategoriesStreamUseCase,
    this._getProvidersStreamUseCase,
    this._getBrandsStreamUseCase,
    this._createBrandUseCase,
    this._createPendingProductUseCase,
  );

  void initCatalogue(String id) {
    if (id.isEmpty) {
      throw Exception('El ID de la cuenta no puede estar vacío.');
    }

    _catalogueSubscription?.cancel();

    _updateState(const _CatalogueState(
      products: [],
      isLoading: true,
    ));

    if (id == 'demo') {
      return;
    }

    _catalogueSubscription =
        _getCatalogueStreamUseCase(GetCatalogueStreamParams(id)).listen(
      (snapshot) {
        final products = snapshot.docs
            .map((doc) =>
                ProductCatalogue.fromMap(doc.data() as Map<String, dynamic>))
            .toList();

        products.sort((a, b) => b.upgrade.compareTo(a.upgrade));

        if (!_areProductListsEqual(_state.products, products)) {
          _updateState(_state.copyWith(products: products));
          _refreshFilteredView();
        }

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

  Future<Product?> getPublicProductByCode(String code) async {
    final result = await _getPublicProductByCodeUseCase(
        GetPublicProductByCodeParams(code));
    return result.fold(
      (failure) => null,
      (product) => product,
    );
  }

  List<ProductCatalogue> searchProducts({
    required String query,
    int? maxResults,
  }) {
    final results = LocalSearchDataSource.searchProducts(
      products: _state.products,
      query: query,
      maxResults: maxResults,
    );

    return results;
  }

  void searchProductsWithDebounce({
    required String query,
    int? maxResults,
    Duration delay = const Duration(milliseconds: 300),
  }) {
    _searchDebounceTimer?.cancel();

    _searchDebounceTimer = Timer(delay, () {
      final results = searchProducts(query: query, maxResults: maxResults);
      _recomputeFilteredProducts(
        query: query,
        searchResults: results,
      );
    });
  }

  void clearSearchResults() {
    _searchDebounceTimer?.cancel();
    _recomputeFilteredProducts(query: '');
  }

  void applyFilter(CatalogueFilter filter) {
    if (filter == _state.activeFilter) {
      return;
    }
    _recomputeFilteredProducts(filter: filter);
  }

  void clearFilter() {
    if (!hasActiveFilter) {
      return;
    }
    _recomputeFilteredProducts(filter: CatalogueFilter.none);
  }

  List<ProductCatalogue> searchByExactCode(String code) {
    return LocalSearchDataSource.searchByExactCode(
      products: _state.products,
      code: code,
    );
  }

  List<ProductCatalogue> searchByCategory(String category) {
    return LocalSearchDataSource.searchByCategory(
      products: _state.products,
      category: category,
    );
  }

  Future<void> forceRefreshCatalogue() async {
    if (_catalogueSubscription == null) {
      return;
    }

    try {
      _updateState(_state.copyWith(isLoading: true));
    } catch (e) {
      _updateState(_state.copyWith(
        isLoading: false,
        scanError: 'Error al actualizar catálogo: $e',
      ));
    }
  }

  List<ProductCatalogue> searchByBrand(String brand) {
    return LocalSearchDataSource.searchByBrand(
      products: _state.products,
      brand: brand,
    );
  }

  List<ProductCatalogue> searchByProvider(String provider) {
    return LocalSearchDataSource.searchByProvider(
      products: _state.products,
      provider: provider,
    );
  }

  List<String> getSearchSuggestions({
    required String query,
    int maxSuggestions = 5,
  }) {
    final suggestions = LocalSearchDataSource.getSearchSuggestions(
      products: _state.products,
      query: query,
      maxSuggestions: maxSuggestions,
    );

    return suggestions;
  }

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

    final publicProduct = await getPublicProductByCode(code);
    if (publicProduct != null) {
      onFoundInPublic(publicProduct);
    } else {
      _state = _state.copyWith(scanError: 'Producto no encontrado');
      notifyListeners();
    }
  }

  Future<void> saveProductToCatalogue(
      ProductCatalogue productToSave, String accountId) async {
    if (accountId.isEmpty) {
      throw Exception('El ID de la cuenta no está definido o es nulo.');
    }
    try {
      _shouldNotifyListeners = false;
      final result = await _addProductToCatalogueUseCase(
          AddProductToCatalogueParams(
              product: productToSave, accountId: accountId));
      result.fold(
        (failure) => throw Exception(failure.message),
        (_) => null,
      );
      _shouldNotifyListeners = true;
      notifyListeners();
    } catch (e) {
      _shouldNotifyListeners = true;
      throw Exception('Error al guardar producto en catálogo: $e');
    }
  }

  /// Genera un SKU híbrido para productos sin código de barras
  String generateHybridSku(String accountId) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final idPart = accountId.length > 5 ? accountId.substring(0, 5) : accountId;
    return 'SKU-$idPart-$timestamp';
  }

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
        reviewed: false, // Siempre false al crear
        creation: DateTime.now(),
        upgrade: DateTime.now(),
        idUserCreation: product.idUserCreation,
        idUserUpgrade: product.idUserUpgrade,
        attributes: product.attributes,
        status: 'pending', // Siempre pending
      );

      // Usar el caso de uso de pendientes
      await _createPendingProductUseCase(productToSave);
    } catch (e) {
      throw Exception('Error al crear producto pendiente: $e');
    }
  }

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

  Future<void> addAndUpdateProductToCatalogue(
      ProductCatalogue product, String accountId,
      {AccountProfile? accountProfile, bool shouldUpdateUpgrade = true}) async {
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

      final existingProduct = getProductByCode(product.code);

      if (existingProduct != null && existingProduct.id.isNotEmpty) {
        final updatedProduct = shouldUpdateUpgrade
            ? product.copyWith(
                upgrade: DateTime.now(),
                documentIdUpgrade: accountId,
              )
            : product.copyWith(
                documentIdUpgrade: accountId,
              );
        final result = await _addProductToCatalogueUseCase(
            AddProductToCatalogueParams(
                product: updatedProduct, accountId: accountId));
        result.fold(
          (failure) => throw Exception(failure.message),
          (_) => null,
        );
      } else {
        final newProduct = product.copyWith(
          creation: DateTime.now(),
          upgrade: DateTime.now(),
          documentIdCreation: accountId,
          documentIdUpgrade: accountId,
        );
        final result = await _addProductToCatalogueUseCase(
            AddProductToCatalogueParams(
                product: newProduct, accountId: accountId));
        result.fold(
          (failure) => throw Exception(failure.message),
          (_) => null,
        );
      }

      if (accountProfile != null && product.salePrice > 0) {
        try {
          final productPrice = ProductPrice(
            id: accountId,
            idAccount: accountId,
            imageAccount: accountProfile.image,
            nameAccount: accountProfile.name,
            price: product.salePrice,
            time: DateTime.now(),
            currencySign: accountProfile.currencySign,
            province: accountProfile.province,
            town: accountProfile.town,
          );

          await _registerProductPriceUseCase(RegisterProductPriceParams(
              productPrice: productPrice, productCode: product.code));
        } catch (e) {
          // Silent error
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

  Future<void> incrementProductSales(String accountId, String productId,
      {int quantity = 1}) async {
    if (accountId.isEmpty || productId.isEmpty) {
      throw Exception('El accountId y productId son requeridos');
    }

    if (quantity <= 0) {
      throw Exception('La cantidad debe ser mayor a 0');
    }

    try {
      final result = await _incrementProductSalesUseCase(
          IncrementProductSalesParams(
              accountId: accountId, productId: productId, quantity: quantity));
      result.fold(
        (failure) => throw Exception(failure.message),
        (_) => null,
      );
    } catch (e) {
      throw Exception('Error al incrementar ventas del producto: $e');
    }
  }

  Future<void> decrementProductStock(
      String accountId, String productId, int quantity) async {
    if (accountId.isEmpty || productId.isEmpty) {
      throw Exception('El accountId y productId son requeridos');
    }

    if (quantity <= 0) {
      throw Exception('La cantidad debe ser mayor a 0');
    }

    try {
      final result = await _decrementProductStockUseCase(
          DecrementProductStockParams(
              accountId: accountId, productId: productId, quantity: quantity));
      result.fold(
        (failure) => throw Exception(failure.message),
        (_) => null,
      );
    } catch (e) {
      throw Exception('Error al decrementar stock del producto: $e');
    }
  }

  Future<void> updateProductFavorite(
      String accountId, String productId, bool isFavorite) async {
    if (accountId.isEmpty || productId.isEmpty) {
      throw Exception('El accountId y productId son requeridos');
    }

    try {
      final result = await _updateProductFavoriteUseCase(
          UpdateProductFavoriteParams(
              accountId: accountId,
              productId: productId,
              isFavorite: isFavorite));
      result.fold(
        (failure) => throw Exception(failure.message),
        (_) => null,
      );
    } catch (e) {
      throw Exception('Error al actualizar favorito del producto: $e');
    }
  }

  Stream<List<Category>> getCategoriesStream(String accountId) {
    return _getCategoriesStreamUseCase(GetCategoriesStreamParams(accountId));
  }

  Stream<List<Provider>> getProvidersStream(String accountId) {
    return _getProvidersStreamUseCase(GetProvidersStreamParams(accountId));
  }

  Stream<List<Mark>> getBrandsStream() {
    return _getBrandsStreamUseCase(const GetBrandsStreamParams());
  }

  Future<void> createBrand(Mark brand, {String country = 'ARG'}) async {
    try {
      final result = await _createBrandUseCase(
          CreateBrandParams(brand: brand, country: country));
      result.fold(
        (failure) => throw Exception(failure.message),
        (_) => null,
      );
    } catch (e) {
      throw Exception('Error al crear marca: $e');
    }
  }

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
          list1[i].favorite != list2[i].favorite ||
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

  /// Implementación de InitializableProvider: Inicializa el provider para una cuenta
  @override
  Future<void> initialize(String accountId) async {
    initCatalogue(accountId);
  }

  /// Implementación de InitializableProvider: Limpia recursos y cancela suscripciones
  @override
  void cleanup() {
    _catalogueSubscription?.cancel();
    _catalogueSubscription = null;
    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = null;
    _state = const _CatalogueState(products: []);

    try {
      notifyListeners();
    } catch (e) {
      debugPrint('⚠️ CatalogueProvider.cleanup: Provider ya disposed');
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CatalogueProvider &&
          runtimeType == other.runtimeType &&
          _state == other._state;

  @override
  int get hashCode => _state.hashCode;

  void _notifyProductChanges() {
    if (!hasListeners) return;
    notifyListeners();
  }

  void _updateState(_CatalogueState newState) {
    final oldState = _state;
    _state = newState;

    if (oldState != _state) {
      _notifyProductChanges();
    }
  }

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
