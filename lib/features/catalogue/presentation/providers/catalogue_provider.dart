import 'dart:async';
import 'dart:typed_data';
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
import 'package:sellweb/core/utils/helpers/id_generator.dart';
import 'package:sellweb/core/services/storage/i_storage_datasource.dart';
import 'package:sellweb/core/services/storage/storage_paths.dart';
import 'package:sellweb/core/di/injection_container.dart';

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
import '../../domain/usecases/update_brand_usecase.dart';
import '../../domain/usecases/create_public_product_usecase.dart';
import '../../domain/usecases/increment_product_followers_usecase.dart';
import '../../domain/usecases/decrement_product_followers_usecase.dart';
import '../../domain/usecases/save_product_usecase.dart';
import '../../domain/usecases/delete_product_usecase.dart';
import '../../domain/usecases/search_brands_usecase.dart';
import '../../domain/usecases/get_popular_brands_usecase.dart';
import '../../domain/usecases/get_brand_by_id_usecase.dart';
import '../../domain/usecases/create_category_usecase.dart';
import '../../domain/usecases/update_category_usecase.dart';
import '../../domain/usecases/create_provider_usecase.dart';
import '../../domain/usecases/update_provider_usecase.dart';

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
  // Filtros por categoría y proveedor
  final String? selectedCategoryId;
  final String? selectedProviderId;

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
    this.selectedCategoryId,
    this.selectedProviderId,
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
    Object? selectedCategoryId = const Object(),
    Object? selectedProviderId = const Object(),
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
      selectedCategoryId: selectedCategoryId == const Object()
          ? this.selectedCategoryId
          : selectedCategoryId as String?,
      selectedProviderId: selectedProviderId == const Object()
          ? this.selectedProviderId
          : selectedProviderId as String?,
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
          activeFilter == other.activeFilter &&
          selectedCategoryId == other.selectedCategoryId &&
          selectedProviderId == other.selectedProviderId;

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
      activeFilter.hashCode ^
      selectedCategoryId.hashCode ^
      selectedProviderId.hashCode;
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
  final UpdateBrandUseCase _updateBrandUseCase;
  final CreatePublicProductUseCase _createPublicProductUseCase;
  final IncrementProductFollowersUseCase _incrementProductFollowersUseCase;
  final DecrementProductFollowersUseCase _decrementProductFollowersUseCase;
  final SaveProductUseCase _saveProductUseCase;
  final DeleteProductUseCase _deleteProductUseCase;
  // Nuevos UseCases para búsqueda optimizada de marcas
  final SearchBrandsUseCase _searchBrandsUseCase;
  final GetPopularBrandsUseCase _getPopularBrandsUseCase;
  final GetBrandByIdUseCase _getBrandByIdUseCase;
  // UseCases para categorías y proveedores
  final CreateCategoryUseCase _createCategoryUseCase;
  final UpdateCategoryUseCase _updateCategoryUseCase;
  final CreateProviderUseCase _createProviderUseCase;
  final UpdateProviderUseCase _updateProviderUseCase;

  // Stream subscription y timer para debouncing
  StreamSubscription<QuerySnapshot>? _catalogueSubscription;
  Timer? _searchDebounceTimer;

  // Immutable state
  _CatalogueState _state = const _CatalogueState(products: []);

  // Listas de categorías y proveedores
  List<Category> _categories = [];
  List<Provider> _providers = [];

  // Public getters
  List<ProductCatalogue> get products => _state.products;
  List<ProductCatalogue> get filteredProducts => _state.filteredProducts;
  List<ProductCatalogue> get visibleProducts =>
      _hasAnyActiveFilter ? _state.filteredProducts : _state.products;
  String get currentSearchQuery => _state.currentSearchQuery;
  ProductCatalogue? get lastScannedProduct => _state.lastScannedProduct;
  String? get lastScannedCode => _state.lastScannedCode;
  bool get showSplash => _state.showSplash;
  String? get scanError => _state.scanError;
  bool get isLoading => _state.isLoading;
  CatalogueFilter get activeFilter => _state.activeFilter;
  bool get hasActiveFilter => activeFilter != CatalogueFilter.none;
  String? get selectedCategoryId => _state.selectedCategoryId;
  String? get selectedProviderId => _state.selectedProviderId;
  bool get hasCategoryFilter => _state.selectedCategoryId != null;
  bool get hasProviderFilter => _state.selectedProviderId != null;

  /// Verifica si hay algún filtro activo (búsqueda, categoría, proveedor o filtro especial)
  bool get _hasAnyActiveFilter =>
      currentSearchQuery.isNotEmpty ||
      hasActiveFilter ||
      hasCategoryFilter ||
      hasProviderFilter;

  bool get isFiltering => _hasAnyActiveFilter;
  List<Category> get categories => _categories;
  List<Provider> get providers => _providers;

  // ==================== MÉTRICAS DEL CATÁLOGO ====================

  /// Calcula las métricas basadas en los productos visibles (filtrados)
  /// Las métricas se ajustan automáticamente según el filtro activo
  CatalogueMetrics get catalogueMetrics {
    final productsList = visibleProducts;
    return CatalogueMetrics.fromProducts(
      products: productsList,
      currencySign:
          productsList.isNotEmpty ? productsList.first.currencySign : '\$',
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
    this._updateBrandUseCase,
    this._createPublicProductUseCase,
    this._incrementProductFollowersUseCase,
    this._decrementProductFollowersUseCase,
    this._saveProductUseCase,
    this._deleteProductUseCase,
    this._searchBrandsUseCase,
    this._getPopularBrandsUseCase,
    this._getBrandByIdUseCase,
    this._createCategoryUseCase,
    this._updateCategoryUseCase,
    this._createProviderUseCase,
    this._updateProviderUseCase,
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

    // Cargar categorías y proveedores
    loadCategories(id);
    loadProviders(id);

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

  /// Genera un SKU híbrido elegante y único para productos sin código de barras
  ///
  /// Formato: SKU-SALT-YYYYMMDD-NNNN
  /// - SALT: Salt aleatorio de 3 caracteres
  /// - YYYYMMDD: Fecha actual (año-mes-día)
  /// - NNNN: Secuencia única del día (4 dígitos)
  ///
  /// Ejemplo: SKU-X8Y-20251211-0001
  String generateHybridSku() {
    return IdGenerator.generateProductSku();
  }

  /// Crea un producto en la base de datos pública (pending)
  ///
  /// ## Flujo de creación:
  /// 1. Se crea el producto con status 'pending' y followers = 1
  /// 2. El primer comercio que lo crea es el primer follower
  /// 3. Otros comercios que lo agreguen incrementarán el contador
  ///
  /// ## Nota importante:
  /// - Solo se llama para productos con código de barras válido
  /// - Los SKU internos NO se guardan en BD pública
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
        followers: 1, // El creador es el primer follower
        favorite: product.favorite,
        reviewed: false, // Siempre false al crear
        creation: DateTime.now(),
        upgrade: DateTime.now(),
        idUserCreation: product.idUserCreation,
        idUserUpgrade: product.idUserUpgrade,
        attributes: product.attributes,
        status: 'pending', // Siempre pending
      );

      // Crear en la base de datos pública (/PRODUCTOS)
      await _createPublicProductUseCase(
          CreatePublicProductParams(productToSave));
    } catch (e) {
      throw Exception('Error al crear producto pendiente: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // GESTIÓN DE FOLLOWERS (Métrica de popularidad)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Incrementa el contador de followers de un producto público
  ///
  /// Se llama cuando un comercio agrega un producto de la BD global
  /// a su catálogo privado por primera vez.
  ///
  /// ## Contexto de uso:
  /// - Producto existe en BD global (status: 'pending' o 'verified')
  /// - Comercio NO tenía el producto en su catálogo
  /// - Comercio agrega el producto a su catálogo
  ///
  /// [productId] - ID del producto público (código de barras)
  Future<void> incrementProductFollowers(String productId) async {
    if (productId.isEmpty) {
      throw Exception('El productId es requerido');
    }

    try {
      final result = await _incrementProductFollowersUseCase(
        IncrementProductFollowersParams(productId: productId),
      );
      result.fold(
        (failure) => throw Exception(failure.message),
        (_) => null,
      );
    } catch (e) {
      throw Exception('Error al incrementar followers: $e');
    }
  }

  /// Decrementa el contador de followers de un producto público
  ///
  /// Se llama cuando un comercio elimina un producto de su catálogo
  /// que estaba referenciando un producto de la BD global.
  ///
  /// ## Contexto de uso:
  /// - Producto existe en BD global
  /// - Comercio tenía el producto en su catálogo
  /// - Comercio elimina el producto de su catálogo
  ///
  /// ## Nota:
  /// - NO se llama para productos SKU internos
  /// - El contador nunca baja de 0
  ///
  /// [productId] - ID del producto público (código de barras)
  Future<void> decrementProductFollowers(String productId) async {
    if (productId.isEmpty) {
      throw Exception('El productId es requerido');
    }

    try {
      final result = await _decrementProductFollowersUseCase(
        DecrementProductFollowersParams(productId: productId),
      );
      result.fold(
        (failure) => throw Exception(failure.message),
        (_) => null,
      );
    } catch (e) {
      throw Exception('Error al decrementar followers: $e');
    }
  }

  /// Verifica si un producto ya existe en el catálogo local
  ///
  /// Usado para determinar si se debe incrementar followers
  /// al agregar un producto de la BD global.
  bool productExistsInCatalogue(String code) {
    return getProductByCode(code) != null;
  }

  /// Guarda un producto aplicando toda la lógica de negocio
  ///
  /// Delega al [SaveProductUseCase] que determina el tipo de producto
  /// y aplica las reglas correspondientes.
  ///
  /// ## Parámetros:
  /// - [product] - Producto a guardar (puede tener imagen ya subida)
  /// - [accountId] - ID de la cuenta del comercio
  /// - [isCreatingMode] - true si es nuevo en catálogo, false si es edición
  /// - [shouldUpdateUpgrade] - true si debe actualizar timestamp de modificación
  ///
  /// ## Retorna:
  /// - [SaveProductResult] con el producto actualizado y mensaje de éxito
  ///
  /// ## Lanza excepciones:
  /// - Si hay error en validación o guardado
  Future<SaveProductResult> saveProduct({
    required ProductCatalogue product,
    required String accountId,
    required bool isCreatingMode,
    bool shouldUpdateUpgrade = true,
    Uint8List? newImageBytes,
  }) async {
    if (accountId.isEmpty) {
      throw Exception('El ID de la cuenta es requerido');
    }
    if (product.code.isEmpty) {
      throw Exception('El código del producto es requerido');
    }

    try {
      _state = _state.copyWith(isLoading: true);
      notifyListeners();

      final existedInCatalogue = productExistsInCatalogue(product.code);

      var productToSave = product;

      // ═══════════════════════════════════════════════════════════════════════
      // ASIGNAR ID = CÓDIGO (único para todos los productos)
      // ═══════════════════════════════════════════════════════════════════════
      if (isCreatingMode && productToSave.id.isEmpty) {
        // SIEMPRE usar el código como ID (tanto SKU como públicos)
        productToSave = productToSave.copyWith(id: productToSave.code);
      }

      // ═══════════════════════════════════════════════════════════════════════
      // SUBIR IMAGEN (ruta según tipo de producto)
      // ═══════════════════════════════════════════════════════════════════════
      if (newImageBytes != null) {
        final storage = getIt<IStorageDataSource>();
        final isSku =
            productToSave.code.startsWith('SKU-') || productToSave.isSku;

        // Determinar ruta según si es SKU o público
        final String path;
        if (isSku) {
          // Productos SKU → Catálogo privado
          path = StoragePaths.productImage(accountId, productToSave.code);
        } else {
          // Productos públicos → Storage público
          path = StoragePaths.publicProductImage(productToSave.code);
        }

        final imageUrl = await storage.uploadFile(
          path,
          newImageBytes,
          metadata: {
            'contentType': 'image/jpeg',
            'uploaded_by': 'catalogue_editor',
            'product_code': productToSave.code,
            'product_type': isSku ? 'sku' : 'public',
          },
        );
        productToSave = productToSave.copyWith(image: imageUrl);
      }

      // Aplicar timestamps según corresponda
      if (isCreatingMode) {
        productToSave = productToSave.copyWith(
          creation: DateTime.now(),
          upgrade: DateTime.now(),
          documentIdCreation: accountId,
          documentIdUpgrade: accountId,
        );
      } else if (shouldUpdateUpgrade) {
        productToSave = productToSave.copyWith(
          upgrade: DateTime.now(),
          documentIdUpgrade: accountId,
        );
      } else {
        productToSave = productToSave.copyWith(
          documentIdUpgrade: accountId,
        );
      }

      final result = await _saveProductUseCase(
        SaveProductParams(
          product: productToSave,
          accountId: accountId,
          isCreatingMode: isCreatingMode,
          existedInCatalogue: existedInCatalogue,
        ),
      );

      return result.fold(
        (failure) => throw Exception(failure.message),
        (saveResult) => saveResult,
      );
    } finally {
      _state = _state.copyWith(isLoading: false);
      notifyListeners();
    }
  }

  /// Elimina un producto del catálogo aplicando lógica de followers
  ///
  /// Delega al [DeleteProductUseCase] que maneja:
  /// - Productos SKU: Solo elimina del catálogo privado
  /// - Productos públicos (verified/pending): Elimina del catálogo y decrementa followers
  ///
  /// ## Parámetros:
  /// - [product] - Producto a eliminar
  /// - [accountId] - ID de la cuenta del comercio
  ///
  /// ## Lanza excepciones:
  /// - Si hay error en la eliminación
  Future<void> deleteProduct({
    required ProductCatalogue product,
    required String accountId,
  }) async {
    if (accountId.isEmpty) {
      throw Exception('El ID de la cuenta es requerido');
    }
    if (product.id.isEmpty) {
      throw Exception('El ID del producto es requerido');
    }

    try {
      _state = _state.copyWith(isLoading: true);
      notifyListeners();

      final result = await _deleteProductUseCase(
        DeleteProductParams(
          product: product,
          accountId: accountId,
        ),
      );

      result.fold(
        (failure) => throw Exception(failure.message),
        (_) => null,
      );
    } finally {
      _state = _state.copyWith(isLoading: false);
      notifyListeners();
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

  /// Busca marcas por nombre con límite de resultados
  ///
  /// Implementa búsqueda optimizada por prefijo.
  /// Ideal para autocompletado y búsqueda en tiempo real.
  ///
  /// [query] - Término de búsqueda (retorna lista vacía si está vacío)
  /// [limit] - Máximo de resultados (default: 20)
  Future<List<Mark>> searchBrands({
    required String query,
    String country = 'ARG',
    int limit = 20,
  }) async {
    try {
      return await _searchBrandsUseCase(
        SearchBrandsParams(
          query: query,
          country: country,
          limit: limit,
        ),
      );
    } catch (e) {
      throw Exception('Error al buscar marcas: $e');
    }
  }

  /// Obtiene las marcas más populares (verificadas y recientes)
  ///
  /// Útil para mostrar opciones iniciales sin necesidad de búsqueda.
  ///
  /// [limit] - Máximo de resultados (default: 20)
  Future<List<Mark>> getPopularBrands({
    String country = 'ARG',
    int limit = 20,
  }) async {
    try {
      return await _getPopularBrandsUseCase(
        GetPopularBrandsParams(
          country: country,
          limit: limit,
        ),
      );
    } catch (e) {
      throw Exception('Error al obtener marcas populares: $e');
    }
  }

  /// Obtiene una marca específica por ID
  ///
  /// Retorna `null` si la marca no existe.
  Future<Mark?> getBrandById(String id, {String country = 'ARG'}) async {
    try {
      return await _getBrandByIdUseCase(
        GetBrandByIdParams(id: id, country: country),
      );
    } catch (e) {
      throw Exception('Error al obtener marca por ID: $e');
    }
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

  Future<void> updateBrand(Mark brand, {String country = 'ARG'}) async {
    try {
      final result = await _updateBrandUseCase(
          UpdateBrandParams(brand: brand, country: country));
      result.fold(
        (failure) => throw Exception(failure.message),
        (_) => null,
      );
    } catch (e) {
      throw Exception('Error al actualizar marca: $e');
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
    String? categoryId,
    String? providerId,
    bool clearCategoryProvider = false,
    bool shouldNotify = true,
  }) {
    final normalizedQuery = (query ?? _state.currentSearchQuery).trim();
    final effectiveFilter = filter ?? _state.activeFilter;
    final effectiveCategoryId = clearCategoryProvider
        ? null
        : (categoryId ?? _state.selectedCategoryId);
    final effectiveProviderId = clearCategoryProvider
        ? null
        : (providerId ?? _state.selectedProviderId);

    final bool hasQuery = normalizedQuery.isNotEmpty;
    final bool hasFilter = effectiveFilter != CatalogueFilter.none;
    final bool hasCategoryFilter = effectiveCategoryId != null;
    final bool hasProviderFilter = effectiveProviderId != null;

    List<ProductCatalogue> workingList = _state.products;

    // 1. Filtro por categoría
    if (hasCategoryFilter) {
      workingList = workingList
          .where((product) => product.category == effectiveCategoryId)
          .toList();
    }

    // 2. Filtro por proveedor
    if (hasProviderFilter) {
      workingList = workingList
          .where((product) => product.provider == effectiveProviderId)
          .toList();
    }

    // 3. Búsqueda por texto (descripción, marca, código, etc.)
    if (hasQuery) {
      // Si tenemos resultados de búsqueda pre-calculados, usarlos como referencia
      if (searchResults != null) {
        // Intersección: productos que están en searchResults Y en workingList
        final searchIds = searchResults.map((p) => p.id).toSet();
        workingList =
            workingList.where((p) => searchIds.contains(p.id)).toList();
      } else {
        // Buscar en la lista de trabajo actual
        workingList = _searchInList(workingList, normalizedQuery);
      }
    }

    // 4. Filtros especiales (favoritos, stock)
    if (hasFilter) {
      workingList = _filterProductsByOption(workingList, effectiveFilter);
    }

    final bool shouldUseFilteredList =
        hasQuery || hasFilter || hasCategoryFilter || hasProviderFilter;

    _state = _state.copyWith(
      filteredProducts: shouldUseFilteredList
          ? List<ProductCatalogue>.from(workingList)
          : const <ProductCatalogue>[],
      currentSearchQuery: normalizedQuery,
      activeFilter: effectiveFilter,
      selectedCategoryId: effectiveCategoryId,
      selectedProviderId: effectiveProviderId,
    );

    if (shouldNotify) {
      notifyListeners();
    }
  }

  /// Búsqueda local en una lista de productos
  List<ProductCatalogue> _searchInList(
      List<ProductCatalogue> source, String query) {
    final normalizedQuery = query.toLowerCase().trim();
    if (normalizedQuery.isEmpty) return source;

    return source.where((product) {
      // Buscar en descripción
      if (product.description.toLowerCase().contains(normalizedQuery))
        return true;
      // Buscar en código
      if (product.code.toLowerCase().contains(normalizedQuery)) return true;
      // Buscar en marca
      if (product.nameMark.toLowerCase().contains(normalizedQuery)) return true;
      // Buscar en categoría
      if (product.nameCategory.toLowerCase().contains(normalizedQuery))
        return true;
      // Buscar en proveedor
      if (product.nameProvider.toLowerCase().contains(normalizedQuery))
        return true;
      return false;
    }).toList();
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

  // ═══════════════════════════════════════════════════════════════════════════
  // GESTIÓN DE CATEGORÍAS Y PROVEEDORES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Carga las categorías desde Firestore
  void loadCategories(String accountId) {
    getCategoriesStream(accountId).listen((categories) {
      _categories = categories;
      notifyListeners();
    });
  }

  /// Carga los proveedores desde Firestore
  void loadProviders(String accountId) {
    getProvidersStream(accountId).listen((providers) {
      _providers = providers;
      notifyListeners();
    });
  }

  /// Crea una nueva categoría
  Future<void> createCategory({
    required String accountId,
    required Category category,
  }) async {
    try {
      await _createCategoryUseCase(
        CreateCategoryParams(
          accountId: accountId,
          category: category,
        ),
      );
    } catch (e) {
      throw Exception('Error al crear categoría: $e');
    }
  }

  /// Actualiza una categoría existente
  Future<void> updateCategory({
    required Category category,
  }) async {
    try {
      final accountId = getIt<AccountProfile>().id;
      await _updateCategoryUseCase(
        UpdateCategoryParams(
          accountId: accountId,
          category: category,
        ),
      );
    } catch (e) {
      throw Exception('Error al actualizar categoría: $e');
    }
  }

  /// Crea un nuevo proveedor
  Future<void> createProvider({
    required String accountId,
    required Provider provider,
  }) async {
    try {
      await _createProviderUseCase(
        CreateProviderParams(
          accountId: accountId,
          provider: provider,
        ),
      );
    } catch (e) {
      throw Exception('Error al crear proveedor: $e');
    }
  }

  /// Actualiza un proveedor existente
  Future<void> updateProvider({
    required Provider provider,
  }) async {
    try {
      final accountId = getIt<AccountProfile>().id;
      await _updateProviderUseCase(
        UpdateProviderParams(
          accountId: accountId,
          provider: provider,
        ),
      );
    } catch (e) {
      throw Exception('Error al actualizar proveedor: $e');
    }
  }

  /// Filtra productos por categoría (usa el sistema centralizado)
  void filterByCategory(String categoryId) {
    _recomputeFilteredProducts(
      categoryId: categoryId,
      providerId: null, // Limpiar filtro de proveedor
      query:
          '', // Mantener la búsqueda vacía, se mostrará el nombre en el buscador desde la UI
    );
  }

  /// Filtra productos por proveedor (usa el sistema centralizado)
  void filterByProvider(String providerId) {
    _recomputeFilteredProducts(
      providerId: providerId,
      categoryId: null, // Limpiar filtro de categoría
      query:
          '', // Mantener la búsqueda vacía, se mostrará el nombre en el buscador desde la UI
    );
  }

  /// Limpia todos los filtros (categoría, proveedor, búsqueda, filtros especiales)
  void clearAllFilters() {
    _recomputeFilteredProducts(
      clearCategoryProvider: true,
      query: '',
      filter: CatalogueFilter.none,
    );
  }

  /// Limpia solo el filtro de categoría/proveedor (mantiene búsqueda y filtros especiales)
  void clearCategoryProviderFilter() {
    _recomputeFilteredProducts(
      clearCategoryProvider: true,
    );
  }

  /// Obtiene el nombre de la categoría seleccionada
  String? get selectedCategoryName {
    if (_state.selectedCategoryId == null) return null;
    try {
      return _categories
          .firstWhere((c) => c.id == _state.selectedCategoryId)
          .name;
    } catch (_) {
      return null;
    }
  }

  /// Obtiene el nombre del proveedor seleccionado
  String? get selectedProviderName {
    if (_state.selectedProviderId == null) return null;
    try {
      return _providers
          .firstWhere((p) => p.id == _state.selectedProviderId)
          .name;
    } catch (_) {
      return null;
    }
  }
}
