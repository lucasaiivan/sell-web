import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:injectable/injectable.dart';
import '../models/product_catalogue_model.dart';
import '../models/category_model.dart';

abstract class CatalogueLocalDataSource {
  Future<List<ProductCatalogueModel>> getProducts();
  Future<void> saveProducts(List<ProductCatalogueModel> products);
  Future<void> saveProduct(ProductCatalogueModel product);
  
  // Categorias
  Future<List<CategoryModel>> getCategories();
  Future<void> saveCategories(List<CategoryModel> categories);
  
  // Clear
  Future<void> clearAll();
}

@LazySingleton(as: CatalogueLocalDataSource)
class CatalogueLocalDataSourceImpl implements CatalogueLocalDataSource {
  final Box _productsBox;
  final Box _categoriesBox;

  CatalogueLocalDataSourceImpl(
    @Named('productsBox') this._productsBox,
    @Named('categoriesBox') this._categoriesBox,
  );

  @override
  Future<List<ProductCatalogueModel>> getProducts() async {
    try {
      final values = _productsBox.values;
      if (values.isEmpty) return [];
      
      return values.map((e) {
        // Asumimos que guardamos Maps (json)
        return ProductCatalogueModel.fromMap(Map<String, dynamic>.from(e));
      }).toList();
    } catch (e) {
      if (kDebugMode) debugPrint('❌ [Hive] Error obteniendo productos: $e');
      return [];
    }
  }

  @override
  Future<void> saveProducts(List<ProductCatalogueModel> products) async {
    try {
      final Map<dynamic, dynamic> entries = {};
      for (var product in products) {
        entries[product.id] = product.toMap();
      }
      await _productsBox.putAll(entries);
      if (kDebugMode) debugPrint('✅ [Hive] ${products.length} productos guardados');
    } catch (e) {
      if (kDebugMode) debugPrint('❌ [Hive] Error guardando productos: $e');
    }
  }

  @override
  Future<void> saveProduct(ProductCatalogueModel product) async {
    try {
      await _productsBox.put(product.id, product.toMap());
    } catch (e) {
      if (kDebugMode) debugPrint('❌ [Hive] Error guardando producto único: $e');
    }
  }

  @override
  Future<List<CategoryModel>> getCategories() async {
    try {
      final values = _categoriesBox.values;
      if (values.isEmpty) return [];
      
      return values.map((e) {
        return CategoryModel.fromMap(Map<String, dynamic>.from(e));
      }).toList();
    } catch (e) {
      if (kDebugMode) debugPrint('❌ [Hive] Error obteniendo categorías: $e');
      return [];
    }
  }

  @override
  Future<void> saveCategories(List<CategoryModel> categories) async {
    try {
      final Map<dynamic, dynamic> entries = {};
      for (var cat in categories) {
        entries[cat.id] = cat.toMap();
      }
      await _categoriesBox.putAll(entries);
    } catch (e) {
      if (kDebugMode) debugPrint('❌ [Hive] Error guardando categorías: $e');
    }
  }

  @override
  Future<void> clearAll() async {
    await _productsBox.clear();
    await _categoriesBox.clear();
  }
}
