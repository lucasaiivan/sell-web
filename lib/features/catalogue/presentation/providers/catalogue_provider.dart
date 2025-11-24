import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';
import '../../domain/entities/product_catalogue.dart';
import '../../domain/usecases/get_products_usecase.dart';
import '../../domain/usecases/update_stock_usecase.dart';

/// Filtros disponibles para el catálogo
enum CatalogueFilter {
  none,
  favorites,
  lowStock,
  outOfStock,
}

/// Provider para gestionar el estado del catálogo de productos.
/// 
/// Utiliza Clean Architecture comunicándose solo con Use Cases.
@injectable
class CatalogueProvider extends ChangeNotifier {
  final GetProductsUseCase getProductsUseCase;
  final UpdateStockUseCase updateStockUseCase;

  CatalogueProvider(
    this.getProductsUseCase,
    this.updateStockUseCase,
  );

  // Estado
  List<ProductCatalogue> _products = [];
  bool _isLoading = false;
  String? _error;
  String _currentSearchQuery = '';
  CatalogueFilter _activeFilter = CatalogueFilter.none;

  // Getters
  List<ProductCatalogue> get products => _products;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get currentSearchQuery => _currentSearchQuery;
  CatalogueFilter get activeFilter => _activeFilter;
  bool get hasActiveFilter => _activeFilter != CatalogueFilter.none;

  /// Obtiene los productos visibles según filtros y búsqueda
  List<ProductCatalogue> get visibleProducts {
    List<ProductCatalogue> filtered = _products;

    // Aplicar búsqueda
    if (_currentSearchQuery.isNotEmpty) {
      filtered = filtered.where((product) {
        final query = _currentSearchQuery.toLowerCase();
        return product.description.toLowerCase().contains(query) ||
            product.code.toLowerCase().contains(query) ||
            product.nameMark.toLowerCase().contains(query);
      }).toList();
    }

    // Aplicar filtro
    switch (_activeFilter) {
      case CatalogueFilter.favorites:
        filtered = filtered.where((p) => p.favorite).toList();
        break;
      case CatalogueFilter.lowStock:
        filtered = filtered
            .where((p) => p.stock && p.quantityStock <= p.alertStock && p.quantityStock > 0)
            .toList();
        break;
      case CatalogueFilter.outOfStock:
        filtered = filtered.where((p) => p.quantityStock <= 0).toList();
        break;
      case CatalogueFilter.none:
        break;
    }

    return filtered;
  }

  /// Carga los productos del catálogo
  Future<void> loadProducts(String accountId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _products = await getProductsUseCase(accountId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Busca productos (con posibilidad de debouncing)
  void searchProducts({required String query}) {
    _currentSearchQuery = query;
    notifyListeners();
  }

  /// Limpia los resultados de búsqueda
  void clearSearchResults() {
    _currentSearchQuery = '';
    notifyListeners();
  }

  /// Aplica un filtro al catálogo
  void applyFilter(CatalogueFilter filter) {
    if (_activeFilter == filter) {
      _activeFilter = CatalogueFilter.none;
    } else {
      _activeFilter = filter;
    }
    notifyListeners();
  }

  /// Actualiza el stock de un producto
  Future<void> updateProductStock({
    required String accountId,
    required String productId,
    required int newStock,
  }) async {
    try {
      await updateStockUseCase(
        accountId: accountId,
        productId: productId,
        newStock: newStock,
      );

      // Actualizar localmente
      final index = _products.indexWhere((p) => p.id == productId);
      if (index != -1) {
        _products[index] = _products[index].copyWith(
          quantityStock: newStock,
          stock: newStock > 0,
        );
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Busca productos con debounce (simulado con Future.delayed)
  void searchProductsWithDebounce({required String query}) {
    // Implementación simple sin debounce real
    // En producción usarías un Timer o paquete de debounce
    searchProducts(query: query);
  }
}
