import 'package:injectable/injectable.dart';
import 'package:fpdart/fpdart.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/catalogue_repository.dart';
import '../entities/mark.dart';

/// Parámetros para CreateBrandUseCase
class CreateBrandParams {
  final Mark brand;
  final String country;

  const CreateBrandParams({
    required this.brand,
    this.country = 'ARG',
  });
}

/// Caso de uso: Crear marca
///
/// **Responsabilidad:**
/// - Crea una nueva marca en la base de datos pública
/// - Delega la operación al repositorio
@lazySingleton
class CreateBrandUseCase extends UseCase<void, CreateBrandParams> {
  final CatalogueRepository _repository;

  CreateBrandUseCase(this._repository);

  /// Ejecuta la creación de la marca
  ///
  /// Retorna [Right(void)] si es exitoso, [Left(Failure)] si falla
  @override
  Future<Either<Failure, void>> call(CreateBrandParams params) async {
    try {
      await _repository.createBrand(params.brand, country: params.country);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Error al crear marca: ${e.toString()}'));
    }
  }
}
