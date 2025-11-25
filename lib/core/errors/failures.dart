import 'package:equatable/equatable.dart';

/// Clase base para todos los fallos de la aplicación
abstract class Failure extends Equatable {
  final String message;

  const Failure(this.message);

  @override
  List<Object> get props => [message];
}

/// Fallo de servidor
class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Error de servidor']);
}

/// Fallo de caché
class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Error de caché']);
}

/// Fallo de red
class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Error de red']);
}
