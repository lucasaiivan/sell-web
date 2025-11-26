import 'package:injectable/injectable.dart';
import 'package:fpdart/fpdart.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/catalogue_repository.dart';

/// Parámetros para DecrementProductStockUseCase
class DecrementProductStockParams {
  final String accountId;
  final String productId;
  final int quantity;

  const DecrementProductStockParams({
    required this.accountId,
    required this.productId,
    required this.quantity,
  });
}

/// Caso de uso: Decrementar stock de producto
///
/// **Responsabilidad:**
/// - Decrementa el stock de un producto
/// - Valida que la cantidad sea positiva
/// - Delega la operación al repositorio
@lazySingleton
class DecrementProductStockUseCase extends UseCase<void, DecrementProductStockParams> {
  final CatalogueRepository _repository;

  DecrementProductStockUseCase(this._repository);

  /// Ejecuta el decremento de stock
  ///
  /// Retorna [Right(void)] si es exitoso, [Left(Failure)] si falla
  @override
  Future<Either<Failure, void>> call(DecrementProductStockParams params) async {
    // Validación de negocio
    if (params.quantity <= 0) {
      return Left(ValidationFailure('La cantidad debe ser mayor a cero'));
    }

    try {
      await _repository.decrementStock(params.accountId, params.productId, params.quantity);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Error al decrementar stock: ${e.toString()}'));
    }
  }
}
