import 'package:injectable/injectable.dart';
import 'package:fpdart/fpdart.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/cash_register_repository.dart';
import '../entities/cash_register.dart';

/// Parámetros para GetActiveCashRegistersUseCase
class GetActiveCashRegistersParams {
  final String accountId;

  const GetActiveCashRegistersParams(this.accountId);
}

/// Caso de uso: Obtener cajas activas
///
/// **Responsabilidad:**
/// - Obtiene las cajas registradoras actualmente abiertas
/// - Delega la operación al repositorio
@lazySingleton
class GetActiveCashRegistersUseCase
    extends UseCase<List<CashRegister>, GetActiveCashRegistersParams> {
  final CashRegisterRepository _repository;

  GetActiveCashRegistersUseCase(this._repository);

  /// Ejecuta la obtención de cajas activas
  ///
  /// Retorna [Right(List<CashRegister>)] si es exitoso, [Left(Failure)] si falla
  @override
  Future<Either<Failure, List<CashRegister>>> call(
      GetActiveCashRegistersParams params) async {
    try {
      final cashRegisters =
          await _repository.getActiveCashRegisters(params.accountId);
      return Right(cashRegisters);
    } catch (e) {
      return Left(
          ServerFailure('Error al obtener cajas activas: ${e.toString()}'));
    }
  }
}
