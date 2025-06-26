import 'package:cloud_firestore/cloud_firestore.dart';
import '../repositories/catalogue_repository.dart';
import '../entities/catalogue.dart';

class GetCatalogueStreamUseCase {
  final CatalogueRepository repository;
  GetCatalogueStreamUseCase(this.repository);
  Stream<QuerySnapshot> call() => repository.getCatalogueStream();
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

class GetPublicProductByCodeUseCase {
  final CatalogueRepository repository;
  GetPublicProductByCodeUseCase(this.repository);
  // Busca un producto público por código de barra
  Future<Product?> call(String code) => repository.getPublicProductByCode(code);
}

class IsProductScannedUseCase {
  final GetProductByCodeUseCase getProductByCodeUseCase;
  IsProductScannedUseCase(this.getProductByCodeUseCase);

  bool call(List<ProductCatalogue> products, String code) {
    final product = getProductByCodeUseCase(products, code);
    return product != null;
  }
}
