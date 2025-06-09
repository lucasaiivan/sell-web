import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/repositories/catalogue_repository.dart';

class CatalogueRepositoryImpl implements CatalogueRepository {
  @override
  Stream<QuerySnapshot> getProductsStream() {
    return FirebaseFirestore.instance.collection('/APP/ARG/PRODUCTOS').snapshots();
  }
}
