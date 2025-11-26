import 'package:injectable/injectable.dart';
import 'package:fpdart/fpdart.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/cash_register_repository.dart';

/// Parámetros para SaveTicketTransactionUseCase
class SaveTicketTransactionParams {
  final String accountId;
  final String ticketId;
  final Map<String, dynamic> transactionData;

  const SaveTicketTransactionParams({
    required this.accountId,
    required this.ticketId,
    required this.transactionData,
  });
}

/// Caso de uso: Guardar transacción de ticket
///
/// **Responsabilidad:**
/// - Guarda un ticket de venta en el historial de transacciones
/// - Valida que los datos no estén vacíos
/// - Delega la operación al repositorio
@lazySingleton
class SaveTicketTransactionUseCase extends UseCase<void, SaveTicketTransactionParams> {
  final CashRegisterRepository _repository;

  SaveTicketTransactionUseCase(this._repository);

  /// Ejecuta el guardado de la transacción
  ///
  /// Retorna [Right(void)] si es exitoso, [Left(Failure)] si falla
  @override
  Future<Either<Failure, void>> call(SaveTicketTransactionParams params) async {
    // Validaciones de negocio
    if (params.ticketId.trim().isEmpty) {
      return Left(ValidationFailure('El ID del ticket es obligatorio'));
    }
    
    if (params.transactionData.isEmpty) {
      return Left(ValidationFailure('Los datos de la transacción son obligatorios'));
    }

    try {
      await _repository.saveTicketTransaction(
        accountId: params.accountId,
        ticketId: params.ticketId,
        transactionData: params.transactionData,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Error al guardar transacción: ${e.toString()}'));
    }
  }
}
