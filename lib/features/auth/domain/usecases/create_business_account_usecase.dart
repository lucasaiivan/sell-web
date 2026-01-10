import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/errors/failures.dart';
import '../entities/account_profile.dart';
import '../repositories/auth_repository.dart';

/// UseCase: Crear nueva cuenta comercio
///
/// **Responsabilidad:**
/// - Validar todos los datos de la cuenta
/// - Verificar disponibilidad del username
/// - Crear la cuenta en Firestore
/// - Asociar al usuario actual como propietario
///
/// **Validaciones:**
/// 1. Username válido (formato)
/// 2. Username disponible (único)
/// 3. Nombre del negocio no vacío
/// 4. Moneda válida
///
/// **Ejemplo de uso:**
/// ```dart
/// final account = AccountProfile(
///   username: 'mi_tienda',
///   name: 'Mi Tienda Online',
///   currencySign: 'AR\$',
///   ownerId: currentAdminId,
///   // ... otros campos
/// );
/// 
/// final result = await createBusinessAccount.call(account);
/// result.fold(
///   (failure) => showError(failure.message),
///   (createdAccount) => navigateToAccount(createdAccount),
/// );
/// ```
@injectable
class CreateBusinessAccountUseCase {
  final AuthRepository _repository;
  CreateBusinessAccountUseCase(
    this._repository,
  );

  /// Ejecuta la creación de la cuenta
  ///
  /// **Parámetros:**
  /// - `account`: Perfil de cuenta a crear
  ///
  /// **Retorna:**
  /// - `Right(AccountProfile)`: Cuenta creada exitosamente
  /// - `Left(Failure)`: Error en validación o creación
  Future<Either<Failure, AccountProfile>> call(AccountProfile account) async {
    // Validaciones 1, 2, 3 eliminadas: Username ya no es requerido

    // Validación 4: Nombre del negocio no vacío
    if (account.name.trim().isEmpty) {
      return Left(ValidationFailure('El nombre del negocio es requerido'));
    }

    // Validación 5: Moneda válida
    if (account.currencySign.trim().isEmpty) {
      return Left(ValidationFailure('Debe seleccionar una moneda'));
    }

    // Validación 6: Owner ID presente
    if (account.ownerId.trim().isEmpty) {
      return Left(ValidationFailure('Error: No se pudo identificar al propietario'));
    }

    // Llamar al repositorio
    return await _repository.createBusinessAccount(account);
  }
}
