import 'package:injectable/injectable.dart';
import 'package:fpdart/fpdart.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/catalogue_repository.dart';

/// Parámetros para UpdateProductFavoriteUseCase
class UpdateProductFavoriteParams {
  final String accountId;
  final String productId;
  final bool isFavorite;

  const UpdateProductFavoriteParams({
    required this.accountId,
    required this.productId,
    required this.isFavorite,
  });
}

/// Caso de uso: Actualizar estado favorito de producto
///
/// **Responsabilidad:**
/// - Actualiza el estado de favorito de un producto
/// - Delega la operación al repositorio
@lazySingleton
class UpdateProductFavoriteUseCase
    extends UseCase<void, UpdateProductFavoriteParams> {
  final CatalogueRepository _repository;

  UpdateProductFavoriteUseCase(this._repository);

  /// Ejecuta la actualización del estado favorito
  ///
  /// Retorna [Right(void)] si es exitoso, [Left(Failure)] si falla
  @override
  Future<Either<Failure, void>> call(UpdateProductFavoriteParams params) async {
    try {
      await _repository.updateProductFavorite(
        params.accountId,
        params.productId,
        params.isFavorite,
      );
      return const Right(null);
    } catch (e) {
      return Left(
          ServerFailure('Error al actualizar favorito: ${e.toString()}'));
    }
  }
}
