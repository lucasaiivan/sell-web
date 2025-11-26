import 'package:injectable/injectable.dart';
import 'package:fpdart/fpdart.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/cash_register_repository.dart';
import '../entities/cash_register.dart';

/// Parámetros para AddCashInflowUseCase
class AddCashInflowParams {
  final String accountId;
  final String cashRegisterId;
  final CashFlow cashFlow;

  const AddCashInflowParams({
    required this.accountId,
    required this.cashRegisterId,
    required this.cashFlow,
  });
}

/// Caso de uso: Agregar ingreso de efectivo
///
/// **Responsabilidad:**
/// - Valida que el monto sea positivo
/// - Registra un ingreso de efectivo en la caja
/// - Delega la operación al repositorio
@lazySingleton
class AddCashInflowUseCase extends UseCase<void, AddCashInflowParams> {
  final CashRegisterRepository _repository;

  AddCashInflowUseCase(this._repository);

  /// Ejecuta el registro de ingreso
  ///
  /// Retorna [Right(void)] si es exitoso, [Left(Failure)] si falla
  @override
  Future<Either<Failure, void>> call(AddCashInflowParams params) async {
    // Validaciones de negocio
    if (params.cashFlow.amount <= 0) {
      return Left(ValidationFailure('El monto debe ser mayor a cero'));
    }
    
    if (params.cashFlow.description.trim().isEmpty) {
      return Left(ValidationFailure('La descripción es obligatoria'));
    }

    try {
      await _repository.addCashInflow(
        accountId: params.accountId,
        cashRegisterId: params.cashRegisterId,
        cashFlow: params.cashFlow,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Error al agregar ingreso: ${e.toString()}'));
    }
  }
}
