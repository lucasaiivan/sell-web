import 'package:injectable/injectable.dart';
import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/mark.dart';
import '../repositories/catalogue_repository.dart';

/// Parámetros para UpdateBrandUseCase
class UpdateBrandParams {
  final Mark brand;
  final String country;

  const UpdateBrandParams({
    required this.brand,
    this.country = 'ARG',
  });
}

/// Caso de uso: Actualizar una marca existente
///
/// Valida que el ID de la marca sea válido y delega
/// la actualización al repositorio.
@lazySingleton
class UpdateBrandUseCase extends UseCase<void, UpdateBrandParams> {
  final CatalogueRepository _repository;

  UpdateBrandUseCase(this._repository);

  @override
  Future<Either<Failure, void>> call(UpdateBrandParams params) async {
    try {
      if (params.brand.id.isEmpty) {
        return Left(
          ValidationFailure('La marca debe tener un ID válido'),
        );
      }

      if (params.brand.name.trim().isEmpty) {
        return Left(
          ValidationFailure('El nombre de la marca es requerido'),
        );
      }

      await _repository.updateBrand(params.brand, country: params.country);
      return const Right(null);
    } catch (e) {
      return Left(
        ServerFailure('Error al actualizar la marca: ${e.toString()}'),
      );
    }
  }
}
