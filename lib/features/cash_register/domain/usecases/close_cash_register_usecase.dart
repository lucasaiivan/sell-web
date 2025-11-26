import 'package:injectable/injectable.dart';
import 'package:fpdart/fpdart.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/cash_register_repository.dart';
import '../entities/cash_register.dart';

/// Parámetros para CloseCashRegisterUseCase
class CloseCashRegisterParams {
  final String accountId;
  final String cashRegisterId;
  final double finalBalance;

  const CloseCashRegisterParams({
    required this.accountId,
    required this.cashRegisterId,
    required this.finalBalance,
  });
}

/// Caso de uso: Cerrar caja registradora
///
/// **Responsabilidad:**
/// - Valida que el balance final no sea negativo
/// - Cierra la caja registradora activa
/// - Delega la operación al repositorio
@lazySingleton
class CloseCashRegisterUseCase extends UseCase<CashRegister, CloseCashRegisterParams> {
  final CashRegisterRepository _repository;

  CloseCashRegisterUseCase(this._repository);

  /// Ejecuta el cierre de caja
  ///
  /// Retorna [Right(CashRegister)] si es exitoso, [Left(Failure)] si falla
  @override
  Future<Either<Failure, CashRegister>> call(CloseCashRegisterParams params) async {
    // Validación de negocio
    if (params.finalBalance < 0) {
      return Left(ValidationFailure('El balance final no puede ser negativo'));
    }

    try {
      final cashRegister = await _repository.closeCashRegister(
        accountId: params.accountId,
        cashRegisterId: params.cashRegisterId,
        finalBalance: params.finalBalance,
      );
      return Right(cashRegister);
    } catch (e) {
      return Left(ServerFailure('Error al cerrar caja: ${e.toString()}'));
    }
  }
}
