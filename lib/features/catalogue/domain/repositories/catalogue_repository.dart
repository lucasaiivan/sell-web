import 'package:cloud_firestore/cloud_firestore.dart';
import '../entities/category.dart';
import '../entities/product.dart';
import '../entities/product_catalogue.dart';
import '../entities/product_price.dart';
import '../entities/mark.dart';
import '../entities/provider.dart';

/// Contrato del repositorio de catálogo.
/// 
/// Define las operaciones disponibles para gestionar productos y categorías.
/// Esta interfaz pertenece al dominio y no conoce detalles de implementación.
abstract class CatalogueRepository {
  /// Obtiene un stream de productos del catálogo
  Stream<QuerySnapshot> getCatalogueStream(String accountId);

  /// Busca un producto público por código de barra
  Future<Product?> getPublicProductByCode(String code);

  /// Agrega un producto al catálogo
  Future<void> addProductToCatalogue(ProductCatalogue product, String accountId);

  /// Crea un nuevo producto público
  Future<void> createPublicProduct(Product product);

  /// Registra el precio de un producto
  Future<void> registerProductPrice(ProductPrice productPrice, String productCode);

  /// Incrementa las ventas de un producto
  Future<void> incrementSales(String accountId, String productId, int quantity);

  /// Decrementa el stock de un producto
  Future<void> decrementStock(String accountId, String productId, int quantity);

  /// Actualiza el estado de favorito
  Future<void> updateProductFavorite(String accountId, String productId, bool isFavorite);

  /// Obtiene un stream de categorías
  Stream<List<Category>> getCategoriesStream(String accountId);

  /// Obtiene un stream de proveedores
  Stream<List<Provider>> getProvidersStream(String accountId);

  /// Obtiene un stream de marcas
  Stream<List<Mark>> getBrandsStream({String country = 'ARG'});

  /// Crea una nueva marca
  Future<void> createBrand(Mark brand, {String country = 'ARG'});

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
  Future<List<Category>> getCategories(String accountId);

  /// Actualiza el stock de un producto
  /// 
  /// [accountId] - ID de la cuenta
  /// [productId] - ID del producto
  /// [newStock] - Nueva cantidad en stock
  Future<void> updateStock(String accountId, String productId, int newStock);
}
