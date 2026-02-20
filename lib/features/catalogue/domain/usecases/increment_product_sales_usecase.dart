import 'package:injectable/injectable.dart';
import 'package:fpdart/fpdart.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/catalogue_repository.dart';

/// Parámetros para IncrementProductSalesUseCase
class IncrementProductSalesParams {
  final String accountId;
  final String productId;
  final double quantity;

  const IncrementProductSalesParams({
    required this.accountId,
    required this.productId,
    this.quantity = 1.0,
  });
}

/// Caso de uso: Incrementar ventas de producto
///
/// **Responsabilidad:**
/// - Incrementa el contador de ventas de un producto
/// - Valida que la cantidad sea positiva
/// - Delega la operación al repositorio
@lazySingleton
class IncrementProductSalesUseCase
    extends UseCase<void, IncrementProductSalesParams> {
  final CatalogueRepository _repository;

  IncrementProductSalesUseCase(this._repository);

  /// Ejecuta el incremento de ventas
  ///
  /// Retorna [Right(void)] si es exitoso, [Left(Failure)] si falla
  @override
  Future<Either<Failure, void>> call(IncrementProductSalesParams params) async {
    // Validación de negocio
    if (params.quantity <= 0.0) {
      return Left(ValidationFailure('La cantidad debe ser mayor a cero'));
    }

    try {
      await _repository.incrementSales(
          params.accountId, params.productId, params.quantity);
      return const Right(null);
    } catch (e) {
      return Left(
          ServerFailure('Error al incrementar ventas: ${e.toString()}'));
    }
  }
}
