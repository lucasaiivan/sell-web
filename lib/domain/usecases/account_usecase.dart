import '../entities/user.dart';
import '../repositories/account_repository.dart';
import '../entities/catalogue.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// case use : Cuentas asociada
class GetUserAccountsUseCase {
  final AccountRepository repository;

  GetUserAccountsUseCase(this.repository);

  /// Guarda el ID de la cuenta seleccionada
  Future<void> saveSelectedAccountId(String accountId) =>
      repository.saveSelectedAccountId(accountId);

  /// Obtiene el ID de la cuenta seleccionada
  Future<String?> getSelectedAccountId() => repository.getSelectedAccountId();

  /// Remueve el ID de la cuenta seleccionada
  Future<void> removeSelectedAccountId() =>
      repository.removeSelectedAccountId();

  /// Obtiene los administradores de cuentas asociados a un usuario por el email
  Future<List<AdminModel>> getAccountAdmins(String email) =>
      repository.getUserAccounts(email);

  /// Obtiene los perfiles de cuentas asociadas a un usuario por el email
  ///
  /// [email]: email del usuario autenticado
  /// Retorna una lista de [ProfileAccountModel] de las cuentas que administra
  Future<List<ProfileAccountModel>> getProfilesAccountsAsociateds(
      String email) async {
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

  /// Devuelve la lista de cuentas asociadas, agregando una cuenta demo si el usuario es anónimo.
  List<ProfileAccountModel> getAccountsWithDemo(
      List<ProfileAccountModel> accounts,
      {bool isAnonymous = false}) {
    final List<ProfileAccountModel> result = List.from(accounts);
    if (isAnonymous) {
      result.add(
        ProfileAccountModel(
          id: 'demo',
          name: 'Negocio de Prueba',
          country: 'DemoLand',
          province: 'DemoProvincia',
          town: 'DemoCiudad',
          image: '',
          currencySign: '24',
        ),
      );
    }
    return result;
  }

  /// Devuelve una lista de productos de prueba para la cuenta demo.
  List<ProductCatalogue> getDemoProducts({int count = 30}) {
    return List.generate(
        count,
        (i) => ProductCatalogue(
              id: 'demo_product_${i + 1}',
              nameMark: 'Marca Demo',
              image: '',
              description: 'Producto de prueba #${i + 1}',
              code: 'DEMO${(i + 1).toString().padLeft(3, '0')}',
              salePrice: 10.0 + i,
              quantityStock: 100 - i,
              stock: true,
              alertStock: 10,
              currencySign: '24',
              creation: Timestamp.now(),
              upgrade: Timestamp.now(),
              documentCreation: Timestamp.now(),
              documentUpgrade: Timestamp.now(),
            ));
  }
}
