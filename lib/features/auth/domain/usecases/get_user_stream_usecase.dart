import 'package:injectable/injectable.dart';
import '../repositories/auth_repository.dart';
import '../entities/auth_profile.dart';

/// Caso de uso: Obtener stream del usuario autenticado
///
/// **Responsabilidad:**
/// - Proporciona un stream que emite cambios en el estado de autenticación
/// - Emite el perfil del usuario cuando está autenticado
/// - Emite null cuando no hay usuario autenticado
/// - Delega la operación al repositorio
@lazySingleton
class GetUserStreamUseCase {
  final AuthRepository _repository;

  GetUserStreamUseCase(this._repository);

  /// Obtiene el stream del usuario autenticado
  ///
  /// Retorna Stream<AuthProfile?> que emite el usuario actual o null
  Stream<AuthProfile?> call() {
    return _repository.user;
  }
}
