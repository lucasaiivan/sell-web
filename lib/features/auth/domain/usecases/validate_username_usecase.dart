import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/errors/failures.dart';

///UseCase: Validar formato de username
///
/// **Responsabilidad:**
/// - Validar que el username cumpla con todas las reglas establecidas
/// - Convertir automáticamente a minúsculas
/// - Retornar el username validado o un error descriptivo
///
/// **Reglas de validación:**
/// 1. Solo caracteres: a-z (minúsculas), 0-9, punto (.), guion bajo (_)
/// 2. Longitud máxima: 30 caracteres
/// 3. Punto (.):
///    - No puede ir al inicio
///    - No puede ir al final
///    - No pueden ir dos seguidos (..)
/// 4. Guion bajo (_):
///    - Puede ir al inicio, final, o varias veces seguido
/// 5. No puede estar vacío
///
/// **Ejemplo de uso:**
/// ```dart
/// final useCase = ValidateUsernameUseCase();
/// final result = useCase.call('Mi_Tienda.Online');
/// result.fold(
///   (failure) => print(failure.message), // Error
///   (username) => print(username), // 'mi_tienda.online'
/// );
/// ```
@injectable
class ValidateUsernameUseCase {
  /// Ejecuta la validación del username
  ///
  /// **Parámetros:**
  /// - `username`: Username a validar
  ///
  /// **Retorna:**
  /// - `Right(String)`: Username validado en minúsculas si es válido
  /// - `Left(Failure)`: Error descriptivo si no cumple las reglas
  Either<Failure, String> call(String username) {
    // Validación 1: No puede estar vacío
    if (username.trim().isEmpty) {
      return Left(ValidationFailure('El nombre de usuario no puede estar vacío'));
    }

    // Convertir a minúsculas
    final lowerUsername = username.toLowerCase();

    // Validación 2: Longitud máxima
    if (lowerUsername.length > 30) {
      return Left(ValidationFailure('El nombre de usuario no puede exceder 30 caracteres'));
    }

    // Validación 3: Caracteres permitidos (a-z, 0-9, ., _)
    final validCharactersRegex = RegExp(r'^[a-z0-9._]+$');
    if (!validCharactersRegex.hasMatch(lowerUsername)) {
      return Left(ValidationFailure(
        'Solo se permiten letras (a-z), números (0-9), punto (.) y guion bajo (_)'));
    }

    // Validación 4: Punto no puede ir al inicio
    if (lowerUsername.startsWith('.')) {
      return Left(ValidationFailure('El punto (.) no puede ir al inicio'));
    }

    // Validación 5: Punto no puede ir al final
    if (lowerUsername.endsWith('.')) {
      return Left(ValidationFailure('El punto (.) no puede ir al final'));
    }

    // Validación 6: No pueden ir dos puntos seguidos
    if (lowerUsername.contains('..')) {
      return Left(ValidationFailure('El punto (.) no puede aparecer dos veces seguidas'));
    }

    // Todo válido
    return Right(lowerUsername);
  }

  /// Valida si un carácter es permitido
  ///
  /// **Parámetros:**
  /// - `char`: Carácter a validar
  ///
  /// **Retorna:** `true` si el carácter es permitido
  bool isValidCharacter(String char) {
    if (char.isEmpty) return false;
    final regex = RegExp(r'^[a-z0-9._]$');
    return regex.hasMatch(char.toLowerCase());
  }

  /// Obtiene mensaje de error para un username inválido
  ///
  /// **Útil para mostrar feedback en tiempo real en la UI**
  String? getValidationError(String username) {
    final result = call(username);
    return result.fold(
      (failure) => failure.message,
      (_) => null,
    );
  }
}
