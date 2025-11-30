import 'package:injectable/injectable.dart';
import 'package:fpdart/fpdart.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/account_repository.dart';

/// Caso de uso: Remover ID de cuenta seleccionada
///
/// **Responsabilidad:**
/// - Limpia el ID de la cuenta seleccionada
/// - Delega la operación al repositorio
@lazySingleton
class RemoveSelectedAccountIdUseCase extends UseCase<void, NoParams> {
  final AccountRepository _repository;

  RemoveSelectedAccountIdUseCase(this._repository);

  /// Ejecuta la remoción del ID de cuenta seleccionada
  ///
  /// Retorna [Right(void)] si es exitoso, [Left(Failure)] si falla
  @override
  Future<Either<Failure, void>> call(NoParams params) async {
    try {
      await _repository.removeSelectedAccountId();
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(
          'Error al remover cuenta seleccionada: ${e.toString()}'));
    }
  }
}
