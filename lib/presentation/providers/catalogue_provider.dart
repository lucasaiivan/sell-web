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

  CatalogueProvider({
    required this.getProductsStreamUseCase,
    required this.getProductByCodeUseCase,
    required this.isProductScannedUseCase,
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

  void initCatalogue(String id) {
    // Cancelar la suscripción anterior si existe
    _catalogueSubscription?.cancel();
    // Limpiar productos y notificar a la UI inmediatamente
    _products = [];
    notifyListeners();
    // case use : Crear un nuevo caso de uso con el ID proporcionado y reiniciar la suscripción
    final newUseCase = GetCatalogueStreamUseCase(CatalogueRepositoryImpl(id: id));
    _initCatalogueWithUseCase(newUseCase);
  }

  void _initCatalogueWithUseCase(GetCatalogueStreamUseCase useCase) {
    _catalogueSubscription?.cancel();
    _catalogueSubscription = useCase().listen((snapshot) {
      _products = snapshot.docs.map((doc) => ProductCatalogue.fromMap(doc.data() as Map<String, dynamic>)).toList();
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
    _products = [];
    _lastScannedProduct = null;
    _lastScannedCode = null;
    _scanError = null;
    getProductsStreamUseCase().listen((snapshot) {
      // Convierte los documentos del snapshot en objetos ProductCatalogue y actualiza la lista interna.
      _products = snapshot.docs.map((doc) => ProductCatalogue.fromMap(doc.data() as Map<String, dynamic>)).toList();
      notifyListeners(); // Notifica a los listeners que hubo un cambio en la lista de productos.
    });
  }

  /// Busca un producto por su código en la lista interna de productos usando el caso de uso correspondiente.
  ProductCatalogue? getProductByCode(String code) {
    return getProductByCodeUseCase(_products, code);
  }

  /// Verifica si un producto con el código dado ya fue escaneado usando el caso de uso correspondiente.
  bool getIsProductScanned(String code) {
    return isProductScannedUseCase(_products, code);
  }

  /// Devuelve el stream de productos para ser usado directamente en la UI si es necesario.
  Stream<QuerySnapshot> get productsStream => getProductsStreamUseCase();

  // 
}
