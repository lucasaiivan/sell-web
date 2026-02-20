import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import 'package:sellweb/core/errors/failures.dart';
import 'package:sellweb/core/usecases/usecase.dart';
import 'package:sellweb/features/cash_register/domain/repositories/cash_register_repository.dart';

/// Obtiene el detalle de una transacción específica
///
/// RESPONSABILIDAD: Consultar transacción individual
/// - Validar IDs
/// - Retornar detalle completo
@lazySingleton
class GetTransactionDetailUseCase
    implements UseCase<Map<String, dynamic>?, GetTransactionDetailParams> {
  final CashRegisterRepository _repository;

  GetTransactionDetailUseCase(this._repository);

  @override
  Future<Either<Failure, Map<String, dynamic>?>> call(
      GetTransactionDetailParams params) async {
    try {
      if (params.accountId.trim().isEmpty) {
        return Left(ValidationFailure('El ID de cuenta no puede estar vacío'));
      }

      if (params.transactionId.trim().isEmpty) {
        return Left(
            ValidationFailure('El ID de transacción no puede estar vacío'));
      }

      final transaction = await _repository.getTransactionDetail(
        accountId: params.accountId,
        transactionId: params.transactionId,
      );

      return Right(transaction);
    } catch (e) {
      return Left(ServerFailure('Error al obtener detalle de transacción: $e'));
    }
  }
}

class GetTransactionDetailParams {
  final String accountId;
  final String transactionId;

  GetTransactionDetailParams({
    required this.accountId,
    required this.transactionId,
  });
}
