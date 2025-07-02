import 'package:cloud_firestore/cloud_firestore.dart';
import '../entities/catalogue.dart';

abstract class CatalogueRepository {
  // Obtiene un stream de los productos del catálogo de la cuenta
  Stream<QuerySnapshot> getCatalogueStream();
  // Busca un producto público por código de barra
  Future<Product?> getPublicProductByCode(String code);
  // Agrega un producto al catálogo de la cuenta
  Future<void> addProductToCatalogue(ProductCatalogue product, String accountId);
  // Crea un nuevo producto en la base de datos pública
  Future<void> createPublicProduct(Product product);
}
