import 'package:injectable/injectable.dart';
import 'package:fpdart/fpdart.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/cash_register_repository.dart';
import '../entities/cash_register.dart';

/// Parámetros para OpenCashRegisterUseCase
class OpenCashRegisterParams {
  final String accountId;
  final String description;
  final double initialCash;
  final String cashierId;
  final String cashierName;

  const OpenCashRegisterParams({
    required this.accountId,
    required this.description,
    required this.initialCash,
    required this.cashierId,
    required this.cashierName,
  });
}

/// Caso de uso: Abrir caja registradora
///
/// **Responsabilidad:**
/// - Valida que el balance inicial no sea negativo
/// - Abre una nueva caja registradora para el día
/// - Delega la operación al repositorio
@lazySingleton
class OpenCashRegisterUseCase
    extends UseCase<CashRegister, OpenCashRegisterParams> {
  final CashRegisterRepository _repository;

  OpenCashRegisterUseCase(this._repository);

  /// Ejecuta la apertura de caja
  ///
  /// Retorna [Right(CashRegister)] si es exitoso, [Left(Failure)] si falla
  @override
  Future<Either<Failure, CashRegister>> call(
      OpenCashRegisterParams params) async {
    // Validaciones de negocio
    if (params.initialCash < 0) {
      return Left(
          ValidationFailure('El efectivo inicial no puede ser negativo'));
    }

    if (params.description.trim().isEmpty) {
      return Left(ValidationFailure('La descripción es obligatoria'));
    }

    try {
      final cashRegister = await _repository.openCashRegister(
        accountId: params.accountId,
        description: params.description,
        initialCash: params.initialCash,
        cashierId: params.cashierId,
        cashierName: params.cashierName,
      );
      return Right(cashRegister);
    } catch (e) {
      return Left(ServerFailure('Error al abrir caja: ${e.toString()}'));
    }
  }
}
