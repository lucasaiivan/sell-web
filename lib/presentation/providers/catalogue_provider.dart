import '../../domain/entities/catalogue.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../domain/usecases/catalogue_usecases.dart';

class CatalogueProvider extends ChangeNotifier {
  final GetProductsStreamUseCase getProductsStreamUseCase;
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
  bool get showSplash => _showSplash;
  set showSplash(bool value) {
    _showSplash = value;
    notifyListeners();
  }
  ProductCatalogue? get lastScannedProduct => _lastScannedProduct;
  String? get lastScannedCode => _lastScannedCode;
  String? get scanError => _scanError;

  // Obtiene el stream de productos desde la base de datos y actualiza la lista interna.
  void _initProducts() {
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
}
