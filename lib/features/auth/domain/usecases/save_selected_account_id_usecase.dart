import 'package:injectable/injectable.dart';
import 'package:fpdart/fpdart.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/account_repository.dart';

/// Parámetros para SaveSelectedAccountIdUseCase
class SaveSelectedAccountIdParams {
  final String accountId;

  const SaveSelectedAccountIdParams(this.accountId);
}

/// Caso de uso: Guardar ID de cuenta seleccionada
///
/// **Responsabilidad:**
/// - Guarda el ID de la cuenta actualmente seleccionada por el usuario
/// - Delega la persistencia al repositorio
@lazySingleton
class SaveSelectedAccountIdUseCase
    extends UseCase<void, SaveSelectedAccountIdParams> {
  final AccountRepository _repository;

  SaveSelectedAccountIdUseCase(this._repository);

  /// Ejecuta el guardado del ID de cuenta seleccionada
  ///
  /// Retorna [Right(void)] si es exitoso, [Left(Failure)] si falla
  @override
  Future<Either<Failure, void>> call(SaveSelectedAccountIdParams params) async {
    try {
      await _repository.saveSelectedAccountId(params.accountId);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(
          'Error al guardar cuenta seleccionada: ${e.toString()}'));
    }
  }
}
