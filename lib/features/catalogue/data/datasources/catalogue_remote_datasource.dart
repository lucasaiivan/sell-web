import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';
import '../models/category_model.dart';
import '../models/product_catalogue_model.dart';
import '../models/product_model.dart';

/// DataSource remoto para operaciones de catálogo en Firestore.
/// 
/// Encapsula toda la lógica de acceso a Firebase Cloud Firestore
/// para productos y categorías.
abstract class CatalogueRemoteDataSource {
  /// Obtiene productos del catálogo de una cuenta desde Firestore
  Future<List<ProductCatalogueModel>> getProducts(String accountId);

  /// Obtiene un producto específico por ID
  Future<ProductCatalogueModel?> getProductById(String accountId, String productId);

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
  Future<void> updateStock(String accountId, String productId, int newStock);
}

/// Implementación de [CatalogueRemoteDataSource] usando Firestore.
@LazySingleton(as: CatalogueRemoteDataSource)
class CatalogueRemoteDataSourceImpl implements CatalogueRemoteDataSource {
  final FirebaseFirestore firestore;

  CatalogueRemoteDataSourceImpl(this.firestore);

  @override
  Future<List<ProductCatalogueModel>> getProducts(String accountId) async {
    try {
      final snapshot = await firestore
          .collection('cuentas')
          .doc(accountId)
          .collection('catalogo')
          .get();

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
      final doc = await firestore
          .collection('cuentas')
          .doc(accountId)
          .collection('catalogo')
          .doc(productId)
          .get();

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
      await firestore
          .collection('cuentas')
          .doc(accountId)
          .collection('catalogo')
          .doc(product.id)
          .set(product.toMap());
    } catch (e) {
      throw Exception('Error al crear producto: $e');
    }
  }

  @override
  Future<void> updateProduct(
      String accountId, ProductCatalogueModel product) async {
    try {
      await firestore
          .collection('cuentas')
          .doc(accountId)
          .collection('catalogo')
          .doc(product.id)
          .update(product.toMap());
    } catch (e) {
      throw Exception('Error al actualizar producto: $e');
    }
  }

  @override
  Future<void> deleteProduct(String accountId, String productId) async {
    try {
      await firestore
          .collection('cuentas')
          .doc(accountId)
          .collection('catalogo')
          .doc(productId)
          .delete();
    } catch (e) {
      throw Exception('Error al eliminar producto: $e');
    }
  }

  @override
  Future<List<ProductModel>> searchGlobalProducts(String query) async {
    try {
      // Búsqueda simple por descripción (puedes mejorar con índices)
      final snapshot = await firestore
          .collection('productos')
          .where('description', isGreaterThanOrEqualTo: query)
          .where('description', isLessThan: '${query}z')
          .limit(50)
          .get();

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
      final snapshot = await firestore.collection('categorias').get();

      return snapshot.docs
          .map((doc) => CategoryModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener categorías: $e');
    }
  }

  @override
  Future<void> updateStock(
      String accountId, String productId, int newStock) async {
    try {
      await firestore
          .collection('cuentas')
          .doc(accountId)
          .collection('catalogo')
          .doc(productId)
          .update({
        'quantityStock': newStock,
        'stock': newStock > 0,
        'upgrade': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Error al actualizar stock: $e');
    }
  }
}
