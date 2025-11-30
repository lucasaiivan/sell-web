import 'dart:convert';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import 'package:sellweb/core/errors/failures.dart';
import 'package:sellweb/core/services/storage/app_data_persistence_service.dart';
import 'package:sellweb/core/usecases/usecase.dart';
import 'package:sellweb/features/sales/domain/entities/ticket_model.dart';

/// Guarda el último ticket vendido en almacenamiento local (SharedPreferences)
///
/// RESPONSABILIDAD: Persistir ticket para recuperación posterior
/// - Validar ticket (ID, productos, precio total)
/// - Serializar a JSON
/// - Guardar en SharedPreferences
@lazySingleton
class SaveLastSoldTicketUseCase
    implements UseCase<void, SaveLastSoldTicketParams> {
  final AppDataPersistenceService _persistenceService;

  SaveLastSoldTicketUseCase(this._persistenceService);

  @override
  Future<Either<Failure, void>> call(SaveLastSoldTicketParams params) async {
    try {
      if (params.ticket.id.trim().isEmpty) {
        return Left(
            ValidationFailure('El ticket debe tener un ID para ser guardado'));
      }

      if (params.ticket.products.isEmpty) {
        return Left(
            ValidationFailure('El ticket debe tener al menos un producto'));
      }

      if (params.ticket.priceTotal <= 0) {
        return Left(
            ValidationFailure('El ticket debe tener un precio total válido'));
      }

      final ticketJson = jsonEncode(params.ticket.toJson());
      await _persistenceService.saveLastSoldTicket(ticketJson);

      return Right(null);
    } catch (e) {
      return Left(CacheFailure('Error al guardar último ticket: $e'));
    }
  }
}

class SaveLastSoldTicketParams {
  final TicketModel ticket;

  SaveLastSoldTicketParams({
    required this.ticket,
  });
}
