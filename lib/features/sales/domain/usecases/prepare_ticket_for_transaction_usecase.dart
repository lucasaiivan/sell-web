import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import 'package:sellweb/core/errors/failures.dart';
import 'package:sellweb/core/usecases/usecase.dart';
import 'package:sellweb/core/utils/helpers/uid_helper.dart';
import 'package:sellweb/features/sales/domain/entities/ticket_model.dart';

/// Prepara un ticket para ser guardado en el historial de transacciones
///
/// RESPONSABILIDAD: Validar y normalizar ticket antes de persistir
/// - Validar productos no vacíos
/// - Generar ID si no existe
/// - Calcular precio total con descuento
/// - Establecer nombre de caja (o default si no hay)
/// - Validar sellerId existe
@lazySingleton
class PrepareTicketForTransactionUseCase
    implements UseCase<TicketModel, PrepareTicketForTransactionParams> {
  @override
  Future<Either<Failure, TicketModel>> call(
      PrepareTicketForTransactionParams params) async {
    try {
      if (params.ticket.products.isEmpty) {
        return Left(ValidationFailure(
            'El ticket debe contener al menos un producto'));
      }

      final ticketId = params.ticket.id.trim().isEmpty
          ? UidHelper.generateUid()
          : params.ticket.id;

      // Usar getTotalPrice que incluye descuento (monto real cobrado)
      final priceTotal = params.ticket.priceTotal > 0
          ? params.ticket.priceTotal
          : params.ticket.getTotalPrice;

      if (priceTotal <= 0) {
        return Left(ValidationFailure(
            'El monto total de la venta debe ser mayor a cero'));
      }

      final cashRegisterName = params.ticket.cashRegisterId.trim().isEmpty
          ? 'Sin caja asignada'
          : params.ticket.cashRegisterName;

      final cashRegisterId = params.ticket.cashRegisterId.trim().isEmpty
          ? ''
          : params.ticket.cashRegisterId;

      if (params.ticket.sellerId.trim().isEmpty) {
        return Left(ValidationFailure(
            'El ID del vendedor no puede estar vacío'));
      }

      final preparedTicket = params.ticket.copyWith(
        id: ticketId,
        priceTotal: priceTotal,
        cashRegisterName: cashRegisterName,
        cashRegisterId: cashRegisterId,
      );

      return Right(preparedTicket);
    } catch (e) {
      return Left(ServerFailure(
          'Error al preparar ticket para transacción: $e'));
    }
  }
}

class PrepareTicketForTransactionParams {
  final TicketModel ticket;

  PrepareTicketForTransactionParams({
    required this.ticket,
  });
}
