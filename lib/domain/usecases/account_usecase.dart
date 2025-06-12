import '../entities/user.dart';
import '../repositories/account_repository.dart';

class GetUserAccountsUseCase {
  final AccountRepository repository;

  GetUserAccountsUseCase(this.repository);

  /// Obtiene los administradores de cuentas asociados a un usuario por el email
  Future<List<AdminModel>> getAccountAdmins(String email) => repository.getUserAccounts(email);

  /// Obtiene los perfiles de cuentas asociadas a un usuario por el email
  ///
  /// [email]: email del usuario autenticado
  /// Retorna una lista de [ProfileAccountModel] de las cuentas que administra
  Future<List<ProfileAccountModel>> getProfilesAccountsAsociateds(String email) async {
    // Obtiene los modelos de administrador (AdminModel) de las cuentas asociadas
    List<AdminModel> accounts = await repository.getUserAccounts(email);
    // Para cada cuenta, obtiene el perfil completo (ProfileAccountModel)
    List<ProfileAccountModel> profiles = [];
    for (final admin in accounts) {
      try {
        final profile = await getAccount(idAccount: admin.account);
        profiles.add(profile);
      } catch (_) {
        // Si alguna cuenta no existe o falla, la omite
        continue;
      }
    }
    return profiles;
  }

  /// Obtiene datos (perfil) de una cuenta específica por su ID
  Future<ProfileAccountModel> getAccount({required String idAccount}) async {
    final profileAccount = await repository.getAccount(idAccount);
    if (profileAccount == null) throw Exception('Cuenta no encontrada'); 
    return profileAccount;
  }
}
