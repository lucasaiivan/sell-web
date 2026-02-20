import 'package:injectable/injectable.dart';
import 'package:fpdart/fpdart.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/catalogue_repository.dart';
import '../entities/product.dart';

/// Parámetros para CreatePublicProductUseCase
class CreatePublicProductParams {
  final Product product;

  const CreatePublicProductParams(this.product);
}

/// Caso de uso: Crear producto público
///
/// **Responsabilidad:**
/// - Crea un nuevo producto en la base de datos pública
/// - Delega la operación al repositorio
@lazySingleton
class CreatePublicProductUseCase
    extends UseCase<void, CreatePublicProductParams> {
  final CatalogueRepository _repository;

  CreatePublicProductUseCase(this._repository);

  /// Ejecuta la creación del producto público
  ///
  /// Retorna [Right(void)] si es exitoso, [Left(Failure)] si falla
  @override
  Future<Either<Failure, void>> call(CreatePublicProductParams params) async {
    try {
      await _repository.createPublicProduct(params.product);
      return const Right(null);
    } catch (e) {
      return Left(
          ServerFailure('Error al crear producto público: ${e.toString()}'));
    }
  }
}
