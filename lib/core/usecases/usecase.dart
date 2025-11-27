import 'package:fpdart/fpdart.dart';
import 'package:sellweb/core/errors/failures.dart';

/// Interfaz base para todos los casos de uso
/// [T] es el tipo de retorno del caso de uso
/// [Params] es el tipo de parámetro del caso de uso
abstract class UseCase<T, Params> {
  Future<Either<Failure, T>> call(Params params);
}


/// Clase para casos de uso sin parámetros
class NoParams {
  const NoParams();
}

/// Interfaz base para casos de uso que retornan un Stream
abstract class StreamUseCase<T, Params> {
  Stream<Either<Failure, T>> call(Params params);
}
