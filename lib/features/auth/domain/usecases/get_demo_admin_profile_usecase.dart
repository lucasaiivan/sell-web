import 'package:injectable/injectable.dart';
import 'package:fpdart/fpdart.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/errors/failures.dart';
import '../entities/admin_profile.dart';

/// Caso de uso: Obtener AdminProfile demo para usuarios invitados
///
/// **Responsabilidad:**
/// - Genera un AdminProfile de prueba con todos los permisos habilitados
@lazySingleton
class GetDemoAdminProfileUseCase extends UseCase<AdminProfile, NoParams> {
  GetDemoAdminProfileUseCase();

  /// Ejecuta la generación de AdminProfile demo
  ///
  /// Retorna [Right(AdminProfile)] con el perfil demo
  @override
  Future<Either<Failure, AdminProfile>> call(NoParams params) async {
    try {
      final demoAdmin = AdminProfile(
        email: 'invitado@demo.com',
        account: 'demo',
        admin: true,
        superAdmin: true,
        personalized: true,
        creation: DateTime.now(),
        lastUpdate: DateTime.now(),
        // Habilitar todos los permisos
        // Habilitar todos los permisos
        permissions: AdminPermission.values.map((e) => e.name).toList(),
      );

      return Right(demoAdmin);
    } catch (e) {
      return Left(
          ServerFailure('Error al generar AdminProfile demo: ${e.toString()}'));
    }
  }
}
