import 'dart:convert';
import 'package:injectable/injectable.dart';
import 'package:sellweb/features/catalogue/domain/entities/product_catalogue.dart';
import '../repositories/account_repository.dart';
import '../entities/admin_profile.dart';
import '../entities/account_profile.dart';
import '../../../../core/services/storage/app_data_persistence_service.dart';

/// Caso de uso: Gestión de cuentas y perfiles de administrador
///
/// **Responsabilidad:**
/// - Coordina operaciones complejas con cuentas y perfiles
/// - Gestiona persistencia local de perfiles de administrador
/// - Proporciona datos de prueba para modo demo
/// - Delega operaciones básicas al repositorio
///
/// **Operaciones:**
/// - Obtener cuentas asociadas a un usuario
/// - Gestionar cuenta seleccionada (save/get/remove)
/// - Cargar/guardar AdminProfile localmente
/// - Proveer datos demo para usuarios invitados
@lazySingleton
class GetUserAccountsUseCase {
  final AccountRepository _repository;
  final AppDataPersistenceService _persistenceService;

  GetUserAccountsUseCase(
    this._repository,
    this._persistenceService,
  );

  // ==========================================
  // OPERACIONES DE REPOSITORIO
  // ==========================================

  /// Obtiene los administradores de cuentas asociados a un usuario por email
  ///
  /// Retorna lista de [AdminProfile] donde el usuario tiene acceso
  Future<List<AdminProfile>> getAccountAdmins(String email) async {
    return await _repository.getUserAccounts(email);
  }

  /// Obtiene los perfiles completos de cuentas asociadas a un usuario
  ///
  /// [email] Email del usuario autenticado
  /// Retorna lista de [AccountProfile] de las cuentas que administra
  Future<List<AccountProfile>> getProfilesAccountsAssociated(
      String email) async {
    print(
        '🔍 [GetUserAccountsUseCase] getProfilesAccountsAssociated - Iniciando para email: $email');

    // Obtiene los AdminProfile de las cuentas asociadas
    final accounts = await _repository.getUserAccounts(email);
    print(
        '📋 [GetUserAccountsUseCase] AdminProfiles obtenidos: ${accounts.length}');
    for (var admin in accounts) {
      print(
          '   - AdminProfile: account=${admin.account}, superAdmin=${admin.superAdmin}');
    }

    // Para cada cuenta, obtiene el perfil completo
    final profiles = <AccountProfile>[];
    for (final admin in accounts) {
      try {
        print(
            '🔄 [GetUserAccountsUseCase] Obteniendo perfil para cuenta: ${admin.account}');
        final profile = await getAccount(idAccount: admin.account);
        profiles.add(profile);
        print(
            '✅ [GetUserAccountsUseCase] Perfil agregado: ${profile.name} (${profile.id})');
      } catch (e) {
        print(
            '⚠️ [GetUserAccountsUseCase] Error obteniendo perfil para ${admin.account}: $e');
        // Si alguna cuenta no existe o falla, la omite
        continue;
      }
    }
    print(
        '🏁 [GetUserAccountsUseCase] Total de perfiles obtenidos: ${profiles.length}');
    return profiles;
  }

  /// Obtiene datos (perfil) de una cuenta específica por su ID
  ///
  /// [idAccount] ID de la cuenta a obtener
  /// Retorna [AccountProfile] de la cuenta
  /// Lanza excepción si la cuenta no existe
  Future<AccountProfile> getAccount({required String idAccount}) async {
    // Caso especial: cuenta demo
    if (idAccount == 'demo') {
      return _getDemoAccount();
    }

    final profileAccount = await _repository.getAccount(idAccount);
    if (profileAccount == null) {
      throw Exception('Cuenta no encontrada');
    }
    return profileAccount;
  }

  /// Guarda el ID de la cuenta seleccionada
  Future<void> saveSelectedAccountId(String accountId) async {
    await _repository.saveSelectedAccountId(accountId);
  }

  /// Obtiene el ID de la cuenta seleccionada
  Future<String?> getSelectedAccountId() async {
    return await _repository.getSelectedAccountId();
  }

  /// Remueve el ID de la cuenta seleccionada
  Future<void> removeSelectedAccountId() async {
    await _repository.removeSelectedAccountId();
  }

  // ==========================================
  // GESTIÓN DE ADMINPROFILE (Persistencia Local)
  // ==========================================

  /// Carga el AdminProfile guardado localmente
  ///
  /// Retorna [AdminProfile] si existe, null si no hay ninguno guardado
  Future<AdminProfile?> loadAdminProfile() async {
    final adminProfileJson = await _persistenceService.getCurrentAdminProfile();
    if (adminProfileJson == null || adminProfileJson.isEmpty) {
      return null;
    }

    try {
      final Map<String, dynamic> jsonMap =
          const JsonDecoder().convert(adminProfileJson) as Map<String, dynamic>;
      return _adminProfileFromMap(jsonMap);
    } catch (e) {
      return null;
    }
  }

