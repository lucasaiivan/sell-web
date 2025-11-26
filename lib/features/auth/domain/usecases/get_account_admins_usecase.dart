import 'package:injectable/injectable.dart';
import 'package:fpdart/fpdart.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/account_repository.dart';
import '../entities/admin_profile.dart';

/// Parámetros para GetAccountAdminsUseCase
class GetAccountAdminsParams {
  final String email;

  const GetAccountAdminsParams(this.email);
}

/// Caso de uso: Obtener administradores de cuentas por email
///
/// **Responsabilidad:**
/// - Obtiene los AdminProfile de las cuentas donde el usuario tiene acceso
/// - Delega la operación al repositorio
@lazySingleton
class GetAccountAdminsUseCase extends UseCase<List<AdminProfile>, GetAccountAdminsParams> {
  final AccountRepository _repository;

  GetAccountAdminsUseCase(this._repository);

  /// Ejecuta la obtención de administradores
  ///
  /// Retorna [Right(List<AdminProfile>)] si es exitoso, [Left(Failure)] si falla
  @override
  Future<Either<Failure, List<AdminProfile>>> call(GetAccountAdminsParams params) async {
    try {
      final admins = await _repository.getUserAccounts(params.email);
      return Right(admins);
    } catch (e) {
      return Left(ServerFailure('Error al obtener administradores: ${e.toString()}'));
    }
  }
}
