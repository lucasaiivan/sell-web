import 'package:cloud_firestore/cloud_firestore.dart'; 
import '../domain/repositories/catalogue_repository.dart';

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
}
