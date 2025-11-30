import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import 'package:sellweb/core/constants/payment_methods.dart';
import 'package:sellweb/core/errors/failures.dart';
import 'package:sellweb/core/usecases/usecase.dart';
import 'package:sellweb/features/sales/domain/entities/ticket_model.dart';

/// Configura la forma de pago del ticket
///
/// RESPONSABILIDAD: Establecer método de pago
/// - Validar forma de pago permitida (cash, transfer, card, qr)
/// - Resetear valueReceived si no es efectivo
@lazySingleton
class SetTicketPaymentModeUseCase
    implements UseCase<TicketModel, SetTicketPaymentModeParams> {
  @override
  Future<Either<Failure, TicketModel>> call(
      SetTicketPaymentModeParams params) async {
    try {
      // Normalizar el código de entrada (por si viene de código legacy)
      final normalizedPayMode = PaymentMethod.migrateLegacyCode(params.payMode);

      final allowedPayModes = PaymentMethod.getValidCodes();
      if (!allowedPayModes.contains(normalizedPayMode)) {
        return Left(
            ValidationFailure('Forma de pago no válida: ${params.payMode}'));
      }

      final valueReceived = normalizedPayMode != PaymentMethod.cash.code
          ? 0.0
          : params.currentTicket.valueReceived;

      final updatedTicket = params.currentTicket.copyWith(
        payMode: normalizedPayMode,
        valueReceived: valueReceived,
      );

      return Right(updatedTicket);
    } catch (e) {
      return Left(ServerFailure('Error al configurar forma de pago: $e'));
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
