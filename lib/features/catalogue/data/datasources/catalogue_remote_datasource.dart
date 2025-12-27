import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';
import 'package:sellweb/core/services/database/i_firestore_datasource.dart';
import 'package:sellweb/core/services/database/firestore_paths.dart';
import '../models/category_model.dart';
import '../models/product_catalogue_model.dart';
import '../models/product_model.dart';

/// DataSource remoto para operaciones de catálogo en Firestore.
///
/// **Refactorizado:** Usa [IFirestoreDataSource] + [FirestorePaths]
///
/// Encapsula toda la lógica de acceso a Firebase Cloud Firestore
/// para productos y categorías.
abstract class CatalogueRemoteDataSource {
  /// Obtiene productos del catálogo de una cuenta desde Firestore
  Future<List<ProductCatalogueModel>> getProducts(String accountId);

  /// Obtiene un producto específico por ID
  Future<ProductCatalogueModel?> getProductById(
      String accountId, String productId);

  /// Crea un producto en el catálogo
  Future<void> createProduct(String accountId, ProductCatalogueModel product);

  /// Actualiza un producto existente
  Future<void> updateProduct(String accountId, ProductCatalogueModel product);

  /// Elimina un producto
  Future<void> deleteProduct(String accountId, String productId);

  /// Busca productos en la colección global
  Future<List<ProductModel>> searchGlobalProducts(String query);

  /// Obtiene categorías disponibles
  Future<List<CategoryModel>> getCategories();

  /// Actualiza el stock de un producto
  Future<void> updateStock(String accountId, String productId, double newStock);
}

/// Implementación de [CatalogueRemoteDataSource] usando Firestore.
@LazySingleton(as: CatalogueRemoteDataSource)
class CatalogueRemoteDataSourceImpl implements CatalogueRemoteDataSource {
  final IFirestoreDataSource _dataSource;

  CatalogueRemoteDataSourceImpl(this._dataSource);

  @override
  Future<List<ProductCatalogueModel>> getProducts(String accountId) async {
    try {
      final path = FirestorePaths.accountCatalogue(accountId);
      final collection = _dataSource.collection(path);
      final snapshot = await _dataSource.getDocuments(collection);

      return snapshot.docs
          .map((doc) => ProductCatalogueModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener productos: $e');
    }
  }

  @override
  Future<ProductCatalogueModel?> getProductById(
      String accountId, String productId) async {
    try {
      final path = FirestorePaths.accountProduct(accountId, productId);
      final docRef = _dataSource.document(path);
      final doc = await docRef.get();

      if (!doc.exists) return null;

      return ProductCatalogueModel.fromMap(doc.data()!);
    } catch (e) {
      throw Exception('Error al obtener producto: $e');
    }
  }

  @override
  Future<void> createProduct(
      String accountId, ProductCatalogueModel product) async {
    try {
      final path = FirestorePaths.accountProduct(accountId, product.id);
      await _dataSource.setDocument(path, product.toMap());
    } catch (e) {
      throw Exception('Error al crear producto: $e');
    }
  }

  @override
  Future<void> updateProduct(
      String accountId, ProductCatalogueModel product) async {
    try {
      final path = FirestorePaths.accountProduct(accountId, product.id);
      await _dataSource.updateDocument(path, product.toMap());
    } catch (e) {
      throw Exception('Error al actualizar producto: $e');
    }
  }

  @override
  Future<void> deleteProduct(String accountId, String productId) async {
    try {
      final path = FirestorePaths.accountProduct(accountId, productId);
      await _dataSource.deleteDocument(path);
    } catch (e) {
      throw Exception('Error al eliminar producto: $e');
    }
  }

  @override
  Future<List<ProductModel>> searchGlobalProducts(String query) async {
    try {
      // Búsqueda simple por descripción (puedes mejorar con índices)
      final path = FirestorePaths.publicProducts();
      final collection = _dataSource.collection(path);
      final firestoreQuery = collection
          .where('description', isGreaterThanOrEqualTo: query)
          .where('description', isLessThan: '${query}z')
          .limit(50);
      final snapshot = await _dataSource.getDocuments(firestoreQuery);

      return snapshot.docs
          .map((doc) => ProductModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Error al buscar productos: $e');
    }
  }

  @override
  Future<List<CategoryModel>> getCategories() async {
    try {
      final path =
          FirestorePaths.accountCategories('DEFAULT'); // Categories globales
      final collection = _dataSource.collection(path);
      final snapshot = await _dataSource.getDocuments(collection);

      return snapshot.docs
          .map((doc) => CategoryModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener categorías: $e');
    }
  }

  @override
  Future<void> updateStock(
      String accountId, String productId, double newStock) async {
    try {
      final path = FirestorePaths.accountProduct(accountId, productId);
      await _dataSource.updateDocument(path, {
        'quantityStock': newStock,
        'stock': newStock > 0,
        'upgrade': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Error al actualizar stock: $e');
    }
  }
}
