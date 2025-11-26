import 'package:injectable/injectable.dart';
import 'package:fpdart/fpdart.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/catalogue_repository.dart';

/// Parámetros para UpdateStockUseCase
class UpdateStockParams {
  final String accountId;
  final String productId;
  final int newStock;

  const UpdateStockParams({
    required this.accountId,
    required this.productId,
    required this.newStock,
  });
}

/// Caso de uso: Actualizar stock de un producto
/// 
/// **Responsabilidad:**
/// - Valida que el stock no sea negativo
/// - Actualiza la cantidad en stock del producto
/// - Delega la operación al repositorio
@lazySingleton
class UpdateStockUseCase extends UseCase<void, UpdateStockParams> {
  final CatalogueRepository repository;

  UpdateStockUseCase(this.repository);

  /// Ejecuta la actualización de stock
  /// 
  /// Retorna [Right(void)] si es exitoso, [Left(Failure)] si falla o el stock es negativo
  @override
  Future<Either<Failure, void>> call(UpdateStockParams params) async {
    // Validación de negocio
    if (params.newStock < 0) {
      return Left(ValidationFailure('El stock no puede ser negativo'));
    }

    try {
      await repository.updateStock(params.accountId, params.productId, params.newStock);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Error al actualizar stock: ${e.toString()}'));
    }
  }
}
