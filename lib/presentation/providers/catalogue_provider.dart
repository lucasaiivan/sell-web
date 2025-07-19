import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sellweb/core/utils/fuctions.dart';
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

  const _CatalogueState({
    required this.products,
    this.lastScannedProduct,
    this.lastScannedCode,
    this.showSplash = false,
    this.scanError,
    this.isLoading = true,
  });

  _CatalogueState copyWith({
    List<ProductCatalogue>? products,
    Object? lastScannedProduct = const Object(),
    Object? lastScannedCode = const Object(),
    bool? showSplash,
    Object? scanError = const Object(),
    bool? isLoading,
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

  // Stream subscription
  StreamSubscription<QuerySnapshot>? _catalogueSubscription;

  // Immutable state
  _CatalogueState _state = _CatalogueState(products: []);

  // Public getters
  List<ProductCatalogue> get products => _state.products;
  ProductCatalogue? get lastScannedProduct => _state.lastScannedProduct;
  String? get lastScannedCode => _state.lastScannedCode;
  bool get showSplash => _state.showSplash;
  String? get scanError => _state.scanError;
  bool get isLoading => _state.isLoading;

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

        _shouldNotifyListeners = false;
        if (!_areProductListsEqual(_state.products, products)) {
          _state = _state.copyWith(products: products);
          _shouldNotifyListeners = true;
          notifyListeners();
        }

        if (_state.isLoading) {
          _state = _state.copyWith(isLoading: false);
          _shouldNotifyListeners = true;
          notifyListeners();
        }

        _shouldNotifyListeners = true;
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
    try {
      final product = _state.products.firstWhere(
        (product) => product.code.trim().toUpperCase() == normalizedCode,
      );
      // Verificar que el producto encontrado tenga un ID válido
      return product.id.isNotEmpty ? product : null;
    } catch (e) {
      // Si no se encuentra ningún producto, devolver null
      return null;
    }
  }

  /// Busca un producto público por código de barra en la base pública.
  Future<Product?> getPublicProductByCode(String code) async {
    return await getPublicProductByCodeUseCase(code);
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

  /// Determina si dos listas de productos son iguales comparando solo los campos relevantes
  bool _areProductListsEqual(
      List<ProductCatalogue> list1, List<ProductCatalogue> list2) {
    if (list1.length != list2.length) return false;

    for (var i = 0; i < list1.length; i++) {
      if (list1[i].id != list2[i].id ||
          list1[i].code != list2[i].code ||
          list1[i].salePrice != list2[i].salePrice ||
          list1[i].description != list2[i].description) {
        return false;
      }
    }
    return true;
  }

  @override
  void dispose() {
    _catalogueSubscription?.cancel();
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
