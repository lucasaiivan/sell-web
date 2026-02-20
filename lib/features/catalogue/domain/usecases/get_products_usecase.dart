import 'package:injectable/injectable.dart';
import 'package:fpdart/fpdart.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/errors/failures.dart';
import '../entities/product_catalogue.dart';
import '../repositories/catalogue_repository.dart';

/// Parámetros para GetProductsUseCase
class GetProductsParams {
  final String accountId;

  const GetProductsParams(this.accountId);
}

/// Caso de uso: Obtener todos los productos del catálogo
///
/// **Responsabilidad:**
/// - Recupera productos de una cuenta específica
/// - Delega la operación al repositorio
@lazySingleton
class GetProductsUseCase
    extends UseCase<List<ProductCatalogue>, GetProductsParams> {
  final CatalogueRepository repository;

  GetProductsUseCase(this.repository);

  /// Ejecuta la obtención de productos
  ///
  /// Retorna [Right(List<ProductCatalogue>)] si es exitoso, [Left(Failure)] si falla
  @override
  Future<Either<Failure, List<ProductCatalogue>>> call(
      GetProductsParams params) async {
    try {
      final products = await repository.getProducts(params.accountId);
      return Right(products);
    } catch (e) {
      return Left(ServerFailure('Error al obtener productos: ${e.toString()}'));
    }
  }
}
