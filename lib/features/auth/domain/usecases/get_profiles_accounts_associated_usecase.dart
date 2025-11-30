import 'package:injectable/injectable.dart';
import 'package:fpdart/fpdart.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/errors/failures.dart';
import '../entities/account_profile.dart';
import 'get_account_admins_usecase.dart';
import 'get_account_usecase.dart';

/// Parámetros para GetProfilesAccountsAssociatedUseCase
class GetProfilesAccountsAssociatedParams {
  final String email;

  const GetProfilesAccountsAssociatedParams(this.email);
}

/// Caso de uso: Obtener perfiles completos de cuentas asociadas a un usuario
///
/// **Responsabilidad:**
/// - Obtiene los AdminProfile del usuario y luego los AccountProfile completos
/// - Coordina múltiples llamadas para obtener datos completos
/// - Omite cuentas que no existan o fallen
@lazySingleton
class GetProfilesAccountsAssociatedUseCase
    extends UseCase<List<AccountProfile>, GetProfilesAccountsAssociatedParams> {
  final GetAccountAdminsUseCase _getAccountAdminsUseCase;
  final GetAccountUseCase _getAccountUseCase;

  GetProfilesAccountsAssociatedUseCase(
    this._getAccountAdminsUseCase,
    this._getAccountUseCase,
  );

  /// Ejecuta la obtención de perfiles de cuentas asociadas
  ///
  /// Retorna [Right(List<AccountProfile>)] con los perfiles disponibles,
  /// [Left(Failure)] si falla completamente
  @override
  Future<Either<Failure, List<AccountProfile>>> call(
      GetProfilesAccountsAssociatedParams params) async {
    print(
        '🔍 [GetProfilesAccountsAssociatedUseCase] Iniciando para email: ${params.email}');

    // Obtiene los AdminProfile
    final adminsResult =
        await _getAccountAdminsUseCase(GetAccountAdminsParams(params.email));

    return adminsResult.fold(
      (failure) {
        print(
            '❌ [GetProfilesAccountsAssociatedUseCase] Error obteniendo AdminProfiles: $failure');
        return Left(failure);
      },
      (admins) async {
        print(
            '📋 [GetProfilesAccountsAssociatedUseCase] AdminProfiles obtenidos: ${admins.length}');

        final profiles = <AccountProfile>[];

        // Para cada admin, obtiene el perfil completo
        for (final admin in admins) {
          print(
              '🔄 [GetProfilesAccountsAssociatedUseCase] Obteniendo perfil para cuenta: ${admin.account}');

          final profileResult =
              await _getAccountUseCase(GetAccountParams(admin.account));

          profileResult.fold(
            (failure) {
              print(
                  '⚠️ [GetProfilesAccountsAssociatedUseCase] Error obteniendo perfil para ${admin.account}: $failure');
              // Continúa con la siguiente cuenta
            },
            (profile) {
              profiles.add(profile);
              print(
                  '✅ [GetProfilesAccountsAssociatedUseCase] Perfil agregado: ${profile.name} (${profile.id})');
            },
          );
        }

        print(
            '🏁 [GetProfilesAccountsAssociatedUseCase] Total de perfiles obtenidos: ${profiles.length}');
        return Right(profiles);
      },
    );
  }
}
