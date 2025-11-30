import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import 'package:sellweb/core/errors/failures.dart';
import 'package:sellweb/core/usecases/usecase.dart';
import 'package:sellweb/features/sales/domain/entities/ticket_model.dart';

/// Asigna un vendedor al ticket
///
/// RESPONSABILIDAD: Vincular ticket con vendedor
/// - Validar sellerId no vacío
/// - Validar sellerName no vacío
/// - Establecer datos del vendedor en ticket
@lazySingleton
class AssignSellerToTicketUseCase
    implements UseCase<TicketModel, AssignSellerToTicketParams> {
  @override
  Future<Either<Failure, TicketModel>> call(
      AssignSellerToTicketParams params) async {
    try {
      if (params.sellerId.trim().isEmpty) {
        return Left(
            ValidationFailure('El ID del vendedor no puede estar vacío'));
      }

      if (params.sellerName.trim().isEmpty) {
        return Left(
            ValidationFailure('El nombre del vendedor no puede estar vacío'));
      }

      final updatedTicket = params.currentTicket.copyWith(
        sellerId: params.sellerId,
        sellerName: params.sellerName,
      );

      return Right(updatedTicket);
    } catch (e) {
      return Left(ServerFailure('Error al asignar vendedor al ticket: $e'));
    }
  }
}

class AssignSellerToTicketParams {
  final TicketModel currentTicket;
  final String sellerId;
  final String sellerName;

  AssignSellerToTicketParams({
    required this.currentTicket,
    required this.sellerId,
    required this.sellerName,
  });
}
