import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:sellweb/core/errors/failures.dart';
import 'package:sellweb/core/usecases/usecase.dart';
import 'package:sellweb/features/cash_register/domain/repositories/cash_register_repository.dart';
import 'package:sellweb/features/sales/domain/entities/ticket_model.dart';

@lazySingleton
class SaveTicketToTransactionHistoryUseCase
    implements UseCase<void, SaveTicketToTransactionHistoryParams> {
  final CashRegisterRepository _repository;

  SaveTicketToTransactionHistoryUseCase(this._repository);

  @override
  Future<Either<Failure, void>> call(
      SaveTicketToTransactionHistoryParams params) async {
    try {
      // ✅ Usar toMap() en lugar de toJson() para preservar Timestamps de Firestore
      // toJson() convierte Timestamps a milliseconds (int), lo que rompe las consultas
      // toMap() mantiene los Timestamps, permitiendo queries con where/orderBy
      await _repository.saveTicketTransaction(
        accountId: params.accountId,
        ticketId: params.ticket.id,
        transactionData: params.ticket.toMap(),
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}

class SaveTicketToTransactionHistoryParams {
  final String accountId;
  final TicketModel ticket;

  const SaveTicketToTransactionHistoryParams({
    required this.accountId,
    required this.ticket,
  });
}
