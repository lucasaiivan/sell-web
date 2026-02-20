import 'package:injectable/injectable.dart';
import 'package:fpdart/fpdart.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/catalogue_repository.dart';

/// Parámetros para IncrementProductFollowersUseCase
class IncrementProductFollowersParams {
  /// ID del producto público (código de barras)
  final String productId;

  const IncrementProductFollowersParams({
    required this.productId,
  });
}

/// Caso de uso: Incrementar contador de followers de un producto público
///
/// ## Responsabilidad:
/// - Incrementa el contador `followers` de un producto en la BD global
/// - Se llama cuando un comercio agrega un producto de la BD global a su catálogo
///
/// ## Contexto de negocio:
/// - El contador `followers` indica cuántos comercios tienen este producto
/// - Sirve como métrica de popularidad y validación comunitaria
/// - Un producto con muchos followers tiene más credibilidad
///
/// ## Flujo:
/// 1. Comercio busca producto por código de barras
/// 2. Producto existe en BD global (status: 'pending' o 'verified')
/// 3. Comercio lo agrega a su catálogo privado
/// 4. Se incrementa `followers` del producto global
@lazySingleton
class IncrementProductFollowersUseCase
    extends UseCase<void, IncrementProductFollowersParams> {
  final CatalogueRepository _repository;

  IncrementProductFollowersUseCase(this._repository);

  /// Ejecuta el incremento de followers
  ///
  /// Retorna [Right(void)] si es exitoso, [Left(Failure)] si falla
  @override
  Future<Either<Failure, void>> call(
      IncrementProductFollowersParams params) async {
    // Validación de negocio
    if (params.productId.isEmpty) {
      return Left(ValidationFailure('El ID del producto es requerido'));
    }

    try {
      await _repository.incrementProductFollowers(params.productId);
      return const Right(null);
    } catch (e) {
      return Left(
          ServerFailure('Error al incrementar followers: ${e.toString()}'));
    }
  }
}
