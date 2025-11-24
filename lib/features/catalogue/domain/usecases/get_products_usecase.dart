import 'package:injectable/injectable.dart';
import '../entities/product_catalogue.dart';
import '../repositories/catalogue_repository.dart';

/// Caso de uso para obtener todos los productos del catálogo.
/// 
/// Encapsula la lógica de negocio para recuperar productos
/// de una cuenta específica.
@lazySingleton
class GetProductsUseCase {
  final CatalogueRepository repository;

  GetProductsUseCase(this.repository);

  /// Ejecuta el caso de uso
  /// 
  /// [accountId] - ID de la cuenta de la cual obtener productos
  /// Retorna lista de productos del catálogo
  Future<List<ProductCatalogue>> call(String accountId) async {
    return await repository.getProducts(accountId);
  }
}
