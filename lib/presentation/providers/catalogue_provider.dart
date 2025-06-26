import 'dart:async';
import '../../data/catalogue_repository_impl.dart';
import '../../domain/entities/catalogue.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../domain/usecases/catalogue_usecases.dart';

class CatalogueProvider extends ChangeNotifier {
  final GetCatalogueStreamUseCase getProductsStreamUseCase;
  final GetProductByCodeUseCase getProductByCodeUseCase;
  final IsProductScannedUseCase isProductScannedUseCase;
  final GetPublicProductByCodeUseCase getPublicProductByCodeUseCase;
  final AddProductToCatalogueUseCase addProductToCatalogueUseCase;

  CatalogueProvider({
    required this.getProductsStreamUseCase,
    required this.getProductByCodeUseCase,
    required this.isProductScannedUseCase,
    required this.getPublicProductByCodeUseCase,
    required this.addProductToCatalogueUseCase,
  }) {
    _initProducts();
  }

  List<ProductCatalogue> _products = [];
  List<ProductCatalogue> get products => _products;

  ProductCatalogue? _lastScannedProduct;
  String? _lastScannedCode;
  bool _showSplash = false;
  String? _scanError;
  StreamSubscription<QuerySnapshot>? _catalogueSubscription;
  bool _isLoading = true;
  bool get isLoading => _isLoading;

  String? _accountId;

  void initCatalogue(String id) {
    // Cancelar la suscripción anterior si existe
    _catalogueSubscription?.cancel();
    // Limpiar productos y notificar a la UI inmediatamente
    _products = [];
    notifyListeners();
    _accountId = id; // Asignar el ID de la cuenta actual
    // case use : Crear un nuevo caso de uso con el ID proporcionado y reiniciar la suscripción
    final newUseCase = GetCatalogueStreamUseCase(CatalogueRepositoryImpl(id: id));
    _initCatalogueWithUseCase(newUseCase);
  }

  void _initCatalogueWithUseCase(GetCatalogueStreamUseCase useCase) {
    _isLoading = true;
    notifyListeners();
    _catalogueSubscription?.cancel();
    _catalogueSubscription = useCase().listen((snapshot) {
      _products = snapshot.docs.map((doc) => ProductCatalogue.fromMap(doc.data() as Map<String, dynamic>)).toList();
      _isLoading = false;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _catalogueSubscription?.cancel();
    super.dispose();
  }

  bool get showSplash => _showSplash;
  set showSplash(bool value) {
    _showSplash = value;
    notifyListeners();
  }
  ProductCatalogue? get lastScannedProduct => _lastScannedProduct; // Devuelve el último producto escaneado
  String? get lastScannedCode => _lastScannedCode; // Devuelve el último código escaneado
  String? get scanError => _scanError; // Devuelve el error de escaneo si existe

  // Modifica _initProducts para usar _accountId si está definido
  void _initProducts() {
    _isLoading = true;
    notifyListeners();
    _products = [];
    _lastScannedProduct = null;
    _lastScannedCode = null;
    _scanError = null;
    getProductsStreamUseCase().listen((snapshot) {
      // Convierte los documentos del snapshot en objetos ProductCatalogue y actualiza la lista interna.
      _products = snapshot.docs.map((doc) => ProductCatalogue.fromMap(doc.data() as Map<String, dynamic>)).toList();
      _isLoading = false;
      notifyListeners(); // Notifica a los listeners que hubo un cambio en la lista de productos.
    });
  }

  /// Busca un producto por su código en la lista interna de productos usando el caso de uso correspondiente.
  ProductCatalogue? getProductByCode(String code) {
    return getProductByCodeUseCase(_products, code);
  }

  /// Busca un producto público por código de barra en la base pública.
  Future<Product?> getPublicProductByCode(String code) async {
    return await getPublicProductByCodeUseCase(code);
  }

  /// Intenta escanear un producto: si no está en el catálogo, busca en la base pública y lo agrega a la lista seleccionada si el usuario acepta.
  Future<void> scanProduct(String code, {required Function(Product) onFoundInPublic}) async {
    final localProduct = getProductByCode(code);
    if (localProduct != null) {
      _lastScannedProduct = localProduct;
      _lastScannedCode = code;
      notifyListeners();
      return;
    }
    // Buscar en la base pública
    final publicProduct = await getPublicProductByCode(code);
    if (publicProduct != null) {
      // Llamar callback para que la UI decida si agregarlo
      onFoundInPublic(publicProduct);
    } else {
      _scanError = 'Producto no encontrado';
      notifyListeners();
    }
  }

  /// Devuelve el stream de productos para ser usado directamente en la UI si es necesario.
  Stream<QuerySnapshot> get productsStream => getProductsStreamUseCase();

  /// Carga productos demo si la cuenta seleccionada es demo.
  void loadDemoProducts(List<ProductCatalogue> demoProducts) {
    _isLoading = false;
    _products = demoProducts;
    notifyListeners();
  }

  /// Agrega un producto al catálogo de la cuenta actual usando el caso de uso
  Future<void> addProductToCatalogue(ProductCatalogue product) async { 
    // Si el id está vacío o nulo, asignar el código como id
    final productToSave = (product.id.isEmpty)? product.copyWith(id: product.code) : product;
    _accountId ??= CatalogueRepositoryImpl().id; // Asegurarse de que _accountId tenga un valor 
    await addProductToCatalogueUseCase(productToSave, _accountId!);
  }
}
