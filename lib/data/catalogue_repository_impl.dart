import 'package:cloud_firestore/cloud_firestore.dart'; 
import '../domain/repositories/catalogue_repository.dart';
import '../domain/entities/catalogue.dart';

class CatalogueRepositoryImpl implements CatalogueRepository {
  final String? id;
  CatalogueRepositoryImpl({this.id});

  @override
  Stream<QuerySnapshot> getCatalogueStream() { 
    if (id == null) {
      // Si no hay usuario autenticado ni userId inyectado, retorna un stream vacío
      return const Stream.empty();
    }
    return FirebaseFirestore.instance.collection('/ACCOUNTS/$id/CATALOGUE').snapshots();
  }

  @override
  Future<Product?> getPublicProductByCode(String code) async {
    final query = await FirebaseFirestore.instance
        .collection('/APP/ARG/PRODUCTOS')
        .where('code', isEqualTo: code)
        .limit(1)
        .get();
    if (query.docs.isNotEmpty) {
      return Product.fromMap(query.docs.first.data());
    }
    return null;
  }
}
