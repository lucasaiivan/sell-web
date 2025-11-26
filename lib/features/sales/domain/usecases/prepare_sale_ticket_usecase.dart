import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import 'package:sellweb/core/errors/failures.dart';
import 'package:sellweb/core/usecases/usecase.dart';
import 'package:sellweb/core/utils/helpers/uid_helper.dart';
import 'package:sellweb/features/cash_register/domain/entities/cash_register.dart';
import 'package:sellweb/features/sales/domain/entities/ticket_model.dart';

/// Prepara un ticket completo para venta
///
/// RESPONSABILIDAD: Validar y finalizar ticket antes de venta
/// - Asignar vendedor
/// - Asociar con caja (opcional)
/// - Calcular precio total con descuentos
/// - Generar ID si no existe
/// - Validar ticket completo
@lazySingleton
class PrepareSaleTicketUseCase
    implements UseCase<TicketModel, PrepareSaleTicketParams> {
  @override
  Future<Either<Failure, TicketModel>> call(
      PrepareSaleTicketParams params) async {
    try {
      // Validar vendedor
      if (params.sellerId.trim().isEmpty) {
        return Left(ValidationFailure(
            'El ID del vendedor no puede estar vacío'));
      }

      if (params.sellerName.trim().isEmpty) {
        return Left(ValidationFailure(
            'El nombre del vendedor no puede estar vacío'));
      }

      // Asignar vendedor
      var updatedTicket = params.currentTicket.copyWith(
        sellerId: params.sellerId,
        sellerName: params.sellerName,
      );

      // Asociar caja si existe
      if (params.activeCashRegister != null) {
        if (params.activeCashRegister!.id.isEmpty) {
          return Left(ValidationFailure(
              'La caja registradora debe tener un ID válido'));
        }

        updatedTicket = updatedTicket.copyWith(
          cashRegisterId: params.activeCashRegister!.id,
          cashRegisterName: params.activeCashRegister!.description,
        );
      }

      // Calcular precio total con descuento aplicado
      updatedTicket = updatedTicket.copyWith(
        priceTotal: updatedTicket.getTotalPrice,
      );

      // Generar ID si no existe
      if (updatedTicket.id.isEmpty) {
        updatedTicket = updatedTicket.copyWith(
          id: UidHelper.generateUid(),
        );
      }

      // Validar ticket completo
      if (updatedTicket.products.isEmpty) {
        return Left(ValidationFailure(
            'El ticket debe tener al menos un producto'));
      }

      if (updatedTicket.priceTotal <= 0) {
        return Left(ValidationFailure(
            'El ticket debe tener un precio total válido'));
      }

      return Right(updatedTicket);
    } catch (e) {
      return Left(
          ServerFailure('Error al preparar ticket para venta: $e'));
    }
  }
}

class PrepareSaleTicketParams {
  final TicketModel currentTicket;
  final String sellerId;
  final String sellerName;
  final CashRegister? activeCashRegister;

  PrepareSaleTicketParams({
    required this.currentTicket,
    required this.sellerId,
    required this.sellerName,
    this.activeCashRegister,
  });
}
