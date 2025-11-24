import 'dart:convert';
import '../entities/user.dart';
import '../repositories/account_repository.dart';
import '../entities/catalogue.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/services/storage/app_data_persistence_service.dart';

// case use : Cuentas asociada
class AccountsUseCase {
  final AccountRepository repository;
  final AppDataPersistenceService _persistenceService;

  AccountsUseCase(this.repository,
      {AppDataPersistenceService? persistenceService})
      : _persistenceService =
            persistenceService ?? AppDataPersistenceService.instance;

  /// Guarda el ID de la cuenta seleccionada
  Future<void> saveSelectedAccountId(String accountId) =>
      repository.saveSelectedAccountId(accountId);

  /// Obtiene el ID de la cuenta seleccionada
  Future<String?> getSelectedAccountId() => repository.getSelectedAccountId();

  /// Remueve el ID de la cuenta seleccionada
  Future<void> removeSelectedAccountId() =>
      repository.removeSelectedAccountId();

  /// Obtiene los administradores de cuentas asociados a un usuario por el email
  Future<List<AdminProfile>> getAccountAdmins(String email) =>
      repository.getUserAccounts(email);

  /// Obtiene los perfiles de cuentas asociadas a un usuario por el email
  ///
  /// [email]: email del usuario autenticado
  /// Retorna una lista de [AccountProfile] de las cuentas que administra
  Future<List<AccountProfile>> getProfilesAccountsAsociateds(
      String email) async {
    // Obtiene los modelos de administrador (AdminModel) de las cuentas asociadas
    List<AdminProfile> accounts = await repository.getUserAccounts(email);
    // Para cada cuenta, obtiene el perfil completo (ProfileAccountModel)
    List<AccountProfile> profiles = [];
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
  Future<AccountProfile> getAccount({required String idAccount}) async {
    if (idAccount == 'demo') {
      return AccountProfile(
        id: 'demo',
        name: 'Negocio de Prueba',
        country: 'Argentina',
        province: 'Buenos Aires',
        town: 'Demo City',
        image: 'https://cdn-icons-png.flaticon.com/512/869/869636.png',
        currencySign: '\$',
      );
    }
    final profileAccount = await repository.getAccount(idAccount);
    if (profileAccount == null) throw Exception('Cuenta no encontrada');
    return profileAccount;
  }

  /// Devuelve la lista de cuentas asociadas, agregando una cuenta demo si el usuario es anónimo.
  List<AccountProfile> getAccountsWithDemo(List<AccountProfile> accounts,
      {bool isAnonymous = false}) {
    final List<AccountProfile> result = List.from(accounts);
    if (isAnonymous) {
      result.add(
        AccountProfile(
          id: 'demo',
          name: 'Negocio de Prueba',
          country: 'Argentina',
          province: 'Buenos Aires',
          town: 'Demo City',
          image:
              'https://cdn-icons-png.flaticon.com/512/869/869636.png', // Icono genérico de tienda
          currencySign: '\$',
        ),
      );
    }
    return result;
  }

  /// Devuelve un perfil de administrador de prueba para el modo invitado
  AdminProfile getDemoAdminProfile() {
    return AdminProfile(
      email: 'invitado@demo.com',
      account: 'demo',
      admin: true,
      superAdmin: true,
      personalized: true,
      creation: Timestamp.now(),
      lastUpdate: Timestamp.now(),
      // Habilitar todos los permisos
      arqueo: true,
      historyArqueo: true,
      transactions: true,
      catalogue: true,
      multiuser: true,
      editAccount: true,
    );
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

  // ==========================================
  // GESTIÓN DE ADMINPROFILE
  // ==========================================

  /// Carga el AdminProfile desde SharedPreferences
  Future<AdminProfile?> loadAdminProfile() async {
    final adminProfileJson = await _persistenceService.getCurrentAdminProfile();
    if (adminProfileJson == null || adminProfileJson.isEmpty) {
      return null;
    }

    try {
      final Map<String, dynamic> jsonMap =
          const JsonDecoder().convert(adminProfileJson) as Map<String, dynamic>;
      return AdminProfile.fromMap(jsonMap);
    } catch (e) {
      return null;
    }
  }

  /// Guarda el AdminProfile en SharedPreferences
  Future<void> saveAdminProfile(AdminProfile adminProfile) async {
    try {
      await _persistenceService.saveCurrentAdminProfile(
        jsonEncode(adminProfile.toJson()),
      );
    } catch (e) {
      throw Exception('Error al guardar AdminProfile en persistencia: $e');
    }
  }

  /// Limpia el AdminProfile guardado
  Future<void> clearAdminProfile() async {
    await _persistenceService.clearCurrentAdminProfile();
  }

  /// Busca el AdminProfile correspondiente a un email y cuenta específica
  ///
  /// [email] - Email del usuario autenticado
  /// [accountId] - ID de la cuenta seleccionada (opcional)
  ///
  /// Si [accountId] está vacío, retorna el primer perfil encontrado
  /// Si [accountId] está especificado, busca el perfil correspondiente a esa cuenta
  Future<AdminProfile?> fetchAdminProfile(String email,
      {String accountId = ''}) async {
    try {
      // Obtener todos los AdminProfile asociados al email
      final adminProfiles = await getAccountAdmins(email);

      if (adminProfiles.isEmpty) {
        return null;
      }

      // Si no hay cuenta seleccionada, retornar el primero
      if (accountId.isEmpty) {
        return adminProfiles.first;
      }

      // Buscar el AdminProfile que corresponde a la cuenta seleccionada
      try {
        return adminProfiles.firstWhere(
          (admin) => admin.account == accountId,
        );
      } catch (_) {
        // Si no se encuentra, retornar null
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  /// Carga el ID de la cuenta seleccionada desde SharedPreferences
  Future<String?> loadSelectedAccountId() async {
    return await _persistenceService.getSelectedAccountId();
  }

  /// Guarda el ID de la cuenta seleccionada en SharedPreferences
  Future<void> saveAccountId(String accountId) async {
    await _persistenceService.saveSelectedAccountId(accountId);
  }
}