  /// Guarda el AdminProfile localmente
  ///
  /// [adminProfile] Perfil de administrador a guardar
  Future<void> saveAdminProfile(AdminProfile adminProfile) async {
    try {
      final json = _adminProfileToJson(adminProfile);
      await _persistenceService.saveCurrentAdminProfile(jsonEncode(json));
    } catch (e) {
      throw Exception('Error al guardar AdminProfile en persistencia: $e');
    }
  }

  /// Limpia el AdminProfile guardado localmente
  Future<void> clearAdminProfile() async {
    await _persistenceService.clearCurrentAdminProfile();
  }

  /// Busca el AdminProfile correspondiente a un email y cuenta específica
  ///
  /// [email] Email del usuario autenticado
  /// [accountId] ID de la cuenta seleccionada (opcional)
  ///
  /// Si [accountId] está vacío, retorna el primer perfil encontrado
  /// Si [accountId] está especificado, busca el perfil correspondiente
  Future<AdminProfile?> fetchAdminProfile(
    String email, {
    String accountId = '',
  }) async {
    try {
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
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  // ==========================================
  // DATOS DEMO (Usuario Invitado)
  // ==========================================

  /// Agrega cuenta demo a la lista si el usuario es anónimo
  ///
  /// [accounts] Lista de cuentas existentes
  /// [isAnonymous] Si el usuario es invitado/anónimo
  /// Retorna lista con cuenta demo añadida si aplica
  List<AccountProfile> getAccountsWithDemo(
    List<AccountProfile> accounts, {
    bool isAnonymous = false,
  }) {
    final result = List<AccountProfile>.from(accounts);
    if (isAnonymous) {
      result.add(_getDemoAccount());
    }
    return result;
  }

  /// Retorna perfil de administrador de prueba para modo invitado
  AdminProfile getDemoAdminProfile() {
    return AdminProfile(
      email: 'invitado@demo.com',
      account: 'demo',
      admin: true,
      superAdmin: true,
      personalized: true,
      creation: DateTime.now(),
      lastUpdate: DateTime.now(),
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
              quantityStock: (100 - i).toDouble(),
              stock: true,
              alertStock: 10.0,
              currencySign: '24',
              creation: DateTime.now(),
              upgrade: DateTime.now(),
              documentCreation: DateTime.now(),
              documentUpgrade: DateTime.now(),
            ));
  }

  // ==========================================
  // MÉTODOS PRIVADOS
  // ==========================================

  /// Crea cuenta demo para modo invitado
  AccountProfile _getDemoAccount() {
    return AccountProfile(
      id: 'demo',
      name: 'Negocio de Prueba',
      country: 'Argentina',
      province: 'Buenos Aires',
      town: 'Demo City',
      image: 'https://cdn-icons-png.flaticon.com/512/869/869636.png',
      currencySign: '\$',
      creation: DateTime.now(),
      trialStart: DateTime.now(),
      trialEnd: DateTime.now().add(const Duration(days: 30)),
    );
  }

  /// Convierte AdminProfile a Map para JSON
  Map<String, dynamic> _adminProfileToJson(AdminProfile admin) {
    return {
      'id': admin.id,
      'inactivate': admin.inactivate,
      'inactivateNote': admin.inactivateNote,
      'account': admin.account,
      'email': admin.email,
      'name': admin.name,
      'superAdmin': admin.superAdmin,
      'admin': admin.admin,
      'personalized': admin.personalized,
      'creation': admin.creation.toIso8601String(),
      'lastUpdate': admin.lastUpdate.toIso8601String(),
      'startTime': admin.startTime,
      'endTime': admin.endTime,
      'daysOfWeek': admin.daysOfWeek,
      'arqueo': admin.arqueo,
      'historyArqueo': admin.historyArqueo,
      'transactions': admin.transactions,
      'catalogue': admin.catalogue,
      'multiuser': admin.multiuser,
      'editAccount': admin.editAccount,
    };
  }

  /// Convierte Map a AdminProfile desde JSON
  AdminProfile _adminProfileFromMap(Map<String, dynamic> data) {
    return AdminProfile(
      id: data['id'] ?? '',
      inactivate: data['inactivate'] ?? false,
      inactivateNote: data['inactivateNote'] ?? '',
      account: data['account'] ?? '',
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      superAdmin: data['superAdmin'] ?? false,
      admin: data['admin'] ?? false,
      personalized: data['personalized'] ?? false,
      creation: data['creation'] is String
          ? DateTime.parse(data['creation'])
          : DateTime.now(),
      lastUpdate: data['lastUpdate'] is String
          ? DateTime.parse(data['lastUpdate'])
          : DateTime.now(),
      startTime: data['startTime'] ?? {},
      endTime: data['endTime'] ?? {},
      daysOfWeek: (data['daysOfWeek'] as List?)?.cast<String>() ?? [],
      arqueo: data['arqueo'] ?? false,
      historyArqueo: data['historyArqueo'] ?? false,
      transactions: data['transactions'] ?? false,
      catalogue: data['catalogue'] ?? false,
      multiuser: data['multiuser'] ?? false,
      editAccount: data['editAccount'] ?? false,
    );
  }
}
