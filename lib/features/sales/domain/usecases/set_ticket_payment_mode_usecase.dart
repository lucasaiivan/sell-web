import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import 'package:sellweb/core/errors/failures.dart';
import 'package:sellweb/core/usecases/usecase.dart';
import 'package:sellweb/features/sales/domain/entities/ticket_model.dart';

/// Configura la forma de pago del ticket
///
/// RESPONSABILIDAD: Establecer método de pago
/// - Validar forma de pago permitida (effective, card, mercadopago)
/// - Resetear valueReceived si no es efectivo
@lazySingleton
class SetTicketPaymentModeUseCase
    implements UseCase<TicketModel, SetTicketPaymentModeParams> {
  @override
  Future<Either<Failure, TicketModel>> call(
      SetTicketPaymentModeParams params) async {
    try {
      final allowedPayModes = ['effective', 'card', 'mercadopago', ''];
      if (!allowedPayModes.contains(params.payMode)) {
        return Left(ValidationFailure(
            'Forma de pago no válida: ${params.payMode}'));
      }

      final valueReceived = params.payMode != 'effective'
          ? 0.0
          : params.currentTicket.valueReceived;

      final updatedTicket = params.currentTicket.copyWith(
        payMode: params.payMode,
        valueReceived: valueReceived,
      );

      return Right(updatedTicket);
    } catch (e) {
      return Left(
          ServerFailure('Error al configurar forma de pago: $e'));
    }
  }
}

class SetTicketPaymentModeParams {
  final TicketModel currentTicket;
  final String payMode;

  SetTicketPaymentModeParams({
    required this.currentTicket,
    required this.payMode,
  });
}
