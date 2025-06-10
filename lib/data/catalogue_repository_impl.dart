import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import '../domain/repositories/catalogue_repository.dart';

class CatalogueRepositoryImpl implements CatalogueRepository {
  final String? id;
  CatalogueRepositoryImpl({this.id});

  @override
  Stream<QuerySnapshot> getProductsStream() {
    final uid = id ?? fb_auth.FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      // Si no hay usuario autenticado ni userId inyectado, retorna un stream vacío
      return const Stream.empty();
    }
    return FirebaseFirestore.instance
        .collection('/ACCOUNTS/$uid/CATALOGUE')
        .snapshots();
  }
}
