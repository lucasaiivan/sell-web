import 'dart:async';
import 'package:sellweb/core/utils/fuctions.dart';

import '../../data/catalogue_repository_impl.dart';
import '../../domain/entities/catalogue.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart'; 
import '../../domain/usecases/catalogue_usecases.dart';
import '../../domain/usecases/account_usecase.dart';

class CatalogueProvider extends ChangeNotifier {

  // Casos de uso para interactuar con el catálogo
  GetCatalogueStreamUseCase getProductsStreamUseCase;
  final GetProductByCodeUseCase getProductByCodeUseCase;
  final IsProductScannedUseCase isProductScannedUseCase;
  final GetPublicProductByCodeUseCase getPublicProductByCodeUseCase;
  AddProductToCatalogueUseCase addProductToCatalogueUseCase;
  final GetUserAccountsUseCase getUserAccountsUseCase;

  CatalogueProvider({
    required this.getProductsStreamUseCase,
    required this.getProductByCodeUseCase,
    required this.isProductScannedUseCase,
    required this.getPublicProductByCodeUseCase,
    required this.addProductToCatalogueUseCase,
    required this.getUserAccountsUseCase,
  });  // Removido _initProducts() del constructor

  List<ProductCatalogue> _products = [];
  List<ProductCatalogue> get products => _products;

  ProductCatalogue? _lastScannedProduct;
  String? _lastScannedCode;
  bool _showSplash = false;
  String? _scanError;
  StreamSubscription<QuerySnapshot>? _catalogueSubscription;
  bool _isLoading = true;
  bool get isLoading => _isLoading;

  /// Inicializa el catálogo para una cuenta específica
  void initCatalogue(String id) { 
    // Validar que el ID no esté vacío
    if (id.isEmpty) {
      throw Exception('El ID de la cuenta no puede estar vacío.'); 
    }
    
    // Cancelar la suscripción anterior si existe
    _catalogueSubscription?.cancel();
    
    // Reinicializar el estado del catálogo
    _isLoading = true;
    _products = [];
    _lastScannedProduct = null;
    _lastScannedCode = null;
    _scanError = null;
    
    // Notificar cambios inmediatamente para mostrar el estado de carga
    notifyListeners();
    
    // Crear nuevos casos de uso con el nuevo ID de cuenta
    final newCatalogueRepository = CatalogueRepositoryImpl(id: id);
    getProductsStreamUseCase = GetCatalogueStreamUseCase(newCatalogueRepository);
    addProductToCatalogueUseCase = AddProductToCatalogueUseCase(newCatalogueRepository);
    
    // Inicializar el stream de productos para la nueva cuenta
    _catalogueSubscription = getProductsStreamUseCase().listen(
      (snapshot) {
        // Convertir los documentos del snapshot en objetos ProductCatalogue
        _products = snapshot.docs
            .map((doc) => ProductCatalogue.fromMap(doc.data() as Map<String, dynamic>))
            .toList();
        _isLoading = false;
        notifyListeners();
      },
      onError: (error) {
        // Manejar errores del stream
        print('Error al cargar productos del catálogo: $error');
        _isLoading = false;
        _products = [];
        notifyListeners();
      },
    );
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

  /// Busca un producto por su código en la lista del catálogo.
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
    final accountId = await getUserAccountsUseCase.getSelectedAccountId();
    
    // Si el id está vacío o nulo, asignar el código como id
    final productToSave =  product.copyWith(
      creation: Utils().getTimestampNow(), // fecha de creación del producto 
      upgrade: Utils().getTimestampNow(), // fecha de actualización del producto
      )  ;

    print('--------------------------- Guardando producto en catálogo: ${productToSave.toMap()}' );
    print('--------------------------- ID de cuenta actual: $accountId');
    
    if (accountId == null || accountId.isEmpty) {
      throw Exception('--------------------------- El ID de la cuenta no está definido o es nulo. Por favor, inicializa el catálogo con un ID de cuenta válido.');
    }
    try {
      await addProductToCatalogueUseCase(productToSave, accountId);  
      notifyListeners();
    } catch (e) {
      // Relanzar el error con más contexto
      throw Exception('--------------------------- Error al guardar producto en catálogo: $e');
    }
  }
 
}
