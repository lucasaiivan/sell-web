import 'dart:convert';
import 'package:injectable/injectable.dart';
import 'package:fpdart/fpdart.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/services/storage/app_data_persistence_service.dart';
import '../entities/admin_profile.dart';

/// Parámetros para SaveAdminProfileUseCase
class SaveAdminProfileParams {
  final AdminProfile adminProfile;

  const SaveAdminProfileParams(this.adminProfile);
}

/// Caso de uso: Guardar AdminProfile localmente
///
/// **Responsabilidad:**
/// - Serializa AdminProfile a JSON
/// - Guarda el JSON en persistencia local
@lazySingleton
class SaveAdminProfileUseCase extends UseCase<void, SaveAdminProfileParams> {
  final AppDataPersistenceService _persistenceService;

  SaveAdminProfileUseCase(this._persistenceService);

  /// Ejecuta el guardado del AdminProfile
  ///
  /// Retorna [Right(void)] si es exitoso, [Left(Failure)] si falla
  @override
  Future<Either<Failure, void>> call(SaveAdminProfileParams params) async {
    try {
      final json = _adminProfileToJson(params.adminProfile);
      await _persistenceService.saveCurrentAdminProfile(jsonEncode(json));
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Error al guardar AdminProfile: ${e.toString()}'));
    }
  }

  /// Convierte AdminProfile a Map para JSON
  Map<String, dynamic> _adminProfileToJson(AdminProfile admin) {
    return {
      'id': admin.id,
      'inactivate': admin.inactivate,
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
}
