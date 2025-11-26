import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import 'package:sellweb/core/errors/failures.dart';
import 'package:sellweb/core/services/storage/app_data_persistence_service.dart';
import 'package:sellweb/core/usecases/usecase.dart';

/// Elimina el último ticket vendido del almacenamiento local
///
/// RESPONSABILIDAD: Limpiar ticket persistido
/// - Eliminar de SharedPreferences
@lazySingleton
class ClearLastSoldTicketUseCase implements UseCase<void, NoParams> {
  final AppDataPersistenceService _persistenceService;

  ClearLastSoldTicketUseCase(this._persistenceService);

  @override
  Future<Either<Failure, void>> call(NoParams params) async {
    try {
      await _persistenceService.clearLastSoldTicket();
      return Right(null);
    } catch (e) {
      return Left(CacheFailure('Error al limpiar último ticket: $e'));
    }
  }
}
