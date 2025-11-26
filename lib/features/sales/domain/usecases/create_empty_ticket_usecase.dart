import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import 'package:sellweb/core/errors/failures.dart';
import 'package:sellweb/core/usecases/usecase.dart';
import 'package:sellweb/features/sales/domain/entities/ticket_model.dart';

/// Crea un ticket vacío para iniciar una nueva venta
///
/// RESPONSABILIDAD: Crear ticket temporal en memoria
/// - Inicializar con lista de productos vacía
/// - Asignar timestamp de creación
@lazySingleton
class CreateEmptyTicketUseCase implements UseCase<TicketModel, NoParams> {
  @override
  Future<Either<Failure, TicketModel>> call(NoParams params) async {
    try {
      return Right(TicketModel(
        listPoduct: [],
        creation: Timestamp.now(),
      ));
    } catch (e) {
      return Left(ServerFailure('Error al crear ticket vacío: $e'));
    }
  }
}
