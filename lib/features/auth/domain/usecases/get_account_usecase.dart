import 'package:injectable/injectable.dart';
import 'package:fpdart/fpdart.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/account_repository.dart';
import '../entities/account_profile.dart';

/// Parámetros para GetAccountUseCase
class GetAccountParams {
  final String accountId;

  const GetAccountParams(this.accountId);
}

/// Caso de uso: Obtener perfil de una cuenta específica
///
/// **Responsabilidad:**
/// - Obtiene el AccountProfile completo de una cuenta por su ID
/// - Delega la operación al repositorio
@lazySingleton
class GetAccountUseCase extends UseCase<AccountProfile, GetAccountParams> {
  final AccountRepository _repository;

  GetAccountUseCase(this._repository);

  /// Ejecuta la obtención del perfil de cuenta
  ///
  /// Retorna [Right(AccountProfile)] si es exitoso, [Left(Failure)] si falla
  @override
  Future<Either<Failure, AccountProfile>> call(GetAccountParams params) async {
    try {
      final profile = await _repository.getAccount(params.accountId);
      
      if (profile == null) {
        return Left(ServerFailure('Cuenta no encontrada'));
      }
      
      return Right(profile);
    } catch (e) {
      return Left(ServerFailure('Error al obtener cuenta: ${e.toString()}'));
    }
  }
}
