import 'package:injectable/injectable.dart';
import 'package:fpdart/fpdart.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/account_repository.dart';

/// Caso de uso: Obtener ID de cuenta seleccionada
///
/// **Responsabilidad:**
/// - Obtiene el ID de la cuenta actualmente seleccionada
/// - Delega la operación al repositorio
@lazySingleton
class GetSelectedAccountIdUseCase extends UseCase<String?, NoParams> {
  final AccountRepository _repository;

  GetSelectedAccountIdUseCase(this._repository);

  /// Ejecuta la obtención del ID de cuenta seleccionada
  ///
  /// Retorna [Right(String?)] con el ID o null si no hay selección,
  /// [Left(Failure)] si falla
  @override
  Future<Either<Failure, String?>> call(NoParams params) async {
    try {
      final accountId = await _repository.getSelectedAccountId();
      return Right(accountId);
    } catch (e) {
      return Left(CacheFailure(
          'Error al obtener cuenta seleccionada: ${e.toString()}'));
    }
  }
}
