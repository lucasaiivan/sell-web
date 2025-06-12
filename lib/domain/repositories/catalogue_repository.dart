import 'package:cloud_firestore/cloud_firestore.dart';

abstract class CatalogueRepository {
  Stream<QuerySnapshot> getCatalogueStream();
}
