import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import 'package:sellweb/core/errors/failures.dart';
import 'package:sellweb/core/services/storage/app_data_persistence_service.dart';
import 'package:sellweb/core/usecases/usecase.dart';

/// Verifica si existe un último ticket guardado en almacenamiento local
///
/// RESPONSABILIDAD: Comprobar existencia de ticket persistido
/// - Verificar SharedPreferences
/// - Retornar true/false según existencia
@lazySingleton
class HasLastSoldTicketUseCase implements UseCase<bool, NoParams> {
  final AppDataPersistenceService _persistenceService;

  HasLastSoldTicketUseCase(this._persistenceService);

  @override
  Future<Either<Failure, bool>> call(NoParams params) async {
    try {
      final ticketJson = await _persistenceService.getLastSoldTicket();
      return Right(ticketJson != null && ticketJson.isNotEmpty);
    } catch (e) {
      return Left(CacheFailure('Error al verificar último ticket: $e'));
    }
  }
}
