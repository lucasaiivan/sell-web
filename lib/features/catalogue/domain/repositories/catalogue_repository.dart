import '../entities/category.dart';
import '../entities/product.dart';
import '../entities/product_catalogue.dart';

/// Contrato del repositorio de catálogo.
/// 
/// Define las operaciones disponibles para gestionar productos y categorías.
/// Esta interfaz pertenece al dominio y no conoce detalles de implementación.
abstract class CatalogueRepository {
  /// Obtiene todos los productos del catálogo de una cuenta
  /// 
  /// [accountId] - ID de la cuenta
  /// Retorna una lista de productos del catálogo
  Future<List<ProductCatalogue>> getProducts(String accountId);

  /// Obtiene un producto específico del catálogo
  /// 
  /// [accountId] - ID de la cuenta
  /// [productId] - ID del producto
  Future<ProductCatalogue?> getProductById(String accountId, String productId);

  /// Crea un nuevo producto en el catálogo
  /// 
  /// [accountId] - ID de la cuenta
  /// [product] - Datos del producto a crear
  Future<void> createProduct(String accountId, ProductCatalogue product);

  /// Actualiza un producto existente
  /// 
  /// [accountId] - ID de la cuenta
  /// [product] - Datos actualizados del producto
  Future<void> updateProduct(String accountId, ProductCatalogue product);

  /// Elimina un producto del catálogo
  /// 
  /// [accountId] - ID de la cuenta
  /// [productId] - ID del producto a eliminar
  Future<void> deleteProduct(String accountId, String productId);

  /// Busca productos globales (no del catálogo de la cuenta)
  /// 
  /// [query] - Término de búsqueda
  /// Retorna lista de productos globales que coinciden
  Future<List<Product>> searchGlobalProducts(String query);

  /// Obtiene todas las categorías disponibles
  Future<List<Category>> getCategories();

  /// Actualiza el stock de un producto
  /// 
  /// [accountId] - ID de la cuenta
  /// [productId] - ID del producto
  /// [newStock] - Nueva cantidad en stock
  Future<void> updateStock(String accountId, String productId, int newStock);
}
