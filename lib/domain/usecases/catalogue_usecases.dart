import 'package:cloud_firestore/cloud_firestore.dart';
import '../repositories/catalogue_repository.dart';

class GetProductsStreamUseCase {
  final CatalogueRepository repository;
  GetProductsStreamUseCase(this.repository);
  Stream<QuerySnapshot> call() => repository.getProductsStream();
}
