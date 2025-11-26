import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import 'package:sellweb/core/errors/failures.dart';
import 'package:sellweb/core/usecases/usecase.dart';
import 'package:sellweb/features/cash_register/domain/entities/cash_register.dart';
import 'package:sellweb/features/sales/domain/entities/ticket_model.dart';

/// Asocia un ticket con una caja registradora
///
/// RESPONSABILIDAD: Vincular ticket con caja activa
/// - Validar caja (ID válido, descripción no vacía)
/// - Establecer ID y nombre de caja en ticket
@lazySingleton
class AssociateTicketWithCashRegisterUseCase
    implements UseCase<TicketModel, AssociateTicketWithCashRegisterParams> {
  @override
  Future<Either<Failure, TicketModel>> call(
      AssociateTicketWithCashRegisterParams params) async {
    try {
      if (params.cashRegister.id.isEmpty) {
        return Left(ValidationFailure(
            'La caja registradora debe tener un ID válido'));
      }

      if (params.cashRegister.description.trim().isEmpty) {
        return Left(ValidationFailure(
            'La caja registradora debe tener una descripción'));
      }

      final updatedTicket = params.currentTicket.copyWith(
        cashRegisterId: params.cashRegister.id,
        cashRegisterName: params.cashRegister.description,
      );

      return Right(updatedTicket);
    } catch (e) {
      return Left(ServerFailure(
          'Error al asociar ticket con caja registradora: $e'));
    }
  }
}

class AssociateTicketWithCashRegisterParams {
  final TicketModel currentTicket;
  final CashRegister cashRegister;

  AssociateTicketWithCashRegisterParams({
    required this.currentTicket,
    required this.cashRegister,
  });
}
