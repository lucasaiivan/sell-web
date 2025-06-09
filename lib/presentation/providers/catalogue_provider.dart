import '../../domain/entities/catalogue.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../domain/usecases/catalogue_usecases.dart';

class CatalogueProvider extends ChangeNotifier {
  final GetProductsStreamUseCase getProductsStreamUseCase;
  CatalogueProvider({required this.getProductsStreamUseCase}) {
    _initProducts();
  }

  List<Product> _products = [];
  List<Product> get products => _products;

  Product? _lastScannedProduct;
  String? _lastScannedCode;
  bool _showSplash = false;
  String? _scanError;
  bool get showSplash => _showSplash;
  set showSplash(bool value) {
    _showSplash = value;
    notifyListeners();
  }
  Product? get lastScannedProduct => _lastScannedProduct;
  String? get lastScannedCode => _lastScannedCode;
  String? get scanError => _scanError;

  void _initProducts() {
    getProductsStreamUseCase().listen((snapshot) {
      _products = snapshot.docs.map((doc) => Product.fromMap(doc.data() as Map<String, dynamic>)).toList();
      notifyListeners();
    });
  }

  Product? getProductByCode(String code) {
    try {
      return _products.firstWhere((p) => p.code == code);
    } catch (_) {
      return null;
    }
  }

  Future<bool> getIsProductScanned(String code) async {
    final product = getProductByCode(code);
    if (product != null) {
      return true;
    } else {
      return false;
    }
    
  }

  Stream<QuerySnapshot> get productsStream => getProductsStreamUseCase();
}
