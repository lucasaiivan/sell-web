import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/errors/failures.dart';
import '../entities/account_profile.dart';
import '../entities/admin_profile.dart';
import '../repositories/auth_repository.dart';

/// UseCase: Actualizar cuenta comercio existente
///
/// **Responsabilidad:**
/// - Verificar permisos del usuario (propietario o permiso manageAccount)
/// - Validar datos modificables
/// - Actualizar la cuenta en Firestore
///
/// **Campos editables:**
/// - Nombre del negocio
/// - Moneda
/// - País, provincia, ciudad
/// - Imagen
///
/// **Campos NO editables:**
/// - Username (por diseño, mantener inmutable)
/// - ID
/// - OwnerId
///
/// **Ejemplo de uso:**
/// ```dart
/// final updatedAccount = currentAccount.copyWith(
///   name: 'Nuevo Nombre',
///   currencySign: 'US\$',
/// );
/// 
/// final result = await updateBusinessAccount.call(
///   account: updatedAccount,
///   currentAdmin: currentAdminProfile,
/// );
/// 
/// result.fold(
///   (failure) => showError(failure.message),
///   (_) => showSuccess('Cuenta actualizada'),
/// );
/// ```
@injectable
class UpdateBusinessAccountUseCase {
  final AuthRepository _repository;

  UpdateBusinessAccountUseCase(this._repository);

  /// Ejecuta la actualización de la cuenta
  ///
  /// **Parámetros:**
  /// - `account`: Perfil de cuenta con cambios a aplicar
  /// - `currentAdmin`: Perfil del administrador que realiza el cambio
  ///
  /// **Retorna:**
  /// - `Right(void)`: Actualización exitosa
  /// - `Left(Failure)`: Error en permisos o actualización
  Future<Either<Failure, void>> call({
    required AccountProfile account,
    required AdminProfile currentAdmin,
  }) async {
    // Validación 1: Verificar permisos
    final hasPermission = account.isOwner(currentAdmin.id) ||
        currentAdmin.hasPermission(AdminPermission.manageAccount);

    if (!hasPermission) {
      return Left(PermissionFailure(
        'No tienes permisos para editar esta cuenta'));
    }

    // Validación 2: ID de cuenta presente
    if (account.id.trim().isEmpty) {
      return Left(ValidationFailure('Error: ID de cuenta inválido'));
    }

    // Validación 3: Nombre del negocio no vacío
    if (account.name.trim().isEmpty) {
      return Left(ValidationFailure('El nombre del negocio es requerido'));
    }

    // Validación 4: Moneda válida
    if (account.currencySign.trim().isEmpty) {
      return Left(ValidationFailure('Debe seleccionar una moneda'));
    }

    // Llamar al repositorio
    return await _repository.updateBusinessAccount(account);
  }
}
