import 'package:cloud_firestore/cloud_firestore.dart';
import '../repositories/catalogue_repository.dart';
import '../entities/catalogue.dart';

class GetProductsStreamUseCase {
  final CatalogueRepository repository;
  GetProductsStreamUseCase(this.repository);
  Stream<QuerySnapshot> call() => repository.getProductsStream();
}

class GetProductByCodeUseCase {
  // Recibe la lista de productos y el código a buscar
  ProductCatalogue? call(List<ProductCatalogue> products, String code) {
    try {
      return products.firstWhere((p) => p.code == code);
    } catch (_) {
      return null;
    }
  }
}

class IsProductScannedUseCase {
  final GetProductByCodeUseCase getProductByCodeUseCase;
  IsProductScannedUseCase(this.getProductByCodeUseCase);

  bool call(List<ProductCatalogue> products, String code) {
    final product = getProductByCodeUseCase(products, code);
    return product != null;
  }
}
