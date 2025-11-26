import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import 'package:sellweb/core/errors/failures.dart';
import 'package:sellweb/core/usecases/usecase.dart';
import 'package:sellweb/features/sales/domain/entities/ticket_model.dart';

/// Configura el valor recibido en efectivo
///
/// RESPONSABILIDAD: Establecer monto recibido del cliente
/// - Validar valor no negativo
/// - Solo aplica para pagos en efectivo
@lazySingleton
class SetTicketReceivedCashUseCase
    implements UseCase<TicketModel, SetTicketReceivedCashParams> {
  @override
  Future<Either<Failure, TicketModel>> call(
      SetTicketReceivedCashParams params) async {
    try {
      if (params.value < 0) {
        return Left(ValidationFailure(
            'El valor recibido no puede ser negativo'));
      }

      final updatedTicket = params.currentTicket.copyWith(
        valueReceived: params.value,
      );

      return Right(updatedTicket);
    } catch (e) {
      return Left(
          ServerFailure('Error al configurar valor recibido: $e'));
    }
  }
}

class SetTicketReceivedCashParams {
  final TicketModel currentTicket;
  final double value;

  SetTicketReceivedCashParams({
    required this.currentTicket,
    required this.value,
  });
}
