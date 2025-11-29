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
      final adminProfileJson = await _persistenceService.getCurrentAdminProfile();
      
      if (adminProfileJson == null || adminProfileJson.isEmpty) {
        return const Right(null);
      }

      final Map<String, dynamic> jsonMap =
          const JsonDecoder().convert(adminProfileJson) as Map<String, dynamic>;
      
      final adminProfile = _adminProfileFromMap(jsonMap);
      return Right(adminProfile);
    } catch (e) {
      return Left(CacheFailure('Error al cargar AdminProfile: ${e.toString()}'));
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
      arqueo: data['arqueo'] ?? false,
      historyArqueo: data['historyArqueo'] ?? false,
      transactions: data['transactions'] ?? false,
      catalogue: data['catalogue'] ?? false,
      multiuser: data['multiuser'] ?? false,
      editAccount: data['editAccount'] ?? false,
    );
  }
}
