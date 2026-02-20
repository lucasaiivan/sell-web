import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/auth_repository.dart';

/// UseCase: Verificar disponibilidad de username
///
/// **Responsabilidad:**
/// - Consultar el repositorio para verificar si un username está disponible
/// - Retornar true si está disponible, false si ya existe
///
/// **Flujo:**
/// 1. Recibe un username (debe estar previamente validado)
/// 2. Consulta el repositorio
/// 3. Retorna disponibilidad
///
/// **Ejemplo de uso:**
/// ```dart
/// final result = await checkUsernameAvailability.call('mi_tienda');
/// result.fold(
///   (failure) => print('Error: ${failure.message}'),
///   (isAvailable) => print(isAvailable ? 'Disponible' : 'Ya existe'),
/// );
/// ```
@injectable
class CheckUsernameAvailabilityUseCase {
  final AuthRepository _repository;

  CheckUsernameAvailabilityUseCase(this._repository);

  /// Ejecuta la verificación de disponibilidad
  ///
  /// **Parámetros:**
  /// - `username`: Username a verificar (debe estar validado previamente)
  ///
  /// **Retorna:**
  /// - `Right(true)`: Username está disponible
  /// - `Right(false)`: Username ya existe
  /// - `Left(Failure)`: Error en la consulta
  Future<Either<Failure, bool>> call(String username) async {
    if (username.trim().isEmpty) {
      return Left(ValidationFailure('El nombre de usuario no puede estar vacío'));
    }

    // Consultar repositorio
    final result = await _repository.checkUsernameExists(username.toLowerCase());

    // Invertir el resultado (exists -> !available)
    return result.map((exists) => !exists);
  }
}
