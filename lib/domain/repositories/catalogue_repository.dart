import 'package:cloud_firestore/cloud_firestore.dart';
import '../entities/catalogue.dart';

abstract class CatalogueRepository {
  // Obtiene un stream de los productos del catálogo de la cuenta
  Stream<QuerySnapshot> getCatalogueStream();
  // Busca un producto público por código de barra
  Future<Product?> getPublicProductByCode(String code);
  // Agrega un producto al catálogo de la cuenta
  Future<void> addProductToCatalogue(
      ProductCatalogue product, String accountId);
  // Crea un nuevo producto en la base de datos pública
  Future<void> createPublicProduct(Product product);
  // Incrementa el contador de ventas de un producto
  Future<void> incrementSales(String accountId, String productId, int quantity);
  // Decrementa el stock de un producto
  Future<void> decrementStock(String accountId, String productId, int quantity);
  // Registra el precio de un producto en la base de datos pública
  Future<void> registerProductPrice(
      ProductPrice productPrice, String productCode);
  // Actualiza el estado de favorito de un producto
  Future<void> updateProductFavorite(
      String accountId, String productId, bool isFavorite);

  // Obtiene un stream de las categorías de la cuenta
  Stream<List<Category>> getCategoriesStream(String accountId);

  // Obtiene un stream de los proveedores de la cuenta
  Stream<List<Provider>> getProvidersStream(String accountId);

  // Obtiene un stream de las marcas públicas
  Stream<List<Mark>> getBrandsStream({String country = 'ARG'});

  // Crea una nueva marca en la base de datos pública
  Future<void> createBrand(Mark brand, {String country = 'ARG'});
}
