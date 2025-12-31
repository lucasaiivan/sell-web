import 'dart:convert';
import 'package:injectable/injectable.dart';
import 'package:fpdart/fpdart.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/services/storage/app_data_persistence_service.dart';
import '../entities/admin_profile.dart';

/// Caso de uso: Cargar AdminProfile guardado localmente
///
/// **Responsabilidad:**
/// - Carga el AdminProfile desde la persistencia local
/// - Deserializa el JSON a entidad AdminProfile
@lazySingleton
class LoadAdminProfileUseCase extends UseCase<AdminProfile?, NoParams> {
  final AppDataPersistenceService _persistenceService;

  LoadAdminProfileUseCase(this._persistenceService);

  /// Ejecuta la carga del AdminProfile local
  ///
  /// Retorna [Right(AdminProfile?)] con el perfil o null si no existe,
  /// [Left(Failure)] si falla la deserialización
  @override
  Future<Either<Failure, AdminProfile?>> call(NoParams params) async {
    try {
      final adminProfileJson =
          await _persistenceService.getCurrentAdminProfile();

      if (adminProfileJson == null || adminProfileJson.isEmpty) {
        return const Right(null);
      }

      final Map<String, dynamic> jsonMap =
          const JsonDecoder().convert(adminProfileJson) as Map<String, dynamic>;

      final adminProfile = _adminProfileFromMap(jsonMap);
      return Right(adminProfile);
    } catch (e) {
      return Left(
          CacheFailure('Error al cargar AdminProfile: ${e.toString()}'));
    }
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
      permissions: _getPermissionsFromMap(data),
    );
  }

  List<String> _getPermissionsFromMap(Map<String, dynamic> data) {
    List<String> permissions = data.containsKey("permissions")
        ? List<String>.from(data["permissions"])
        : [];

    // Migración manual
    if ((data['arqueo'] ?? false) && !permissions.contains(AdminPermission.createCashCount.name)) {
      permissions.add(AdminPermission.createCashCount.name);
    }
    if ((data['historyArqueo'] ?? false) && !permissions.contains(AdminPermission.viewCashCountHistory.name)) {
      permissions.add(AdminPermission.viewCashCountHistory.name);
    }
    if ((data['transactions'] ?? false) && !permissions.contains(AdminPermission.manageTransactions.name)) {
      permissions.add(AdminPermission.manageTransactions.name);
    }
    if ((data['catalogue'] ?? false) && !permissions.contains(AdminPermission.manageCatalogue.name)) {
      permissions.add(AdminPermission.manageCatalogue.name);
    }
    if ((data['multiuser'] ?? false) && !permissions.contains(AdminPermission.manageUsers.name)) {
      permissions.add(AdminPermission.manageUsers.name);
    }
    if ((data['editAccount'] ?? false) && !permissions.contains(AdminPermission.manageAccount.name)) {
      permissions.add(AdminPermission.manageAccount.name);
    }
    return permissions;
  }
}
