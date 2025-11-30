import 'package:injectable/injectable.dart';
import 'package:fpdart/fpdart.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/cash_register_repository.dart';
import '../../../sales/domain/entities/ticket_model.dart';
import '../entities/cash_register.dart';

class ProcessTicketAnnullmentParams {
  final String accountId;
  final TicketModel ticket;
  final CashRegister? activeCashRegister;

  const ProcessTicketAnnullmentParams({
    required this.accountId,
    required this.ticket,
    this.activeCashRegister,
  });
}

@lazySingleton
class ProcessTicketAnnullmentUseCase
    extends UseCase<TicketModel, ProcessTicketAnnullmentParams> {
  final CashRegisterRepository _repository;

  ProcessTicketAnnullmentUseCase(this._repository);

  @override
  Future<Either<Failure, TicketModel>> call(
      ProcessTicketAnnullmentParams params) async {
    if (params.ticket.annulled) {
      return Left(ValidationFailure('El ticket ya está anulado'));
    }

    if (params.ticket.id.trim().isEmpty) {
      return Left(ValidationFailure('El ticket debe tener un ID válido'));
    }

    try {
      final annulledTicket = params.ticket.copyWith(annulled: true);

      await _repository.saveTicketTransaction(
        accountId: params.accountId,
        ticketId: params.ticket.id,
        transactionData: annulledTicket.toMap(),
      );

      if (params.activeCashRegister != null &&
          params.ticket.cashRegisterId == params.activeCashRegister!.id) {
        await _repository.updateBillingOnAnnullment(
          accountId: params.accountId,
          cashRegisterId: params.activeCashRegister!.id,
          billingDecrement: params.ticket.priceTotal,
          discountDecrement: params.ticket.getDiscountAmount,
        );
      }

      return Right(annulledTicket);
    } catch (e) {
      return Left(ServerFailure('Error al anular ticket: ${e.toString()}'));
    }
  }
}
