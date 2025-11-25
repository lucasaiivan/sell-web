import 'package:fpdart/fpdart.dart';
import 'package:sellweb/core/errors/failures.dart';

/// Interfaz base para todos los casos de uso
/// [Type] es el tipo de retorno del caso de uso
/// [Params] es el tipo de parámetro del caso de uso
abstract class UseCase<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}

/// Clase para casos de uso sin parámetros
class NoParams {
  const NoParams();
}
