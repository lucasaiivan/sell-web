import 'package:injectable/injectable.dart';
import 'package:fpdart/fpdart.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/services/storage/app_data_persistence_service.dart';

/// Caso de uso: Limpiar AdminProfile guardado localmente
///
/// **Responsabilidad:**
/// - Elimina el AdminProfile de la persistencia local
@lazySingleton
class ClearAdminProfileUseCase extends UseCase<void, NoParams> {
  final AppDataPersistenceService _persistenceService;

  ClearAdminProfileUseCase({AppDataPersistenceService? persistenceService})
      : _persistenceService = persistenceService ?? AppDataPersistenceService.instance;

  /// Ejecuta la limpieza del AdminProfile
  ///
  /// Retorna [Right(void)] si es exitoso, [Left(Failure)] si falla
  @override
  Future<Either<Failure, void>> call(NoParams params) async {
    try {
      await _persistenceService.clearCurrentAdminProfile();
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Error al limpiar AdminProfile: ${e.toString()}'));
    }
  }
}
