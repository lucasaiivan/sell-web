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
  Future<void> registerProductPrice(ProductPrice productPrice, String productCode);
}
