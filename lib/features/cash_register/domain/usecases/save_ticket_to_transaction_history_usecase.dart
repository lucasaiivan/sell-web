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
      await _repository.saveTicketTransaction(
        accountId: params.accountId,
        ticketId: params.ticket.id,
        transactionData: params.ticket.toJson(),
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
