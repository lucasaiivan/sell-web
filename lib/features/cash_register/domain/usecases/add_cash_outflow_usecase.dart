import 'package:injectable/injectable.dart';
import 'package:fpdart/fpdart.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/cash_register_repository.dart';
import '../entities/cash_register.dart';

/// Parámetros para AddCashOutflowUseCase
class AddCashOutflowParams {
  final String accountId;
  final String cashRegisterId;
  final CashFlow cashFlow;

  const AddCashOutflowParams({
    required this.accountId,
    required this.cashRegisterId,
    required this.cashFlow,
  });
}

/// Caso de uso: Agregar egreso de efectivo
///
/// **Responsabilidad:**
/// - Valida que el monto sea positivo
/// - Registra un egreso de efectivo de la caja
/// - Delega la operación al repositorio
@lazySingleton
class AddCashOutflowUseCase extends UseCase<void, AddCashOutflowParams> {
  final CashRegisterRepository _repository;

  AddCashOutflowUseCase(this._repository);

  /// Ejecuta el registro de egreso
  ///
  /// Retorna [Right(void)] si es exitoso, [Left(Failure)] si falla
  @override
  Future<Either<Failure, void>> call(AddCashOutflowParams params) async {
    // Validaciones de negocio
    if (params.cashFlow.amount <= 0) {
      return Left(ValidationFailure('El monto debe ser mayor a cero'));
    }

    if (params.cashFlow.description.trim().isEmpty) {
      return Left(ValidationFailure('La descripción es obligatoria'));
    }

    try {
      await _repository.addCashOutflow(
        accountId: params.accountId,
        cashRegisterId: params.cashRegisterId,
        cashFlow: params.cashFlow,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Error al agregar egreso: ${e.toString()}'));
    }
  }
}
