import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import 'package:sellweb/core/errors/failures.dart';
import 'package:sellweb/core/usecases/usecase.dart';
import 'package:sellweb/features/sales/domain/entities/ticket_model.dart';

/// Configura el descuento del ticket
///
/// RESPONSABILIDAD: Establecer descuento (absoluto o porcentaje)
/// - Validar descuento no negativo
/// - Configurar tipo de descuento (porcentaje o valor fijo)
@lazySingleton
class SetTicketDiscountUseCase
    implements UseCase<TicketModel, SetTicketDiscountParams> {
  @override
  Future<Either<Failure, TicketModel>> call(
      SetTicketDiscountParams params) async {
    try {
      if (params.discount < 0) {
        return Left(ValidationFailure('El descuento no puede ser negativo'));
      }

      final updatedTicket = params.currentTicket.copyWith(
        discount: params.discount,
        discountIsPercentage: params.isPercentage,
      );

      return Right(updatedTicket);
    } catch (e) {
      return Left(ServerFailure('Error al configurar descuento: $e'));
    }
  }
}

class SetTicketDiscountParams {
  final TicketModel currentTicket;
  final double discount;
  final bool isPercentage;

  SetTicketDiscountParams({
    required this.currentTicket,
    required this.discount,
    this.isPercentage = false,
  });
}
