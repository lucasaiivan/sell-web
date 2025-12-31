import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/errors/failures.dart';
import '../entities/account_profile.dart';
import '../repositories/auth_repository.dart';
import 'validate_username_usecase.dart';
import 'check_username_availability_usecase.dart';

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
  final ValidateUsernameUseCase _validateUsername;
  final CheckUsernameAvailabilityUseCase _checkAvailability;

  CreateBusinessAccountUseCase(
    this._repository,
    this._validateUsername,
    this._checkAvailability,
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
    // Validación 1: Username no vacío
    if (account.username.trim().isEmpty) {
      return Left(ValidationFailure('El nombre de usuario es requerido'));
    }

    // Validación 2: Formato de username
    final usernameValidation = _validateUsername.call(account.username);
    if (usernameValidation.isLeft()) {
      return usernameValidation.map((_) => account); // Retornar el error
    }

    final validatedUsername = usernameValidation.getOrElse((_) => '');

    // Validación 3: Disponibilidad de username
    final availabilityResult = await _checkAvailability.call(validatedUsername);
    final isAvailable = availabilityResult.getOrElse((_) => false);

    if (!isAvailable) {
      return Left(ValidationFailure(
        'El nombre de usuario "$validatedUsername" ya está en uso'));
    }

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

    // Crear cuenta con username validado (en minúsculas)
    final accountToCreate = account.copyWith(username: validatedUsername);

    // Llamar al repositorio
    return await _repository.createBusinessAccount(accountToCreate);
  }
}
