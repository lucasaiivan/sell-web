import 'package:injectable/injectable.dart';
import 'package:fpdart/fpdart.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/catalogue_repository.dart';
import '../entities/product.dart';

/// Parámetros para GetPublicProductByCodeUseCase
class GetPublicProductByCodeParams {
  final String code;

  const GetPublicProductByCodeParams(this.code);
}

/// Caso de uso: Buscar producto público por código
///
/// **Responsabilidad:**
/// - Busca un producto en la base de datos pública por código de barra
/// - Delega la operación al repositorio
@lazySingleton
class GetPublicProductByCodeUseCase
    extends UseCase<Product?, GetPublicProductByCodeParams> {
  final CatalogueRepository _repository;

  GetPublicProductByCodeUseCase(this._repository);

  /// Ejecuta la búsqueda del producto público
  ///
  /// Retorna [Right(Product?)] con el producto o null si no existe,
  /// [Left(Failure)] si falla
  @override
  Future<Either<Failure, Product?>> call(
      GetPublicProductByCodeParams params) async {
    try {
      final product = await _repository.getPublicProductByCode(params.code);
      return Right(product);
    } catch (e) {
      return Left(
          ServerFailure('Error al buscar producto público: ${e.toString()}'));
    }
  }
}
