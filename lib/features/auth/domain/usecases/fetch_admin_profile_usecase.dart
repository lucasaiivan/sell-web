import 'package:injectable/injectable.dart';
import 'package:fpdart/fpdart.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/errors/failures.dart';
import '../entities/admin_profile.dart';
import 'get_account_admins_usecase.dart';

/// Parámetros para FetchAdminProfileUseCase
class FetchAdminProfileParams {
  final String email;
  final String accountId;

  const FetchAdminProfileParams({
    required this.email,
    this.accountId = '',
  });
}

/// Caso de uso: Buscar AdminProfile específico
///
/// **Responsabilidad:**
/// - Busca el AdminProfile correspondiente a un email y cuenta
/// - Si no hay accountId, retorna el primer perfil encontrado
/// - Si hay accountId, busca el perfil específico de esa cuenta
@lazySingleton
class FetchAdminProfileUseCase
    extends UseCase<AdminProfile?, FetchAdminProfileParams> {
  final GetAccountAdminsUseCase _getAccountAdminsUseCase;

  FetchAdminProfileUseCase(this._getAccountAdminsUseCase);

  /// Ejecuta la búsqueda del AdminProfile
  ///
  /// Retorna [Right(AdminProfile?)] con el perfil o null si no existe,
  /// [Left(Failure)] si falla
  @override
  Future<Either<Failure, AdminProfile?>> call(
      FetchAdminProfileParams params) async {
    final adminsResult =
        await _getAccountAdminsUseCase(GetAccountAdminsParams(params.email));

    return adminsResult.fold(
      (failure) => Left(failure),
      (adminProfiles) {
        if (adminProfiles.isEmpty) {
          return const Right(null);
        }

        // Si no hay cuenta seleccionada, retornar el primero
        if (params.accountId.isEmpty) {
          return Right(adminProfiles.first);
        }

        // Buscar el AdminProfile que corresponde a la cuenta seleccionada
        try {
          final admin = adminProfiles.firstWhere(
            (admin) => admin.account == params.accountId,
          );
          return Right(admin);
        } catch (_) {
          return const Right(null);
        }
      },
    );
  }
}
