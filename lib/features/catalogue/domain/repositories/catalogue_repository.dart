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
  Future<void> addProductToCatalogue(
      ProductCatalogue product, String accountId);

  /// Crea un nuevo producto público
  Future<void> createPublicProduct(Product product);

  /// Crea un nuevo producto pendiente de moderación
  Future<void> createPendingProduct(Product product);

  /// Registra el precio de un producto
  Future<void> registerProductPrice(
      ProductPrice productPrice, String productCode);

  /// Incrementa las ventas de un producto
  Future<void> incrementSales(String accountId, String productId, double quantity);

  /// Decrementa el stock de un producto
  Future<void> decrementStock(String accountId, String productId, double quantity);

  /// Actualiza el estado de favorito
  Future<void> updateProductFavorite(
      String accountId, String productId, bool isFavorite);

  /// Obtiene un stream de categorías
  Stream<List<Category>> getCategoriesStream(String accountId);

  /// Obtiene un stream de proveedores
  Stream<List<Provider>> getProvidersStream(String accountId);

  /// Obtiene un stream de marcas
  /// @deprecated Usa searchBrands o getPopularBrands en su lugar para optimizar consultas
  Stream<List<Mark>> getBrandsStream({String country = 'ARG'});

  /// Busca marcas por nombre con límite de resultados
  ///
  /// Usa búsqueda por prefijo optimizada para Firestore.
  /// Solo retorna marcas que comienzan con [query].
  ///
  /// [query] - Término de búsqueda (mínimo 1 carácter)
  /// [country] - País de las marcas (default: 'ARG')
  /// [limit] - Máximo de resultados (default: 20)
  Future<List<Mark>> searchBrands({
    required String query,
    String country = 'ARG',
    int limit = 20,
  });

  /// Obtiene las marcas más populares (verificadas y recientes)
  ///
  /// Retorna marcas verificadas ordenadas por fecha de creación.
  /// Útil para mostrar opciones iniciales sin búsqueda.
  ///
  /// [country] - País de las marcas (default: 'ARG')
  /// [limit] - Máximo de resultados (default: 20)
  Future<List<Mark>> getPopularBrands({
    String country = 'ARG',
    int limit = 20,
  });

  /// Obtiene una marca específica por ID
  ///
  /// [id] - ID de la marca
  /// [country] - País de la marca (default: 'ARG')
  Future<Mark?> getBrandById(String id, {String country = 'ARG'});

  /// Crea una nueva marca
  Future<void> createBrand(Mark brand, {String country = 'ARG'});

  /// Actualiza una marca existente
  Future<void> updateBrand(Mark brand, {String country = 'ARG'});

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
  Future<void> updateStock(String accountId, String productId, double newStock);

  // ═══════════════════════════════════════════════════════════════════════════
  // GESTIÓN DE FOLLOWERS (Contador de comercios usando el producto)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Incrementa el contador de followers de un producto público
  ///
  /// Se llama cuando un comercio agrega un producto de la BD global
  /// a su catálogo privado por primera vez.
  ///
  /// [productId] - ID del producto público (código de barras)
  ///
  /// **Nota:** Este contador sirve como métrica de popularidad
  /// y sistema de validación comunitaria del producto.
  Future<void> incrementProductFollowers(String productId);

  /// Decrementa el contador de followers de un producto público
  ///
  /// Se llama cuando un comercio elimina un producto de su catálogo
  /// que estaba referenciando un producto de la BD global.
  ///
  /// [productId] - ID del producto público (código de barras)
  ///
  /// **Nota:** El contador se mantiene en 0 como mínimo, nunca negativo.
  /// El documento se mantiene aunque followers llegue a 0.
  Future<void> decrementProductFollowers(String productId);

  // ═══════════════════════════════════════════════════════════════════════════
  // GESTIÓN DE CATEGORÍAS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Crea una nueva categoría
  ///
  /// [accountId] - ID de la cuenta
  /// [name] - Nombre de la categoría
  Future<void> createCategory({
    required String accountId,
    required String name,
  });

  /// Actualiza una categoría existente
  ///
  /// [accountId] - ID de la cuenta
  /// [categoryId] - ID de la categoría
  /// [name] - Nuevo nombre de la categoría
  Future<void> updateCategory({
    required String accountId,
    required String categoryId,
    required String name,
  });

  /// Elimina una categoría
  ///
  /// [accountId] - ID de la cuenta
  /// [categoryId] - ID de la categoría a eliminar
  Future<void> deleteCategory({
    required String accountId,
    required String categoryId,
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GESTIÓN DE PROVEEDORES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Crea un nuevo proveedor
  ///
  /// [accountId] - ID de la cuenta
  /// [name] - Nombre del proveedor
  /// [phone] - Teléfono del proveedor (opcional)
  /// [email] - Email del proveedor (opcional)
  Future<void> createProvider({
    required String accountId,
    required String name,
    String? phone,
    String? email,
  });

  /// Actualiza un proveedor existente
  ///
  /// [accountId] - ID de la cuenta
  /// [providerId] - ID del proveedor
  /// [name] - Nuevo nombre del proveedor
  /// [phone] - Nuevo teléfono del proveedor (opcional)
  /// [email] - Nuevo email del proveedor (opcional)
  Future<void> updateProvider({
    required String accountId,
    required String providerId,
    required String name,
    String? phone,
    String? email,
  });

  /// Elimina un proveedor
  ///
  /// [accountId] - ID de la cuenta
  /// [providerId] - ID del proveedor a eliminar
  Future<void> deleteProvider({
    required String accountId,
    required String providerId,
  });
}
