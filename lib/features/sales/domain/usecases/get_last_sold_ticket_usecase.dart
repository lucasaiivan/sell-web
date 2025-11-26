import 'dart:convert';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import 'package:sellweb/core/errors/failures.dart';
import 'package:sellweb/core/services/storage/app_data_persistence_service.dart';
import 'package:sellweb/core/usecases/usecase.dart';
import 'package:sellweb/features/sales/domain/entities/ticket_model.dart';

/// Obtiene el último ticket vendido desde almacenamiento local
///
/// RESPONSABILIDAD: Recuperar ticket persistido
/// - Leer desde SharedPreferences
/// - Deserializar JSON a TicketModel
/// - Manejar casos de ticket corrupto o inexistente
@lazySingleton
class GetLastSoldTicketUseCase
    implements UseCase<TicketModel?, NoParams> {
  final AppDataPersistenceService _persistenceService;

  GetLastSoldTicketUseCase(this._persistenceService);

  @override
  Future<Either<Failure, TicketModel?>> call(NoParams params) async {
    try {
      final ticketJson = await _persistenceService.getLastSoldTicket();

      if (ticketJson == null || ticketJson.isEmpty) {
        return Right(null);
      }

      try {
        final ticketMap = jsonDecode(ticketJson) as Map<String, dynamic>;
        final ticket = TicketModel.sahredPreferencefromMap(ticketMap);
        return Right(ticket);
      } catch (e) {
        // Si falla la deserialización, limpiar ticket corrupto
        await _persistenceService.clearLastSoldTicket();
        return Right(null);
      }
    } catch (e) {
      return Left(CacheFailure('Error al obtener último ticket: $e'));
    }
  }
}
