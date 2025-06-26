import 'package:cloud_firestore/cloud_firestore.dart';
import '../entities/catalogue.dart';

abstract class CatalogueRepository {
  Stream<QuerySnapshot> getCatalogueStream();
  // Busca un producto público por código de barra
  Future<Product?> getPublicProductByCode(String code);
}
