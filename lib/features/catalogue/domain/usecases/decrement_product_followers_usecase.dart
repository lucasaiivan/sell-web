import 'package:injectable/injectable.dart';
import 'package:fpdart/fpdart.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/catalogue_repository.dart';

/// Parámetros para DecrementProductFollowersUseCase
class DecrementProductFollowersParams {
  /// ID del producto público (código de barras)
  final String productId;

  const DecrementProductFollowersParams({
    required this.productId,
  });
}

/// Caso de uso: Decrementar contador de followers de un producto público
///
/// ## Responsabilidad:
/// - Decrementa el contador `followers` de un producto en la BD global
/// - Se llama cuando un comercio elimina un producto de su catálogo
///
/// ## Contexto de negocio:
/// - El contador `followers` nunca debe ser negativo
/// - El documento del producto se mantiene aunque followers llegue a 0
/// - Productos con followers = 0 podrían considerarse para limpieza futura
///
/// ## Flujo:
/// 1. Comercio elimina producto de su catálogo privado
/// 2. Si el producto referenciaba un producto global (no es SKU interno)
/// 3. Se decrementa `followers` del producto global
@lazySingleton
class DecrementProductFollowersUseCase
    extends UseCase<void, DecrementProductFollowersParams> {
  final CatalogueRepository _repository;

  DecrementProductFollowersUseCase(this._repository);

  /// Ejecuta el decremento de followers
  ///
  /// Retorna [Right(void)] si es exitoso, [Left(Failure)] si falla
  @override
  Future<Either<Failure, void>> call(
      DecrementProductFollowersParams params) async {
    // Validación de negocio
    if (params.productId.isEmpty) {
      return Left(ValidationFailure('El ID del producto es requerido'));
    }

    try {
      await _repository.decrementProductFollowers(params.productId);
      return const Right(null);
    } catch (e) {
      return Left(
          ServerFailure('Error al decrementar followers: ${e.toString()}'));
    }
  }
}
