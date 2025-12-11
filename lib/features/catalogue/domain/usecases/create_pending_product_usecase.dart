import 'package:injectable/injectable.dart';
import '../entities/product.dart';
import '../repositories/catalogue_repository.dart';

@lazySingleton
class CreatePendingProductUseCase {
  final CatalogueRepository _repository;

  CreatePendingProductUseCase(this._repository);

  Future<void> call(Product product) async {
    return _repository.createPendingProduct(product);
  }
}
