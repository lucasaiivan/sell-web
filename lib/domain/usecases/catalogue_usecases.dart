import 'package:cloud_firestore/cloud_firestore.dart';
import '../repositories/catalogue_repository.dart';
import '../entities/catalogue.dart';

/// Casos de uso para gestión del catálogo de productos
///
/// RESPONSABILIDAD: Lógica de negocio del catálogo
/// - Obtener stream de productos
/// - Buscar productos por código
/// - Agregar productos al catálogo
/// - Actualizar estadísticas (ventas, stock)
/// - Actualizar estado de favoritos
/// - Gestionar productos públicos
class CatalogueUseCases {
  final CatalogueRepository repository;

  CatalogueUseCases(this.repository);

  // ==========================================
  // CONSULTA DE PRODUCTOS
  // ==========================================

  /// Devuelve un stream de productos del catálogo de la cuenta del negocio seleccionada
  Stream<QuerySnapshot> getCatalogueStream() {
    return repository.getCatalogueStream();
  }

  /// Busca un producto por código de barra en una lista de productos
  ///
  /// [products] - Lista de productos donde buscar
  /// [code] - Código de barra a buscar
  /// Retorna el producto encontrado o null si no existe
  ProductCatalogue? getProductByCode(
      List<ProductCatalogue> products, String code) {
    try {
      return products.firstWhere((p) => p.code == code);
    } catch (_) {
      return null;
    }
  }

  /// Busca un producto público por código de barra en la base de datos pública
  ///
  /// [code] - Código de barra del producto
  /// Retorna el producto público encontrado o null
  Future<Product?> getPublicProductByCode(String code) {
    return repository.getPublicProductByCode(code);
  }

  /// Verifica si un producto ya ha sido escaneado (existe en la lista)
  ///
  /// [products] - Lista de productos donde verificar
  /// [code] - Código de barra a verificar
  /// Retorna true si el producto existe en la lista
  bool isProductScanned(List<ProductCatalogue> products, String code) {
    final product = getProductByCode(products, code);
    return product != null;
  }

  // ==========================================
  // GESTIÓN DE PRODUCTOS
  // ==========================================

  /// Agrega un producto al catálogo de la cuenta del negocio seleccionada
  ///
  /// [product] - Producto a agregar
  /// [accountId] - ID de la cuenta del negocio
  Future<void> addProductToCatalogue(
      ProductCatalogue product, String accountId) {
    return repository.addProductToCatalogue(product, accountId);
  }

  /// Crea un nuevo producto en la base de datos pública
  ///
  /// [product] - Producto público a crear
  Future<void> createPublicProduct(Product product) {
    return repository.createPublicProduct(product);
  }

  /// Registra el precio de un producto en la base de datos pública
  ///
  /// [productPrice] - Datos del precio del producto
  /// [productCode] - Código del producto
  Future<void> registerProductPrice(
      ProductPrice productPrice, String productCode) {
    return repository.registerProductPrice(productPrice, productCode);
  }

  // ==========================================
  // ACTUALIZACIÓN DE ESTADÍSTICAS
  // ==========================================

  /// Incrementa el contador de ventas de un producto específico
  ///
  /// [accountId] - ID de la cuenta del negocio
  /// [productId] - ID del producto
  /// [quantity] - Cantidad vendida (por defecto 1)
  Future<void> incrementProductSales(String accountId, String productId,
      {int quantity = 1}) {
    return repository.incrementSales(accountId, productId, quantity);
  }

  /// Decrementa el stock de un producto específico
  ///
  /// [accountId] - ID de la cuenta del negocio
  /// [productId] - ID del producto
  /// [quantity] - Cantidad a decrementar
  Future<void> decrementProductStock(
      String accountId, String productId, int quantity) {
    return repository.decrementStock(accountId, productId, quantity);
  }

  /// Actualiza el estado de favorito de un producto específico
  ///
  /// [accountId] - ID de la cuenta del negocio
  /// [productId] - ID del producto
  /// [isFavorite] - Nuevo estado de favorito
  Future<void> updateProductFavorite(
      String accountId, String productId, bool isFavorite) {
    return repository.updateProductFavorite(accountId, productId, isFavorite);
  }
}
